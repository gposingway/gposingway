#include "shared/cGraphics.fxh"

/*
    [Shader Options]
*/

uniform float2 _ShiftRed <
    ui_type = "slider";
    ui_min = -0.01;
    ui_max = 0.01;
> = -0.001;

uniform float2 _ShiftGreen <
    ui_type = "slider";
    ui_min = -0.01;
    ui_max = 0.01;
> = 0.0;

uniform float2 _ShiftBlue <
    ui_type = "slider";
    ui_min = -0.01;
    ui_max = 0.01;
> = 0.001;

/*
    [Pixel Shaders]
*/

float4 PS_Abberation(VS2PS_Quad Input) : SV_TARGET0
{
    float4 OutputColor = 0.0;

    // Shift red channel
    OutputColor.r = tex2D(CShade_SampleColorTex, Input.Tex0 + _ShiftRed * float2(1.0, -1.0)).r;
    // Keep green channel to the center
    OutputColor.g = tex2D(CShade_SampleColorTex, Input.Tex0 + _ShiftGreen * float2(1.0, -1.0)).g;
    // Shift blue channel
    OutputColor.b = tex2D(CShade_SampleColorTex, Input.Tex0 + _ShiftBlue * float2(1.0, -1.0)).b;
    // Write alpha value
    OutputColor.a = 1.0;

    return OutputColor;
}

technique CShade_Abberation
{
    pass
    {
        SRGBWriteEnable = WRITE_SRGB;

        VertexShader = VS_Quad;
        PixelShader = PS_Abberation;
    }
}
