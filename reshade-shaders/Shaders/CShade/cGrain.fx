#include "shared/cGraphics.fxh"
#include "shared/cImageProcessing.fxh"

/*
    [Shader Options]
*/

uniform float _Time < source = "timer"; >;

uniform float _Speed <
    ui_label = "Speed";
    ui_type = "drag";
> = 2.0;

uniform float _Variance <
    ui_label = "Variance";
    ui_type = "drag";
> = 0.5;

uniform float _Intensity <
    ui_label = "Intensity";
    ui_type = "drag";
> = 0.005;

/*
    [Pixel Shaders]
    ---
    "Well ill believe it when i see it."
    Yoinked code by Luluco250 (RIP) [https://www.shadertoy.com/view/4t2fRz] [MIT]
*/

float4 PS_FilmGrain(VS2PS_Quad Input) : SV_TARGET0
{
    float Time = rcp(1e+3 / _Time) * _Speed;
    float Seed = dot(Input.HPos.xy, float2(12.9898, 78.233));
    float Noise = frac(sin(Seed) * 43758.5453 + Time);
    return GetGaussianWeight(Noise, _Variance) * _Intensity;
}

technique CShade_FilmGrain
{
    pass
    {
        // (Shader[Src] * SrcBlend) + (Buffer[Dest] * DestBlend)
        // This shader: (Shader[Src] * (1.0 - Buffer[Dest])) + Buffer[Dest]
        BlendEnable = TRUE;
        BlendOp = ADD;
        SrcBlend = INVDESTCOLOR;
        DestBlend = ONE;
        SRGBWriteEnable = WRITE_SRGB;

        VertexShader = VS_Quad;
        PixelShader = PS_FilmGrain;
    }
}
