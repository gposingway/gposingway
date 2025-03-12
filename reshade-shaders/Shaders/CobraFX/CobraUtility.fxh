////////////////////////////////////////////////////////////////////////////////////////////////////////
// Cobra Utility (CobraUtility.fxh) by SirCobra
// Version 0.2.0
// You can find info and all my shaders here: https://github.com/LordKobra/CobraFX
//
// --------Description---------
// This header file contains useful functions and definitions for other shaders to use.
//
// ----------Credits-----------
// The credits are written above the functions.
////////////////////////////////////////////////////////////////////////////////////////////////////////

// Mode: 0: Includes
//       1: UI
//       2: Helper functions
#ifndef COBRA_UTL_MODE
    #error "COBRA_UTL_MODE not defined"
#endif

// Use color & depth functions
#ifndef COBRA_UTL_COLOR
    #define COBRA_UTL_COLOR 0
#endif

// Hide UI Elements in UI Section
#ifndef COBRA_UTL_HIDE_FADE
    #define COBRA_UTL_HIDE_FADE false
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//                                            Defines & UI
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

#if (COBRA_UTL_MODE == 0)

    #ifndef M_PI
        #define M_PI 3.1415927
    #endif

    #ifndef M_E
        #define M_E 2.71828183
    #endif

    #define COBRA_UTL_VERSION "0.2.0"
    #define COBRA_UTL_UI_GENERAL "\n / General Options /\n"
    #define COBRA_UTL_UI_COLOR "\n /  Color Masking  /\n"
    #define COBRA_UTL_UI_DEPTH "\n /  Depth Masking  /\n"
    #define COBRA_UTL_UI_EXTRAS "\n /      Extras     /\n"

    // vector mod and normal fmod
    #undef fmod
    #define fmod(x, y) (frac((x)*rcp(y)) * (y))

    #undef ROUNDUP
    #define ROUNDUP(x, y) (((x - 1) / y) + 1)

#endif

#if (COBRA_UTL_MODE == 1)

    uniform bool UI_ShowMask <
        ui_label     = " Show Mask";
        ui_spacing   = 2;
        ui_tooltip   = "Show the masked pixels. White areas will be preserved, black/grey areas can be affected by\n"
                    "the shaders encompassed.\n"
                    "ColorSort_CS.fx: Dark grey pixels show the noise pattern. Light grey pixels show brightness thresholds.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform bool UI_InvertMask <
        ui_label     = " Invert Mask";
        ui_tooltip   = "Invert the mask.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform bool UI_FilterColor <
        ui_label     = " Filter by Color";
        ui_spacing   = 2;
        ui_tooltip   = "Activates the color masking option.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = false;

    uniform bool UI_ShowSelectedHue <
        ui_label     = " Show Selected Hue";
        ui_tooltip   = "Display the currently selected hue range at the top of the image.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = false;

    uniform float UI_Value <
        ui_label     = " Value";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The value describes the brightness of the hue. 0 is black/no hue and 1 is\n"
                    "maximum hue (e.g. pure red).";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.000;

    uniform float UI_ValueRange <
        ui_label     = " Value Range";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.001;
        ui_step      = 0.001;
        ui_tooltip   = "The tolerance around the value.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.001;

    uniform float UI_ValueEdge <
        ui_label     = " Value Fade";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The smoothness beyond the value range.";
        ui_category  = COBRA_UTL_UI_COLOR;
        hidden       = COBRA_UTL_HIDE_FADE;
    >                = 0.000;

    uniform float UI_Hue <
        ui_label     = " Hue";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The hue describes the color category. It can be red, green, blue or a mix of them.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.000;

    uniform float UI_HueRange <
        ui_label     = " Hue Range";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 0.501;
        ui_step      = 0.001;
        ui_tooltip   = "The tolerance around the hue.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 0.501;

    uniform float UI_Saturation <
        ui_label     = " Saturation";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The saturation determines the colorfulness. 0 is greyscale and 1 pure colors.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.000;

    uniform float UI_SaturationRange <
        ui_label     = " Saturation Range";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The tolerance around the saturation.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.000;

    uniform bool UI_FilterDepth <
        ui_label     = " Filter By Depth";
        ui_spacing   = 2;
        ui_tooltip   = "Activates the depth masking option.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = false;

    uniform float UI_FocusDepth <
        ui_label     = " Focus Depth";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "Manual focus depth of the point which has the focus. Ranges from 0.0, which means camera is\n"
                    "the focus plane, till 1.0 which means the horizon is the focus plane.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 0.030;

    uniform float UI_FocusRangeDepth <
        ui_label     = " Focus Range";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The range of the depth around the manual focus which should still be in focus.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 0.020;

    uniform float UI_FocusEdgeDepth <
        ui_label     = " Focus Fade";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_tooltip   = "The smoothness of the edge of the focus range. Range from 0.0, which means sudden transition,\n"
                    "till 1.0, which means the effect is smoothly fading towards camera and horizon.";
        ui_step      = 0.001;
        ui_category  = COBRA_UTL_UI_DEPTH;
        hidden       = COBRA_UTL_HIDE_FADE;
    >                = 0.000;

    uniform bool UI_Spherical <
        ui_label     = " Spherical Focus";
        ui_tooltip   = "Enables the mask in a sphere around the focus-point instead of a 2D plane.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = false;

    uniform int UI_SphereFieldOfView <
        ui_label     = " Spherical Field of View";
        ui_type      = "slider";
        ui_min       = 1;
        ui_max       = 180;
        ui_units     = "°";
        ui_tooltip   = "Specifies the estimated Field of View (FOV) you are currently playing with. Range from 1°,\n"
                    "till 180° (half the scene). Normal games tend to use values between 60° and 90°.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 75;

    uniform float UI_SphereFocusHorizontal <
        ui_label     = " Spherical Horizontal Focus";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.0;
        ui_tooltip   = "Specifies the location of the focus point on the horizontal axis. Range from 0, which means\n"
                    "left screen border, till 1 which means right screen border.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 0.5;

    uniform float UI_SphereFocusVertical <
        ui_label     = " Spherical Vertical Focus";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.0;
        ui_tooltip   = "Specifies the location of the focus point on the vertical axis. Range from 0, which means\n"
                    "upper screen border, till 1 which means bottom screen border.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 0.5;

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//                                           Helper Functions
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

#if (COBRA_UTL_MODE == 2)

    struct vs2ps
    {
        float4 vpos : SV_Position;
        float4 uv : TEXCOORD0;
    };

    vs2ps vs_basic(const uint id, float2 extras)
    {
        vs2ps o;
        o.uv.x  = (id == 2) ? 2.0 : 0.0;
        o.uv.y  = (id == 1) ? 2.0 : 0.0;
        o.uv.zw = extras;
        o.vpos  = float4(o.uv.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
        return o;
    }

    // return value [-M_PI, M_PI]
    float atan2_approx(float y, float x)
    {
        return acos(x * rsqrt(y * y + x * x)) * (y < 0 ? -1 : 1);
    }

    #if COBRA_UTL_COLOR

        // HSV conversions by Sam Hocevar: http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
        float3 rgb2hsv(float3 c)
        {
            const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            float4 p       = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
            float4 q       = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
            float d        = q.x - min(q.w, q.y);
            const float E  = 1.0e-10;
            return float3(abs(q.z + (q.w - q.y) / (6.0 * d + E)), d / (q.x + E), q.x);
        }

        float3 hsv2rgb(float3 c)
        {
            const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p       = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
            return float3(c.z * lerp(K.xxx, saturate(p - K.xxx), c.y));
        }

        // show the color bar. inspired by originalnicodrs design
        float4 show_hue(float2 texcoord, float4 fragment)
        {
            const float RANGE = 0.145;
            const float DEPTH = 0.06;
            if (abs(texcoord.x - 0.5) < RANGE && texcoord.y < DEPTH)
            {
                float3 hsv   = float3(saturate(texcoord.x - 0.5 + RANGE) / (2.0 * RANGE), 1.0, 1.0);
                float3 rgb   = hsv2rgb(hsv);
                bool active  = min(abs(hsv.r - UI_Hue), (1.0 - abs(hsv.r - UI_Hue))) < UI_HueRange;
                fragment.rgb = active ? rgb : 0.5;
            }

            return fragment;
        }

        // CobraMask Gravity_CS ColorSort_CS
        float check_focus(float3 rgb, float scene_depth, float2 texcoord)
        {
            // colorfilter
            float3 hsv           = rgb2hsv(rgb);
            float d1_f           = abs(hsv.b - UI_Value) - UI_ValueRange;
            d1_f                 = 1.0 - smoothstep(0.0, UI_ValueEdge, d1_f);
            bool d2              = abs(hsv.r - UI_Hue) < (UI_HueRange + exp(-(hsv.g * hsv.g) * 200)) || (1.0 - abs(hsv.r - UI_Hue)) < (UI_HueRange + exp(-(hsv.g * hsv.g) * 100));
            bool d3              = abs(hsv.g - UI_Saturation) <= UI_SaturationRange;
            float is_color_focus = max(d3 * d2 * d1_f, UI_FilterColor == 0); // color threshold

            // depthfilter
            const float DESATURATE_FULL_RANGE = UI_FocusRangeDepth + UI_FocusEdgeDepth;
            const float DEGREE_PER_PIXEL      = float(UI_SphereFieldOfView) / ReShade::ScreenSize.x;
            texcoord                          = (texcoord - float2(UI_SphereFocusHorizontal, UI_SphereFocusVertical)) * ReShade::ScreenSize.xy;
            float fov_diff                    = length(texcoord) * DEGREE_PER_PIXEL;
            float depth_diff                  = UI_Spherical ? sqrt((scene_depth * scene_depth) + (UI_FocusDepth * UI_FocusDepth) - (2.0 * scene_depth * UI_FocusDepth * cos(fov_diff * (2.0 * M_PI / 360.0)))) : abs(scene_depth - UI_FocusDepth);
            float depth_val                   = 1.0 - saturate((depth_diff > DESATURATE_FULL_RANGE) ? 1.0 : smoothstep(UI_FocusRangeDepth, DESATURATE_FULL_RANGE, depth_diff));
            depth_val                         = max(depth_val, UI_FilterDepth == 0);
            float in_focus                    = is_color_focus * depth_val;
            return lerp(in_focus, 1 - in_focus, UI_InvertMask);
        }

    #endif

#endif

#undef COBRA_UTL_HIDE_FADE
#undef COBRA_UTL_COLOR
#undef COBRA_UTL_MODE
