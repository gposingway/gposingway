////////////////////////////////////////////////////////////////////////////////////////////////////////
// Realistic Long-Exposure (RealLongExposure.fx) by SirCobra
// Version 0.5.3
// You can find info and all my shaders here: https://github.com/LordKobra/CobraFX
//
// --------Description---------
// RealLongExposure.fx enables you to capture changes over time, like in long-exposure photography.
// It will record the game's output for a user-defined amount of seconds, to create the final image,
// just as a camera would do in real life.
//
// ----------Credits-----------
// Thanks to Marty McFly, papadanku and Lord of Lunacy for many performance tips!
////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "Reshade.fxh"

uniform float timer <
    source = "timer";
> ;

// Shader Start

// Namespace Everything!

namespace COBRA_RLE
{

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                            Defines & UI
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Defines
    #define COBRA_RLE_VERSION "0.5.3"

    #define COBRA_UTL_MODE 0
    #include ".\CobraUtility.fxh"

    #define COBRA_RLE_TIME_MAX 16777216 // 2^24 because of 23 bit fraction plus 'implicit leading bit'

    // Optional Compute Shader Support and R32I support from ReShade 5.9
    #if (((__RENDERER__ >= 0xb000 && __RENDERER__ < 0x10000) || (__RENDERER__ >= 0x14300)) && __RESHADE__ >= 50900)
        #define COBRA_RLE_COMPUTE 1
    #else
        #define COBRA_RLE_COMPUTE 0
    #endif

    #define COBRA_RLE_YSIZE 20
    // UI

    uniform float UI_ExposureDuration <
        ui_label     = " Exposure Duration";
        ui_type      = "slider";
        ui_spacing   = 2;
        ui_min       = 0.1;
        ui_max       = 120.0;
        ui_step      = 0.1;
        ui_units     = "s";
        ui_tooltip   = "Exposure duration in seconds.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.0;

    uniform bool UI_StartExposure <
        ui_label     = " Start Exposure";
        ui_tooltip   = "Click to start the exposure process. It will run for the given amount of seconds and then freeze.\n"
                       "TIP: Bind this to a hotkey for convenient usage (right-click the button).";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform bool UI_ShowProgress <
        ui_label     = " Show Progress";
        ui_tooltip   = "Display a circular progress bar at the top during the exposure.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform bool UI_ShowGreenOnFinish <
        ui_label     = " Show Green Dot On Finish";
        ui_tooltip   = "Display a green dot at the top to signalize the exposure has finished and entered preview mode.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform float UI_ISO <
        ui_label     = " ISO";
        ui_type      = "slider";
        ui_min       = 100.0;
        ui_max       = 1600.0;
        ui_step      = 1.0;
        ui_tooltip   = "Sensitivity to light. 100 is normalized to the game. 1600 is 16 times the sensitivity.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 100.0;

    uniform float UI_Gamma <
        ui_label     = " Gamma";
        ui_type      = "slider";
        ui_min       = 0.4;
        ui_max       = 4.4;
        ui_step      = 0.01;
        ui_tooltip   = "The gamma correction value. The default value is 1. The higher this value, the more persistent\n"
                       "highlights will be.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.0;

    uniform uint UI_Delay <
        ui_label     = " Delay";
        ui_type      = "slider";
        ui_min       = 0;
        ui_max       = 100;
        ui_step      = 1;
        ui_units     = "ms";
        ui_tooltip   = "The delay before exposure starts in milliseconds.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1;

    uniform int UI_BufferEnd <
        ui_type     = "radio";
        ui_spacing  = 2;
        ui_text     = " Shader Version: " COBRA_RLE_VERSION;
        ui_label    = " ";
    > ;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                         Textures & Samplers
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Texture

    texture TEX_Exposure
    {
        Width  = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA32F;
    };

    texture TEX_Timer
    {
        Width  = 1;
        Height = 1;
        Format = RGBA32F;
    };

#if COBRA_RLE_COMPUTE == 0

    texture TEX_ExposureCopy
    {
        Width  = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA32F;
    };

    texture TEX_TimerCopy
    {
        Width  = 1;
        Height = 1;
        Format = RG32F;
    };
#else

    texture TEX_SyncCount
    {
        Width  = 1;
        Height = 1;
        Format = R32U;
    };

#endif

    // Sampler

    sampler2D SAM_Exposure
    {
        Texture   = TEX_Exposure;
        MagFilter = POINT;
        MinFilter = POINT;
        MipFilter = POINT;
    };

    sampler2D SAM_Timer
    {
        Texture   = TEX_Timer;
        MagFilter = POINT;
        MinFilter = POINT;
        MipFilter = POINT;
    };

#if COBRA_RLE_COMPUTE == 0

    sampler2D SAM_ExposureCopy
    {
        Texture   = TEX_ExposureCopy;
        MagFilter = POINT;
        MinFilter = POINT;
        MipFilter = POINT;
    };

    sampler2D SAM_TimerCopy
    {
        Texture   = TEX_TimerCopy;
        MagFilter = POINT;
        MinFilter = POINT;
        MipFilter = POINT;
    };
#else

    // Storage

    storage2D<float4> STOR_Exposure { Texture = TEX_Exposure; };
    storage2D<float4> STOR_Timer { Texture = TEX_Timer; };
    storage<uint> STOR_SyncCount { Texture = TEX_SyncCount; };

#endif

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                           Helper Functions
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    #define COBRA_UTL_MODE 2
    #include ".\CobraUtility.fxh"

    // return the exposure weight of a single frame
    float4 get_exposure(float4 value)
    {
        float iso_norm = UI_ISO * 0.01;
        value.rgb      = iso_norm * pow(abs(value.rgb), UI_Gamma);
        return value;
    }

    float4 show_progress(float2 texcoord, float4 fragment, float progress)
    {
        const float2 POS  = float2(0.5, 0.07);
        const float RANGE = 0.05;
        const float2 AR   = float2(BUFFER_ASPECT_RATIO, 1.0);
        float2 tx         = (texcoord - POS) * AR;
        float angle       = (atan2_approx(tx.x, tx.y) + M_PI) / (2 * M_PI);
        float intensity   = (sqrt(dot(abs(tx), abs(tx))) - RANGE) * 100;
        intensity         = progress > 1.0 ? (1 - saturate(intensity)) * UI_ShowGreenOnFinish : (1 - abs(intensity)) * UI_ShowProgress;
        if (intensity > 0.0 && intensity <= 1.0 && progress < 1.0)
        {
            fragment = lerp(fragment, float4(0.0, 0.0, 0.0, 1.0), 0.65 * saturate(intensity * 4));
        }

        intensity = intensity * 0.7;
        if (intensity > 0.0 && intensity <= 1.0 && progress > angle)
        {
            fragment = lerp(fragment, float4(0.3, 0.7, 0.3, 1.0), saturate(intensity * 4));
        }

        return fragment;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                              Shaders
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

#if COBRA_RLE_COMPUTE == 0

    vs2ps VS_LongExposure(uint id : SV_VertexID)
    {
        float2 timer_values = tex2Dfetch(SAM_Timer, int2(0, 0)).rg;
        float current_time  = timer % COBRA_RLE_TIME_MAX; // @TODO timer now and during framecount pass can differ -> untracked frame possible
        vs2ps o             = vs_basic(id, timer_values);
        // during exposure: active -> add rgb, inactive -> keep current and skip PS
        if (!(UI_StartExposure && abs(current_time - timer_values.x) > UI_Delay) || (abs(current_time - timer_values.x) >= 1000 * UI_ExposureDuration))
            o.vpos.xy = 0.0;
        return o;
    }

    void PS_LongExposure(vs2ps o, out float4 fragment : SV_Target)
    {
        float2 timer_values = o.uv.zw;
        float current_time  = timer % COBRA_RLE_TIME_MAX;
        fragment.rgb        = tex2Dfetch(ReShade::BackBuffer, floor(o.vpos.xy)).rgb;
        fragment.a          = 1;
        fragment            = get_exposure(fragment);
        // at beginning: reset so it is ready for activation
        fragment.a    = timer_values.y < 0.5 ? 1.0 : 0.0;
        fragment.rgb += timer_values.y < 0.5 ? 0.0 : tex2Dfetch(SAM_ExposureCopy, floor(o.vpos.xy)).rgb;
    }

    void PS_CopyExposure(vs2ps o, out float4 fragment : SV_Target)
    {
        fragment = tex2Dfetch(SAM_Exposure, floor(o.vpos.xy));
    }

    vs2ps VS_UpdateTimer(uint id : SV_VertexID)
    {
        float2 timer_values = tex2Dfetch(SAM_TimerCopy, int2(0, 0)).rg;
        return vs_basic(id, timer_values);
    }

    void PS_UpdateTimer(vs2ps o, out float2 fragment : SV_Target)
    {
        // timer 1x2
        // value 1: starting point - modified while shader offline - frozen on activation of StartExposure
        // value 2: framecounter - 0 while offline - counting up while online
        float2 timer_values = o.uv.zw;
        float current_time  = timer % COBRA_RLE_TIME_MAX;
        if (!UI_StartExposure)
        {
            fragment = float2(current_time, 0.0);
            return;
        }

        fragment.x = timer_values.x;
        if ((abs(current_time - timer_values.x) < 1000.0 * UI_ExposureDuration) && (abs(current_time - timer_values.x) > UI_Delay) && UI_StartExposure)
        {
            fragment.y = timer_values.y + 1.0;
        }
        else
        {
            fragment.y = timer_values.y;
        }
    }

    void PS_CopyTimer(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float2 fragment : SV_Target)
    {
        fragment = tex2D(SAM_Timer, texcoord).rg; // @TODO CS RW timer?
    }

#else

    groupshared float4 timer_value[1];

    void CS_LongExposure(uint3 id : SV_DispatchThreadID, uint3 tid : SV_GroupThreadID, uint gi : SV_GroupIndex)
    {
        if (gi == 0)
        {
            timer_value[0].xy = tex2Dfetch(STOR_Timer, int2(0, 0)).xy;
            timer_value[0].z  = timer % COBRA_RLE_TIME_MAX;
            timer_value[0].w  = (UI_StartExposure && (abs(timer_value[0].z - timer_value[0].x) > UI_Delay) && (abs(timer_value[0].z - timer_value[0].x) < 1000.0 * UI_ExposureDuration));
            uint passes = atomicAdd(STOR_SyncCount, int2(0, 0), 1u);
            if (passes == ROUNDUP(BUFFER_WIDTH, 8) * COBRA_RLE_YSIZE - 1)
            {
                float4 frag = 0.0;
                frag.a      = 1.0;
                if (!UI_StartExposure)
                {
                    frag.x = timer_value[0].z;
                }
                else
                {
                    frag.x = timer_value[0].x;
                    frag.y = timer_value[0].y + timer_value[0].w;
                }
                // reset
                atomicExchange(STOR_SyncCount, int2(0, 0), 0);
                tex2Dstore(STOR_Timer, int2(0, 0), frag);
            }
        }
        barrier();
        [branch]
        if(any(id.xy >= BUFFER_SCREEN_SIZE) || timer_value[0].w < 0.5) 
            return;

        float4 fragment = 1.0;
        fragment.rgb    = tex2Dfetch(ReShade::BackBuffer, id.xy).rgb;
        fragment        = get_exposure(fragment);
        // at beginning: reset so it is ready for activation

        fragment.a = timer_value[0].y < 0.5;
        fragment.rgb += (1 - fragment.a) * tex2Dfetch(STOR_Exposure, id.xy).rgb;

        //barrier();

        tex2Dstore(STOR_Exposure, id.xy, fragment);
    }

#endif

    vs2ps VS_DisplayExposure(uint id : SV_VertexID)
    {
        float2 timer_values = tex2Dfetch(SAM_Timer, int2(0, 0)).rg;
        vs2ps o             = vs_basic(id, timer_values);

        if (!UI_StartExposure)
            o.vpos.xy = 0.0;
        return o;
    }

    void PS_DisplayExposure(vs2ps o, out float4 fragment : SV_Target)
    {
        float4 exposure_rgb = tex2Dfetch(SAM_Exposure, int2(floor(o.vpos.xy)));
        float4 game_rgb     = tex2Dfetch(ReShade::BackBuffer, int2(floor(o.vpos.xy)));
        float2 timer_values = o.uv.zw;
        float current_time  = timer % COBRA_RLE_TIME_MAX;
        fragment            = float4(0.0, 0.0, 0.0, 1.0);

        if (UI_StartExposure && timer_values.y)
        {
            fragment.rgb = exposure_rgb.rgb / timer_values.y;
            fragment.rgb = pow(abs(fragment.rgb), 1 / UI_Gamma);
        }
        else
        {
            fragment.rgb = game_rgb.rgb;
        }

        if (!UI_StartExposure || !(UI_ShowProgress || UI_ShowGreenOnFinish))
            return;

        float progress = (current_time - timer_values.x) / (1000 * UI_ExposureDuration);
        fragment.rgb   = show_progress(o.uv.xy, fragment, progress).rgb;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                             Techniques
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    technique TECH_RealLongExposure <
        ui_label     = "Realistic Long-Exposure";
        ui_tooltip   = "------About-------\n"
                       "RealLongExposure.fx enables you to capture changes over time, like in long-exposure photography.\n"
                       "It will record the game's output for a user-defined amount of seconds, to create the final image,\n"
                       "just as a camera would do in real life.\n\n"
                       "Version:    " COBRA_RLE_VERSION "\nAuthor:     SirCobra\nCollection: CobraFX\n"
                       "            https://github.com/LordKobra/CobraFX";
    >
    {
#if COBRA_RLE_COMPUTE == 0

        pass LongExposure
        {
            VertexShader = VS_LongExposure;
            PixelShader  = PS_LongExposure;
            RenderTarget = TEX_Exposure;
            // BlendEnable    = true;
            // BlendOpAlpha   = MAX;
            // DestBlendAlpha = ONE;
            // DestBlend      = INVSRCALPHA;
        }

        pass CopyExposure
        {
            VertexShader = VS_LongExposure;
            PixelShader  = PS_CopyExposure;
            RenderTarget = TEX_ExposureCopy;
        }

        pass UpdateTimer
        {
            VertexShader = VS_UpdateTimer;
            PixelShader  = PS_UpdateTimer;
            RenderTarget = TEX_Timer;
        }

        pass CopyTimer
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_CopyTimer;
            RenderTarget = TEX_TimerCopy;
        }

#else

        pass LongExposure
        {
            ComputeShader = CS_LongExposure<8, ROUNDUP(BUFFER_HEIGHT, COBRA_RLE_YSIZE)>;
            DispatchSizeX = ROUNDUP(BUFFER_WIDTH,8);
            DispatchSizeY = COBRA_RLE_YSIZE;
        }

#endif

        pass DisplayExposure
        {
            VertexShader = VS_DisplayExposure;
            PixelShader  = PS_DisplayExposure;
        }
    }
}
