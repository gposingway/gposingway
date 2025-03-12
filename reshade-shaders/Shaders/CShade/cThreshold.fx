#include "shared/cGraphics.fxh"

/*
    [Shader Options]
*/

uniform float _Threshold <
    ui_label = "Threshold";
    ui_type = "drag";
    ui_min = 0.0;
> = 0.8;

uniform float _Smooth <
    ui_label = "Smoothing";
    ui_type = "drag";
    ui_min = 0.0;
> = 0.5;

uniform float _Saturation <
    ui_label = "Saturation";
    ui_type = "drag";
    ui_min = 0.0;
> = 1.0;

uniform float _Intensity <
    ui_label = "Intensity";
    ui_type = "drag";
    ui_min = 0.0;
> = 1.0;

/*
    [Pixel Shaders]
*/

float Med3(float x, float y, float z)
{
    return max(min(x, y), min(max(x, y), z));
}

float4 PS_Threshold(VS2PS_Quad Input) : SV_TARGET0
{
    const float Knee = mad(_Threshold, _Smooth, 1e-5f);
    const float3 Curve = float3(_Threshold - Knee, Knee * 2.0, 0.25 / Knee);
    float4 Color = tex2D(CShade_SampleColorTex, Input.Tex0);

    // Under-threshold
    float Brightness = Med3(Color.r, Color.g, Color.b);
    float ResponseCurve = clamp(Brightness - Curve.x, 0.0, Curve.y);
    ResponseCurve = Curve.z * ResponseCurve * ResponseCurve;

    // Combine and apply the brightness response curve
    Color = Color * max(ResponseCurve, Brightness - _Threshold) / max(Brightness, 1e-10);
    Brightness = Med3(Color.r, Color.g, Color.b);
    return saturate(lerp(Brightness, Color, _Saturation) * _Intensity);
}

technique CShade_Threshold
{
    pass
    {
        SRGBWriteEnable = WRITE_SRGB;

        VertexShader = VS_Quad;
        PixelShader = PS_Threshold;
    }
}