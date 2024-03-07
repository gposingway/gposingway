/*------------------.
| :: Description :: |
'-------------------/

Before-After PS (version 2.0.0)

Copyright:
This code © 2018-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/4.0/
*/

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "LinearGammaWorkflow.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

uniform uint LineWidth
<	__UNIFORM_SLIDER_INT1
	ui_category = "Line options";
	ui_units = " pixels";
	ui_label = "line width";
	ui_tooltip =
		"Separation line thickness in pixels.\n"
		"To enable, set 'edge blur' to 0 pixels.";
	ui_min = 0u; ui_max = 64u;
> = 8u;

uniform float3 LineColor
< 	__UNIFORM_COLOR_FLOAT3
	ui_category = "Line options";
	ui_label = "line color";
	ui_tooltip = "To enable, set 'edge blur' to 0 pixels.";
> = float3(0.0625, 0.0625, 0.0625);

uniform uint EdgeBlur
<	__UNIFORM_DRAG_INT1
	ui_category = "Line options";
	ui_units = " pixels";
	ui_label = "edge blur";
	ui_tooltip = "Disables line.";
	ui_min = 0u; ui_max = BUFFER_WIDTH;
> = 0u;

uniform int EdgeAngle
<	__UNIFORM_SLIDER_INT1
	ui_category = "Separation edge";
	ui_units = "°";
	ui_label = "tilt angle";
	ui_tooltip = "Tilt the separation line.";
	ui_min = -180; ui_max = 180;
> = 0;

uniform float EdgeOffset
<	__UNIFORM_DRAG_FLOAT1
	ui_category = "Separation edge";
	ui_label = "offset";
	ui_tooltip = "Offset the separation edge.";
	ui_min = -1f; ui_max = 1f; ui_step = 0.001;
> = 0f;

/*---------------.
| :: Textures :: |
'---------------*/

// First pass render target
texture BeforeTarget
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
};
sampler BeforeSampler
{ Texture = BeforeTarget; };

/*----------------.
| :: Functions :: |
'----------------*/

// Overlay blending mode
float Overlay(float LayerAB)
{
	float MinAB = min(LayerAB, 0.5);
	float MaxAB = max(LayerAB, 0.5);
	return 2f*(MinAB*MinAB+MaxAB+MaxAB-MaxAB*MaxAB)-1.5;
}
// Get coordinates rotation matrix
float2x2 getRotation(int angle)
{
	// Convert angle to radians
	float angleRadians = radians(angle);
	// Get rotation components
	float sine = sin(angleRadians), cosine = cos(angleRadians);
	// Generate rotated 2D axis as a 2x2 matrix
	return float2x2(
		cosine, sine,  // rotated space X axis
		 -sine, cosine // rotated space Y axis
	);
}

/*--------------.
| :: Shaders :: |
'--------------*/

// Generate a triangle covering the entire screen
float4 BeforeAfterVS(in uint id : SV_VertexID) : SV_Position
{
	// Define vertex position
	const float2 vertexPos[3] = {
		float2(-1f, 1f), // top left
		float2(-1f,-3f), // bottom left
		float2( 3f, 1f)  // top right
	};
	return float4(vertexPos[id], 0f, 1f);
}

void BeforePS(
	float4 pixelPos  : SV_Position,
	out float3 Image : SV_Target
)
{
	// Just grab screen texture
	Image = tex2Dfetch(ReShade::BackBuffer, uint2(pixelPos.xy)).rgb;
}

void AfterPS(
	float4 pixelPos  : SV_Position,
	out float3 Image : SV_Target
)
{
	// Get rotation axis matrix
	const float2x2 rotationMtx = getRotation(EdgeAngle);
	// Get line mask from rotated offset coordinates
	float lineCoord = mul(rotationMtx, uint2(pixelPos.xy)-mad(EdgeOffset, 0.5, 0.5)*BUFFER_SCREEN_SIZE).x;

	// Scale line coordinates to gradient mask
	if (EdgeBlur!=0u)
		lineCoord = mad(lineCoord, rcp(EdgeBlur), 0.5);

	// Linear gamma workflow
	Image = lerp(
		GammaConvert::to_linear(tex2Dfetch(BeforeSampler, uint2(pixelPos.xy)).rgb),
		GammaConvert::to_linear(tex2Dfetch(ReShade::BackBuffer, uint2(pixelPos.xy)).rgb),
		EdgeBlur==0u
			? saturate(lineCoord+0.5) // make jaggies-free transition
			: Overlay(saturate(lineCoord)) // make smooth transition
	);

	// Draw separation line
	if (LineWidth!=0u && EdgeBlur==0u)
		Image = lerp(
			Image,
			GammaConvert::to_linear(LineColor), // linear workflow
			saturate(mad(LineWidth, 0.5, 0.5-abs(lineCoord))) // Generate line mask
		);

	// Linear gamma workflow
	Image = GammaConvert::to_display(Image);
}

/*-------------.
| :: Output :: |
'-------------*/

technique Before
<
	ui_tooltip =
		"Place this technique before effects you want compare.\n"
		"Then move technique 'After'"
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 4.0";
>
{
	pass
	{
		VertexShader = BeforeAfterVS;
		PixelShader = BeforePS;
		RenderTarget = BeforeTarget;
	}
}

technique After
<
	ui_tooltip =
		"Place this technique after effects you want compare.\n"
		"Then move technique 'Before'"
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 4.0";
>
{
	pass
	{
		VertexShader = BeforeAfterVS;
		PixelShader = AfterPS;
	}
}
