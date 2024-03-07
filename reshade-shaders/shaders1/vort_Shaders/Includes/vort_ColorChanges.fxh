/*******************************************************************************
    Author: Vortigern

    License: MIT, Copyright (c) 2023 Vortigern

    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
*******************************************************************************/

/* TODO:
- add more tonemappers:
    Agx -> https://github.com/MrLixm/AgXc/tree/main/reshade
    Tony McMapface -> https://github.com/h3r2tic/tony-mc-mapface/tree/main

- Move the inverse tonemap, tonemap and color grading to a LUT

- Useful links for applying LUTs:
    https://www.lightillusion.com/what_are_luts.html
    https://lut.tgratzer.com/
    https://github.com/prod80/prod80-ReShade-Repository/blob/master/Shaders/PD80_02_LUT_Creator.fx
    https://github.com/prod80/prod80-ReShade-Repository/blob/master/Shaders/PD80_LUT_v2.fxh
    https://github.com/FransBouma/OtisFX/blob/master/Shaders/MultiLUT.fx

- It is easier to install OCIO latest on Fedora using it's package manager
- OpenColorIO (OCIO) links
    https://opencolorio.readthedocs.io/en/latest/guides/using_ocio/using_ocio.html
    https://opencolorio.readthedocs.io/en/latest/tutorials/baking_luts.html
    https://help.maxon.net/c4d/en-us/Content/_REDSHIFT_/html/Compositing+with+ACES.html
*/

#pragma once
#include "Includes/vort_Defs.fxh"
#include "Includes/vort_HDR_UI.fxh"
#include "Includes/vort_Depth.fxh"
#include "Includes/vort_Filters.fxh"
#include "Includes/vort_LDRTex.fxh"
#include "Includes/vort_HDRTexA.fxh"
#include "Includes/vort_HDRTexB.fxh"
#include "Includes/vort_ACES.fxh"

namespace ColorChanges {

/*******************************************************************************
    Globals
*******************************************************************************/

#define CC_OUT_TEX HDRTexVortA

#if V_ENABLE_BLOOM
    #define CC_IN_SAMP sHDRTexVortB
#else
    #define CC_IN_SAMP sHDRTexVortA
#endif

#if IS_SRGB
    #define LINEAR_MIN FLOAT_MIN
    #define LINEAR_MAX FLOAT_MAX
#elif IS_SCRGB
    #define LINEAR_MIN -0.5
    #define LINEAR_MAX (1e4 / V_HDR_WHITE_LVL)
#elif IS_HDR_PQ
    #define LINEAR_MIN 0.0
    #define LINEAR_MAX (1e4 / V_HDR_WHITE_LVL)
#elif IS_HDR_HLG
    #define LINEAR_MIN 0.0
    #define LINEAR_MAX (1e3 / V_HDR_WHITE_LVL)
#else
    #define LINEAR_MIN 0.0
    #define LINEAR_MAX 1.0
#endif

#define TO_LOG_CS(_x) ACEScgToACEScct(_x)
#define TO_LINEAR_CS(_x) ACEScctToACEScg(_x)
#define GET_LUMI(_x) ACESToLumi(_x)
#define LINEAR_MID_GRAY 0.18
#define LOG_MID_GRAY ACES_LOG_MID_GRAY

/*******************************************************************************
    Functions
*******************************************************************************/

float3 ApplyLottes(float3 c)
{
    float k = max(1.001, UI_CC_LottesMod);
    float3 v = Max3(c.r, c.g, c.b);

    return k * c * RCP(1.0 + v);
}

float3 InverseLottes(float3 c)
{
    float k = max(1.001, UI_CC_LottesMod);
    float3 v = Max3(c.r, c.g, c.b);

    return c * RCP(k - v);
}

#if V_ENABLE_SHARPEN
float3 ApplySharpen(float3 c, sampler samp, float2 uv)
{
    float3 blurred = Filter9Taps(uv, samp, 0);
    float3 sharp = RGBToYCbCrLumi(c - blurred);
    float depth = GetLinearizedDepth(uv);
    float limit = abs(dot(sharp, 0.3333));

    sharp = sharp * UI_CC_SharpenStrength * (1 - depth) * (limit < UI_CC_SharpenLimit);

    if (UI_CC_ShowSharpening) return sharp;

    // apply sharpening and unsharpening
    if(depth < UI_CC_SharpenSwitchPoint)
        c = c + sharp;
    else
        c = lerp(c, blurred, depth * UI_CC_UnsharpenStrength);

    return c;
}
#endif

#if V_ENABLE_COLOR_GRADING
float3 ChangeWhiteBalance(float3 col, float temp, float tint) {
    static const float3x3 LIN_2_LMS_MAT = float3x3(
        3.90405e-1, 5.49941e-1, 8.92632e-3,
        7.08416e-2, 9.63172e-1, 1.35775e-3,
        2.31082e-2, 1.28021e-1, 9.36245e-1
    );

    float3 lms = mul(LIN_2_LMS_MAT, col);

    temp /= 0.6;
    tint /= 0.6;

    float x = 0.31271 - temp * (temp < 0 ? 0.1 : 0.05);
    float y = 2.87 * x - 3 * x * x - 0.27509507 + tint * 0.05;

    float X = x / y;
    float Z = (1 - x - y) / y;

    static const float3 w1 = float3(0.949237, 1.03542, 1.08728);

    float3 w2 = float3(
         0.7328 * X + 0.4296 - 0.1624 * Z,
        -0.7036 * X + 1.6975 + 0.0061 * Z,
         0.0030 * X + 0.0136 + 0.9834 * Z
    );

    lms *= w1 / w2;

    static const float3x3 LMS_2_LIN_MAT = float3x3(
         2.85847e+0, -1.62879e+0, -2.48910e-2,
        -2.10182e-1,  1.15820e+0,  3.24281e-4,
        -4.18120e-2, -1.18169e-1,  1.06867e+0
    );

    return mul(LMS_2_LIN_MAT, lms);
}

float3 ApplyColorGrading(float3 c)
{
    // white balance
    c = ChangeWhiteBalance(c.rgb, UI_CC_WBTemp, UI_CC_WBTint);

    // color filter
    c *= UI_CC_ColorFilter;

    // saturation
    float lumi = GET_LUMI(c);
    c = lerp(lumi.xxx, c, UI_CC_Saturation + 1.0);

    // RGB(channel) mixer
    c = float3(
        dot(c.rgb, UI_CC_RGBMixerRed.rgb * 4.0 - 2.0),
        dot(c.rgb, UI_CC_RGBMixerGreen.rgb * 4.0 - 2.0),
        dot(c.rgb, UI_CC_RGBMixerBlue.rgb * 4.0 - 2.0)
    );

    // Hue Shift
    float3 hsv = RGBToHSV(c);
    hsv.x = frac(hsv.x + UI_CC_HueShift);
    c = HSVToRGB(hsv);

    // start grading in log space
    c = TO_LOG_CS(c);

    // contrast in log space
    float contrast = UI_CC_Contrast + 1.0;
    c = lerp(LOG_MID_GRAY.xxx, c, contrast.xxx);

    // Shadows,Midtones,Highlights,Offset in log space
    // My calculations were done in desmos: https://www.desmos.com/calculator/vvur0dzia9

    // affect the color and luminance seperately
    float3 shadows = UI_CC_ShadowsColor - GET_LUMI(UI_CC_ShadowsColor) + UI_CC_ShadowsLumi + 0.5;
    float3 midtones = UI_CC_MidtonesColor - GET_LUMI(UI_CC_MidtonesColor) + UI_CC_MidtonesLumi + 0.5;
    float3 highlights = UI_CC_HighlightsColor - GET_LUMI(UI_CC_HighlightsColor) + UI_CC_HighlightsLumi + 0.5;
    float3 offset = UI_CC_OffsetColor - GET_LUMI(UI_CC_OffsetColor) + UI_CC_OffsetLumi + 0.5;

    static const float shadows_str = 0.5;
    static const float midtones_str = 1.0;
    static const float highlights_str = 1.0;
    static const float offset_str = 0.5;

    // do the scaling
    shadows = 1.0 - exp2((1.0 - 2.0 * shadows) * shadows_str);
    midtones = exp2((1.0 - 2.0 * midtones) * midtones_str);
    highlights = exp2((2.0 * highlights - 1.0) * highlights_str);
    offset = (offset - 0.5) * offset_str;

    // apply shadows, highlights, offset, midtones
    c = (c <= 1) ? (c * (1.0 - shadows) + shadows) : c;
    c = (c >= 0) ? (c * highlights) : c;
    c = c + offset;
    c = (c >= 0 && c <= 1.0) ? POW(c, midtones) : c;

    // end grading in log space
    c = TO_LINEAR_CS(c);

    return c;
}
#endif

float3 ApplyStartProcessing(float3 c)
{
    c = ApplyLinearCurve(c);

#if IS_SRGB
    c = saturate(c);
    c = InverseLottes(c);
    c = RGBToACEScg(c);
#endif

    return c;
}

float3 ApplyEndProcessing(float3 c)
{
#if V_SHOW_ONLY_HDR_COLORS
    c = !all(saturate(c - c * c)) ? 1.0 : 0.0;
#elif IS_SRGB
    c = c >= 0 ? c * exp2(UI_CC_ManualExp) : c;

    // clamp before tonemapping
    c = clamp(c, LINEAR_MIN, LINEAR_MAX);

    c = ACEScgToRGB(c);
    c = ApplyLottes(c);
    c = saturate(c);
#endif

    c = ApplyGammaCurve(c);

    return c;
}

/*******************************************************************************
    Shaders
*******************************************************************************/

void PS_Start(PS_ARGS4) {
    float3 c = Sample(sLDRTexVort, i.uv).rgb;

    c = ApplyStartProcessing(c);
    o = float4(c, 1);
}

void PS_End(PS_ARGS4)
{
    float3 c = Sample(CC_IN_SAMP, i.uv).rgb;

#if V_ENABLE_SHARPEN
    c = ApplySharpen(c, CC_IN_SAMP, i.uv);
#endif

#if V_ENABLE_COLOR_GRADING
    c = ApplyColorGrading(c);
#endif

    c = ApplyEndProcessing(c);
    o = float4(c, 1);
}

/*******************************************************************************
    Passes
*******************************************************************************/
#define PASS_START \
    pass { VertexShader = PostProcessVS; PixelShader = ColorChanges::PS_Start; RenderTarget = CC_OUT_TEX; }

#define PASS_END \
    pass { VertexShader = PostProcessVS; PixelShader = ColorChanges::PS_End; SRGB_WRITE_ENABLE }

} // namespace end
