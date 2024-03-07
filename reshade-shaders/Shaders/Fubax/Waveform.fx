/*------------------.
| :: Description :: |
'-------------------/

Scopes FX - Waveform PS/VS (version 1.4.4)

Copyright:
This code © 2021-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons Attribution-NonCommercial-
NoDerivs 3.0 Unported License. To view a copy of this license, visit
http://creativecommons.org/licenses/by-nc-nd/3.0/

Additional permissions under Creative Commons Plus (CC+):

§ 1. The copyright owner further grants permission for commercial reuse of image
recordings based on the work (e.g., Let's Play videos, gameplay streams, and
screenshots featuring ReShade filters). Any such use must include credit to the
creator and the name of the used shader.
 Intent §: To facilitate non-corporate, common use of the shader at no cost.
Outcome §: That recognition of the work in any derivative images is ensured.

§ 2. Additionally, permission is granted for the translation of the front-end UI
text within this shader.
 Intent §: To increase accessibility and understanding across different
languages.
Outcome §: That usability across users from diverse linguistic backgrounds is
promoted, allowing them to fully engage with the shader.

Contact:
If you want additional licensing for your commercial product, please contact me:
jakub.m.fober@protonmail.com

About:
This effect will analyze all the pixels on the screen
and display them as a waveform pattern.
*/

/*-------------.
| :: Macros :: |
'-------------*/

#ifndef SCOPES_FAST_CHECKERBOARD
	#define SCOPES_FAST_CHECKERBOARD 1
#endif
// Determine waveform orientation
#ifndef SCOPES_VERTICAL_WAVEFORM
	#define SCOPES_VERTICAL_WAVEFORM 0
#endif
// Determine native scope size
#ifndef SCOPES_WAVEFORM_SIZE
	#define SCOPES_WAVEFORM_SIZE 256
#endif

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ColorConversion.fxh"
#include "LinearGammaWorkflow.fxh"
#include "BlueNoiseDither.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

uniform float2 ScopePosition
<	__UNIFORM_DRAG_FLOAT2
	ui_category = "Location and size";
	ui_label = "position on screen";
	ui_tooltip = "Move waveform on the screen.";
	ui_min = 0f; ui_max = 1f;
> = float2(0.1, 0.1);

uniform float2 ScopeScale
<	__UNIFORM_DRAG_FLOAT2
	ui_category = "Location and size";
	ui_label = "size scale";
	ui_tooltip = "Scale waveform on the screen.";
	ui_spacing = 1u;
	ui_min = 0f; ui_max = 1f;
> = float2(0.5, 0f);

uniform uint ScopeBrightness
<	__UNIFORM_SLIDER_INT1
	ui_category = "Waveform settings";
	ui_units = "x";
	ui_label = "brightness of waveform";
	ui_tooltip = "Adjust waveform sensitivity.";
	ui_min = 1u; ui_max = 1024u;
> = 32u;

uniform float ScopeUITransparency
<	__UNIFORM_SLIDER_FLOAT1
	ui_category_closed = true;
	ui_category = "UI settings";
	ui_label = "visibility of UI";
	ui_tooltip = "Set marker-lines transparency-level.";
	ui_min = 0f; ui_max = 1f; ui_step = 0.01;
> = 0.10;

uniform float ScopeBackgroundTransparency
<	__UNIFORM_SLIDER_FLOAT1
	ui_category = "UI settings";
	ui_label = "opacity of background";
	ui_tooltip = "Set waveform transparency-level.";
	ui_min = 0.5; ui_max = 1f; ui_step = 0.01;
> = 0.92;

uniform uint ScopeRoundness
<	__UNIFORM_SLIDER_INT1
	ui_category = "UI settings";
	ui_units = "G";
	ui_label = "roundness of border";
	ui_tooltip =
		"Set G-continuity corner roundness\n"
		"\nG0 ... Sharp corners"
		"\nG1 ... Round corners"
		"\nG2 ... Smooth corners"
		"\nG3 ... Luxury corners";
	ui_min = 0u; ui_max = 3u;
> = 2u;

uniform uint ScopeBorder
<	__UNIFORM_SLIDER_INT1
	ui_category = "UI settings";
	ui_units = " pixels";
	ui_label = "size of border";
	ui_tooltip = "Set rounded border size in pixels.";
	ui_min = 0u; ui_max = 64u;
> = 10u;

uniform float3 ScopeColor
<	__UNIFORM_COLOR_FLOAT3
	ui_category = "UI settings";
	ui_label = "color of waveform";
	ui_spacing = 1u;
	ui_tooltip = "Set custom waveform display color.";
> = float3(1f, 1f, 1f);

uniform float3 ScopeUIColor
<	__UNIFORM_COLOR_FLOAT3
	ui_category = "UI settings";
	ui_label = "color of UI";
	ui_tooltip = "Set custom UI color.";
> = float3(1f, 0.96, 0.5);

#if SCOPES_FAST_CHECKERBOARD
// System variable
uniform uint FRAME_INDEX < source = "framecount"; >;
#endif

/*----------------.
| :: Constants :: |
'----------------*/

// Golden ratio phi (0.618)
#define GOLDEN_RATIO (sqrt(1.25)-0.5) // simplified by JMF in 2022
// Get scope UI spacing
#define SCOPES_UI_SPACING 8u
// Get scope pixel brightness
#if SCOPES_VERTICAL_WAVEFORM
	#define SCOPES_WAVEFORM_BRIGHTNESS BUFFER_RCP_WIDTH
#else
	#define SCOPES_WAVEFORM_BRIGHTNESS BUFFER_RCP_HEIGHT
#endif

/*---------------.
| :: Textures :: |
'---------------*/

// Waveform texture target; gathers chroma quantity statistics
texture waveformTex
{
	// Span resolution
#if SCOPES_VERTICAL_WAVEFORM
	Width  = SCOPES_WAVEFORM_SIZE;
	Height = BUFFER_HEIGHT;
#else
	Width  = BUFFER_WIDTH;
	Height = SCOPES_WAVEFORM_SIZE;
#endif
#if SCOPES_FAST_CHECKERBOARD
	Format = RGBA32F; // store 4-frames in 4-channels
#else
	Format = R32F;
#endif
};

// Waveform texture sampler with black borders
sampler waveformSampler
{
	Texture = waveformTex;
	AddressU = BORDER;
	AddressV = BORDER;
};

/*----------------.
| :: Functions :: |
'----------------*/

/**
G continuity distance function by Jakub Max Fober.
Determined empirically. (G from 0, to 3)
	G=0 -> Sharp corners
	G=1 -> Round corners
	G=2 -> Smooth corners
	G=3 -> Luxury corners
*/
float glength(uint G, float2 pos)
{
	if (G==0u) return max(abs(pos.x), abs(pos.y)); // G0
	pos = pow(abs(pos), ++G); // power of G+1
	return pow(pos.x+pos.y, rcp(G)); // power G+1 root
}

// Draw UI lines
float getUI(float2 texCoord, float2 pos, float2 pixelSize)
{
	// Create UI lines
	float lines = clamp(1f-abs(frac(texCoord.y*4f-0.5)-0.5)*0.25*pixelSize.y, 0f, 1f); // 25% lines
	// Masks
	lines *= clamp((0.5-abs(texCoord.x-0.5))*pixelSize.x, 0f, 1f); // mask sides
	lines *= 1u-min(1u, uint(pos.x)%SCOPES_UI_SPACING); // create dotted line

	return lines;
}

	/* SHADERS */

#if SCOPES_FAST_CHECKERBOARD
// No texture mapping
void ClearRenderTargetVS(in uint vertexId : SV_VertexID, out float4 position : SV_Position)
{
	// Initialize some values
	position.z = 0f; // not used
	position.w = 1f; // not used

	// Generate vertex position for triangle ABC
	static const float2 positionList[3u] =
	{
		float2(-1f, 1f), // A
		float2( 3f, 1f), // B
		float2(-1f,-3f)  // C
	};

	// Load position
	position.xy = positionList[vertexId];
}

// Clear render target
float4 ClearRenderTargetPS() : SV_Target
{
	// Store 4-frames as 4-channels
	// Here, mask stores maximum possible value, for each channel
	static const float4 channelMask[4u] =
		{
			float4(0f, 1f, 1f, 1f)*(ScopeBrightness*SCOPES_WAVEFORM_SIZE/4u), // frame 0
			float4(1f, 0f, 1f, 1f)*(ScopeBrightness*SCOPES_WAVEFORM_SIZE/4u), // frame 1
			float4(1f, 1f, 0f, 1f)*(ScopeBrightness*SCOPES_WAVEFORM_SIZE/4u), // frame 2
			float4(1f, 1f, 1f, 0f)*(ScopeBrightness*SCOPES_WAVEFORM_SIZE/4u)  // frame 3
		};

	return channelMask[FRAME_INDEX%4u]; // this mask uses MIN filter
}
#endif

// Gather luma statistics and store in a vertex position
void GatherStatsVS(uint pixelID : SV_VertexID, out float4 position : SV_Position)
{
	// Initialize some values
	position.z = 0f;  // not used
	position.w = 0.5; // fill texture

	uint2 texelCoord; // get pixel coordinates from vertex ID
#if SCOPES_FAST_CHECKERBOARD
	#if SCOPES_VERTICAL_WAVEFORM
	// Get 1/4-resolution pixel coordinates
	texelCoord.y = pixelID%BUFFER_HEIGHT;
	texelCoord.x = pixelID/BUFFER_HEIGHT*4u;

	// Offset sampled pixel in 4-frame cycle
	texelCoord.x += FRAME_INDEX%4u;
	#else
	// Get 1/4-resolution pixel coordinates
	texelCoord.x = pixelID%BUFFER_WIDTH;
	texelCoord.y = pixelID/BUFFER_WIDTH*4u;

	// Offset sampled pixel in 4-frame cycle
	texelCoord.y += FRAME_INDEX%4u;
	#endif
#else
	texelCoord.x = pixelID%BUFFER_WIDTH;
	texelCoord.y = pixelID/BUFFER_WIDTH;
#endif

	// Get current-pixel color data in RGB, convert to luma Y and store as Y position
	float3 color = tex2Dfetch(ReShade::BackBuffer, texelCoord).rgb;
#if SCOPES_VERTICAL_WAVEFORM
	// Linear gamma workflow
	position.x = ColorConvert::RGB_to_Luma(GammaConvert::to_linear(color));
	position.y = 0.5-(texelCoord.y+0.5)*BUFFER_RCP_HEIGHT;
#else
	position.x = (texelCoord.x+0.5)*BUFFER_RCP_WIDTH;
	// Linear gamma workflow
	position.y = ColorConvert::RGB_to_Luma(GammaConvert::to_linear(color));
#endif
	position.xy = position.xy*(1f-BUFFER_PIXEL_SIZE)-0.5;
}

// Add pixel data to waveform image
#if SCOPES_FAST_CHECKERBOARD
void GatherStatsPS(out float4 values : SV_Target)
{
	// Store 4-frames as 4-channels
	static const float4 channelMask[4] =
	{
		float4(1f, 0f, 0f, 0f), // frame 0
		float4(0f, 1f, 0f, 0f), // frame 1
		float4(0f, 0f, 1f, 0f), // frame 2
		float4(0f, 0f, 0f, 1f)  // frame 3
	};

	// Isolate each channel for each frame
	values = channelMask[FRAME_INDEX%4u]*(SCOPES_WAVEFORM_BRIGHTNESS*ScopeBrightness);
}
#else
void GatherStatsPS(out float value : SV_Target)
{ value = SCOPES_WAVEFORM_BRIGHTNESS*ScopeBrightness; }
#endif

// Main display waveform vertex shader
void WaveformRectangleVS(
	uint vertexID : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texCoord : TEXCOORD0
){
	// Initialize values
	position.z =  0f; // not used
	position.w = 0.5; // scale to bounds

	// Initialize vertex position list for a rectangle
	static const float2 positionList[4] =
	{
		float2(-0.5, 0.5),
		float2( 0.5, 0.5),
		float2(-0.5,-0.5),
		float2( 0.5,-0.5)
	};
	// Set constant vertex position
	position.xy = positionList[vertexID];

	// Generate texture coordinate list for a rectangle with border offset
	static const float2 texCoordList[4] =
	{
		float2(0f, 0f),
		float2(1f, 0f),
		float2(0f, 1f),
		float2(1f, 1f)
	};
	// Set constant texture coordinates
	texCoord = texCoordList[vertexID];

	// Get scale with border
	float2 wavefromScaleBorder  = lerp(
			ScopeBorder*2u+SCOPES_WAVEFORM_SIZE,
			ScopeBorder*2u+BUFFER_SCREEN_SIZE,
			ScopeScale
		)*BUFFER_PIXEL_SIZE;
	// Get scale and offset without border
	float2 wavefromScale  = lerp(SCOPES_WAVEFORM_SIZE*BUFFER_PIXEL_SIZE, 1f, ScopeScale);
	float2 wavefromOffset = lerp(wavefromScale*0.5, 1f-wavefromScale*0.5, ScopePosition)-0.5;

	// Offset and scale
	position.xy = position.xy*wavefromScaleBorder+wavefromOffset;

	// Scale texture coordinates
	{
		float2 borderWidth = wavefromScaleBorder/wavefromScale;
		texCoord = texCoord*borderWidth-(borderWidth*0.5-0.5);
	}
}

// Main display waveform pixel shader
void DisplayWaveformPS(
	float4 pos : SV_Position,
	float2 texCoord : TEXCOORD0,
	out float3 color : SV_Target
){
#if SCOPES_FAST_CHECKERBOARD
	float waveform = dot(tex2D(waveformSampler, texCoord), 1f);
#else
	float waveform = tex2D(waveformSampler, texCoord).r;
#endif

	// Get waveform size in pixels
	float2 pixelSize = lerp(SCOPES_WAVEFORM_SIZE, BUFFER_SCREEN_SIZE, ScopeScale);

	// Blend waveform
	if (ScopeBackgroundTransparency!=1f || ScopeBorder!=0u)
	{
		// Sample background in linear-gamma
		color = GammaConvert::to_linear(tex2Dfetch(ReShade::BackBuffer, uint2(pos.xy)).rgb);
		// Get rounded border mask
		if (ScopeBorder!=0u)
		{
			float2 borderSDF = abs(texCoord*2f-1f)-1f; // get SDF for the border
			borderSDF *= pixelSize*rcp(ScopeBorder*2u); // normalize to the edge
			float borderMask = 1f-glength(min(ScopeRoundness, 4u), max(borderSDF, 0f)); // create rounded-corner mask
			borderMask = clamp(borderMask*ScopeBorder, 0f, 1f); // normalize to pixel size and clamp
			// Blend with background and display color
			color = lerp(color*(1f-borderMask*ScopeBackgroundTransparency), ScopeColor, waveform);
		}
		else // blend with background without border
			color = lerp(color*(1f-ScopeBackgroundTransparency), ScopeColor, waveform);
	}
	else color = waveform*ScopeColor;

	// Clamp to visible range
	color = clamp(color, 0f, 1f);

	if (ScopeUITransparency!=0f) // if UI visible
	{
#if SCOPES_VERTICAL_WAVEFORM
		float lines = getUI(texCoord.yx, pos.yx, pixelSize.yx);
#else
		float lines = getUI(texCoord.xy, pos.xy, pixelSize.xy);
#endif
		// Draw UI
		color = lerp(color, ScopeUIColor, lines*ScopeUITransparency);
	}

	// Linear workflow
	color = GammaConvert::to_display(color); // manual gamma correction
	// Dither final output
	color = BlueNoise::dither(color, uint2(pos.xy));
}

/*-------------.
| :: Output :: |
'-------------*/

technique Waveform
<
	ui_label = "scopes FX: waveform analysis";
	ui_tooltip =
		"Analyze colors using waveform.\n"
		"\n"
		"This effect © 2021-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-NC-ND 3.0 +\n"
		"for additional permissions see the source code.";
>
{
#if SCOPES_FAST_CHECKERBOARD
	pass ClearRenderTarget
	{
		RenderTarget = waveformTex;

		BlendEnable = true;

		BlendOp = MIN;
		BlendOpAlpha = MIN;
		// Background
		DestBlend = ONE;
		DestBlendAlpha = ONE;
		// Foreground
		SrcBlend = ONE;
		SrcBlendAlpha = ONE;

		VertexShader = PostProcessVS;
		PixelShader = ClearRenderTargetPS;
	}
#endif
	pass AnalizeColor
	{
#if SCOPES_FAST_CHECKERBOARD
	#if SCOPES_VERTICAL_WAVEFORM
		VertexCount = (BUFFER_WIDTH/4u)*BUFFER_HEIGHT;
	#else
		VertexCount = BUFFER_WIDTH*(BUFFER_HEIGHT/4u);
	#endif

		BlendOpAlpha = ADD;
		DestBlendAlpha = ONE; // background
		SrcBlendAlpha = ONE;  // foreground
#else
		ClearRenderTargets = true;
		VertexCount = BUFFER_WIDTH*BUFFER_HEIGHT;
#endif
		PrimitiveTopology = POINTLIST;

		RenderTarget = waveformTex;

		BlendEnable = true;

		BlendOp = ADD;
		DestBlend = ONE; // background
		SrcBlend = ONE;  // foreground


		VertexShader = GatherStatsVS;
		PixelShader = GatherStatsPS;
	}
	pass ScopeRectangle
	{
		PrimitiveTopology = TRIANGLESTRIP;
		VertexCount = 4;

		// BlendEnable = true;
		// SrcBlend = SRCALPHA;     // foreground
		// DestBlend = INVSRCALPHA; // background

		VertexShader = WaveformRectangleVS;
		PixelShader = DisplayWaveformPS;
	}
}
