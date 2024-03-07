////////////////////////////////////////////////////////////////////////////////////////////////////////
// Gravity (Gravity.fx) by SirCobra
// Version 0.2.2
// You can find info and all my shaders here: https://github.com/LordKobra/CobraFX
//
// --------Description---------
// Gravity.fx lets pixels gravitate towards the bottom of the screen in the game's 3D environment.
// You can filter the affected pixels by depth and by color.
// It uses a custom seed (currently the Mandelbrot set) to determine the intensity of each pixel.
// Make sure to also test out the texture-RNG variant with the picture "gravityrng.png" provided
// in the Textures folder. You can replace the texture with your own picture, as long as it
// is 1920x1080, RGBA8 and has the same name. Only the red-intensity is taken. So either use red
// images or greyscale images.
// The effect is quite resource consuming. On large resolutions, check out Gravity_CS.fx instead.
// ----------Credits-----------
// The effect can be applied to a specific area like a DoF shader. The basic methods for this were taken
// with permission from https://github.com/FransBouma/OtisFX/blob/master/Shaders/Emphasize.fx
// Code basis for the Mandelbrot set: http://nuclear.mutantstargoat.com/articles/sdr_fract/
// Thanks to kingeric1992 for optimizing the code!
// Thanks to FransBouma, Lord of Lunacy and Annihlator for advice on my first shader :)
////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//                                            Defines & UI
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

// Defines

#define COBRA_GRV_VERSION "0.2.2"
#define COBRA_GRV_UI_GENERAL "\n / General Options /\n"
#define COBRA_GRV_UI_DEPTH "\n /  Depth Options  /\n"
#define COBRA_GRV_UI_COLOR "\n /  Color Options  /\n"

#ifndef M_PI
    #define M_PI 3.1415927
#endif

#define ENABLE_RED (1 << 0)
#define ENABLE_GREEN (1 << 1)
#define ENABLE_BLUE (1 << 2)
#define ENABLE_ALPHA (1 << 3)

// render targets don't work with dx9
#if (__RENDERER__ >= 0xa000)
    #define COBRA_GRV_COMPUTE 1
#else
    #define COBRA_GRV_COMPUTE 0
    #warning "Gravity.fx does not work in DirectX 9 games."
#endif

// Includes

#include "Reshade.fxh"

// Shader Start

#if COBRA_GRV_COMPUTE != 0

// Namespace Everything!

namespace COBRA_GRV
{
    // UI

    uniform float UI_GravityIntensity <
        ui_label     = " Gravity Intensity";
        ui_type      = "slider";
        ui_spacing   = 2;
        ui_min       = 0.00;
        ui_max       = 1.00;
        ui_step      = 0.01;
        ui_tooltip   = "Gravity strength. Higher values look cooler but increase the computation time by a lot!";
        ui_category  = COBRA_GRV_UI_GENERAL;
    >                = 0.50;

    uniform float UI_GravityRNG <
        ui_label     = " Gravity RNG";
        ui_type      = "slider";
        ui_min       = 0.01;
        ui_max       = 0.99;
        ui_step      = 0.02;
        ui_tooltip   = "Changes the random intensity of each pixel.";
        ui_category  = COBRA_GRV_UI_GENERAL;
    >                = 0.75;

    uniform bool UI_UseImage <
        ui_label     = " Use Image";
        ui_tooltip   = "Changes the RNG to the input image called gravityrng.png located in the Textures folder.\nYou can change the image for your own RNG as long as the name and resolution stay the same.";
        ui_category  = COBRA_GRV_UI_GENERAL;
    >                = false;

    uniform bool UI_AllowOverlapping <
        ui_label     = " Allow Overlapping";
        ui_tooltip   = "This way the effect does not get hidden behind other objects.";
        ui_category  = COBRA_GRV_UI_GENERAL;
    >                = false;

    uniform float UI_FocusDepth <
        ui_label     = " Focus Depth";
        ui_spacing   = 2;
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "Manual depth of the focus center. Ranges from 0.0, which means the camera position\nis the focus plane, till 1.0 which means the horizon is the focus plane.";
        ui_category  = COBRA_GRV_UI_DEPTH;
    >                = 0.030;

    uniform float UI_FocusRangeDepth <
        ui_label     = " Focus Range";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The depth range around the manual focus which should still be in focus.";
        ui_category  = COBRA_GRV_UI_DEPTH;
    >                = 1.000;

    uniform float UI_FocusEdgeDepth <
        ui_label     = " Focus Fade";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_tooltip   = "The smoothness of the edge of the focus range. Range from 0.0, which means sudden\ntransition, till 1.0, which means the effect is smoothly fading towards camera and horizon.";
        ui_step      = 0.001;
        ui_category  = COBRA_GRV_UI_DEPTH;
    >                = 0.020;

    uniform bool UI_Spherical <
        ui_label     = " Spherical Focus";
        ui_tooltip   = "Enables the effect in a sphere around the focus-point instead of a 2D plane.";
        ui_category  = COBRA_GRV_UI_DEPTH;
    >                = false;

    uniform int UI_SphereFieldOfView <
        ui_label     = " Spherical Field of View";
        ui_type      = "slider";
        ui_min       = 1;
        ui_max       = 180;
        ui_units     = "°";
        ui_tooltip   = "Specifies the estimated Field of View you are currently playing with. Range from 1,\nwhich means 1 Degree, till 180 which means 180 Degree (half the scene).\nNormal games tend to use values between 60 and 90.";
        ui_category  = COBRA_GRV_UI_DEPTH;
    >                = 75;

    uniform float UI_SphereFocusHorizontal <
        ui_label     = " Spherical Horizontal Focus";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.0;
        ui_tooltip   = "Specifies the location of the focuspoint on the horizontal axis. Range from 0, which\nmeans left screen border, till 1 which means right screen border.";
        ui_category  = COBRA_GRV_UI_DEPTH;
    >                = 0.5;

    uniform float UI_SphereFocusVertical <
        ui_label     = " Spherical Vertical Focus";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.0;
        ui_tooltip   = "Specifies the location of the focuspoint on the vertical axis. Range from 0, which\nmeans upper screen border, till 1 which means bottom screen border.";
        ui_category  = COBRA_GRV_UI_DEPTH;
    >                = 0.5;

    uniform float3 UI_EffectTint <
        ui_label     = " Effect Tint";
        ui_type      = "color";
        ui_spacing   = 2;
        ui_tooltip   = "Specifies the tint of the gravitating pixels, the further they move away from their origin.";
        ui_category  = COBRA_GRV_UI_COLOR;
    >                = float3(0.50, 0.50, 0.50);

    uniform float UI_TintIntensity <
        ui_label     = " Tint Intensity";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.0;
        ui_tooltip   = "Specifies intensity of the tint applied to the gravitating pixels. Range from 0.0, which\nmeans no tint, till 1.0 which means fully tinted.";
        ui_category  = COBRA_GRV_UI_COLOR;
    >                = 0.0;

    uniform float3 UI_FilterColor <
        ui_label     = " Filter Color";
        ui_type      = "color";
        ui_tooltip   = "The target color of the color filter. The effect will only be applied to colors similar\nto this color.";
        ui_category  = COBRA_GRV_UI_COLOR;
    >                = float3(1.00, 0.0, 0.0);

    uniform float UI_FilterRange <
        ui_label     = " Filter Range";
        ui_type      = "slider";
        ui_min       = 0;
        ui_max       = 1.74;
        ui_tooltip   = "The tolerance around the target color. Ranges from 0.0, which means no tolerance\nto 1.74, which tolerates every possible color.";
        ui_category  = COBRA_GRV_UI_COLOR;
    >                = 1.74;

    uniform int UI_BufferEnd <
        ui_type     = "radio";
        ui_spacing  = 2;
        ui_text     = " Shader Version: " COBRA_GRV_VERSION;
        ui_label    = " ";
    > ;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                         Textures & Samplers
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Texture

    texture TEX_GravityDistanceMap
    {
        Width  = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = R16F;
    };

    texture TEX_GravityCurrentSeed
    {
        Format = R16F;
    };

    texture TEX_GravitySeedMapExt < source = "gravity_noise.png";
    >
    {
        Width  = 1920;
        Height = 1080;
        Format = RGBA8;
    };

    // raw depth, CoC,  GravitySeed, reserved
    texture TEX_GravityBuf
    {
        Width  = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA16F;
    };

    // Sampler

    sampler2D SAM_GravityBuf { Texture = TEX_GravityBuf; };
    sampler2D SAM_GravityDistanceMap { Texture = TEX_GravityDistanceMap; };
    sampler2D SAM_GravityCurrentSeed { Texture = TEX_GravityCurrentSeed; };
    sampler2D SAM_GravitySeedMapExt { Texture = TEX_GravitySeedMapExt; };

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                           Helper Functions
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Calculate Focus Intensity
    float check_focus(float2 texcoord : TEXCOORD)
    {
        float4 col_val            = tex2D(ReShade::BackBuffer, texcoord);
        float depth               = ReShade::GetLinearizedDepth(texcoord);
        const float FOCUS         = UI_FocusDepth;
        const float FULL_RANGE    = UI_FocusRangeDepth + UI_FocusEdgeDepth;
        texcoord.x                = (texcoord.x - UI_SphereFocusHorizontal) * ReShade::ScreenSize.x;
        texcoord.y                = (texcoord.y - UI_SphereFocusVertical) * ReShade::ScreenSize.y;
        const float DEG_PER_PIXEL = UI_SphereFieldOfView / ReShade::ScreenSize.x;
        float fov_diff            = sqrt((texcoord.x * texcoord.x) + (texcoord.y * texcoord.y)) * DEG_PER_PIXEL;
        float depth_diff          = UI_Spherical ? sqrt((depth * depth) + (FOCUS * FOCUS) - (2 * depth * FOCUS * cos(fov_diff * (2 * M_PI / 360.0)))) : abs(depth - FOCUS);
        float coc_val             = (1 - saturate((depth_diff > FULL_RANGE) ? 1.0 : smoothstep(UI_FocusRangeDepth, FULL_RANGE, depth_diff)));
        return ((distance(col_val.rgb, UI_FilterColor.rgb) < UI_FilterRange) ? coc_val : 0.0);
    }

    // calculate Mandelbrot Seed
    // inspired by http://nuclear.mutantstargoat.com/articles/sdr_fract/
    float mandelbrot_rng(float2 texcoord : TEXCOORD)
    {
        const float2 CENTER = float2(0.675, 0.46);                           // an interesting center at the mandelbrot for our zoom
        const float ZOOM    = 0.033 * UI_GravityRNG;                         // smaller numbers increase zoom
        const float AR      = ReShade::ScreenSize.x / ReShade::ScreenSize.y; // format to screenspace
        float2 z, c;
        c.x = AR * (texcoord.x - 0.5) * ZOOM - CENTER.x;
        c.y = (texcoord.y - 0.5) * ZOOM - CENTER.y;
        // c = float2(AR,1.0)*(texcoord-0.5) * ZOOM - CENTER;
        int i;
        z = c;

        for (i = 0; i < 100; i++)
        {
            float x = z.x * z.x - z.y * z.y + c.x;
            float y = 2 * z.x * z.y + c.y;
            if ((x * x + y * y) > 4.0)
                break;
            z.x = x;
            z.y = y;
        }

        const float intensity = 1.0;
        return saturate(((intensity * (i == 100 ? 0.0 : float(i)) / 100.0) - 0.8) / 0.22);
    }

    // Calculates the maximum Distance Map
    // For every pixel in GravityIntensity: If GravityIntensity*mandelbrot > j*offset.y : set new real max distance
    float distance_main(float2 texcoord : TEXCOORD)
    {
        float real_max_distance = 0.0;
        const float2 OFFSET     = float2(0.0, BUFFER_RCP_HEIGHT);
        int iterations          = round(min(texcoord.y, UI_GravityIntensity) * BUFFER_HEIGHT);
        int j;

        for (j = 0; j < iterations; j++)
        {

            float rng_value        = tex2Dlod(SAM_GravityBuf, float4(texcoord - j * OFFSET, 0, 1)).b;
            float tex_distance_max = UI_GravityIntensity * rng_value;
            if ((tex_distance_max) > (j * OFFSET.y)) // @TODO optimize, avoid conditionals
            {
                real_max_distance = j * OFFSET.y; // new max threshold
            }
        }
        return real_max_distance;
    }

    // Applies Gravity to the Pixels recursively
    float4 gravity_main(float4 vpos, float2 texcoord : TEXCOORD)
    {
        float real_max_distance = tex2Dfetch(SAM_GravityDistanceMap, vpos.xy).r;
        int iterations          = round(real_max_distance * BUFFER_HEIGHT);

        vpos.z            = 0;
        float4 sample_pos = vpos;
        for (float depth = tex2Dfetch(SAM_GravityBuf, vpos.xy).x;
             vpos.z < iterations; ++vpos.z, --vpos.y)
        {
            float4 samp = tex2Dfetch(SAM_GravityBuf, vpos.xy);
            samp.w *= samp.z;

            [flatten] if (!any(samp <= float4(depth - UI_AllowOverlapping, 0.01, 0.05, vpos.z)))
            {
                sample_pos = vpos;
                sample_pos.z /= samp.w;
                depth = samp.x;
            }
        }

        float4 col_fragment = tex2Dfetch(ReShade::BackBuffer, sample_pos.xy);
        return lerp(col_fragment, float4(UI_EffectTint, 1.0), sample_pos.z * UI_TintIntensity);
    }

    float rng_delta()
    {
        const float OLD_RNG = tex2Dfetch(SAM_GravityCurrentSeed, (0).xx).x;
        const float NEW_RNG = UI_GravityRNG + UI_UseImage * 0.01 + UI_GravityIntensity;
        return OLD_RNG - NEW_RNG;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                              Shaders
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    void VS_GenerateRNG(uint vid : SV_VERTEXID, out float4 pos : SV_POSITION, out float2 uv : TEXCOORD)
    {
        PostProcessVS(vid, pos, uv);
        pos.xy *= abs(rng_delta()) > 0.005;
    }

    // RNG MAP
    void PS_GenerateRNG(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
    {
        float value = tex2D(SAM_GravitySeedMapExt, texcoord).r;
        value       = saturate((value - 1 + UI_GravityRNG) / UI_GravityRNG);
        fragment    = UI_UseImage ? value : mandelbrot_rng(texcoord);
    }

    void VS_GenerateDistance(uint vid : SV_VERTEXID, out float4 pos : SV_POSITION, out float2 uv : TEXCOORD)
    {
        PostProcessVS(vid, pos, uv);
        pos.xy *= abs(rng_delta()) > 0.005;
    }

    // DISTANCE MAP
    void PS_GenerateDistance(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float fragment : SV_Target)
    {
        fragment = distance_main(texcoord);
    }

    // COC + SEED
    void PS_GenerateCoC(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
    {
        vpos.w      = 0;
        fragment.x  = -ReShade::GetLinearizedDepth(texcoord);
        fragment.y  = check_focus(texcoord);
        fragment.zw = UI_GravityIntensity * fragment.y * BUFFER_HEIGHT;
    }

    void PS_UpdateRNGSeed(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float fragment : SV_Target)
    {
        fragment = UI_GravityRNG + UI_UseImage * 0.01 + UI_GravityIntensity;
    }

    // MAIN FUNCTION
    void PS_Gravity(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target)
    {
        vpos.w      = 0;
        outFragment = gravity_main(vpos, texcoord);
    }

    // PRECALC
    void VS_GenerateRNG2(uint vid : SV_VERTEXID, out float4 pos : SV_POSITION, out float2 uv : TEXCOORD)
    {
        PostProcessVS(vid, pos, uv);
        pos.xy *= true;
    }

    void VS_GenerateDistance2(uint vid : SV_VERTEXID, out float4 pos : SV_POSITION, out float2 uv : TEXCOORD)
    {
        PostProcessVS(vid, pos, uv);
        pos.xy *= true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                             Techniques
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    technique TECH_PreGravity <
        hidden     = true;
        enabled    = true;
        timeout    = 1000;
    >
    {
        pass GenerateRNG
        {
            VertexShader          = VS_GenerateRNG2;
            PixelShader           = PS_GenerateRNG;
            RenderTarget          = TEX_GravityBuf;
            RenderTargetWriteMask = ENABLE_BLUE;
        }

        pass GenerateDistance
        {
            VertexShader = VS_GenerateDistance2;
            PixelShader  = PS_GenerateDistance;
            RenderTarget = TEX_GravityDistanceMap;
        }

        pass GenerateCoC
        {
            VertexShader          = PostProcessVS;
            PixelShader           = PS_GenerateCoC;
            RenderTarget          = TEX_GravityBuf;
            RenderTargetWriteMask = ENABLE_RED | ENABLE_GREEN | ENABLE_ALPHA;
        }
    }

    technique TECH_Gravity <
        ui_label     = "Gravity";
        ui_tooltip   = "------About-------\n"
                       "Gravity.fx lets pixels gravitate towards the bottom of the screen in the game's 3D environment.\n"
                       "You can filter the affected pixels by depth and by color.\n"
                       "It uses a custom seed (currently the Mandelbrot set) to determine the intensity of each pixel.\n"
                       "Make sure to also test out the texture-RNG variant with the picture 'gravityrng.png' provided\n"
                       "in the Textures folder. You can replace the texture with your own picture, as long as it\n"
                       "is 1920x1080, RGBA8 and has the same name. Only the red-intensity is taken. So either use red\n"
                       "images or greyscale images.\n"
                       "The effect is quite resource consuming. On large resolutions, check out Gravity_CS.fx instead.\n\n"
                       "Version:    " COBRA_GRV_VERSION "\nAuthor:     SirCobra\nCollection: CobraFX\n"
                       "            https://github.com/LordKobra/CobraFX";
    >
    {
        pass GenerateRNG
        {
            VertexShader          = VS_GenerateRNG;
            PixelShader           = PS_GenerateRNG;
            RenderTarget          = TEX_GravityBuf;
            RenderTargetWriteMask = ENABLE_BLUE;
        }

        // dist to max scather point.
        pass GenerateDistance
        {
            VertexShader = VS_GenerateDistance;
            PixelShader  = PS_GenerateDistance;
            RenderTarget = TEX_GravityDistanceMap;
        }

        // also populate x with raw depth.
        pass GenerateCoC
        {
            VertexShader          = PostProcessVS;
            PixelShader           = PS_GenerateCoC;
            RenderTarget          = TEX_GravityBuf;
            RenderTargetWriteMask = ENABLE_RED | ENABLE_GREEN | ENABLE_ALPHA;
        }

        pass UpdateRNGSeed
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_UpdateRNGSeed;
            RenderTarget = TEX_GravityCurrentSeed;
        }

        pass ApplyGravity
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_Gravity;
        }
    }
}
#endif // Shader End

/*-------------.
| :: Footer :: |
'--------------/

About the Pipeline:
* We generate the RNGMap interactively. It's our intensity function.
* Then comes a map which generates the maximum distance a pixel has to search only based on RNGMap and GravityStrength.
* Then we update the current settings. Only if the settings change the above steps have to be executed again.
* Then we apply Gravity including the DepthMap and colours.

*/
