#include "shared/cGraphics.fxh"

/*
    [Vertex Shaders]
*/

struct VS2PS_Census
{
    float4 HPos : SV_POSITION;
    float4 Tex0 : TEXCOORD0;
    float4 Tex1 : TEXCOORD1;
    float4 Tex2 : TEXCOORD2;
};

VS2PS_Census VS_Census(APP2VS Input)
{
    // Sample locations:
    // [0].xy [1].xy [2].xy
    // [0].xz [1].xz [2].xz
    // [0].xw [1].xw [2].xw

    const float2 PixelSize = 1.0 / float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    // Get fullscreen texcoord and vertex position
    VS2PS_Quad FSQuad = VS_Quad(Input);

    VS2PS_Census Output;
    Output.HPos = FSQuad.HPos;
    Output.Tex0 = FSQuad.Tex0.xyyy + (float4(-1.0, 1.0, 0.0, -1.0) * PixelSize.xyyy);
    Output.Tex1 = FSQuad.Tex0.xyyy + (float4(0.0, 1.0, 0.0, -1.0) * PixelSize.xyyy);
    Output.Tex2 = FSQuad.Tex0.xyyy + (float4(1.0, 1.0, 0.0, -1.0) * PixelSize.xyyy);
    return Output;
}

/*
    [Pixel Shaders]
*/

float Med3(float A, float B, float C)
{
    return clamp(A, min(B, C), max(B, C));
}

float4 PS_Census(VS2PS_Census Input) : SV_TARGET0
{
    float4 OutputColor0 = 0.0;
    float3 Transform = 0.0;

    const int Neighbors = 8;
    float3 SampleNeighbor[Neighbors];
    SampleNeighbor[0] = tex2D(CShade_SampleColorTex, Input.Tex0.xy).rgb;
    SampleNeighbor[1] = tex2D(CShade_SampleColorTex, Input.Tex1.xy).rgb;
    SampleNeighbor[2] = tex2D(CShade_SampleColorTex, Input.Tex2.xy).rgb;
    SampleNeighbor[3] = tex2D(CShade_SampleColorTex, Input.Tex0.xz).rgb;
    SampleNeighbor[4] = tex2D(CShade_SampleColorTex, Input.Tex2.xz).rgb;
    SampleNeighbor[5] = tex2D(CShade_SampleColorTex, Input.Tex0.xw).rgb;
    SampleNeighbor[6] = tex2D(CShade_SampleColorTex, Input.Tex1.xw).rgb;
    SampleNeighbor[7] = tex2D(CShade_SampleColorTex, Input.Tex2.xw).rgb;
    float3 CenterSample = tex2D(CShade_SampleColorTex, Input.Tex1.xz).rgb;

    // Generate 8-bit integer from the 8-pixel neighborhood
    for(int i = 0; i < Neighbors; i++)
    {
        float3 Comparison = step(SampleNeighbor[i], CenterSample);
        Transform += ldexp(Comparison, i);
    }

    float OTransform = Med3(Transform.r, Transform.g, Transform.b);

    // Convert the 8-bit integer to float, and average the results from each channel
    return OTransform * (1.0 / (exp2(8) - 1));
}

technique CShade_CensusTransform
{
    pass
    {
        SRGBWriteEnable = WRITE_SRGB;

        VertexShader = VS_Census;
        PixelShader = PS_Census;
    }
}
