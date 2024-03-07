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

#pragma once

#ifndef V_ENABLE_BLOOM
    #define V_ENABLE_BLOOM 1
#endif

#ifndef V_ENABLE_SHARPEN
    #define V_ENABLE_SHARPEN 1
#endif

#ifndef V_ENABLE_COLOR_GRADING
    #define V_ENABLE_COLOR_GRADING 1
#endif

#ifndef V_BLOOM_MANUAL_PASSES
    #define V_BLOOM_MANUAL_PASSES 0 // if 0 -> auto select depending on the resolution, else -> 2 <= X <= 9
#endif

#ifndef V_BLOOM_DEBUG
    #define V_BLOOM_DEBUG 0
#endif

#ifndef V_SHOW_ONLY_HDR_COLORS
    #define V_SHOW_ONLY_HDR_COLORS 0
#endif

#if IS_SRGB
    #define CAT_TONEMAP "Tonemapping"

    UI_FLOAT(CAT_TONEMAP, UI_CC_LottesMod, "Lottes Modifier", "Changes the color range of the tonemapper", 1.0, 1.5, 1.025)
    UI_FLOAT(CAT_TONEMAP, UI_CC_ManualExp, "Manual Exposure", "Changes the exposure of the scene", -5.0, 5.0, 0.0)
#endif

#if V_ENABLE_BLOOM
    #define CAT_BLOOM "Bloom"

    UI_FLOAT(CAT_BLOOM, UI_Bloom_Intensity, "Bloom Intensity", "Controls the amount of bloom", 0.0, 1.0, 0.02)
    UI_FLOAT(CAT_BLOOM, UI_Bloom_Radius, "Bloom Radius", "Affects the size/scale of the bloom", 0.0, 1.0, 0.8)
    UI_FLOAT(CAT_BLOOM, UI_Bloom_DitherStrength, "Dither Strength", "How much noise to add.", 0.0, 1.0, 0.05)
#endif

#if V_ENABLE_SHARPEN
    #define CAT_SHARP "Sharpen"

    UI_BOOL(CAT_SHARP, UI_CC_ShowSharpening, "Show only Sharpening", "", false)
    UI_FLOAT(CAT_SHARP, UI_CC_SharpenLimit, "Sharpen Limit", "Control which pixel to be sharpened", 0.0, 0.1, 0.015)
    UI_FLOAT(CAT_SHARP, UI_CC_SharpenStrength, "Sharpening Strength", "Controls the shaprening strength.", 0.0, 1.0, 0.8)
    UI_FLOAT(CAT_SHARP, UI_CC_UnsharpenStrength, "Unsharpening Strength", "Controls the unsharpness strength.", 0.0, 1.0, 0.4)
    UI_FLOAT(CAT_SHARP, UI_CC_SharpenSwitchPoint, "Switch Point", "Controls at what distance blurring occurs.", 0.0, 1.0, 0.1)
#endif

#if V_ENABLE_COLOR_GRADING
    #define CAT_CC "Color Grading"

    UI_FLOAT(CAT_CC, UI_CC_WBTemp, "Temperature", "Changes the white balance temperature.", -0.5, 0.5, 0.0)
    UI_FLOAT(CAT_CC, UI_CC_WBTint, "Tint", "Changes the white balance tint.", -0.5, 0.5, 0.0)
    UI_FLOAT(CAT_CC, UI_CC_Contrast, "Contrast", "Changes the contrast of the image", -1.0, 1.0, 0.0)
    UI_FLOAT(CAT_CC, UI_CC_Saturation, "Saturation", "Changes the saturation of all colors", -1.0, 1.0, 0.0)
    UI_FLOAT(CAT_CC, UI_CC_HueShift, "Hue Shift", "Changes the hue of all colors", -0.5, 0.5, 0.0)
    UI_COLOR(CAT_CC, UI_CC_ColorFilter, "Color Filter", "Multiplies every color by this color", 1.0);
    UI_COLOR(CAT_CC, UI_CC_RGBMixerRed, "RGB Mixer Red", "Modifies the reds", float3(0.75, 0.5, 0.5))
    UI_COLOR(CAT_CC, UI_CC_RGBMixerGreen, "RGB Mixer Green", "Modifies the greens", float3(0.5, 0.75, 0.5))
    UI_COLOR(CAT_CC, UI_CC_RGBMixerBlue, "RGB Mixer Blue", "Modifies the blues", float3(0.5, 0.5, 0.75))

    UI_COLOR(CAT_CC, UI_CC_ShadowsColor, "Shadows Color", "Changes the color of the shadows mainly.", 0.5)
    UI_COLOR(CAT_CC, UI_CC_MidtonesColor, "Midtones Color", "Changes the color of the midtones mainly.", 0.5)
    UI_COLOR(CAT_CC, UI_CC_HighlightsColor, "Highlights Color", "Changes the color of the highlights mainly.", 0.5)
    UI_COLOR(CAT_CC, UI_CC_OffsetColor, "Offset Color", "Changes the color of the whole curve.", 0.5)

    UI_FLOAT(CAT_CC, UI_CC_ShadowsLumi, "Shadows Luminance", "Changes the luminance of the shadows mainly.", -0.5, 0.5, 0.0)
    UI_FLOAT(CAT_CC, UI_CC_MidtonesLumi, "Midtones Luminance", "Change the luminance of the midtones mainly.", -0.5, 0.5, 0.0)
    UI_FLOAT(CAT_CC, UI_CC_HighlightsLumi, "Highlights Luminance", "Changes the luminance of the highlights mainly.", -0.5, 0.5, 0.0)
    UI_FLOAT(CAT_CC, UI_CC_OffsetLumi, "Offset Luminance", "Changes the luminance of whole curve.", -0.5, 0.5, 0.0)
#endif

UI_HELP(
_vort_HDR_Help_,
"V_ENABLE_BLOOM - 0 or 1\n"
"Toggle the bloom effect.\n"
"\n"
"V_ENABLE_SHARPEN - 0 or 1\n"
"Toggle the sharpening and far blur.\n"
"\n"
"V_ENABLE_COLOR_GRADING - 0 or 1\n"
"Toggle all the color granding effects\n"
"\n"
"V_BLOOM_MANUAL_PASSES - 0 or [2 - 9].\n"
"How many downsample/upsamples of the image to do in order to perform the bloom.\n"
"At 0 defaults to 8 passes for 1080p and 9 for 4K resolution.\n"
"\n"
"V_BLOOM_DEBUG - 0 or 1\n"
"Shows 4 bright squares to see the bloom effect and make UI adjustments if you want.\n"
"\n"
"V_SHOW_ONLY_HDR_COLORS - 0 or 1\n"
"If 1, shows in white the HDR colors\n"
"\n"
"V_USE_HW_LIN - 0 or 1\n"
"Toggle hardware linearization (better performance).\n"
"Disable if you use REST addon version older than 1.2.1\n"
)
