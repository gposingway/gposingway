#include "shared/cGraphics.fxh"
#include "shared/cImageProcessing.fxh"

/*
    [Shader Options]
*/

uniform float _Radius <
    ui_label = "Radius";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;


/*
    [Pixel Shaders]
*/

float4 PS_NoiseBlur(VS2PS_Quad Input) : SV_TARGET0
{
    float4 OutputColor = 0.0;

    const float Pi2 = acos(-1.0) * 2.0;
    const float2 ScreenSize = int2(BUFFER_WIDTH, BUFFER_HEIGHT);
    const float2 PixelSize = 1.0 / ScreenSize;
    float Noise = Pi2 * GetGradientNoise(Input.Tex0.xy * 256.0);

    float2 Rotation = 0.0;
    sincos(Noise, Rotation.y, Rotation.x);

    float2x2 RotationMatrix = float2x2(Rotation.x, Rotation.y,
                                      -Rotation.y, Rotation.x);

    float Height = saturate(1.0 - saturate(pow(abs(Input.Tex0.y), 1.0)));
    float AspectRatio = ScreenSize.y * (1.0 / ScreenSize.x);

    float4 Weight = 0.0;
    [unroll] for(int i = 1; i < 4; ++i)
    {
        [unroll] for(int j = 0; j < 4 * i; ++j)
        {
            float Shift = (Pi2 / (4.0 * float(i))) * float(j);
            float2 AngleShift = 0.0;
            sincos(Shift, AngleShift.x, AngleShift.y);
            AngleShift *= float(i);

            float2 SampleOffset = mul(AngleShift, RotationMatrix);
            SampleOffset *= _Radius;
            SampleOffset.x *= AspectRatio;
            OutputColor += tex2D(CShade_SampleColorTex, Input.Tex0 + (SampleOffset * 0.01));
            Weight++;
        }
    }

    return OutputColor / Weight;
}

technique CShade_NoiseBlur
{
    pass
    {
        SRGBWriteEnable = WRITE_SRGB;

        VertexShader = VS_Quad;
        PixelShader = PS_NoiseBlur;
    }
}
