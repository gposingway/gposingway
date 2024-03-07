#include "shared/cGraphics.fxh"
#include "shared/cImageProcessing.fxh"

/*
    [Shader Options]
*/

uniform int _Select <
    ui_label = "Method";
    ui_tooltip = "Select Chromaticity";
    ui_type = "combo";
    ui_items = " Length (XY)\0 Length (XYZ)\0 Average (XY)\0 Average (XYZ)\0 Sum (XY)\0 Sum (XYZ)\0 Ratio (XY)\0 Sphere (XY)\0 CoCg (XY)\0 CrCb (XY)\0";
> = 0;

/*
    [Pixel Shaders]
*/

float4 PS_Chromaticity(VS2PS_Quad Input) : SV_TARGET0
{
    float3 Color = tex2D(CShade_SampleColorTex, Input.Tex0).rgb ;
    float3 Gamma = tex2D(CShade_SampleGammaTex, Input.Tex0).rgb;
    float3 Chromaticity = 0.0;

    switch(_Select)
    {
        case 0: // Length (XY)
            Chromaticity.rg = GetSumChromaticity(Color, 0).rg;
            break;
        case 1: // Length (XYZ)
            Chromaticity.rgb = GetSumChromaticity(Color, 0).rgb;
            break;
        case 2: // Average (XY)
            Chromaticity.rg = GetSumChromaticity(Color, 1).rg;
            break;
        case 3: // Average (XYZ)
            Chromaticity.rgb = GetSumChromaticity(Color, 1).rgb;
            break;
        case 4: // Sum (XY)
            Chromaticity.rg = GetSumChromaticity(Color, 2).rg;
            break;
        case 5: // Sum (XYZ)
            Chromaticity.rgb = GetSumChromaticity(Color, 2).rgb;
            break;
        case 6: // Ratio (XY)
            Chromaticity.rg = GetRatioRG(Color);
            break;
        case 7: // Sphere (XY)
            Chromaticity.rg = GetSphericalRG(Color);
            break;
        case 8: // CoCg (XY)
            Chromaticity.rg = GetCoCg(Gamma);
            break;
        case 9: // CrCb (XY)
            Chromaticity.rg = GetCrCb(Gamma);
            break;
        default: // No Chromaticity
            Chromaticity.rgb = 0.0;
            break;
    }

    return float4(Chromaticity, 1.0);
}

technique CShade_Chromaticity
{
    pass
    {
        VertexShader = VS_Quad;
        PixelShader = PS_Chromaticity;
    }
}
