/*------------------.
| :: Description :: |
'-------------------/

Scopes FX - Zebra Lines PS (version 1.2.3)

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
This effect will show over/under exposed image areas as a zebra lines.
*/

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

uniform float ScopeThresholdWhite
<	__UNIFORM_SLIDER_FLOAT1
	ui_category_closed = true;
	ui_category = "Clipping threshold";
	ui_units = "%%";
	ui_label = "threshold for whites";
	ui_tooltip = "Inclusive percent value threshold for whites clipping.";
	ui_min = 50f;
	ui_max = 100f;
	ui_step = 0.1;
> = 99f;

uniform bool ScopeClipWhite
<	__UNIFORM_INPUT_BOOL1
	ui_category = "Clipping threshold";
	ui_label = "show whites clipping";
	ui_tooltip = "Enable whites-clipping zebra lines.";
> = true;

uniform float ScopeThresholdBlack
<	__UNIFORM_SLIDER_FLOAT1
	ui_category = "Clipping threshold";
	ui_units = "%%";
	ui_label = "threshold for blacks";
	ui_spacing = 2u;
	ui_tooltip = "Inclusive percent value threshold for blacks clipping.";
	ui_min = 0f;
	ui_max = 50f;
	ui_step = 0.1;
> = 1f;

uniform bool ScopeClipBlack
<	__UNIFORM_INPUT_BOOL1
	ui_category = "Clipping threshold";
	ui_label = "show blacks clipping";
	ui_tooltip = "Enable blacks-clipping zebra lines.";
> = true;

uniform bool ScopeRGBClipping
<	__UNIFORM_INPUT_BOOL1
	ui_category = "Clipping threshold";
	ui_label = "RGB clipping mode";
	ui_tooltip = "Enable zebra-lines for red, green, blue components.";
> = false;

uniform uint ScopeLineWidth
<	__UNIFORM_SLIDER_INT1
	ui_category_closed = true;
	ui_category = "UI settings";
	ui_units = " pixels";
	ui_label = "width of lines";
	ui_tooltip = "Zebra-lines width in pixels.";
	ui_min = 3u;
	ui_max = 10u;
> = 4u;

uniform uint ScopeLineAngle
<	__UNIFORM_SLIDER_INT1
	ui_category = "UI settings";
	ui_units = "°";
	ui_label = "angle of lines";
	ui_tooltip = "Zebra-lines angle in degrees.";
	ui_min = 0u;
	ui_max = 90u;
> = 22u;

/*--------------.
| :: Shaders :: |
'--------------*/

void ZebraLinesVS(
	in  uint   vertexId : SV_VertexID,
	out float4 position : SV_Position // no texture mapping
)
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

void ZebraLinesPS(
	    float4 pos   : SV_Position,
	out float3 color : SV_Target // no texture mapping
)
{
	// Get normalized rotation vector
	static const float2x2 rotationMtx = float2x2(
		 cos(radians(ScopeLineAngle)),  sin(radians(ScopeLineAngle)), // white clip rotation vector
		 sin(radians(ScopeLineAngle)), -cos(radians(ScopeLineAngle))  // black clip rotation vector
	);

	// Get pixel-size gradient at the rotation angle
	float2 zebraLines = abs(mul(rotationMtx, pos.xy));

	// Create zebra pattern
	zebraLines = abs(zebraLines%(ScopeLineWidth*2u)-ScopeLineWidth)-ScopeLineWidth*0.5;
	// Limit to visible range
	zebraLines = clamp(zebraLines, 0f, 1f);

	// Sample background image in sRGB and convert to linear RGB
	color = GammaConvert::to_linear(tex2Dfetch(ReShade::BackBuffer, uint2(pos.xy)).rgb);

	// UI settings
	if (ScopeRGBClipping)
	{
		float4 mask;
		// Apply threshold
		mask.rgb = color-ScopeThresholdWhite*0.01;
		mask.a = ScopeThresholdBlack*0.01-max(max(color.r, color.g), color.b);
		// Apply edge sharpness
		mask = clamp(mask*(255u*2u)+1f, 0f, 1f);
		// Blend background with zebra-lines using threshold
		if (ScopeClipWhite) color = lerp(
				color,
				zebraLines.x*mask.rgb,
				max(max(mask.r, mask.g), mask.b)
			);
		if (ScopeClipBlack)
			color = lerp(color, zebraLines.y, mask.a);
	}
	else
	{
		// Get V component of HSV color space
		float2 mask = max(max(color.r, color.g), color.b);

		// Apply threshold
		mask.x = mask.x-ScopeThresholdWhite*0.01;
		mask.y = ScopeThresholdBlack*0.01-mask.y;
		// Apply edge sharpness
		mask = clamp(mask*(255u*2u)+1f, 0f, 1f);
		// Blend background with zebra-lines using threshold
		if (ScopeClipWhite) color = lerp(color, zebraLines.x, mask.x);
		if (ScopeClipBlack) color = lerp(color, zebraLines.y, mask.y);
	}

	// Linear workflow
	color = GammaConvert::to_display(color); // manual gamma correction
	// Dither final output
	color = BlueNoise::dither(color, uint2(pos.xy));
}

/*-------------.
| :: Output :: |
'-------------*/

technique ZebraLines
<
	ui_label = "scopes FX: zebra-lines clipping";
	ui_tooltip =
		"Check for RGB clipping in blacks and whites.\n"
		"\n"
		"This effect © 2021-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-NC-ND 3.0 +\n"
		"for additional permissions see the source code.";
>
{
	pass
	{
		VertexShader = ZebraLinesVS;
		PixelShader = ZebraLinesPS;
	}
}
