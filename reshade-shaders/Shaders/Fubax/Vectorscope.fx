/*------------------.
| :: Description :: |
'-------------------/

Scopes FX - Vectorscope PS/VS (version 1.7.1)

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
This effect will analyze all the pixels on the screen and display them
as a vectorscope color-wheel.
*/

/*-------------.
| :: Macros :: |
'-------------*/

// Checkerboard sampling increases performance 2x, gives 4-frame 'motion blur'
#ifndef SCOPES_FAST_CHECKERBOARD
	#define SCOPES_FAST_CHECKERBOARD 1
#endif
// Determine native scope size
#ifndef SCOPES_VECTORSCOPE_SIZE
	#define SCOPES_VECTORSCOPE_SIZE 256
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
	ui_category = "Location and scale";
	ui_label = "position on screen";
	ui_tooltip = "Move vectorscope on the screen.";
	ui_min = 0f; ui_max = 1f;
> = float2(0.9, 0.1);

uniform float ScopeSize
<	__UNIFORM_SLIDER_FLOAT1
	ui_category = "Location and scale";
	ui_label = "size scale";
	ui_tooltip = "Scale vectorscope on the screen.";
	ui_min = 0f; ui_max = 1f;
> = 0f;

uniform uint ScopeBrightness
<	__UNIFORM_SLIDER_INT1
	ui_category = "Vectorscope settings";
	ui_units = "x";
	ui_label = "brightness of vectorscope";
	ui_tooltip = "Adjust vectorscope sensitivity.";
	ui_min = 1u; ui_max = 1024u;
> = 64u;

uniform float ScopeUiTransparency
<	__UNIFORM_SLIDER_FLOAT1
	ui_category = "UI settings";
	ui_category_closed = true;
	ui_label = "visibility of UI";
	ui_tooltip = "Set marker-lines transparency-level.";
	ui_min = 0f; ui_max = 1f; ui_step = 0.01;
> = 0.5;

uniform float ScopeUiThickness
<	__UNIFORM_SLIDER_FLOAT1
	ui_category = "UI settings";
	ui_units = " pixel";
	ui_label = "thickness of UI";
	ui_tooltip = "Make UI lines more thick.";
	ui_min = 1f; ui_max = 2f; ui_step = 0.1;
> = 1f;

uniform float ScopeBackgroundTransparency
<	__UNIFORM_SLIDER_FLOAT1
	ui_category = "UI settings";
	ui_label = "opacity of background";
	ui_tooltip = "Set vectorscope transparency-level.";
	ui_min = 0.5; ui_max = 1f; ui_step = 0.01;
> = 0.92;

#if SCOPES_FAST_CHECKERBOARD
// System variable
uniform uint FRAME_INDEX < source = "framecount"; >;
#endif

/*----------------.
| :: Constants :: |
'----------------*/

// Golden ratio phi (0.618)
#define GOLDEN_RATIO (sqrt(1.25)-0.5) // simplified by JMF in 2022
// Get scope scale relative to border
#define SCOPES_BORDER_SIZE GOLDEN_RATIO
// Get scope pixel brightness
#define SCOPES_VECTORSCOPE_BRIGHTNESS (SCOPES_VECTORSCOPE_SIZE*BUFFER_RCP_WIDTH*BUFFER_RCP_HEIGHT)

/*---------------.
| :: Textures :: |
'---------------*/

// Vectorscope texture target; gathers chroma quantity statistics
texture vectorscopeTex
{
	// Square resolution
	Width =  SCOPES_VECTORSCOPE_SIZE;
	Height = SCOPES_VECTORSCOPE_SIZE;
#if SCOPES_FAST_CHECKERBOARD
	Format = RGBA32F; // store 4-frames in 4-channels
#else
	Format = R32F;
#endif
};

// Vectorscope texture sampler with black borders
sampler vectorscopeSampler
{
	Texture = vectorscopeTex;
	MagFilter = POINT;
	AddressU = BORDER;
	AddressV = BORDER;
};

/*--------------.
| :: Shaders :: |
'--------------*/

#if SCOPES_FAST_CHECKERBOARD
// No texture mapping
void ClearRenderTargetVS(
	in  uint   vertexId : SV_VertexID,
	out float4 position : SV_Position
)
{
	// Initialize some values
	position.z = 0f; // not used
	position.w = 1f; // not used

	// Generate vertex position for triangle ABC
	static const float2 positionList[3u] =
	{
		float2(-1f, 1f), // a
		float2( 3f, 1f), // b
		float2(-1f,-3f)  // c
	};

	// Load position
	position.xy = positionList[vertexId];
}

// Clear render target
float4 ClearRenderTargetPS() : SV_Target
{
	// Store 4-frames as 4-channels
	// Here, mask stores maximum possible value, for each channel
	static const float4 channelMask[4] =
		{
			float4(0f, 1f, 1f, 1f)*(ScopeBrightness*SCOPES_VECTORSCOPE_SIZE/4u), // frame 0
			float4(1f, 0f, 1f, 1f)*(ScopeBrightness*SCOPES_VECTORSCOPE_SIZE/4u), // frame 1
			float4(1f, 1f, 0f, 1f)*(ScopeBrightness*SCOPES_VECTORSCOPE_SIZE/4u), // frame 2
			float4(1f, 1f, 1f, 0f)*(ScopeBrightness*SCOPES_VECTORSCOPE_SIZE/4u)  // frame 3
		};

	return channelMask[FRAME_INDEX%4u]; // this mask uses MIN filter
}
#endif

// Gather chroma statistics and store in a vertex position
void GatherStatsVS(
	    uint   pixelID  : SV_VertexID,
	out float4 position : SV_Position
)
{
	// Initialize some values
	position.z = 0f;  // not used
	position.w = 0.5; // fill texture

	uint2 texelCoord; // get pixel coordinates from vertex ID
#if SCOPES_FAST_CHECKERBOARD
	// Get 1/4-resolution pixel coordinates
	texelCoord.x = pixelID%(BUFFER_WIDTH/2u)*2u;
	texelCoord.y = pixelID/(BUFFER_WIDTH/2u)*2u;

	// Checkerboard pattern offset cycle
	static const uint2 offset_Z[4] = // z-sampling pattern
		{
			uint2(0u, 0u), // frame 0
			uint2(1u, 0u), // frame 1
			uint2(0u, 1u), // frame 2
			uint2(1u, 1u)  // frame 3
		};
	// Offset sampled pixel in 4-frame cycle
	texelCoord += offset_Z[FRAME_INDEX%4u];
#else
	texelCoord.x = pixelID%BUFFER_WIDTH;
	texelCoord.y = pixelID/BUFFER_WIDTH;
#endif

	// Get current-pixel color data in RGB, convert to chroma CbCr and store as 2D position
	position.xy = ColorConvert::RGB_to_Chroma(
		GammaConvert::to_linear( // linear gamma workflow
			tex2Dfetch(ReShade::BackBuffer, texelCoord).rgb
		));
}

// Add pixel data to vectorscope image
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
	values = channelMask[FRAME_INDEX%4u]*(SCOPES_VECTORSCOPE_BRIGHTNESS*ScopeBrightness);
}
#else
void GatherStatsPS(out float value : SV_Target)
{ value = SCOPES_VECTORSCOPE_BRIGHTNESS*ScopeBrightness; }
#endif

/** Pixel scale function for anti-aliasing by Jakub Max Fober
This algorithm is derived from scientific paper:
arXiv: 20104077 [cs.GR] (2020) */
float getPixelScale(float gradient)
{
	// Calculate gradient delta between pixels
	float2 del = float2(ddx(gradient), ddy(gradient));
	// Get reciprocal delta length for anti-aliasing
	return rsqrt(dot(del, del));
}

// Function that returns color and alpha-mask for the UI
float4 DrawUI(float2 texCoord)
{
	// Convert texture coordinates to chroma coordinates
	texCoord.x = texCoord.x-0.5;
	texCoord.y = 0.5-texCoord.y;
	// Get user interface lines as an array
	static const float2 hexagonVert[6] = {
		ColorConvert::RGB_to_Chroma(float3(1f, 0f, 0f)), // R
		ColorConvert::RGB_to_Chroma(float3(1f, 1f, 0f)), // Yl
		ColorConvert::RGB_to_Chroma(float3(0f, 1f, 0f)), // G
		ColorConvert::RGB_to_Chroma(float3(0f, 1f, 1f)), // Cy
		ColorConvert::RGB_to_Chroma(float3(0f, 0f, 1f)), // B
		ColorConvert::RGB_to_Chroma(float3(1f, 0f, 1f))  // Mg
	};
	// Get skin-tone CbCr position from skin-tone RGB color
	float2 skintonePos = ColorConvert::RGB_to_Chroma((float3(1f, 0.15+sqrt(0.0125), 0f))); // formula for skin-tone color engineered by JMF
	skintonePos = lerp(length(skintonePos), GOLDEN_RATIO, GOLDEN_RATIO)*normalize(skintonePos); // set line length beyond full saturation hexagon
	// Normalize skin-tone line length-gradient
	static const float2 skintoneLine = skintonePos/dot(skintonePos, skintonePos);

	// Get rotation vectors for each line of hexagon, used as signed-distance field
	float2 hexagonLine[6] =
	{
		float2(hexagonVert[0].y-hexagonVert[1].y, hexagonVert[1].x-hexagonVert[0].x), // R-Yl
		float2(hexagonVert[1].y-hexagonVert[2].y, hexagonVert[2].x-hexagonVert[1].x), // Yl-G
		float2(hexagonVert[2].y-hexagonVert[3].y, hexagonVert[3].x-hexagonVert[2].x), // G-Cy
		float2(hexagonVert[3].y-hexagonVert[4].y, hexagonVert[4].x-hexagonVert[3].x), // Cy-B
		float2(hexagonVert[4].y-hexagonVert[5].y, hexagonVert[5].x-hexagonVert[4].x), // B-Mg
		float2(hexagonVert[5].y-hexagonVert[0].y, hexagonVert[0].x-hexagonVert[5].x)  // Mg-R
	};

	// Initialize variables
	float hexagonGradient[6];
	float skintoneGradient[2];
	float gradientPixelScale[7];
	// Generate hexagon signed-distance field
	float hexagonSdf100 = -ScopeUiThickness;
	float hexagonSdf75 = -ScopeUiThickness;
	[unroll] for (uint i=0u; i<6u; i++)
	{
		// Normalize lines gradient
		hexagonLine[i] /= dot(hexagonLine[i], hexagonVert[i]);
		// Get R-Yl-G-Cy-B-Mg hexagon signed-distance field
		hexagonGradient[i] = dot(hexagonLine[i], texCoord)-1f;
		// Get pixel scale for anti-aliasing
		gradientPixelScale[i] = getPixelScale(hexagonGradient[i]);
		// Combine edges distance fields into a single hexagon SDF
		hexagonSdf100 = max(hexagonSdf100, hexagonGradient[i]*gradientPixelScale[i]);
		hexagonSdf75 = max(hexagonSdf75, (hexagonGradient[i]+0.25)*gradientPixelScale[i]);
	}
	// Get skin-tone line signed-distance field
	skintoneGradient[0] = dot(skintoneLine, texCoord);
	// Get skin-tone pixel scale for anti-aliasing
	gradientPixelScale[6] = getPixelScale(skintoneGradient[0]);
	// Get skin-tone line signed-distance field, rotated 90 degrees
	skintoneGradient[1] = dot(float2(-skintoneLine.y, skintoneLine.x), texCoord);

	// Initialize UI color
	float4 uiColor; uiColor.a = 0f;
	// Add 100% and 75% saturation hexagon to UI mask
	uiColor.a += saturate(ScopeUiThickness-abs(hexagonSdf100));
	uiColor.a += saturate(ScopeUiThickness-abs(hexagonSdf75));

	// Generate skin-tone line anti-aliased bounds mask
	skintoneGradient[0] = saturate((0.5-abs(skintoneGradient[0]-0.5))*gradientPixelScale[6]+0.5);
	// Generate skin-tone line anti-aliased edge
	skintoneGradient[1] = saturate(ScopeUiThickness-abs(skintoneGradient[1])*gradientPixelScale[6]);

	// Add skin-tone line to UI mask
	float skintoneLineMask = skintoneGradient[0]*skintoneGradient[1];
	uiColor.a = max(uiColor.a, skintoneLineMask);

	// Output UI color
	uiColor.rgb = float3(lerp(1f, 1f-GOLDEN_RATIO, GammaConvert::to_display(ScopeUiTransparency)), texCoord); // get UI color in YCbCr
	uiColor.rgb = GammaConvert::to_linear(saturate(ColorConvert::YCbCr_to_RGB(uiColor.xyz))); // convert to RGB

	return uiColor;
}


// Main display vectorscope vertex shader
void VectorscopeRectangleVS(
	    uint   vertexID  : SV_VertexID,
	out float4 position  : SV_Position,
	out float2 texCoord  : TEXCOORD0,
	out float2 texCoord1 : TEXCOORD1
)
{
	// Initialize values
	position.z = 0f;  // not used
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
	static const float borderSize = 2f*SCOPES_BORDER_SIZE;
	static const float2 texCoordList[4] =
	{
		(float2(0f, 0f)-0.5)*borderSize+0.5,
		(float2(1f, 0f)-0.5)*borderSize+0.5,
		(float2(0f, 1f)-0.5)*borderSize+0.5,
		(float2(1f, 1f)-0.5)*borderSize+0.5
	};
	// Set constant texture coordinates
	texCoord =  texCoordList[vertexID];
	// Set constant pixel coordinates
	texCoord1 = positionList[vertexID];


	// Correct aspect and scale
#if BUFFER_WIDTH>BUFFER_HEIGHT
	float2 scopeSize = lerp(SCOPES_VECTORSCOPE_SIZE*BUFFER_RCP_HEIGHT*borderSize, 1f, ScopeSize);
	scopeSize.x *= BUFFER_HEIGHT*BUFFER_RCP_WIDTH; // panorama
#elif BUFFER_WIDTH<BUFFER_HEIGHT
	float2 scopeSize = lerp(SCOPES_VECTORSCOPE_SIZE*BUFFER_RCP_WIDTH*borderSize, 1f, ScopeSize);
	scopeSize.y *= BUFFER_WIDTH*BUFFER_RCP_HEIGHT; // portrait
#else // square aspect
	float2 scopeSize = lerp(SCOPES_VECTORSCOPE_SIZE*BUFFER_RCP_WIDTH*borderSize, 1f, ScopeSize);
#endif
	position.xy *= scopeSize; // scale scope
	position.xy += lerp(scopeSize*0.5-0.5, 0.5-scopeSize*0.5, ScopePosition); // offset scope
}

// Main display vectorscope pixel shader
void DisplayVectorscopePS(
	    float4 pos       : SV_Position,
	    float2 texCoord  : TEXCOORD0,
	    float2 texCoord1 : TEXCOORD1,
	out float4 color     : SV_Target
)
{
	// Get radial signed-distance-field (SDF)
	color.a = 0.5-length(texCoord1);
	// Normalize SDF to pixel size
	color.a *= lerp(
		SCOPES_VECTORSCOPE_SIZE*SCOPES_BORDER_SIZE*2f, // default pixel-size
#if BUFFER_WIDTH>BUFFER_HEIGHT // panorama
		float(BUFFER_HEIGHT), // maximum size
#else // portrait, square
		float(BUFFER_WIDTH),  // maximum size
#endif
		ScopeSize
	);
	// Clamp to visible range
	color.a = clamp(color.a, 0f, 1f); // circular mask
	// Apply transparency
	color.a *= ScopeBackgroundTransparency;

	// Determine vectorscope look
	color.rgb = float3(GOLDEN_RATIO, texCoord.x-0.5, 0.5-texCoord.y); // base color in YCbCr
	color.rgb = ColorConvert::YCbCr_to_RGB(color.rgb); // convert to sRGB
	// Manual gamma correction
	color.rgb = GammaConvert::to_linear(color.rgb); // convert to linear RGB
	// Blend with background
	{
	// Mask vectorscope image
#if SCOPES_FAST_CHECKERBOARD
		float vectorscopeMask = dot(tex2D(vectorscopeSampler, texCoord), 1f); // combine all frames encoded in 4-color channels
#else
		float vectorscopeMask = tex2D(vectorscopeSampler, texCoord).r;
#endif
		float3 background = tex2Dfetch(ReShade::BackBuffer, uint2(pos.xy)).rgb;
		// Linear workflow
		background = GammaConvert::to_linear(background); // manual gamma correction
		background = lerp(background, 0f, color.a); // blend with circular background
		color.rgb = lerp(background, color.rgb, vectorscopeMask); // blend with vectorscope read
	}
	color.rgb = saturate(color.rgb); // clamp values

	{
		// Get the anti-aliased UI color and alpha
		float4 UI = DrawUI(texCoord);
		// Apply the UI to background picture
		// Linear workflow
		color.rgb = lerp(color.rgb, UI.rgb, UI.a*GammaConvert::to_linear(ScopeUiTransparency));
		color.a = max(UI.a, color.a);
	}
	color.a = ceil(color.a);

	// Linear workflow
	color.rgb = GammaConvert::to_display(color.rgb); // manual gamma correction
	// Dither final output
	color.rgb = BlueNoise::dither(color.rgb, uint2(pos.xy));
}

/*-------------.
| :: Output :: |
'-------------*/

technique Vectorscope
<
	ui_label = "scopes FX: vectorscope analysis";
	ui_tooltip =
		"Analyze colors using vectorscope color-wheel.\n"
		"\n"
		"This effect © 2021-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-NC-ND 3.0 +\n"
		"for additional permissions see the source code.";
>
{
#if SCOPES_FAST_CHECKERBOARD
	pass ClearRenderTarget
	{
		RenderTarget = vectorscopeTex;

		BlendEnable = true;

		BlendOp =      MIN;
		BlendOpAlpha = MIN;
		// Background
		DestBlend =      ONE;
		DestBlendAlpha = ONE;
		// Foreground
		SrcBlend =      ONE;
		SrcBlendAlpha = ONE;

		VertexShader = ClearRenderTargetVS;
		PixelShader =  ClearRenderTargetPS;
	}
#endif
	pass AnalyzeColor
	{
#if SCOPES_FAST_CHECKERBOARD
		VertexCount = (BUFFER_WIDTH/2u)*(BUFFER_HEIGHT/2u);

		BlendOpAlpha =   ADD;
		DestBlendAlpha = ONE; // background
		SrcBlendAlpha =  ONE; // foreground
#else
		VertexCount = BUFFER_WIDTH*BUFFER_HEIGHT;
		ClearRenderTargets = true;
#endif
		RenderTarget = vectorscopeTex;

		PrimitiveTopology = POINTLIST;

		BlendEnable = true;

		BlendOp =   ADD;
		DestBlend = ONE; // background
		SrcBlend =  ONE; // foreground


		VertexShader = GatherStatsVS;
		PixelShader =  GatherStatsPS;
	}
	pass ScopeRectangle
	{
		PrimitiveTopology = TRIANGLESTRIP;
		VertexCount = 4;

		// BlendEnable = true;
		// SrcBlend =  SRCALPHA;    // foreground
		// DestBlend = INVSRCALPHA; // background

		VertexShader = VectorscopeRectangleVS;
		PixelShader = DisplayVectorscopePS;
	}
}
