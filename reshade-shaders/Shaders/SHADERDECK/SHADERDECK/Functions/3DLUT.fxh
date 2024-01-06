float3 MultiLUT_Linear(float3 color, sampler InTex, int index)
{
    int2   tex_size;
    float2 lutsize;
    float3 lutuv, lutcolor;

    // Find the texture width and height
    tex_size   = tex2Dsize(InTex);

    // Find the correct LUT size
    lutsize    = float2(1.0 / tex_size.x, 1.0 / sqrt(tex_size.x));
    color.rgb  = saturate(color.rgb) * (sqrt(tex_size.x) - 1.0);
    lutuv.z    = floor(color.z);
    color.z   -= lutuv.z;
    color.xy   = (color.xy + 0.5) * lutsize;
    color.x   += lutuv.z * lutsize.y;
    color.y   *= (sqrt(tex_size.x) / tex_size.y);
    lutuv.x    = color.x;
    lutuv.z    = lutuv.x + lutsize.y;

    lutuv.y    = color.y + (index) * (sqrt(tex_size.x) / tex_size.y);

    lutcolor   = lerp(tex2D(InTex, lutuv.xy).rgb, tex2D(InTex, lutuv.zy).rgb, color.z);

    return saturate(lutcolor);
}

/*  ///////////////////////////////////////////////////////////////////////////////////  **

    Tetrahedral interpolated MultiLUT
    <> by kingeric (Nov 5th, 2022)

	ReShade FX port
	<> by Kitsuune (June 23rd, 2023)

**  ///////////////////////////////////////////////////////////////////////////////////  */

float4 tex2Dfetch_atlas(sampler2D s, int3 size, int3 pos, int slice)
{
    return tex2Dfetch(s, int2(pos.x + size.x * pos.z, pos.y + size.y * slice));
}

float3 ApplyTLUT(sampler2D samplerIn, float3 color, int slice)
{
    const int size = sqrt(tex2Dsize(samplerIn).x);
    
    float3 d =  color * (size.xxx - 1);
    int3   i =  d, p00, p11;
    int2   j = int2(1, 0);
    bool3  b = (d -= i) >= d.gbr;

    [flatten] // should flatten itself without annotation.
    if (b.x)  // x >= y
    {
        [flatten]
        if      (b.y) d = d.xyz, p00 = j.xyy, p11 = j.xxy; // xyz
        else if (b.z) d = d.zxy, p00 = j.yyx, p11 = j.xyx; // zxy
        else          d = d.xzy, p00 = j.xyy, p11 = j.xyx; // xzy
    }

    else // y > x
    {
        [flatten]
        if      (!b.y) d = d.zyx, p00 = j.yyx, p11 = j.yxx; // zyx
        else if (!b.z) d = d.yxz, p00 = j.yxy, p11 = j.xxy; // yxz
        else           d = d.yzx, p00 = j.yxy, p11 = j.yxx; // yzx
    }

    return mul(float4(1. - d.x, d.z, d.xy - d.yz),
                float4x3(tex2Dfetch_atlas(samplerIn, size, i + j.y, slice).rgb,
                         tex2Dfetch_atlas(samplerIn, size, i + j.x, slice).rgb,
                         tex2Dfetch_atlas(samplerIn, size, i + p00, slice).rgb,
                         tex2Dfetch_atlas(samplerIn, size, i + p11, slice).rgb));
}

float3 ApplyTLUT(sampler2D samplerIn, float3 color)
{ 
    return ApplyTLUT(samplerIn, color, 0);
}

float3 FilmNegative(float3 color, int tex, int stock)
{
    switch(tex)
    {
        case  0: return saturate(ApplyTLUT(NegativeAtlas, color, stock));

        #if ((CUST_NEGATIVE_LUT_COUNT > 0) && (CUST_NEGATIVE_LUT_COUNT < 6))
        case  1: return saturate(ApplyTLUT(CustomNegativeAtlas, color, stock));
        #endif
        
        default: return color;
    }
}

float3 FilmPrint(float3 color, int tex, int stock)
{
    switch(tex)
    {
        case  0: return saturate(ApplyTLUT(PrintAtlas, color, stock));

        #if ((CUST_PRINT_LUT_COUNT > 0) && (CUST_PRINT_LUT_COUNT < 6))
        case  1: return saturate(ApplyTLUT(CustomPrintAtlas, color, stock));
        #endif

        default: return color;
    }
}