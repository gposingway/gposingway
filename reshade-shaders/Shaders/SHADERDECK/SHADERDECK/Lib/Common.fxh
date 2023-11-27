///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                             ///
///     .d8888b.  888    888        d8888 8888888b.  8888888888 8888888b.                       ///
///    d88P  Y88b 888    888       d88888 888  "Y88b 888        888   Y88b                      ///
///    Y88b.      888    888      d88P888 888    888 888        888    888                      ///
///     "Y888b.   8888888888     d88P 888 888    888 8888888    888   d88P                      ///
///        "Y88b. 888    888    d88P  888 888    888 888        8888888P"                       ///
///          "888 888    888   d88P   888 888    888 888        888 T88b                        ///
///    Y88b  d88P 888    888  d8888888888 888  .d88P 888        888  T88b                       ///
///     "Y8888P"  888    888 d88P     888 8888888P"  8888888888 888   T88b                      ///
///    8888888b.  8888888888  .d8888b.  888    d8P                                              ///
///    888  "Y88b 888        d88P  Y88b 888   d8P                                               ///
///    888    888 888        888    888 888  d8P                                                ///
///    888    888 8888888    888        888d88K                                                 ///
///    888    888 888        888        8888888b                                                ///
///    888    888 888        888    888 888  Y88b                                               ///
///    888  .d88P 888        Y88b  d88P 888   Y88b                                              ///
///    8888888P"  8888888888  "Y8888P"  888    Y88b                                             ///
///                                                                                             ///
///    <> BY TREYM                                                                              ///
///                                                                                             ///
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

/*  ///////////////////////////////////////////////////////////////////////////////////////////  **
**  ///////////////////////////////////////////////////////////////////////////////////////////  **

    DO NOT REDISTRIBUTE WITHOUT PERMISION!

**  ///////////////////////////////////////////////////////////////////////////////////////////  **
**  ///////////////////////////////////////////////////////////////////////////////////////////  */


// MACROS /////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#include "SHADERDECK/Lib/Macros.fxh"


// UNIFORM VARIABLES //////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
uniform float Timer < source = "timer"; >;


// GLOBAL DEFINITIONS /////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#define pi 3.14159265359


// COMMON FUNCTIONS ///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
float  linearstep(float  Low, float  Up, float  x)
{
    return saturate((x - Low) / (Up - Low));
}

float2 linearstep(float2 Low, float2 Up, float2 x)
{
    return saturate((x - Low) / (Up - Low));
}

float3 linearstep(float3 Low, float3 Up, float3 x)
{
    return saturate((x - Low) / (Up - Low));
}

float3 ConeOverlap(float3 c)
{
    float k = 0.4 * 0.5;
    float2 f = float2(1 - 2 * k, k);
    float3x3 m = float3x3(f.xyy, f.yxy, f.yyx);
    return mul(c, m);
}

float3 ConeOverlapInv(float3 c)
{
    float k = 0.4 * 0.5;
    float2 f = float2(k - 1, k) * rcp(3 * k - 1);
    float3x3 m = float3x3(f.xyy, f.yxy, f.yyx);
    return mul(c, m);
}

float LinearToSRGB( float x )
{
    // Approximately pow(x, 1.0 / 2.2)
    return x < 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0 / 2.4) - 0.055;
}

float3 LinearToSRGB( float3 x )
{
    // Approximately pow(x, 1.0 / 2.2)
    return x < 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0 / 2.4) - 0.055;
}

float4 LinearToSRGB( float4 x )
{
    // Approximately pow(x, 1.0 / 2.2)
    return x < 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0 / 2.4) - 0.055;
}

float SRGBToLinear( float x )
{
    // Approximately pow(x, 2.2)
    return x < 0.04045 ? x / 12.92 : pow( (x + 0.055) / 1.055, 2.4 );
}

float3 SRGBToLinear( float3 x )
{
    // Approximately pow(x, 2.2)
    return x < 0.04045 ? x / 12.92 : pow( (x + 0.055) / 1.055, 2.4 );
}

float4 SRGBToLinear( float4 x )
{
    // Approximately pow(x, 2.2)
    return x < 0.04045 ? x / 12.92 : pow( (x + 0.055) / 1.055, 2.4 );
}

float3 ToHDR(float3 color, float multi)
{
    color = ConeOverlap(color);
    return exp2(multi * color);
}

float3 ToSDR(float3 color, float multi)
{
    color = log2(color) / multi;
    return saturate(ConeOverlapInv(color));
}

float3 LogC3(float3 LinearColor)
{
    float3 LogColor;
    
    // Log curve
    LogColor =  LinearColor > 0.010591
             ? (0.247190 * log10(5.555556 * LinearColor + 0.052272) + 0.385537)
             : (5.367655 * LinearColor + 0.092809);

    LogColor = ConeOverlapInv(LogColor);

    return saturate(LogColor);
}

float3 LogC4(float3 HDRLinear)
{
    float3 LogColor;

    LogColor = (HDRLinear <=  -0.0180570)
             ? (HDRLinear  - (-0.0180570)) / 0.113597
             : (log2(2231.826309067688 * HDRLinear + 64.0) - 6.0) / 14.0 * 0.9071358748778104 + 0.0928641251221896;

    LogColor = ConeOverlapInv(LogColor);

    return saturate(LogColor);
}


float3 RGBToHSL(float3 color)
{
	float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)

	float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
	float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
	float delta = fmax - fmin;             //Delta RGB value

	hsl.z = (fmax + fmin) / 2.0; // Luminance

	if (delta == 0.0)		//This is a gray, no chroma...
	{
		hsl.x = 0.0;	// Hue
		hsl.y = 0.0;	// Saturation
	}

	else                                    //Chromatic data...
	{
		if (hsl.z < 0.5)
			hsl.y = delta / (fmax + fmin); // Saturation
		else
			hsl.y = delta / (2.0 - fmax - fmin); // Saturation

		float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
		float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
		float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

		if (color.r == fmax )
			hsl.x = deltaB - deltaG; // Hue
		else if (color.g == fmax)
			hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
		else if (color.b == fmax)
			hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

		if (hsl.x < 0.0)
			hsl.x += 1.0; // Hue
		else if (hsl.x > 1.0)
			hsl.x -= 1.0; // Hue
	}

	return hsl;
}

float HueToRGB(float f1, float f2, float hue)
{
	if (hue < 0.0)
		hue += 1.0;
	else if (hue > 1.0)
		hue -= 1.0;

	float res;
	if ((6.0 * hue) < 1.0)
		res = f1 + (f2 - f1) * 6.0 * hue;
	else if ((2.0 * hue) < 1.0)
		res = f2;
	else if ((3.0 * hue) < 2.0)
		res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
	else
		res = f1;

	return res;
}

float3 HSLToRGB(float3 hsl)
{
	float3 rgb;

	if (hsl.y == 0.0)
		rgb = float3(hsl.z, hsl.z, hsl.z); // Luminance

	else
	{
		float f2;

		if (hsl.z < 0.5)
			f2 = hsl.z * (1.0 + hsl.y);
		else
			f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);

		float f1 = 2.0 * hsl.z - f2;

		rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
		rgb.g = HueToRGB(f1, f2, hsl.x);
		rgb.b= HueToRGB(f1, f2, hsl.x - (1.0/3.0));
	}

	return rgb;
}

float3 HUEtoRGB(float H)
{
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);

    return saturate(float3(R,G,B));
}


float RGBCVtoHUE(float3 RGB, float C, float V)
{
    float3 Delta = (V - RGB) / C;
    Delta.rgb -= Delta.brg;
    Delta.rgb += float3(2,4,6);

    // NOTE 1
    Delta.brg = step(V, RGB) * Delta.brg;
    float H;

    H = max(Delta.r, max(Delta.g, Delta.b));

    return frac(H / 6);
}

float3 RGBToHSV(float3 RGB)
{
    float3 HSV = 0;
    HSV.z = max(RGB.r, max(RGB.g, RGB.b));

    float M = min(RGB.r, min(RGB.g, RGB.b));
    float C = HSV.z - M;

    if (C != 0)
    {
        HSV.x = RGBCVtoHUE(RGB, C, HSV.z);
        HSV.y = C / HSV.z;
    }

  return HSV;
}


float3 HSVToRGB(float3 HSV)
{
    float3 RGB = HUEtoRGB(HSV.x);

    return ((RGB - 1) * HSV.y + 1) * HSV.z;
}

float3 ColorTemperatureToRGB(float temperatureInKelvins)
{
	float3 retColor;

    temperatureInKelvins = clamp(temperatureInKelvins, 1000.0, 40000.0) / 100.0;

    if (temperatureInKelvins <= 66.0)
    {
        retColor.r = 1.0;
        retColor.g = clamp(0.39008157876901960784 * log(temperatureInKelvins) - 0.63184144378862745098, 0.0, 30000.0);
    }

    else
    {
    	float t = temperatureInKelvins - 60.0;
        retColor.r = clamp(1.29293618606274509804 * pow(abs(t), -0.1332047592), 0.0, 30000.0);
        retColor.g = clamp(1.12989086089529411765 * pow(abs(t), -0.0755148492), 0.0, 30000.0);
    }

    if (temperatureInKelvins >= 66.0)
	{
		retColor.b = 1.0;
	}
        
    else if (temperatureInKelvins <= 19.0)
	{
		retColor.b = 0.0;
	}
        
    else
	{
		retColor.b = clamp(0.54320678911019607843 * log(temperatureInKelvins - 10.0) - 1.19625408914, 0.0, 30000.0);
	}
        
    return retColor;
}

float3 Kelvin(float3 color, float kelvin)
{
    float3 ktemp, result, hsl, lumablend;
    float luma;

    ktemp     = ColorTemperatureToRGB(kelvin);

	luma      = GetLuma(color);

	result    = color * ktemp;

	hsl       = RGBToHSL(result);
	lumablend = HSLToRGB(float3(hsl.x, hsl.y, luma));

	return lerp(result, lumablend, 0.75);
}

float3 WhiteBalance(float3 color, float scene, float cam)
{
    float kelvin, luma;

    // Normalize kelvin input (6500 = no change to image)
    kelvin = 6500 + ((6500 - cam) + (scene - 6500));

    // Store image luma
    luma   = GetLuma(color);

    // Apply the whitebalance
    color *= ColorTemperatureToRGB(kelvin); // Apply color temp
    color /= GetLuma(color); // Luma preservation
	color *= luma; // Luma preservation

    return color;
}

// Based on code by Dan Bruton
// http://www.physics.sfasu.edu/astro/color/spectra.html
float3 NMToRGB(int nm)
{
    float  atten;
    float3 color;

    if      ((nm >= 380) && (nm <= 440))
    {
        atten   = 0.3 + 0.7 * (nm - 380) / (440 - 380);
        color.r = pow((-(nm - 440) / (440 - 380)) * atten, 0.8);
        color.g = 0.0;
        color.b = pow(1.0 * atten, 0.8);
    }

    else if ((nm >= 440) && (nm <= 490))
    {
        color.r = 0.0;
        color.g = pow((nm - 440) / (490 - 440), 0.8);
        color.b = 1.0;
    }

    else if ((nm >= 490) && (nm <= 510))
    {
        color.r = 0.0;
        color.g = 1.0;
        color.b = pow(-(nm - 510) / (510 - 490), 0.8);
    }

    else if ((nm >= 510) && (nm <= 580))
    {
        color.r = pow((nm - 510) / (580 - 510), 0.8);
        color.g = 1.0;
        color.b = 0.0;
    }

    else if ((nm >= 580) && (nm <= 645))
    {
        color.r = 1.0;
        color.g = pow(-(nm - 645) / (645 - 580), 0.8);
        color.b = 0.0;
    }

    else if ((nm >= 645) && (nm <= 750))
    {
        atten   = 0.3 + 0.7 * (750 - nm) / (750 - 645);
        color.r = pow(1.0 * atten, 0.8);
        color.g = 0.0;
        color.b = 0.0;
    }

    else
    {
        color = 0.0;
    }

    return color;
}

float ScotopicLuma(float3 color)
{
    float3x3 RGBToXYZ = float3x3
    (
        0.5149, 0.3244, 0.1607,
        0.3654, 0.6704, 0.0642,
        0.0248, 0.1248, 0.8504
    );

    color = mul(RGBToXYZ, color);

    return color.y * (1.33 * (1.0 + ((color.y + color.z) / color.x)) - 1.68);
}

float3 PurkinjeEffect(float3 color, float blend)
{
    // Tint color should be near middle grey
    return lerp(color, ScotopicLuma(color) * lerp(0.5, (NMToRGB(475) * 0.5), 0.25), blend);
}

// Bicubic function written by kingeric1992
float4 tex2Dbicub(sampler texSampler, float2 coord)
{
    float2 texsize = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    float4 uv;
    uv.xy = coord * texsize;

    // distant to nearest center
    float2 center  = floor(uv.xy - 0.5) + 0.5;
    float2 dist1st = uv.xy - center;
    float2 dist2nd = dist1st * dist1st;
    float2 dist3rd = dist2nd * dist1st;

    // B-Spline weights
    float2 weight0 =     -dist3rd + 3 * dist2nd - 3 * dist1st + 1;
    float2 weight1 =  3 * dist3rd - 6 * dist2nd               + 4;
    float2 weight2 = -3 * dist3rd + 3 * dist2nd + 3 * dist1st + 1;
    float2 weight3 =      dist3rd;

    weight0 += weight1;
    weight2 += weight3;

    // sample point to utilize bilinear filtering interpolation
    uv.xy  = center - 1 + weight1 / weight0;
    uv.zw  = center + 1 + weight3 / weight2;
    uv    /= texsize.xyxy;

    // Sample and blend
    return (weight0.y * (tex2D(texSampler, uv.xy) * weight0.x + tex2D(texSampler, uv.zy) * weight2.x) +
            weight2.y * (tex2D(texSampler, uv.xw) * weight0.x + tex2D(texSampler, uv.zw) * weight2.x)) / 36;
}

float4 tex2Dbicub2(sampler texSampler, float2 coord, float2 inscale)
{
    float2 texsize = int2(BUFFER_WIDTH * inscale.x, BUFFER_HEIGHT * inscale.y);

    float4 uv;
    uv.xy = coord * texsize;

    // distant to nearest center
    float2 center  = floor(uv.xy - 0.5) + 0.5;
    float2 dist1st = uv.xy - center;
    float2 dist2nd = dist1st * dist1st;
    float2 dist3rd = dist2nd * dist1st;

    // B-Spline weights
    float2 weight0 =     -dist3rd + 3 * dist2nd - 3 * dist1st + 1;
    float2 weight1 =  3 * dist3rd - 6 * dist2nd               + 4;
    float2 weight2 = -3 * dist3rd + 3 * dist2nd + 3 * dist1st + 1;
    float2 weight3 =      dist3rd;

    weight0 += weight1;
    weight2 += weight3;

    // sample point to utilize bilinear filtering interpolation
    uv.xy  = center - 1 + weight1 / weight0;
    uv.zw  = center + 1 + weight3 / weight2;
    uv    /= texsize.xyxy;

    // Sample and blend
    return (weight0.y * (tex2D(texSampler, uv.xy) * weight0.x + tex2D(texSampler, uv.zy) * weight2.x) +
            weight2.y * (tex2D(texSampler, uv.xw) * weight0.x + tex2D(texSampler, uv.zw) * weight2.x)) / 36;
}


// BACKBUFFER AND RENDER TARGETS //////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
texture BACKBUFFER               : COLOR;
texture DEPTHBUFFER              : DEPTH;
sampler TextureColor             { Texture = BACKBUFFER; AddressU = BORDER; AddressV = BORDER; AddressW = BORDER; };
sampler TextureColorMirror       { Texture = BACKBUFFER; AddressU = MIRROR; AddressV = MIRROR; AddressW = MIRROR; };


// VERTEX SHADER //////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
void VS_Tri(in uint id : SV_VertexID, out float4 vpos : SV_Position, out float2 uv : TEXCOORD)
{
	uv.x = (id == 2) ? 2.0 : 0.0;
	uv.y = (id == 1) ? 2.0 : 0.0;
	vpos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}