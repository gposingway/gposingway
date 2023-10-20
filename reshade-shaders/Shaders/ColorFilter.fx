//Color Filter by Ioxa
//Version 08.08.17 for ReShade 3.0

#if !defined ActiveColorFilters
	#define ActiveColorFilters 6
#endif

uniform int ________UseFilter________1
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter1";
> = 1;

uniform float3 FilterColor1 <
	ui_type = "color";
> = float3(1.000000,0.717647,0.156863);

uniform float BaseSaturation1
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode1
<
	ui_type = "combo";
	ui_items = "None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight2\0SoftLight3\0Screen\0";
> = 0;

uniform int LumaMode1
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma1
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold1
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
	ui_step = 0.001;
> = 0.300;

uniform float UpperThreshold1
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
	ui_step = 0.001;
> = 0.7;

uniform float ThresholdRange1
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.500;

uniform float Strength1
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 1.000;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = 0.085;

uniform int DebugMode1
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;

#if ActiveColorFilters >= 2
uniform int ________UseFilter________2
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter2.";
> = 0;

uniform float3 FilterColor2 <
	ui_type = "color";
> = float3(0.000000,1.000000,0.000000);

uniform float BaseSaturation2
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode2
<
	ui_type = "combo";
	ui_items = "\None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight2\0SoftLight3\0Screen\0";
	ui_step = 0.20;
> = 0;

uniform int LumaMode2
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma2
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold2
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
> = 0.000;

uniform float UpperThreshold2
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
> = 1.000;

uniform float ThresholdRange2
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.0;

uniform float Strength2
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = -0.01;

uniform int DebugMode2
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;
#endif

#if ActiveColorFilters >= 3
uniform int ________UseFilter________3
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter3.";
> = 0;

uniform float3 FilterColor3 <
	ui_type = "color";
> = float3(0.509804,0.294118,0.000000);

uniform float BaseSaturation3
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode3
<
	ui_type = "combo";
	ui_items = "\None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight#2\0SoftLight#3\0Screen\0";
> = 3;

uniform int LumaMode3
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma3
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold3
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
> = 0.200;

uniform float UpperThreshold3
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
> = 0.800;

uniform float ThresholdRange3
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.300;

uniform float Strength3
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = 0.070;

uniform int DebugMode3
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;
#endif 

#if ActiveColorFilters >= 4
uniform int ________UseFilter________4
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter4.";
> = 1;

uniform float3 FilterColor4 <
	ui_type = "color";
> = float3(0.000000,0.000000,1.000000);

uniform float BaseSaturation4
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode4
<
	ui_type = "combo";
	ui_items = "\None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight#2\0SoftLight#3\0Screen\0";
> = 5;

uniform int LumaMode4
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma4
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold4
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
> = 0.100;

uniform float UpperThreshold4
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
> = 0.300;

uniform float ThresholdRange4
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.300;

uniform float Strength4
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = 0.059;

uniform int DebugMode4
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;
#endif

#if ActiveColorFilters >= 5
uniform int ________UseFilter________5
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter5.";
> = 1;

uniform float3 FilterColor5 <
	ui_type = "color";
> = float3(1.000000,0.490196,0.000000);

uniform float BaseSaturation5
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode5
<
	ui_type = "combo";
	ui_items = "\None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight#2\0SoftLight#3\0Screen\0";
> = 6;

uniform int LumaMode5
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma5
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold5
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
> = 0.500;

uniform float UpperThreshold5
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
> = 0.900;

uniform float ThresholdRange5
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.500;

uniform float Strength5
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = 0.090;

uniform int DebugMode5
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;
#endif


#if ActiveColorFilters >= 6
uniform int ________UseFilter________6
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter6.";
> = 1;

uniform float3 FilterColor6 <
	ui_type = "color";
> = float3(0.039216,0.000000,0.156863);

uniform float BaseSaturation6
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode6
<
	ui_type = "combo";
	ui_items = "\None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight#2\0SoftLight#3\0Screen\0";
> = 0;

uniform int LumaMode6
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma6
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold6
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
> = 0.000;

uniform float UpperThreshold6
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
> = 0.200;

uniform float ThresholdRange6
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.220;

uniform float Strength6
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = 0.080;


uniform int DebugMode6
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;
#endif

#if ActiveColorFilters >= 7
uniform int ________UseFilter________7
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter7.";
> = 0;

uniform float3 FilterColor7 <
	ui_type = "color";
> = float3(0.039216,0.000000,0.156863);

uniform float BaseSaturation7
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode7
<
	ui_type = "combo";
	ui_items = "\None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight#2\0SoftLight#3\0Screen\0";
> = 0;

uniform int LumaMode7
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma7
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold7
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
> = 0.000;

uniform float UpperThreshold7
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
> = 0.200;

uniform float ThresholdRange7
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.220;

uniform float Strength7
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = 0.080;


uniform int DebugMode7
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;
#endif

#if ActiveColorFilters >= 8
uniform int ________UseFilter________8
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter8.";
> = 0;

uniform float3 FilterColor8 <
	ui_type = "color";
> = float3(0.039216,0.000000,0.156863);

uniform float BaseSaturation8
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode8
<
	ui_type = "combo";
	ui_items = "\None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight#2\0SoftLight#3\0Screen\0";
> = 0;

uniform int LumaMode8
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma8
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold8
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
> = 0.000;

uniform float UpperThreshold8
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
> = 0.200;

uniform float ThresholdRange8
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.220;

uniform float Strength8
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = 0.080;


uniform int DebugMode8
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;
#endif

#if ActiveColorFilters >= 9
uniform int ________UseFilter________9
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter9.";
> = 0;

uniform float3 FilterColor9 <
	ui_type = "color";
> = float3(0.039216,0.000000,0.156863);

uniform float BaseSaturation9
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode9
<
	ui_type = "combo";
	ui_items = "\None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight#2\0SoftLight#3\0Screen\0";
> = 0;

uniform int LumaMode9
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma9
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold9
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
> = 0.000;

uniform float UpperThreshold9
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
> = 0.200;

uniform float ThresholdRange9
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.220;

uniform float Strength9
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = 0.080;

uniform int DebugMode9
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;
#endif

#if ActiveColorFilters >= 10
uniform int ________UseFilter________10
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Set to 1 to use ColorFilter10.";
> = 0;

uniform float3 FilterColor10 <
	ui_type = "color";
> = float3(0.039216,0.000000,0.156863);

uniform float BaseSaturation10
<
	ui_type = "drag";
	ui_min = -1.000; ui_max = 2.000;
	ui_tooltip = "Saturation of the base layer.";
	ui_step = 0.001;
> = 1.0;

uniform int BlendMode10
<
	ui_type = "combo";
	ui_items = "\None\0Overlay\0Multiply\0SoftLight\0LinearLight\0BurnAndDodge\0WarmScreen\0SoftLight#2\0SoftLight#3\0Screen\0";
> = 0;

uniform int LumaMode10
<
	ui_type = "combo";
	ui_items = "Average\0Luma\0Min\0Max\0Red\0Green\0Blue\0";
> = 0;

uniform int PreserveLuma10
<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
> = 0;

uniform float LowerThreshold10
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are less than this value.";
> = 0.000;

uniform float UpperThreshold10
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "Filter will not be applied to portions of the original image that are greater than this value.";
> = 0.200;

uniform float ThresholdRange10
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Smoothes the transition between the white and black areas of the threshold mask.";
> = 0.220;

uniform float Strength10
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Strength of the filter. Positive values add color, negative values remove color.";
	ui_step = 0.001;
> = 0.080;

uniform int DebugMode10
<
	ui_type = "combo";
	ui_items = "None\0ThresholdMask\0Filter\0Luma\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;
#endif

#include "ReShade.fxh"

#define DoSaturation(A,B,C) lerp(A,B,C);

float DoThresholdMask(float x, float y, float z, float luma)
{

	float mask = 1.0;
	
	if(x > 0.000)
	{
		x = 1.0-x;
		z *= x;
		mask -= smoothstep(x-z,x+z,1.0-luma);
	}
	
	if(y < 1.000)
	{
		z *= y;
		mask = lerp(mask,0.0,smoothstep(y-z,y+z,luma));
	}
	
	return mask;
}

float3 DoBlendMode(float3 A, float3 B, float luma, float Mode)
{
	
	if(Mode == 1)
	{
		//overlay
		A = lerp(2*B*A, 1.0 - 2*(1.0-B)*(1.0-A), step(0.5,luma));
	}
		
	if(Mode == 2)
	{
		//multiply
		A = (2*B*A);
	}
		
	if(Mode == 3)
	{
		//softlight
		A = lerp((2*B-1)*(A-pow(A,2))+A, (2*B-1)*(pow(A,0.5)-A)+A,step(0.501,luma));
	}
	
	if(Mode == 4)
	{
		//linear light
		A = B+2*A-1;
	}
		
	if(Mode == 5)
	{
		//Burn and Dodge
		A = lerp(A+B-1,A+B,smoothstep(0.0,1.0,luma));
	}
		
	if(Mode == 6)
	{
		//screen
		A = 1.0 - (2*(1.0-B)*(1.0-A));
	}
		
	if(Mode == 7)
	{
		//soft light #2
		A = lerp(B*(A+0.5),1-(1-B)*(1-(A-0.5)),step(0.5,A));
	}
		
	if(Mode == 8)
	{
		//soft light #3
		A = lerp((2*A-1)*(B-pow(B,2))+B, ((2*A-1)*(pow(B,0.5)-B))+B, step(0.49,A));
	}
		
	if(Mode == 9)
	{
		//screen
		A = 1.0 - (1.0-B)*(1.0-A);
	}
	
	return saturate(A);
}


float DoLuma(float3 x, int y)
{
	if(y == 0)
	{
		return dot(x,0.333);
	}
	
	if(y == 1)
	{
		return dot(x,float3(0.32786885,0.655737705,0.0163934436));
	}
	
	if(y == 2)
	{
		return min(x.r,min(x.g,x.b));
	}
	
	if(y == 3)
	{
		return max(x.r,max(x.g,x.b));
	}
	
	if(y == 4)
	{
		return x.r;
	}
	
	if(y == 5)
	{
		return x.g;
	}
	
	if(y == 6)
	{
		return x.b;
	}

	return 1;
}

float3 DoFilter(float3 Orig, float3 Filter, float Saturation, float LowerThreshold, float UpperThreshold, float ThresholdRange, float Strength, int LumaMode, int BlendMode, int DebugMode, int PreserveLuma)
{
	float3 A = Filter;
	
	float luma = DoLuma(Orig,LumaMode);
			
	if(DebugMode == 3)
	{
		return float3(luma,luma,luma);
	}

	float3 B = lerp(luma,Orig,Saturation);
	
	if(BlendMode)
	{
	A = DoBlendMode(A,B,luma,BlendMode);
	}
	
	if( LowerThreshold > 0.000 || UpperThreshold < 1.000 || DebugMode == 1)
	{
		
		float mask = DoThresholdMask(LowerThreshold,UpperThreshold,ThresholdRange,luma);
		A = lerp(Orig,A,mask);
		
		if (DebugMode == 1)
		{
			return float3(mask,mask,mask);
		}
	}
	
	if(DebugMode == 2)
	{
		return A;
	}
	
	if(PreserveLuma)
	{
		A -= DoLuma(A,LumaMode);
		A += luma;
	}
	
	return lerp(Orig,A,Strength);
}

float3 FilterBlend(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	float luma;
	float3 A;
	float3 B;
	float mask;
	
if(________UseFilter________1)
{
	//DoFilter(float3 Orig, float3 Filter, float Saturation, float LowerThreshold, float UpperThreshold, float ThresholdRange, float Strength, int LumaMode, int BlendMode, int Debug, int PreserveLuma)
	orig = DoFilter(orig,FilterColor1,BaseSaturation1,LowerThreshold1,UpperThreshold1,ThresholdRange1,Strength1,LumaMode1,BlendMode1,DebugMode1,PreserveLuma1);

}

#if ActiveColorFilters >= 2
if(________UseFilter________2)
{
	orig = DoFilter(orig,FilterColor2,BaseSaturation2,LowerThreshold2,UpperThreshold2,ThresholdRange2,Strength2,LumaMode2,BlendMode2,DebugMode2,PreserveLuma2);
}
#endif 

#if ActiveColorFilters >= 3
if (________UseFilter________3)
{
	orig = DoFilter(orig,FilterColor3,BaseSaturation3,LowerThreshold3,UpperThreshold3,ThresholdRange3,Strength3,LumaMode3,BlendMode3,DebugMode3,PreserveLuma3);
}
#endif

#if ActiveColorFilters >= 4
if (________UseFilter________4)
{
	orig = DoFilter(orig,FilterColor4,BaseSaturation4,LowerThreshold4,UpperThreshold4,ThresholdRange4,Strength4,LumaMode4,BlendMode4,DebugMode4,PreserveLuma4);

}
#endif

#if ActiveColorFilters >= 5
if (________UseFilter________5)
{
	orig = DoFilter(orig,FilterColor5,BaseSaturation5,LowerThreshold5,UpperThreshold5,ThresholdRange5,Strength5,LumaMode5,BlendMode5,DebugMode5,PreserveLuma5);

}
#endif

#if ActiveColorFilters >= 6
if (________UseFilter________6)
{
	orig = DoFilter(orig,FilterColor6,BaseSaturation6,LowerThreshold6,UpperThreshold6,ThresholdRange6,Strength6,LumaMode6,BlendMode6,DebugMode6,PreserveLuma6);

}
#endif

#if ActiveColorFilters >= 7
if (________UseFilter________7)
{
	orig = DoFilter(orig,FilterColor7,BaseSaturation7,LowerThreshold7,UpperThreshold7,ThresholdRange7,Strength7,LumaMode7,BlendMode7,DebugMode7,PreserveLuma7);

}
#endif

#if ActiveColorFilters >= 8
if (________UseFilter________8)
{
	orig = DoFilter(orig,FilterColor8,BaseSaturation8,LowerThreshold8,UpperThreshold8,ThresholdRange8,Strength8,LumaMode8,BlendMode8,DebugMode8,PreserveLuma8);

}
#endif

#if ActiveColorFilters >= 9
if (________UseFilter________9)
{
	orig = DoFilter(orig,FilterColor9,BaseSaturation9,LowerThreshold9,UpperThreshold9,ThresholdRange9,Strength9,LumaMode9,BlendMode9,DebugMode9,PreserveLuma9);

}
#endif

#if ActiveColorFilters >= 10
if (________UseFilter________10)
{
	orig = DoFilter(orig,FilterColor10,BaseSaturation10,LowerThreshold10,UpperThreshold10,ThresholdRange10,Strength10,LumaMode10,BlendMode10,DebugMode10,PreserveLuma10);

}
#endif

	return saturate(orig.rgb);
}

technique ColorFilter
{

	pass A 
	{
		VertexShader = PostProcessVS;
		PixelShader = FilterBlend;
	}
	
}
