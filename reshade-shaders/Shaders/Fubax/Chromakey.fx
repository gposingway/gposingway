/*------------------.
| :: Description :: |
'-------------------/

Chromakey PS (version 1.6.1)

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

/*-----------.
| :: Menu :: |
'-----------*/

uniform float Threshold
<	__UNIFORM_SLIDER_FLOAT1
	ui_min = 0f; ui_max = 0.999; ui_step = 0.001;
	ui_category = "Distance adjustment";
> = 0.5;

uniform bool RadialX <
	ui_label = "Horizontally radial depth";
	ui_category = "Radial distance";
	ui_category_closed = true;
> = false;
uniform bool RadialY <
	ui_label = "Vertically radial depth";
	ui_category = "Radial distance";
> = false;

uniform int FOV
<	__UNIFORM_SLIDER_INT1
	ui_units = "°";
	ui_label = "FOV (horizontal)";
	ui_tooltip = "Field of view in degrees";
	#if __RESHADE__ < 40000
		ui_step = 1;
	#endif
	ui_min = 0; ui_max = 170;
	ui_category = "Radial distance";
> = 90;

uniform int Pass
<	__UNIFORM_RADIO_INT1
	ui_label = "Keying type";
	ui_items = "Background key\0Foreground key\0";
	ui_category = "Direction adjustment";
> = 0;

uniform bool Floor <
	ui_label = "Mask floor";
	ui_category = "Floor masking (experimental)";
	ui_category_closed = true;
> = false;

uniform float FloorAngle
<	__UNIFORM_SLIDER_FLOAT1
	ui_units = "°";
	ui_label = "Floor angle";
	ui_category = "Floor masking (experimental)";
	ui_min = 0f; ui_max = 1f;
> = 1f;

uniform int Precision
<	__UNIFORM_SLIDER_INT1
	ui_label = "Floor precision";
	ui_category = "Floor masking (experimental)";
	ui_min = 2; ui_max = 64;
> = 4;

uniform int Color
<	__UNIFORM_RADIO_INT1
	ui_label = "Keying color";
	ui_tooltip = "Ultimatte(tm) Super Blue and Green are industry standard colors for chromakey";
	ui_items = "Super Blue Ultimatte(tm)\0Green Ultimatte(tm)\0Custom\0";
	ui_category = "Color settings";
	ui_category_closed = true;
> = 1;

uniform float3 CustomColor
<	__UNIFORM_COLOR_FLOAT3
	ui_label = "Custom color";
	ui_category = "Color settings";
> = float3(1f, 0f, 0f);

uniform bool AntiAliased <
	ui_label = "Anti-aliased mask";
	ui_tooltip = "Disabling this option will reduce masking gaps";
	ui_category = "Additional settings";
	ui_category_closed = true;
> = false;

/*----------------.
| :: Functions :: |
'----------------*/

float MaskAA(float2 texcoord)
{
	// Sample depth image
	float Depth = ReShade::GetLinearizedDepth(texcoord);

	// Convert to radial depth
	float2 Size;
	Size.x = tan(radians(FOV*0.5));
	Size.y = Size.x/BUFFER_ASPECT_RATIO;
	if (RadialX) Depth *= length(float2((texcoord.x-0.5)*Size.x, 1f));
	if (RadialY) Depth *= length(float2((texcoord.y-0.5)*Size.y, 1f));

	// Return jagged mask
	if (!AntiAliased) return step(Threshold, Depth);

	// Get half-pixel size in depth value
	float hPixel = fwidth(Depth)*0.5;

	return smoothstep(Threshold-hPixel, Threshold+hPixel, Depth);
}

float3 GetPosition(float2 texcoord)
{
	// Get view angle for trigonometric functions
	const float theta = radians(FOV*0.5);

	float3 position = float3(texcoord*2f-1f, ReShade::GetLinearizedDepth(texcoord));
	// Reverse perspective
	position.xy *= position.z;

	return position;
}

// Normal map (OpenGL oriented) generator from DisplayDepth.fx
float3 GetNormal(float2 texcoord)
{
	float3 offset = float3(BUFFER_PIXEL_SIZE.xy, 0f);
	float2 posCenter = texcoord.xy;
	float2 posNorth  = posCenter - offset.zy;
	float2 posEast   = posCenter + offset.xz;

	float3 vertCenter = float3(posCenter - 0.5, 1f)*ReShade::GetLinearizedDepth(posCenter);
	float3 vertNorth  = float3(posNorth - 0.5,  1f)*ReShade::GetLinearizedDepth(posNorth);
	float3 vertEast   = float3(posEast - 0.5,   1f)*ReShade::GetLinearizedDepth(posEast);

	return normalize(cross(vertCenter-vertNorth, vertCenter-vertEast))*0.5+0.5;
}

/*--------------.
| :: Shaders :: |
'--------------*/

float3 ChromakeyPS(
	float4 pos      : SV_Position,
	float2 texcoord : TEXCOORD
) : SV_Target
{
	// Define chromakey color, Ultimatte™ Super Blue, Ultimatte™ Green, or user color
	float3 Screen;
	switch(Color)
	{
		case 0: Screen = float3(0.07, 0.18, 0.72); break; // Ultimatte™ Super Blue
		case 1: Screen = float3(0.29, 0.84, 0.36); break; // Ultimatte™ Green
		case 2: Screen = CustomColor;              break; // user defined color
	}

	// Generate depth mask
	float DepthMask = MaskAA(texcoord);

	if (Floor)
	{
		float AngleScreen = (float)round(GetNormal(texcoord).y*Precision)/Precision;
		float AngleFloor = (float)round(FloorAngle*Precision)/Precision;

		bool FloorMask = AngleScreen==AngleFloor;

		DepthMask = FloorMask ? 1f : DepthMask;
	}

	if(bool(Pass)) DepthMask = 1f-DepthMask;

	return lerp(tex2D(ReShade::BackBuffer, texcoord).rgb, Screen, DepthMask);
}

/*-------------.
| :: Output :: |
'-------------*/

technique Chromakey
<
	ui_tooltip =
		"Generate green-screen wall based on depth\n"
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 4.0";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromakeyPS;
	}
}
