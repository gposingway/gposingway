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

// base idea from https://www.froyok.fr/blog/2021-12-ue4-custom-bloom/

#pragma once
#include "Includes/vort_Defs.fxh"
#include "Includes/vort_HDR_UI.fxh"
#include "Includes/vort_Filters.fxh"
#include "Includes/vort_DownTex.fxh"
#include "Includes/vort_UpTex.fxh"
#include "Includes/vort_NoiseTex.fxh"
#include "Includes/vort_HDRTexA.fxh"
#include "Includes/vort_HDRTexB.fxh"

namespace Bloom {

/*******************************************************************************
    Globals
*******************************************************************************/

#define BLOOM_IN_TEX HDRTexVortA
#define BLOOM_IN_SAMP sHDRTexVortA
#define BLOOM_OUT_TEX HDRTexVortB

/*******************************************************************************
    Functions
*******************************************************************************/

float4 Downsample(VSOUT i, sampler prev_samp, int prev_mip)
{
    return float4(Filter13Taps(i.uv, prev_samp, prev_mip), 1);
}

float4 UpsampleAndCombine(VSOUT i, sampler prev_samp, sampler curr_samp, int curr_mip)
{
    float3 curr_color = Sample(curr_samp, i.uv).rgb;
    float3 prev_color = Filter9Taps(i.uv, prev_samp, curr_mip + 1);

    return float4(lerp(curr_color, prev_color, UI_Bloom_Radius), 1);
}

/*******************************************************************************
    Shaders
*******************************************************************************/

void PS_Debug(PS_ARGS4)
{
    static const int off = 8;
    static const float max_c = 500;

    int2 f1 = int2(BUFFER_SCREEN_SIZE.x * 0.2, BUFFER_SCREEN_SIZE.y * 0.5);
    int2 f2 = int2(f1.x * 2, f1.y);
    int2 f3 = int2(f1.x * 3, f1.y);
    int2 f4 = int2(f1.x * 4, f1.y);
    int2 pixels = i.uv * BUFFER_SCREEN_SIZE;
    float3 c = 0;

    if(all(bool4(pixels >= (f1 - off), pixels <= f1)))
        c.r = max_c;
    else if(all(bool4(pixels >= (f2 - off), pixels <= f2)))
        c.g = max_c;
    else if(all(bool4(pixels >= (f3 - off), pixels <= f3)))
        c.b = max_c;
    else if(all(bool4(pixels >= (f4 - off), pixels <= f4)))
        c = max_c;

    o = float4(c, 1);
}

void PS_Down0(PS_ARGS4) { o = Downsample(i, BLOOM_IN_SAMP, 0); }
void PS_Down1(PS_ARGS4) { o = Downsample(i, sDownTexVort1, 1); }
void PS_Down2(PS_ARGS4) { o = Downsample(i, sDownTexVort2, 2); }
void PS_Down3(PS_ARGS4) { o = Downsample(i, sDownTexVort3, 3); }
void PS_Down4(PS_ARGS4) { o = Downsample(i, sDownTexVort4, 4); }
void PS_Down5(PS_ARGS4) { o = Downsample(i, sDownTexVort5, 5); }
void PS_Down6(PS_ARGS4) { o = Downsample(i, sDownTexVort6, 6); }
void PS_Down7(PS_ARGS4) { o = Downsample(i, sDownTexVort7, 7); }
void PS_Down8(PS_ARGS4) { o = Downsample(i, sDownTexVort8, 8); }

#if (V_BLOOM_MANUAL_PASSES >= 9 || V_BLOOM_MANUAL_PASSES == 0) && BUFFER_HEIGHT >= 2160
    void PS_UpAndComb8(PS_ARGS4) { o = UpsampleAndCombine(i, sDownTexVort9, sDownTexVort8, 8); }
    void PS_UpAndComb7(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort8, sDownTexVort7, 7); }
    void PS_UpAndComb6(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort7, sDownTexVort6, 6); }
    void PS_UpAndComb5(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort6, sDownTexVort5, 5); }
    void PS_UpAndComb4(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort5, sDownTexVort4, 4); }
    void PS_UpAndComb3(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort4, sDownTexVort3, 3); }
    void PS_UpAndComb2(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort3, sDownTexVort2, 2); }
    void PS_UpAndComb1(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort2, sDownTexVort1, 1); }
#endif

#if (V_BLOOM_MANUAL_PASSES >= 8 || V_BLOOM_MANUAL_PASSES == 0) && BUFFER_HEIGHT < 2160
    void PS_UpAndComb7(PS_ARGS4) { o = UpsampleAndCombine(i, sDownTexVort8, sDownTexVort7, 7); }
    void PS_UpAndComb6(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort7, sDownTexVort6, 6); }
    void PS_UpAndComb5(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort6, sDownTexVort5, 5); }
    void PS_UpAndComb4(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort5, sDownTexVort4, 4); }
    void PS_UpAndComb3(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort4, sDownTexVort3, 3); }
    void PS_UpAndComb2(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort3, sDownTexVort2, 2); }
    void PS_UpAndComb1(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort2, sDownTexVort1, 1); }
#endif

#if V_BLOOM_MANUAL_PASSES == 7
    void PS_UpAndComb6(PS_ARGS4) { o = UpsampleAndCombine(i, sDownTexVort7, sDownTexVort6, 6); }
    void PS_UpAndComb5(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort6, sDownTexVort5, 5); }
    void PS_UpAndComb4(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort5, sDownTexVort4, 4); }
    void PS_UpAndComb3(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort4, sDownTexVort3, 3); }
    void PS_UpAndComb2(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort3, sDownTexVort2, 2); }
    void PS_UpAndComb1(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort2, sDownTexVort1, 1); }
#endif

#if V_BLOOM_MANUAL_PASSES == 6
    void PS_UpAndComb5(PS_ARGS4) { o = UpsampleAndCombine(i, sDownTexVort6, sDownTexVort5, 5); }
    void PS_UpAndComb4(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort5, sDownTexVort4, 4); }
    void PS_UpAndComb3(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort4, sDownTexVort3, 3); }
    void PS_UpAndComb2(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort3, sDownTexVort2, 2); }
    void PS_UpAndComb1(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort2, sDownTexVort1, 1); }
#endif

#if V_BLOOM_MANUAL_PASSES == 5
    void PS_UpAndComb4(PS_ARGS4) { o = UpsampleAndCombine(i, sDownTexVort5, sDownTexVort4, 4); }
    void PS_UpAndComb3(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort4, sDownTexVort3, 3); }
    void PS_UpAndComb2(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort3, sDownTexVort2, 2); }
    void PS_UpAndComb1(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort2, sDownTexVort1, 1); }
#endif

#if V_BLOOM_MANUAL_PASSES == 4
    void PS_UpAndComb3(PS_ARGS4) { o = UpsampleAndCombine(i, sDownTexVort4, sDownTexVort3, 3); }
    void PS_UpAndComb2(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort3, sDownTexVort2, 2); }
    void PS_UpAndComb1(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort2, sDownTexVort1, 1); }
#endif

#if V_BLOOM_MANUAL_PASSES == 3
    void PS_UpAndComb2(PS_ARGS4) { o = UpsampleAndCombine(i, sDownTexVort3, sDownTexVort2, 2); }
    void PS_UpAndComb1(PS_ARGS4) { o = UpsampleAndCombine(i, sUpTexVort2, sDownTexVort1, 1); }
#endif

#if V_BLOOM_MANUAL_PASSES == 1 || V_BLOOM_MANUAL_PASSES == 2
    void PS_UpAndComb1(PS_ARGS4) { o = UpsampleAndCombine(i, sDownTexVort2, sDownTexVort1, 1); }
#endif

void PS_UpAndComb0(PS_ARGS4)
{
    o = UpsampleAndCombine(i, sUpTexVort1, BLOOM_IN_SAMP, 0);

    float2 tuv = BUFFER_SCREEN_SIZE / 512.0;
    float3 noise = Sample(sGaussNoiseTexVort, i.uv * tuv).rgb;

    // apply dithering
    o.rgb += frac(noise + INV_PHI * (FRAME_COUNT % 16)) * PI * (0.01 * UI_Bloom_DitherStrength);

    // final result
    o.rgb = lerp(Sample(BLOOM_IN_SAMP, i.uv).rgb, o.rgb, UI_Bloom_Intensity);
}

/*******************************************************************************
    Passes
*******************************************************************************/

#define PASS_BLOOM_DEBUG \
    pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Debug; RenderTarget = BLOOM_IN_TEX; }

#define PASS_BLOOM_DOWN_DEFAULT \
    pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down0; RenderTarget = DownTexVort1; } \
    pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down1; RenderTarget = DownTexVort2; }

#define PASS_BLOOM_UP_DEFAULT \
    pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb1; RenderTarget = UpTexVort1; } \
    pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb0; RenderTarget = BLOOM_OUT_TEX; }

#if V_BLOOM_MANUAL_PASSES == 1 || V_BLOOM_MANUAL_PASSES == 2
    #define PASS_BLOOM_DOWN PASS_BLOOM_DOWN_DEFAULT
    #define PASS_BLOOM_UP PASS_BLOOM_UP_DEFAULT
#endif

#if V_BLOOM_MANUAL_PASSES == 3
    #define PASS_BLOOM_DOWN \
        PASS_BLOOM_DOWN_DEFAULT \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down2; RenderTarget = DownTexVort3; }

    #define PASS_BLOOM_UP \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb2; RenderTarget = UpTexVort2; } \
        PASS_BLOOM_UP_DEFAULT
#endif

#if V_BLOOM_MANUAL_PASSES == 4
    #define PASS_BLOOM_DOWN \
        PASS_BLOOM_DOWN_DEFAULT \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down2; RenderTarget = DownTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down3; RenderTarget = DownTexVort4; }

    #define PASS_BLOOM_UP \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb3; RenderTarget = UpTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb2; RenderTarget = UpTexVort2; } \
        PASS_BLOOM_UP_DEFAULT
#endif

#if V_BLOOM_MANUAL_PASSES == 5
    #define PASS_BLOOM_DOWN \
        PASS_BLOOM_DOWN_DEFAULT \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down2; RenderTarget = DownTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down3; RenderTarget = DownTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down4; RenderTarget = DownTexVort5; }

    #define PASS_BLOOM_UP \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb4; RenderTarget = UpTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb3; RenderTarget = UpTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb2; RenderTarget = UpTexVort2; } \
        PASS_BLOOM_UP_DEFAULT
#endif

#if V_BLOOM_MANUAL_PASSES == 6
    #define PASS_BLOOM_DOWN \
        PASS_BLOOM_DOWN_DEFAULT \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down2; RenderTarget = DownTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down3; RenderTarget = DownTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down4; RenderTarget = DownTexVort5; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down5; RenderTarget = DownTexVort6; }

    #define PASS_BLOOM_UP \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb5; RenderTarget = UpTexVort5; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb4; RenderTarget = UpTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb3; RenderTarget = UpTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb2; RenderTarget = UpTexVort2; } \
        PASS_BLOOM_UP_DEFAULT
#endif

#if V_BLOOM_MANUAL_PASSES == 7
    #define PASS_BLOOM_DOWN \
        PASS_BLOOM_DOWN_DEFAULT \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down2; RenderTarget = DownTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down3; RenderTarget = DownTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down4; RenderTarget = DownTexVort5; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down5; RenderTarget = DownTexVort6; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down6; RenderTarget = DownTexVort7; }

    #define PASS_BLOOM_UP \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb6; RenderTarget = UpTexVort6; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb5; RenderTarget = UpTexVort5; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb4; RenderTarget = UpTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb3; RenderTarget = UpTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb2; RenderTarget = UpTexVort2; } \
        PASS_BLOOM_UP_DEFAULT
#endif

#if (V_BLOOM_MANUAL_PASSES >= 8 || V_BLOOM_MANUAL_PASSES == 0) && BUFFER_HEIGHT < 2160
    #define PASS_BLOOM_DOWN \
        PASS_BLOOM_DOWN_DEFAULT \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down2; RenderTarget = DownTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down3; RenderTarget = DownTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down4; RenderTarget = DownTexVort5; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down5; RenderTarget = DownTexVort6; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down6; RenderTarget = DownTexVort7; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down7; RenderTarget = DownTexVort8; }

    #define PASS_BLOOM_UP \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb7; RenderTarget = UpTexVort7; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb6; RenderTarget = UpTexVort6; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb5; RenderTarget = UpTexVort5; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb4; RenderTarget = UpTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb3; RenderTarget = UpTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb2; RenderTarget = UpTexVort2; } \
        PASS_BLOOM_UP_DEFAULT
#endif

#if (V_BLOOM_MANUAL_PASSES >= 9 || V_BLOOM_MANUAL_PASSES == 0) && BUFFER_HEIGHT >= 2160
    #define PASS_BLOOM_DOWN \
        PASS_BLOOM_DOWN_DEFAULT \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down2; RenderTarget = DownTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down3; RenderTarget = DownTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down4; RenderTarget = DownTexVort5; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down5; RenderTarget = DownTexVort6; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down6; RenderTarget = DownTexVort7; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down7; RenderTarget = DownTexVort8; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_Down8; RenderTarget = DownTexVort9; }

    #define PASS_BLOOM_UP \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb8; RenderTarget = UpTexVort8; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb7; RenderTarget = UpTexVort7; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb6; RenderTarget = UpTexVort6; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb5; RenderTarget = UpTexVort5; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb4; RenderTarget = UpTexVort4; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb3; RenderTarget = UpTexVort3; } \
        pass { VertexShader = PostProcessVS; PixelShader = Bloom::PS_UpAndComb2; RenderTarget = UpTexVort2; } \
        PASS_BLOOM_UP_DEFAULT
#endif

} // namespace end
