//===================================================================================================================
#include "ReShade.fxh"
#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif
#undef PixelSize
#define PixelSize  	float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
//===================================================================================================================
#define BLOOM_LINEAR_COEF	((BLOOM_LINEAR_TAPS * 2) - 1)
#define BLOOM_PASSES		2			//[1, 2, 3, 4] Number of passes. More means larger bloom, but slower
#define BLOOM_TEXTURESIZE 	0.25			//Changes the size of the bloom texture. 1.0 is screen resolution.
#define BLOOM_LINEAR_TAPS	12			//Number of taps per pass. The total number of taps is this times 4.
//===================================================================================================================
uniform float BLOOM_THRESHOLD <
	ui_label = "Bloom - Threshold";
	ui_tooltip = "Bloom will only affect pixels above this value.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	> = 0.5;
uniform float BLOOM_STRENGTH <
	ui_label = "Bloom - Strength";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	> = 0.5;
uniform float BLOOM_RADIUS <
	ui_label = "Bloom - Radius";
	ui_tooltip = "Pixel Radius per tap.";
	ui_type = "slider";
	ui_min = 1.0; ui_max = 10.0;
	> = 5.0;
uniform float BLOOM_SATURATION <
	ui_label = "Bloom - Saturation";
	ui_tooltip = "Controls the saturation of the bloom. 1.0 = no change.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	> = 1.0;
uniform int BLOOM_BLEND <
	ui_label = "Bloom - Blending mode";
	ui_type = "combo";
	ui_items = "Add\0Add - No Clip\0Screen\0Soft Light\0Color Dodge\0";
	> = 1;
uniform bool BLOOM_DEBUG <
	ui_label = "Bloom - Debug";
	ui_tooltip = "Shows only the bloom effect.";
	> = false;
//===================================================================================================================
texture		TexBloomH { Width = BUFFER_WIDTH*BLOOM_TEXTURESIZE; Height = BUFFER_HEIGHT*BLOOM_TEXTURESIZE; Format = RGBA8;};
texture		TexBloomV { Width = BUFFER_WIDTH*BLOOM_TEXTURESIZE; Height = BUFFER_HEIGHT*BLOOM_TEXTURESIZE; Format = RGBA8;};
sampler2D	SamplerBloomH { Texture = TexBloomH; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};
sampler2D	SamplerBloomV { Texture = TexBloomV; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};
//===================================================================================================================
float3 BlendScreen(float3 a, float3 b) {
	return 1 - ((1 - a) * (1 - b));
}
float3 BlendSoftLight(float3 a, float3 b) {
	return (1 - 2 * b) * (a * a) + 2 * b * a;
}
float3 BlendColorDodge(float3 a, float3 b) {
	return a / (1 - b);
}
float4 GaussBlurFirstPass(float2 coords : TEXCOORD) : COLOR {
	float4 ret = max(tex2D(ReShade::BackBuffer, coords) - BLOOM_THRESHOLD, 0.0);

	for(int i=1; i < BLOOM_LINEAR_TAPS; i++)
	{
		ret += max(tex2D(ReShade::BackBuffer, coords + float2(i * PixelSize.x * BLOOM_RADIUS, 0.0)) - BLOOM_THRESHOLD, 0.0);
		ret += max(tex2D(ReShade::BackBuffer, coords - float2(i * PixelSize.x * BLOOM_RADIUS, 0.0)) - BLOOM_THRESHOLD, 0.0);
	}
	
	return ret / (1.0 - BLOOM_THRESHOLD) / BLOOM_LINEAR_COEF;
}

float4 GaussBlurH(float2 coords : TEXCOORD) : COLOR {
	float4 ret = tex2D(SamplerBloomV, coords);

	for(int i=1; i < BLOOM_LINEAR_TAPS; i++)
	{
		ret += tex2D(SamplerBloomV, coords + float2(i * PixelSize.x * BLOOM_RADIUS, 0.0));
		ret += tex2D(SamplerBloomV, coords - float2(i * PixelSize.x * BLOOM_RADIUS, 0.0));
	}
	
	return ret / BLOOM_LINEAR_COEF;
}

float4 GaussBlurV(float2 coords : TEXCOORD) : COLOR {
	float4 ret = tex2D(SamplerBloomH, coords);
	
	for(int i=1; i < BLOOM_LINEAR_TAPS; i++)
	{
		ret += tex2D(SamplerBloomH, coords + float2(0.0, i * PixelSize.y * BLOOM_RADIUS));
		ret += tex2D(SamplerBloomH, coords - float2(0.0, i * PixelSize.y * BLOOM_RADIUS));
	}
	
	return ret / BLOOM_LINEAR_COEF;
}
//===================================================================================================================
float4 PS_BloomFirstPass(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	return GaussBlurFirstPass(texcoord);
}

float4 PS_BloomH(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	return GaussBlurH(texcoord);
}

float4 PS_BloomV(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	return GaussBlurV(texcoord);
}

float4 PS_Combine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	float4 ret = tex2D(ReShade::BackBuffer, texcoord);
	float4 bloom = tex2D(SamplerBloomV, texcoord);
	bloom.rgb = lerp(dot(bloom.rgb, float3(0.2126, 0.7152, 0.0722)), bloom.rgb, BLOOM_SATURATION) * BLOOM_STRENGTH;

	if (BLOOM_DEBUG) return bloom;

	if (BLOOM_BLEND == 0) //Add
		ret.rgb += bloom.rgb;
	else if (BLOOM_BLEND == 1) //Add - No clip
		ret.rgb += bloom.rgb * saturate(1.0 - ret.rgb);
	else if (BLOOM_BLEND == 2) //Screen
		ret.rgb = BlendScreen(ret.rgb, bloom.rgb);
	else if (BLOOM_BLEND == 3) //Soft Light
		ret.rgb = BlendSoftLight(ret.rgb, bloom.rgb);
	else if (BLOOM_BLEND == 4) //Color Dodge
		ret.rgb = BlendColorDodge(ret.rgb, bloom.rgb);

#if GSHADE_DITHER
	return float4(ret.rgb + TriDither(ret.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), ret.a);
#else
	return ret;
#endif
}
	


technique Pirate_Bloom
{
	pass BloomH
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_BloomFirstPass;
		RenderTarget = TexBloomH;
	}
	pass BloomV
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_BloomV;
		RenderTarget = TexBloomV;
	}
#if (BLOOM_PASSES > 1)
	pass BloomH2
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_BloomH;
		RenderTarget = TexBloomH;
	}
	pass BloomV2
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_BloomV;
		RenderTarget = TexBloomV;
	}
#endif
#if (BLOOM_PASSES > 2)
	pass BloomH3
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_BloomH;
		RenderTarget = TexBloomH;
	}
	pass BloomV3
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_BloomV;
		RenderTarget = TexBloomV;
	}
#endif
#if (BLOOM_PASSES > 3)
	pass BloomH4
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_BloomH;
		RenderTarget = TexBloomH;
	}
	pass BloomV4
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_BloomV;
		RenderTarget = TexBloomV;
	}
#endif
	pass Combine
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_Combine;
	}
}
