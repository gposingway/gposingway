// SETUP & FUNCTIONS ///////////////////////////////
////////////////////////////////////////////////////
static const float HSL_Threshold_Base  = 0.05;
static const float HSL_Threshold_Curve = 1.0;

float3 HSLShift(float3 color)
{
    float3 hsl = RGBToHSL(color);
    const float4 node[9]=
    {
        float4(HUERed,       0.0),//red
        float4(HUEOrange,   30.0),
        float4(HUEYellow,   60.0),
        float4(HUEGreen,   120.0),
        float4(HUECyan,    180.0),
        float4(HUEBlue,    240.0),
        float4(HUEPurple,  270.0),
        float4(HUEMagenta, 300.0),
        float4(HUERed,     360.0),//red
    };

    int base;
    for(int i=0; i<8; i++) if(node[i].a < hsl.r*360.0 )base = i;

    float w = saturate(abs(hsl.r*360.0-node[base].a)/(node[base+1].a-node[base].a));

    float3 H0 = RGBToHSL(node[base].rgb);
    float3 H1 = RGBToHSL(node[base+1].rgb);

    H1.x += (H1.x < H0.x)? 1.0:0.0;

    float3 shift = frac(lerp( H0, H1 , w));
    w = max( hsl.g, 0.0)*max( 1.0-hsl.b, 0.0);
    shift.b = (shift.b - 0.5)*(pow(w, HSL_Threshold_Curve)*(1.0-HSL_Threshold_Base)+HSL_Threshold_Base)*2.0;

    return saturate(HSLToRGB(saturate(float3(shift.r, hsl.g*(shift.g*2.0), hsl.b*(1.0+shift.b)))));
}