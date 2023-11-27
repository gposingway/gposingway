
#include "shared/cGraphics.fxh"
#include "shared/cBuffers.fxh"

namespace cEnsor
{
    uniform int _Blockiness <
        ui_label = "Blockiness";
        ui_type = "slider";
        ui_min = 0;
        ui_max = 7;
    > = 3;

    uniform float _Threshold <
        ui_label = "Luma Threshold";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
    > = 0.1;

    uniform bool _DisplayMask <
        ui_label = "Display Mask";
        ui_type = "radio";
    > = false;

    CREATE_SAMPLER(SampleTempTex0, TempTex0_RGB10A2, POINT, CLAMP)

    float4 PS_Blit(VS2PS_Quad Input) : SV_TARGET0
    {
        return float4(tex2D(CShade_SampleColorTex, Input.Tex0).rgb, 1.0);
    }

    float4 PS_Censor(VS2PS_Quad Input) : SV_TARGET0
    {
        float4 Color = tex2D(CShade_SampleColorTex, Input.Tex0);
        float4 Pixel = tex2Dlod(SampleTempTex0, float4(Input.Tex0, 0.0, _Blockiness));
        float MaxC = max(max(Pixel.r, Pixel.g), Pixel.b);
        bool Mask = saturate(MaxC > _Threshold);

        if(_DisplayMask)
        {
            return Mask;
        }
        else
        {
            return lerp(Color, Pixel, Mask);
        }
    }

    technique CShade_Censor
    {
        pass
        {
            VertexShader = VS_Quad;
            PixelShader = PS_Blit;
            RenderTarget = TempTex0_RGB10A2;
        }

        pass
        {
            SRGBWriteEnable = WRITE_SRGB;
            VertexShader = VS_Quad;
            PixelShader = PS_Censor;
        }
    }
}
