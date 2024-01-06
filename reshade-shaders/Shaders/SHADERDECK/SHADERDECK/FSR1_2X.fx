////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                                  ///
///  .d8888b.  888    888        d8888 8888888b.  8888888888 8888888b.  8888888b.  8888888888  .d8888b.  888    d8P  ///
/// d88P  Y88b 888    888       d88888 888  "Y88b 888        888   Y88b 888  "Y88b 888        d88P  Y88b 888   d8P   ///
/// Y88b.      888    888      d88P888 888    888 888        888    888 888    888 888        888    888 888  d8P    ///
///  "Y888b.   8888888888     d88P 888 888    888 8888888    888   d88P 888    888 8888888    888        888d88K     ///
///     "Y88b. 888    888    d88P  888 888    888 888        8888888P"  888    888 888        888        8888888b    ///
///       "888 888    888   d88P   888 888    888 888        888 T88b   888    888 888        888    888 888  Y88b   ///
/// Y88b  d88P 888    888  d8888888888 888  .d88P 888        888  T88b  888  .d88P 888        Y88b  d88P 888   Y88b  ///
///  "Y8888P"  888    888 d88P     888 8888888P"  8888888888 888   T88b 8888888P"  8888888888  "Y8888P"  888    Y88b ///
///                                                                                                                  ///
///    FSR 1.0 2X                                                                                                    ///
///    <> BY AMD                                                                                                     ///
///                                                                                                                  ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*  ///////////////////////////////////////////////////////////////////////////////////////////  **
**  ///////////////////////////////////////////////////////////////////////////////////////////  **
    
    This shader uses AMD's FSR 1.0 algorithm to internally upscale the image to 2X your render
    resolution, then downsamples that back down to your screensize. This is effectively a poor
    man's fake "supersampling."

    I cannot remember who did this port. If the author of this port sees this, please contact
    me so that I can credit you.

    - TreyM

**  ///////////////////////////////////////////////////////////////////////////////////////////  **
**  ///////////////////////////////////////////////////////////////////////////////////////////  */

#include "ReShade.fxh"

uniform float sharpness <
    ui_min = 0.0;
    ui_max = 2.0;
    ui_type = "slider";
> = 1.75;

//uniform bool noise_removal = true;

#define AP1 bool
#define AF1 float
#define AF2 float2
#define AF3 float3
#define AF4 float4
#define AU1 uint
#define AU2 uint2
#define AU4 uint4
#define ASU2 int2
#define AF1_AU1(x) asfloat(AU1(x))
#define AF2_AU2(x) asfloat(AU2(x))
#define AU1_AF1(x) asuint(AF1(x))
AF1 AF1_x(AF1 a){return AF1(a);}
AF2 AF2_x(AF1 a){return AF2(a,a);}
AF3 AF3_x(AF1 a){return AF3(a,a,a);}
AF4 AF4_x(AF1 a){return AF4(a,a,a,a);}
#define AF1_(a) AF1_x(AF1(a))
#define AF2_(a) AF2_x(AF1(a))
#define AF3_(a) AF3_x(AF1(a))
#define AF4_(a) AF4_x(AF1(a))
AU1 AU1_x(AU1 a){return AU1(a);}
#define AU1_(a) AU1_x(AU1(a))
AF1 AMax3F1(AF1 x,AF1 y,AF1 z){return max(x,max(y,z));}
AF3 AMax3F3(AF3 x,AF3 y,AF3 z){return max(x,max(y,z));}
AF1 AMin3F1(AF1 x,AF1 y,AF1 z){return min(x,min(y,z));}
AF3 AMin3F3(AF3 x,AF3 y,AF3 z){return min(x,min(y,z));}
AF1 ARcpF1(AF1 x){return rcp(x);}
AF1 ASatF1(AF1 x){return saturate(x);}
AF3 ASatF3(AF3 x){return saturate(x);}
AU1 ABfe(AU1 src,AU1 off,AU1 bits){AU1 mask=(1u<<bits)-1;return (src>>off)&mask;}
AU1 ABfiM(AU1 src,AU1 ins,AU1 bits){AU1 mask=(1u<<bits)-1;return (ins&mask)|(src&(~mask));}
AU2 ARmp8x8(AU1 a){return AU2(ABfe(a,1u,3u),ABfiM(ABfe(a,3u,3u),a,1u));}
AF1 APrxLoRcpF1(AF1 a){return AF1_AU1(AU1_(0x7ef07ebb)-AU1_AF1(a));}
AF1 APrxMedRcpF1(AF1 a){AF1 b=AF1_AU1(AU1_(0x7ef19fff)-AU1_AF1(a));return b*(-b*a+AF1_(2.0));}
AF1 APrxLoRsqF1(AF1 a){return AF1_AU1(AU1_(0x5f347d74)-(AU1_AF1(a)>>AU1_(1)));}
#define AExp2F1(a) exp2(AF1(a))
#define FSR_RCAS_LIMIT (0.25-(1.0/16.0))

texture2D texColorBuffer : COLOR;
sampler2D samplerColor
{
    Texture = texColorBuffer;
};

texture2D texFSR2x
{
    Width   = 2 * BUFFER_WIDTH;
    Height  = 2 * BUFFER_HEIGHT;
    Format  = RGBA16;
};

sampler2D samplerFSR2x
{
    Texture = texFSR2x;
};

storage2D storageFSR2x
{
    Texture = texFSR2x;
};

texture2D texFSR1L
{
    Width   = BUFFER_WIDTH;
    Height  = BUFFER_HEIGHT;
    Format  = RGBA16;
};

sampler2D samplerFSR1L
{
    Texture = texFSR1L;
};

storage2D storageFSR1L
{
    Texture = texFSR1L;
};

texture2D texFSRC
{
    Width   = BUFFER_WIDTH;
    Height  = BUFFER_HEIGHT;
    Format  = RGBA16;
};

sampler2D samplerFSRC
{
    Texture = texFSRC;
};

storage2D storageFSRC
{
    Texture = texFSRC;
};

void FsrEasuSet(inout AF2 dir, inout AF1 len, AF2 pp,
                AP1 biS, AP1 biT, AP1 biU, AP1 biV,
                AF1 lA, AF1 lB, AF1 lC, AF1 lD, AF1 lE)
{
    AF1 w      = AF1_(0.0);
    if (biS) w = (AF1_(1.0) - pp.x) * (AF1_(1.0) - pp.y);
    if (biT) w =              pp.x  * (AF1_(1.0) - pp.y);
    if (biU) w = (AF1_(1.0) - pp.x) *              pp.y;
    if (biV) w =              pp.x  *              pp.y;
    AF1 dc     = lD - lC;
    AF1 cb     = lC - lB;
    AF1 lenX   = max(abs(dc), abs(cb));
    lenX       = APrxLoRcpF1(lenX);
    AF1 dirX   = lD - lB;
    dir.x     += dirX * w;
    lenX       = ASatF1(abs(dirX) * lenX);
    lenX      *= lenX;
    len       += lenX * w;
    AF1 ec     = lE - lC;
    AF1 ca     = lC - lA;
    AF1 lenY   = max(abs(ec), abs(ca));
    lenY       = APrxLoRcpF1(lenY);
    AF1 dirY   = lE - lA;
    dir.y     += dirY * w;
    lenY       = ASatF1(abs(dirY) * lenY);
    lenY      *= lenY;
    len       += lenY * w;
}

void FsrEasuTap(inout AF3 aC, inout AF1 aW, AF2 off, AF2 dir, AF2 len, AF1 lob,
                 AF1 clp, AF3 c)
{
    AF2 v;
    v.x    = (off.x * ( dir.x)) + (off.y * dir.y);
    v.y    = (off.x * (-dir.y)) + (off.y * dir.x);
    v     *= len;
    AF1 d2 = v.x * v.x + v.y * v.y;
    d2     = min(d2, clp);
    AF1 wB = AF1_(2.0 / 5.0) * d2 + AF1_(-1.0);
    AF1 wA = lob * d2 + AF1_(-1.0);
    wB    *= wB;
    wA    *= wA;
    wB     = AF1_(25.0 / 16.0) * wB + AF1_(-(25.0 / 16.0 - 1.0));
    AF1 w  = wB * wA;
    aC    += c * w;
    aW    += w;
}

void FsrEasu(out AF3 pix, AU2 ip)
{
    AF4 con0, con1, con2, con3;
    con0[0]     = BUFFER_WIDTH * ARcpF1((2 * BUFFER_WIDTH));
    con0[1]     = BUFFER_HEIGHT * ARcpF1((2 * BUFFER_HEIGHT));
    con0[2]     = AF1_(0.5) * BUFFER_WIDTH * ARcpF1((2 * BUFFER_WIDTH)) - AF1_(0.5);
    con0[3]     = AF1_(0.5) * BUFFER_HEIGHT * ARcpF1((2 * BUFFER_HEIGHT)) - AF1_(0.5);
    con1[0]     = ARcpF1(BUFFER_WIDTH);
    con1[1]     = ARcpF1(BUFFER_HEIGHT);
    con1[2]     = AF1_( 1.0) * ARcpF1(BUFFER_WIDTH);
    con1[3]     = AF1_(-1.0) * ARcpF1(BUFFER_HEIGHT);
    con2[0]     = AF1_(-1.0) * ARcpF1(BUFFER_WIDTH);
    con2[1]     = AF1_( 2.0) * ARcpF1(BUFFER_HEIGHT);
    con2[2]     = AF1_( 1.0) * ARcpF1(BUFFER_WIDTH);
    con2[3]     = AF1_( 2.0) * ARcpF1(BUFFER_HEIGHT);
    con3[0]     = AF1_( 0.0) * ARcpF1(BUFFER_WIDTH);
    con3[1]     = AF1_( 4.0) * ARcpF1(BUFFER_HEIGHT);
    AF2 pp      = AF2(ip) * con0.xy + con0.zw;
    AF2 fp      = floor(pp);
    pp         -= fp;
    AF2 p0      = fp * con1.xy + con1.zw;
    AF2 p1      = p0 + con2.xy;
    AF2 p2      = p0 + con2.zw;
    AF2 p3      = p0 + con3.xy;
    AF4 bczzR   = tex2DgatherR(samplerColor, p0);
    AF4 bczzG   = tex2DgatherG(samplerColor, p0);
    AF4 bczzB   = tex2DgatherB(samplerColor, p0);
    AF4 ijfeR   = tex2DgatherR(samplerColor, p1);
    AF4 ijfeG   = tex2DgatherG(samplerColor, p1);
    AF4 ijfeB   = tex2DgatherB(samplerColor, p1);
    AF4 klhgR   = tex2DgatherR(samplerColor, p2);
    AF4 klhgG   = tex2DgatherG(samplerColor, p2);
    AF4 klhgB   = tex2DgatherB(samplerColor, p2);
    AF4 zzonR   = tex2DgatherR(samplerColor, p3);
    AF4 zzonG   = tex2DgatherG(samplerColor, p3);
    AF4 zzonB   = tex2DgatherB(samplerColor, p3);
    AF4 bczzL   = bczzB * AF4_(0.5) + (bczzR * AF4_(0.5) + bczzG);
    AF4 ijfeL   = ijfeB * AF4_(0.5) + (ijfeR * AF4_(0.5) + ijfeG);
    AF4 klhgL   = klhgB * AF4_(0.5) + (klhgR * AF4_(0.5) + klhgG);
    AF4 zzonL   = zzonB * AF4_(0.5) + (zzonR * AF4_(0.5) + zzonG);
    AF1 bL      = bczzL.x;
    AF1 cL      = bczzL.y;
    AF1 iL      = ijfeL.x;
    AF1 jL      = ijfeL.y;
    AF1 fL      = ijfeL.z;
    AF1 eL      = ijfeL.w;
    AF1 kL      = klhgL.x;
    AF1 lL      = klhgL.y;
    AF1 hL      = klhgL.z;
    AF1 gL      = klhgL.w;
    AF1 oL      = zzonL.z;
    AF1 nL      = zzonL.w;
    AF2 dir     = AF2_(0.0);
    AF1 len     = AF1_(0.0);
    FsrEasuSet(dir, len, pp, true,  false, false, false, bL, eL, fL, gL, jL);
    FsrEasuSet(dir, len, pp, false, true,  false, false, cL, fL, gL, hL, kL);
    FsrEasuSet(dir, len, pp, false, false, true,  false, fL, iL, jL, kL, nL);
    FsrEasuSet(dir, len, pp, false, false, false, true,  gL, jL, kL, lL, oL);
    AF2 dir2    = dir * dir;
    AF1 dirR    = dir2.x + dir2.y;
    AP1 zro     = dirR<AF1_(1.0 / 32768.0);
    dirR        = APrxLoRsqF1(dirR);
    dirR        = zro ? AF1_(1.0) : dirR;
    dir.x       = zro ? AF1_(1.0) : dir.x;
    dir        *= AF2_(dirR);
    len         = len * AF1_(0.5);
    len        *= len;
    AF1 stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
    AF2 len2    = AF2(AF1_(1.0) + (stretch - AF1_(1.0)) * len, AF1_(1.0) + AF1_(-0.5) * len);
    AF1 lob     = AF1_(0.5) + AF1_((1.0 / 4.0 - 0.04) - 0.5) * len;
    AF1 clp     = APrxLoRcpF1(lob);
    AF3 min4    = min(AMin3F3(AF3(ijfeR.z, ijfeG.z, ijfeB.z), AF3(klhgR.w, klhgG.w, klhgB.w),
        AF3(ijfeR.y, ijfeG.y, ijfeB.y)), AF3(klhgR.x, klhgG.x, klhgB.x));
    AF3 max4    = max(AMax3F3(AF3(ijfeR.z, ijfeG.z, ijfeB.z), AF3(klhgR.w, klhgG.w, klhgB.w),
        AF3(ijfeR.y, ijfeG.y, ijfeB.y)), AF3(klhgR.x, klhgG.x, klhgB.x));
    AF3 aC      = AF3_(0.0);
    AF1 aW      = AF1_(0.0);
    FsrEasuTap(aC, aW, AF2( 0.0,-1.0) - pp, dir, len2, lob, clp, AF3(bczzR.x, bczzG.x, bczzB.x));
    FsrEasuTap(aC, aW, AF2( 1.0,-1.0) - pp, dir, len2, lob, clp, AF3(bczzR.y, bczzG.y, bczzB.y));
    FsrEasuTap(aC, aW, AF2(-1.0, 1.0) - pp, dir, len2, lob, clp, AF3(ijfeR.x, ijfeG.x, ijfeB.x));
    FsrEasuTap(aC, aW, AF2( 0.0, 1.0) - pp, dir, len2, lob, clp, AF3(ijfeR.y, ijfeG.y, ijfeB.y));
    FsrEasuTap(aC, aW, AF2( 0.0, 0.0) - pp, dir, len2, lob, clp, AF3(ijfeR.z, ijfeG.z, ijfeB.z));
    FsrEasuTap(aC, aW, AF2(-1.0, 0.0) - pp, dir, len2, lob, clp, AF3(ijfeR.w, ijfeG.w, ijfeB.w));
    FsrEasuTap(aC, aW, AF2( 1.0, 1.0) - pp, dir, len2, lob, clp, AF3(klhgR.x, klhgG.x, klhgB.x));
    FsrEasuTap(aC, aW, AF2( 2.0, 1.0) - pp, dir, len2, lob, clp, AF3(klhgR.y, klhgG.y, klhgB.y));
    FsrEasuTap(aC, aW, AF2( 2.0, 0.0) - pp, dir, len2, lob, clp, AF3(klhgR.z, klhgG.z, klhgB.z));
    FsrEasuTap(aC, aW, AF2( 1.0, 0.0) - pp, dir, len2, lob, clp, AF3(klhgR.w, klhgG.w, klhgB.w));
    FsrEasuTap(aC, aW, AF2( 1.0, 2.0) - pp, dir, len2, lob, clp, AF3(zzonR.z, zzonG.z, zzonB.z));
    FsrEasuTap(aC, aW, AF2( 0.0, 2.0) - pp, dir, len2, lob, clp, AF3(zzonR.w, zzonG.w, zzonB.w));
    pix         = min(max4, max(min4, aC * AF3_(ARcpF1(aW))));
}

void mainCS(uint3 LocalThreadId : SV_GroupThreadID, uint3 WorkGroupId : SV_GroupID)
{
    AU2 gxy = ARmp8x8(LocalThreadId.x) + AU2(WorkGroupId.x << 3u, WorkGroupId.y << 3u);
    AF3 c;
    FsrEasu(c, gxy);
    tex2Dstore(storageFSR2x, gxy, float4(c, 1.0));
}

void dlFilter(out AF3 pix, AU2 ip)
{
    ip *= 2;
    float3 a = tex2Dfetch(samplerFSR2x, ip).rgb;
    ip.x++;
    float3 b = tex2Dfetch(samplerFSR2x, ip).rgb;
    ip.y++;
    float3 c = tex2Dfetch(samplerFSR2x, ip).rgb;
    ip.x--;
    float3 d = tex2Dfetch(samplerFSR2x, ip).rgb;
    pix      = (a+b+c+d)*0.25;
    pix      = (pix > 0.04045) ? pow((pix + 0.055) * (1.0 / 1.055), 2.4) : (pix * (1.0 / 12.92));
}

void main2CS(uint3 LocalThreadId : SV_GroupThreadID, uint3 WorkGroupId : SV_GroupID)
{
    AU2 gxy = ARmp8x8(LocalThreadId.x) + AU2(WorkGroupId.x << 4u, WorkGroupId.y << 4u);

    AF3 c;
    dlFilter(c, gxy);
    tex2Dstore(storageFSR1L, gxy, float4(c, 1.0));
    gxy.x  += 8u;

    dlFilter(c, gxy);
    tex2Dstore(storageFSR1L, gxy, float4(c, 1.0));
    gxy.y  += 8u;

    dlFilter(c, gxy);
    tex2Dstore(storageFSR1L, gxy, float4(c, 1.0));
    gxy.x  -= 8u;

    dlFilter(c, gxy);
    tex2Dstore(storageFSR1L, gxy, float4(c, 1.0));
}

void FsrRcas(out AF1 pixR, out AF1 pixG, out AF1 pixB, AU2 ip)
{
    ASU2 sp     = ASU2(ip);
    AF3 b       = tex2Dfetch(samplerFSR1L, sp + ASU2( 0,-1)).rgb;
    AF3 d       = tex2Dfetch(samplerFSR1L, sp + ASU2(-1, 0)).rgb;
    AF3 e       = tex2Dfetch(samplerFSR1L, sp).rgb;
    AF3 f       = tex2Dfetch(samplerFSR1L, sp + ASU2( 1, 0)).rgb;
    AF3 h       = tex2Dfetch(samplerFSR1L, sp + ASU2( 0, 1)).rgb;
    AF1 bR      = b.r;
    AF1 bG      = b.g;
    AF1 bB      = b.b;
    AF1 dR      = d.r;
    AF1 dG      = d.g;
    AF1 dB      = d.b;
    AF1 eR      = e.r;
    AF1 eG      = e.g;
    AF1 eB      = e.b;
    AF1 fR      = f.r;
    AF1 fG      = f.g;
    AF1 fB      = f.b;
    AF1 hR      = h.r;
    AF1 hG      = h.g;
    AF1 hB      = h.b;
    AF1 bL      = bB * AF1_(0.5) + (bR * AF1_(0.5) + bG);
    AF1 dL      = dB * AF1_(0.5) + (dR * AF1_(0.5) + dG);
    AF1 eL      = eB * AF1_(0.5) + (eR * AF1_(0.5) + eG);
    AF1 fL      = fB * AF1_(0.5) + (fR * AF1_(0.5) + fG);
    AF1 hL      = hB * AF1_(0.5) + (hR * AF1_(0.5) + hG);
    // AF1 nz = AF1_(0.25) * bL + AF1_(0.25) * dL + AF1_(0.25) * fL + AF1_(0.25) * hL - eL;
    // nz = ASatF1(abs(nz) * APrxMedRcpF1(
    //     AMax3F1(AMax3F1(bL, dL, eL), fL, hL) - AMin3F1(AMin3F1(bL, dL, eL), fL, hL)));
    // nz = AF1_(-0.5) * nz + AF1_(1.0);
    AF1 mn4R    = min(AMin3F1(bR, dR, fR), hR);
    AF1 mn4G    = min(AMin3F1(bG, dG, fG), hG);
    AF1 mn4B    = min(AMin3F1(bB, dB, fB), hB);
    AF1 mx4R    = max(AMax3F1(bR, dR, fR), hR);
    AF1 mx4G    = max(AMax3F1(bG, dG, fG), hG);
    AF1 mx4B    = max(AMax3F1(bB, dB, fB), hB);
    AF2 peakC   = AF2(1.0, -1.0 * 4.0);
    AF1 hitMinR = mn4R * ARcpF1(AF1_(4.0) * mx4R);
    AF1 hitMinG = mn4G * ARcpF1(AF1_(4.0) * mx4G);
    AF1 hitMinB = mn4B * ARcpF1(AF1_(4.0) * mx4B);
    AF1 hitMaxR = (peakC.x - mx4R) * ARcpF1(AF1_(4.0) * mn4R + peakC.y);
    AF1 hitMaxG = (peakC.x - mx4G) * ARcpF1(AF1_(4.0) * mn4G + peakC.y);
    AF1 hitMaxB = (peakC.x - mx4B) * ARcpF1(AF1_(4.0) * mn4B + peakC.y);
    AF1 lobeR   = max(-hitMinR, hitMaxR);
    AF1 lobeG   = max(-hitMinG, hitMaxG);
    AF1 lobeB   = max(-hitMinB, hitMaxB);
    AF1 lobe    = max(AF1_(-FSR_RCAS_LIMIT),
        min(AMax3F1(lobeR, lobeG, lobeB), AF1_(0.0))) * AExp2F1(-(2.0 - sharpness));
    //lobe = noise_removal ? (lobe * nz) : lobe;
    AF1 rcpL    = APrxMedRcpF1(AF1_(4.0) * lobe + AF1_(1.0));
    pixR        = (lobe * bR + lobe * dR + lobe * hR + lobe * fR + eR) * rcpL;
    pixG        = (lobe * bG + lobe * dG + lobe * hG + lobe * fG + eG) * rcpL;
    pixB        = (lobe * bB + lobe * dB + lobe * hB + lobe * fB + eB) * rcpL;
} 

void main3CS(uint3 LocalThreadId : SV_GroupThreadID, uint3 WorkGroupId : SV_GroupID)
{
    AU2 gxy = ARmp8x8(LocalThreadId.x) + AU2(WorkGroupId.x << 3u, WorkGroupId.y << 3u);
    AF3 c;
    FsrRcas(c.r, c.g, c.b, gxy);
    c       = (c > 0.0031308) ? (1.055 * pow(c, 1.0 / 2.4) - 0.055) : (12.92 * c);
    tex2Dstore(storageFSRC, gxy, float4(c, 1.0));
}

float4 copyPS(float4 vpos : SV_Position) : SV_Target
{
    return tex2Dfetch(samplerFSRC, vpos.xy);
}

technique FSR1_2X < ui_label = "FSR 1.0 2X"; ui_tooltip = "Fake supersampling using AMD's FSR 1.0 algorithm."; >
{
    pass
    {
        ComputeShader = mainCS< 64, 1 >;
        DispatchSizeX = (2 * BUFFER_WIDTH  + 7) / 8;
        DispatchSizeY = (2 * BUFFER_HEIGHT + 7) / 8;
    }

    pass
    {
        ComputeShader = main2CS< 64, 1 >;
        DispatchSizeX = (BUFFER_WIDTH  + 15) / 16;
        DispatchSizeY = (BUFFER_HEIGHT + 15) / 16;
    }

    pass
    {
        ComputeShader = main3CS< 64, 1 >;
        DispatchSizeX = (BUFFER_WIDTH  + 7) / 8;
        DispatchSizeY = (BUFFER_HEIGHT + 7) / 8;
    }

    pass
    {
        VertexShader  = PostProcessVS;
        PixelShader   = copyPS;
    }
}