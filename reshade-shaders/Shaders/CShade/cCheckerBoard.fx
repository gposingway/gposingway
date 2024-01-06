#include "shared/cGraphics.fxh"

/*
    [Shader Options]
*/

uniform float4 _Color1 <
    ui_label = "Color 1";
    ui_type = "color";
    ui_min = 0.0;
> = 1.0;

uniform float4 _Color2 <
    ui_label = "Color 2";
    ui_type = "color";
    ui_min = 0.0;
> = 0.0;

uniform bool _InvertCheckerboard <
    ui_label = "Invert Checkerboard Pattern";
    ui_type = "radio";
> = false;

/*
    [Pixel Shaders]
*/

float4 PS_Checkerboard(VS2PS_Quad Input) : SV_TARGET0
{
    float4 Checkerboard = frac(dot(Input.HPos.xy, 0.5)) * 2.0;
    Checkerboard = _InvertCheckerboard ? 1.0 - Checkerboard : Checkerboard;
    Checkerboard = Checkerboard == 1.0 ? _Color1 : _Color2;
    return Checkerboard;
}

technique CShade_CheckerBoard
{
    pass
    {
        SRGBWriteEnable = WRITE_SRGB;

        VertexShader = VS_Quad;
        PixelShader = PS_Checkerboard;
    }
}
