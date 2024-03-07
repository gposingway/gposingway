#include "shared/cBuffers.fxh"
#include "shared/cGraphics.fxh"
#include "shared/cImageProcessing.fxh"
#include "shared/cVideoProcessing.fxh"

namespace cOpticalFlow
{
    /*
        [Shader Options]
    */

    uniform float _MipBias <
        ui_label = "Mipmap Bias";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 7.0;
    > = 0.0;

    uniform float _BlendFactor <
        ui_label = "Temporal Blending Factor";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 0.9;
    > = 0.0;

    /*
        [Textures & Samplers]
    */

    CREATE_SAMPLER(SampleTempTex1, TempTex1_RG8, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex2a, TempTex2a_RG16F, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex2b, TempTex2b_RG16F, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex3, TempTex3_RG16F, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex4, TempTex4_RG16F, LINEAR, MIRROR)
    CREATE_SAMPLER(SampleTempTex5, TempTex5_RG16F, LINEAR, MIRROR)

    CREATE_TEXTURE(Tex2c, BUFFER_SIZE_2, RG16F, 8)
    CREATE_SAMPLER(SampleTex2c, Tex2c, LINEAR, MIRROR)

    CREATE_TEXTURE(OFlowTex, BUFFER_SIZE_2, RG16F, 1)
    CREATE_SAMPLER(SampleOFlowTex, OFlowTex, LINEAR, MIRROR)

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

    // Run Lucas-Kanade

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

    // Postfilter blur

    // We use MRT to immeduately copy the current blurred frame for the next frame
    float4 PS_HBlur_Postfilter(VS2PS_Quad Input, out float4 Copy : SV_TARGET0) : SV_TARGET1
    {
        Copy = tex2D(SampleTempTex2b, Input.Tex0.xy);
        return float4(GetPixelBlur(Input, SampleOFlowTex, true).rg, 0.0, 1.0);
    }

    float4 PS_VBlur_Postfilter(VS2PS_Quad Input) : SV_TARGET0
    {
        return float4(GetPixelBlur(Input, SampleTempTex2a, false).rg, 0.0, 1.0);
    }

    float4 PS_Display(VS2PS_Quad Input) : SV_TARGET0
    {
        float2 InvTexSize = fwidth(Input.Tex0);

        float2 Vectors = tex2Dlod(SampleTempTex2b, float4(Input.Tex0.xy, 0.0, _MipBias)).xy;
        Vectors = DecodeVectors(Vectors, InvTexSize);

        float3 NVectors = normalize(float3(Vectors, 1.0));
        NVectors = saturate((NVectors * 0.5) + 0.5);

        return float4(NVectors, 1.0);
    }

    #define CREATE_PASS(VERTEX_SHADER, PIXEL_SHADER, RENDER_TARGET) \
        pass \
        { \
            VertexShader = VERTEX_SHADER; \
            PixelShader = PIXEL_SHADER; \
            RenderTarget0 = RENDER_TARGET; \
        }

    technique CShade_OpticalFlow
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

        // Display
        pass
        {
            SRGBWriteEnable = WRITE_SRGB;

            VertexShader = VS_Quad;
            PixelShader = PS_Display;
        }
    }
}
