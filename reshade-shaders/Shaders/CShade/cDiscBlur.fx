#include "shared/cBuffers.fxh"
#include "shared/cGraphics.fxh"
#include "shared/cImageProcessing.fxh"

namespace cDiscBlur
{
    /*
        [Shader Options]
    */

    uniform float _Offset <
        ui_label = "Sample Offset";
        ui_type = "drag";
        ui_min = 0.0;
    > = 0.0;

    uniform float _Radius <
        ui_label = "Radius";
        ui_type = "drag";
        ui_min = 0.0;
    > = 64.0;

    uniform int _Samples <
        ui_label = "Sample Count";
        ui_type = "drag";
        ui_min = 0;
    > = 16;

    /*
        [Textures & Samplers]
    */

    CREATE_SAMPLER(SampleTempTex1, TempTex1_RGBA16F, LINEAR, CLAMP)

    /*
        [Pixel Shaders]
        ---
        Repurposed Wojciech Sterna's shadow sampling code as a screen-space convolution
        ---
        http://maxest.gct-game.net/content/chss.pdf
    */

    float4 PS_GenMipLevels(VS2PS_Quad Input) : SV_TARGET0
    {
        return tex2D(CShade_SampleColorTex, Input.Tex0);
    }

    float4 PS_VogelBlur(VS2PS_Quad Input) : SV_TARGET0
    {
        // Initialize variables we need to accumulate samples and calculate offsets
        float4 OutputColor = 0.0;

        // LOD calculation to fill in the gaps between samples
        const float Pi = acos(-1.0);
        float SampleArea = Pi * (_Radius * _Radius) / float(_Samples);
        float LOD = max(0.0, 0.5 * log2(SampleArea));

        // Offset and weighting attributes
        float2 ScreenSize = int2(BUFFER_WIDTH / 2, BUFFER_HEIGHT / 2);
        float2 PixelSize = 1.0 / ldexp(ScreenSize, -LOD);
        float Weight = 1.0 / (float(_Samples));

        for(int i = 0; i < _Samples; i++)
        {
            float2 Offset = SampleVogel(i, _Samples);
            OutputColor += tex2Dlod(SampleTempTex1, float4(Input.Tex0 + (Offset * PixelSize), 0.0, LOD)) * Weight;
        }

        return OutputColor;
    }

    technique CShade_Blur
    {
        pass GenMipLevels
        {
            VertexShader = VS_Quad;
            PixelShader = PS_GenMipLevels;
            RenderTarget0 = TempTex1_RGBA16F;
        }

        pass VogelBlur
        {
            SRGBWriteEnable = WRITE_SRGB;

            VertexShader = VS_Quad;
            PixelShader = PS_VogelBlur;
        }
    }
}