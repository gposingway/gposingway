#include "shared/cGraphics.fxh"

/*
    [Shader Options]
*/

uniform float4 _Color <
    ui_label = "Color";
    ui_type = "color";
    ui_min = 0.0;
> = 1.0;

/*
    [Pixel Shaders]
*/

float4 PS_Color(VS2PS_Quad Input) : SV_TARGET0
{
    return _Color;
}

// Use BlendOp to multiple the backbuffer with this quad's color
technique CShade_ColorBlendOp
{
    pass
    {
        BlendEnable = TRUE;
        BlendOp = ADD;
        SrcBlend = DESTCOLOR;
        DestBlend = SRCALPHA;
        SRGBWriteEnable = WRITE_SRGB;

        VertexShader = VS_Quad;
        PixelShader = PS_Color;
    }
}
