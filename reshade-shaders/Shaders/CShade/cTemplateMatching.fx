#include "shared/cGraphics.fxh"

namespace cTemplateMatching
{
    /*
        [Shader Options]
    */

    uniform int _Method <
        ui_label = "Template Matching Method";
        ui_type = "combo";
        ui_items = " SSD\0 NCC\0";
    > = 0;

    uniform int _Size <
        ui_label = "Window Size";
        ui_type = "slider";
        ui_min = 1;
        ui_max = 3;
    > = 1;

    /*
        [Textures & Samplers]
    */

    CREATE_TEXTURE(CurrentTex, BUFFER_SIZE_0, R8, 1)
    CREATE_SAMPLER(SampleCurrentTex, CurrentTex, LINEAR, CLAMP)

    CREATE_TEXTURE(PreviousTex, BUFFER_SIZE_0, R8, 1)
    CREATE_SAMPLER(SamplePreviousTex, PreviousTex, LINEAR, CLAMP)

    /*
        [Pixel Shaders]
    */

    float PS_Blit0(VS2PS_Quad Input) : SV_TARGET0
    {
        float3 Color = tex2D(CShade_SampleColorTex, Input.Tex0).rgb;
        return dot(Color, 1.0 / 3.0);
    }

    float4 PS_TemplateMatching(VS2PS_Quad Input) : SV_TARGET0
    {
        float4 PixelSize = float4(1.0, 1.0, 0.0, 0.0) / BUFFER_SIZE_0.xyyy;
        float SumIT = 0.0;
        float SumT2 = 0.0;
        float SumI2 = 0.0;
        float M = 0.0;

        switch(_Method)
        {
            case 0:
                M = 0.0;
                break;
            case 1:
                M = 1.0;
                break;
        }

        for (int x = -_Size; x <= _Size; x++)
        for (int y = -_Size; y <= _Size; y++)
        {
            int2 Shift = int2(x, y);
            float4 Tex = Input.Tex0.xyyy + (Shift.xyyy * PixelSize);
            float I = tex2Dlod(SamplePreviousTex, Tex).r;
            float T = tex2Dlod(SampleCurrentTex, Tex).r;

            switch(_Method)
            {
                case 0:
                    float D = T - I;
                    SumIT += (D * D);
                    break;
                case 1:
                    SumIT += (T * I);
                    break;
            }

            SumT2 += (T * T);
            SumI2 += (I * I);
        }

        float N = sqrt(SumT2 * SumI2);
        float O = (N != 0.0) ? SumIT / N : M;

        return O;
    }

    float4 PS_Blit1(VS2PS_Quad Input) : SV_TARGET0
    {
        return tex2D(SampleCurrentTex, Input.Tex0);
    }

    technique CShade_TemplateMatching
    {
        pass
        {
            VertexShader = VS_Quad;
            PixelShader = PS_Blit0;

            RenderTarget0 = CurrentTex;
        }

        pass
        {
            SRGBWriteEnable = WRITE_SRGB;

            VertexShader = VS_Quad;
            PixelShader = PS_TemplateMatching;
        }

        pass
        {
            VertexShader = VS_Quad;
            PixelShader = PS_Blit1;

            RenderTarget0 = PreviousTex;
        }
    }
}
