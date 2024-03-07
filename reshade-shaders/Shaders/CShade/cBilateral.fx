#include "shared/cGraphics.fxh"
#include "shared/cImageProcessing.fxh"

float4 PS_Bilateral(VS2PS_Quad Input) : SV_TARGET0
{
    // Get constant
    const float Pi2 = acos(-1.0) * 2.0;

    // Initialize variables we need to accumulate samples and calculate offsets
    float4 OutputColor = 0.0;

    // Offset and weighting attributes
    float2 PixelSize = 1.0 / float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    // Get bilateral filter
    float3 TotalWeight = 0.0;
    float3 Center = tex2D(CShade_SampleColorTex, Input.Tex0).rgb;
    [unroll] for(int i = 1; i < 4; ++i)
    {
        [unroll] for(int j = 0; j < 4 * i; ++j)
        {
            float2 Shift = (Pi2 / (4.0 * float(i))) * float(j);
            sincos(Shift, Shift.x, Shift.y);
            Shift *= float(i);

            float3 Pixel = tex2D(CShade_SampleColorTex, Input.Tex0 + (Shift * PixelSize)).rgb;
            float3 Weight = abs(1.0 - abs(Pixel - Center));
            OutputColor += (Pixel * Weight);
            TotalWeight += Weight;
        }
    }
    OutputColor.rgb /= TotalWeight;

    return OutputColor;
}

technique CShade_Bilateral
{
    pass Bilateral
    {
        SRGBWriteEnable = WRITE_SRGB;

        VertexShader = VS_Quad;
        PixelShader = PS_Bilateral;
    }
}
