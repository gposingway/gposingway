#include "shared/cGraphics.fxh"

/*
    [Shader Options]
*/

uniform int _Select <
    ui_label = "Method";
    ui_type = "combo";
    ui_tooltip = "Select Luminance";
    ui_items = " Average\0 Min\0 Median\0 Max\0 Length\0 None\0";
> = 0;

/*
    [Pixel Shaders]
*/

float4 PS_Luminance(VS2PS_Quad Input) : SV_TARGET0
{
    float4 OutputColor = 0.0;

    float4 Color = tex2D(CShade_SampleColorTex, Input.Tex0);

    switch(_Select)
    {
        case 0:
            // Average
            OutputColor = dot(Color.rgb, 1.0 / 3.0);
            break;
        case 1:
            // Min
            OutputColor = min(Color.r, min(Color.g, Color.b));
            break;
        case 2:
            // Median
            OutputColor = max(min(Color.r, Color.g), min(max(Color.r, Color.g), Color.b));
            break;
        case 3:
            // Max
            OutputColor = max(Color.r, max(Color.g, Color.b));
            break;
        case 4:
            // Length
            OutputColor = length(Color.rgb) * rsqrt(3.0);
            break;
        default:
            OutputColor = Color;
            break;
    }

    return OutputColor;
}

technique CShade_Grayscale
{
    pass
    {
        SRGBWriteEnable = WRITE_SRGB;

        VertexShader = VS_Quad;
        PixelShader = PS_Luminance;
    }
}
