#include "shared/cBuffers.fxh"
#include "shared/cGraphics.fxh"
#include "shared/cImageProcessing.fxh"
#include "shared/cVideoProcessing.fxh"

/*
    This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.

    In jurisdictions that recognize copyright laws, the author or authors
    of this software dedicate any and all copyright interest in the
    software to the public domain. We make this dedication for the benefit
    of the public at large and to the detriment of our heirs and
    successors. We intend this dedication to be an overt act of
    relinquishment in perpetuity of all present and future rights to this
    software under copyright law.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
    OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.

    For more information, please refer to <http://unlicense.org/>
*/

namespace kDatamosh
{
    /*
        [Shader Options]
    */

    uniform float _Time < source = "timer"; >;

    uniform float _MipBias <
        ui_category = "Optical Flow";
        ui_label = "Mipmap Bias";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 7.0;
    > = 0.0;

    uniform float _BlendFactor <
        ui_category = "Optical Flow";
        ui_label = "Temporal Blending Factor";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 0.9;
    > = 0.25;

    uniform int _BlockSize <
        ui_category = "Datamosh";
        ui_label = "Block Size";
        ui_type = "slider";
        ui_min = 0;
        ui_max = 32;
    > = 4;

    uniform float _Entropy <
        ui_category = "Datamosh";
        ui_label = "Entropy";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
    > = 0.1;

    uniform float _Contrast <
        ui_category = "Datamosh";
        ui_label = "Noise Contrast";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 4.0;
    > = 0.1;

    uniform float _Scale <
        ui_category = "Datamosh";
        ui_label = "Velocity Scale";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 2.0;
    > = 1.0;

    uniform float _Diffusion <
        ui_category = "Datamosh";
        ui_label = "Amount of Random Displacement";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 4.0;
    > = 2.0;

    #ifndef LINEAR_SAMPLING
        #define LINEAR_SAMPLING 0
    #endif

    #if LINEAR_SAMPLING == 1
        #define FILTERING LINEAR
    #else
        #define FILTERING POINT
    #endif

    /*
        [Textures and samplers]
    */

    CREATE_SAMPLER(SampleTempTex1, TempTex1_RG8, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex2a, TempTex2a_RG16F, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex2b, TempTex2b_RG16F, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex3, TempTex3_RG16F, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex4, TempTex4_RG16F, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex5, TempTex5_RG16F, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleFilteredFlowTex, TempTex2b_RG16F, FILTERING, MIRROR)

    CREATE_TEXTURE(Tex2c, BUFFER_SIZE_2, RG16F, 8)
    CREATE_SAMPLER(SampleTex2c, Tex2c, LINEAR, MIRROR)

    CREATE_TEXTURE(OFlowTex, BUFFER_SIZE_2, RG16F, 1)
    CREATE_SAMPLER(SampleOFlowTex, OFlowTex, LINEAR, MIRROR)

    CREATE_TEXTURE(AccumTex, BUFFER_SIZE_0, R16F, 1)
    CREATE_SAMPLER(SampleAccumTex, AccumTex, FILTERING, MIRROR)

    CREATE_TEXTURE(FeedbackTex, BUFFER_SIZE_0, RGBA8, 1)
    CREATE_SRGB_SAMPLER(SampleFeedbackTex, FeedbackTex, LINEAR, MIRROR)

    /*
        [Pixel Shaders]
    */

    float2 PS_Normalize(VS2PS_Quad Input) : SV_TARGET0
    {
        float3 Color = tex2D(CShade_SampleColorTex, Input.Tex0).rgb;
        return GetSphericalRG(Color);
    }

    float2 PS_HBlur_Prefilter(VS2PS_Quad Input) : SV_TARGET0
    {
        return GetPixelBlur(Input, SampleTempTex1, true).rg;
    }

    float2 PS_VBlur_Prefilter(VS2PS_Quad Input) : SV_TARGET0
    {
        return GetPixelBlur(Input, SampleTempTex2a, false).rg;
    }

    float2 PS_PyLK_Level4(VS2PS_Quad Input) : SV_TARGET0
    {
        float2 Vectors = 0.0;
        return GetPixelPyLK(Input.Tex0, Vectors, SampleTex2c, SampleTempTex2b);
    }

    float2 PS_PyLK_Level3(VS2PS_Quad Input) : SV_TARGET0
    {
        float2 Vectors = tex2D(SampleTempTex5, Input.Tex0).xy;
        return GetPixelPyLK(Input.Tex0, Vectors, SampleTex2c, SampleTempTex2b);
    }

    float2 PS_PyLK_Level2(VS2PS_Quad Input) : SV_TARGET0
    {
        float2 Vectors = tex2D(SampleTempTex4, Input.Tex0).xy;
        return GetPixelPyLK(Input.Tex0, Vectors, SampleTex2c, SampleTempTex2b);
    }

    float4 PS_PyLK_Level1(VS2PS_Quad Input) : SV_TARGET0
    {
        float2 Vectors = tex2D(SampleTempTex3, Input.Tex0).xy;
        return float4(GetPixelPyLK(Input.Tex0, Vectors, SampleTex2c, SampleTempTex2b), 0.0, _BlendFactor);
    }

    // NOTE: We use MRT to immeduately copy the current blurred frame for the next frame
    float4 PS_HBlur_Postfilter(VS2PS_Quad Input, out float4 Copy : SV_TARGET0) : SV_TARGET1
    {
        Copy = tex2D(SampleTempTex2b, Input.Tex0.xy);
        return float4(GetPixelBlur(Input, SampleOFlowTex, true).rg, 0.0, 1.0);
    }

    float4 PS_VBlur_Postfilter(VS2PS_Quad Input) : SV_TARGET0
    {
        return float4(GetPixelBlur(Input, SampleTempTex2a, false).rg, 0.0, 1.0);
    }

    // Datamosh

    float RandUV(float2 Tex)
    {
        float f = dot(float2(12.9898, 78.233), Tex);
        return frac(43758.5453 * sin(f));
    }

    float2 GetMVBlocks(float2 MV, float2 Tex, out float3 Random)
    {
        float2 TexSize = fwidth(Tex);
        float2 Time = float2(_Time, 0.0);

        // Random numbers
        Random.x = RandUV(Tex.xy + Time.xy);
        Random.y = RandUV(Tex.xy + Time.yx);
        Random.z = RandUV(Tex.yx - Time.xx);

        // Normalized screen space -> Pixel coordinates
        MV = DecodeVectors(MV * _Scale, TexSize);

        // Small random displacement (diffusion)
        MV += (Random.xy - 0.5)  * _Diffusion;

        // Pixel perfect snapping
        return round(MV);
    }

    float4 PS_Accumulate(VS2PS_Quad Input) : SV_TARGET0
    {
        float Quality = 1.0 - _Entropy;
        float3 Random = 0.0;

        // Motion vectors
        float2 MV = tex2Dlod(SampleFilteredFlowTex, float4(Input.Tex0, 0.0, _MipBias)).xy;

        // Get motion blocks
        MV = GetMVBlocks(MV, Input.Tex0, Random);

        // Accumulates the amount of motion.
        float MVLength = length(MV);

        float4 OutputColor = 0.0;

        // Simple update
        float UpdateAcc = min(MVLength, _BlockSize) * 0.005;
        UpdateAcc += (Random.z * lerp(-0.02, 0.02, Quality));

        // Reset to random level
        float ResetAcc = saturate(Random.z * 0.5 + Quality);

        // Reset if the amount of motion is larger than the block size.
        [branch]
        if(MVLength > _BlockSize)
        {
            OutputColor = float4((float3)ResetAcc, 0.0);
        }
        else
        {
            OutputColor = float4((float3)UpdateAcc, 1.0);
        }

        return OutputColor;
    }

    float4 PS_Datamosh(VS2PS_Quad Input) : SV_TARGET0
    {
        float2 TexSize = fwidth(Input.Tex0);
        const float2 DisplacementTexel = BUFFER_SIZE_0;
        const float Quality = 1.0 - _Entropy;
        float3 Random = 0.0;

        // Motion vectors
        float2 MV = tex2Dlod(SampleFilteredFlowTex, float4(Input.Tex0, 0.0, _MipBias)).xy;

        // Get motion blocks
        MV = GetMVBlocks(MV, Input.Tex0, Random);

        // Get random motion
        float RandomMotion = RandUV(Input.Tex0 + length(MV));

        // Pixel coordinates -> Normalized screen space
        MV = EncodeVectors(MV, TexSize);

        // Color from the original image
        float4 Source = tex2D(CShade_SampleColorTex, Input.Tex0);

        // Displacement vector
        float Disp = tex2D(SampleAccumTex, Input.Tex0).r;
        float4 Work = tex2D(SampleFeedbackTex, Input.Tex0 - MV);

        // Generate some pseudo random numbers.
        float4 Rand = frac(float4(1.0, 17.37135, 841.4272, 3305.121) * RandomMotion);

        // Generate noise patterns that look like DCT bases.
        float2 Frequency = Input.HPos.xy * (Rand.x * 80.0 / _Contrast);

        // Basis wave (vertical or horizontal)
        float DCT = cos(lerp(Frequency.x, Frequency.y, 0.5 < Rand.y));

        // Random amplitude (the high freq, the less amp)
        DCT *= Rand.z * (1.0 - Rand.x) * _Contrast;

        // Conditional weighting
        // DCT-ish noise: acc > 0.5
        float CW = (Disp > 0.5) * DCT;
        // Original image: rand < (Q * 0.8 + 0.2) && acc == 1.0
        CW = lerp(CW, 1.0, Rand.w < lerp(0.2, 1.0, Quality) * (Disp > (1.0 - 1e-3)));

        // If the conditions above are not met, choose work.
        return lerp(Work, Source, CW);
    }

    float4 PS_CopyColorTex(VS2PS_Quad Input) : SV_TARGET0
    {
        return tex2D(CShade_SampleColorTex, Input.Tex0);
    }

    #define CREATE_PASS(VERTEX_SHADER, PIXEL_SHADER, RENDER_TARGET) \
        pass \
        { \
            VertexShader = VERTEX_SHADER; \
            PixelShader = PIXEL_SHADER; \
            RenderTarget0 = RENDER_TARGET; \
        }

    technique CShade_KinoDatamosh
    {
        // Normalize current frame
        CREATE_PASS(VS_Quad, PS_Normalize, TempTex1_RG8)

        // Prefilter blur
        CREATE_PASS(VS_Quad, PS_HBlur_Prefilter, TempTex2a_RG16F)
        CREATE_PASS(VS_Quad, PS_VBlur_Prefilter, TempTex2b_RG16F)

        // Bilinear Lucas-Kanade Optical Flow
        CREATE_PASS(VS_Quad, PS_PyLK_Level4, TempTex5_RG16F)
        CREATE_PASS(VS_Quad, PS_PyLK_Level3, TempTex4_RG16F)
        CREATE_PASS(VS_Quad, PS_PyLK_Level2, TempTex3_RG16F)
        pass GetFineOpticalFlow
        {
            ClearRenderTargets = FALSE;
            BlendEnable = TRUE;
            BlendOp = ADD;
            SrcBlend = INVSRCALPHA;
            DestBlend = SRCALPHA;

            VertexShader = VS_Quad;
            PixelShader = PS_PyLK_Level1;
            RenderTarget0 = OFlowTex;
        }

        // Postfilter blur
        pass MRT_CopyAndBlur
        {
            VertexShader = VS_Quad;
            PixelShader = PS_HBlur_Postfilter;
            RenderTarget0 = Tex2c;
            RenderTarget1 = TempTex2a_RG16F;
        }

        pass
        {
            VertexShader = VS_Quad;
            PixelShader = PS_VBlur_Postfilter;
            RenderTarget0 = TempTex2b_RG16F;
        }

        // Datamoshing
        pass
        {
            ClearRenderTargets = FALSE;
            BlendEnable = TRUE;
            BlendOp = ADD;
            SrcBlend = ONE;
            DestBlend = SRCALPHA; // The result about to accumulate

            VertexShader = VS_Quad;
            PixelShader = PS_Accumulate;
            RenderTarget0 = AccumTex;
        }

        pass
        {
            SRGBWriteEnable = WRITE_SRGB;

            VertexShader = VS_Quad;
            PixelShader = PS_Datamosh;
        }

        // Copy frame for feedback
        pass
        {
            SRGBWriteEnable = WRITE_SRGB;

            VertexShader = VS_Quad;
            PixelShader = PS_CopyColorTex;
            RenderTarget0 = FeedbackTex;
        }
    }
}
