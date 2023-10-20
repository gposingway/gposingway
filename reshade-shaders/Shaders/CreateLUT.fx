//Create LUT by Ioxa
//Version 08.08.17 for ReShade 3.0

uniform float X_Position <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 0.467;
	ui_tooltip = "Adjusts the horizontal location of the LUT";
> = 0.0;

uniform float Y_Position <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 0.970;
	ui_tooltip = "Adjusts the vertical Location of the LUT";
> = 0.0;

uniform int ShowImage<
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "When set to 1 the LUT is displayed over the game image.";
> = 0;

#include "ReShade.fxh"

texture CreateLUTtex < source = "CreateLUT.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler	CreateLUTsampler 	{ Texture = CreateLUTtex; AddressU = BORDER; AddressV = BORDER;};

texture CreateLUT_Mask_tex < source = "LUT_Mask.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler	CreateLUT_Mask_Sampler 	{ Texture = CreateLUT_Mask_tex; AddressU = BORDER; AddressV = BORDER;};

float3 CreateLUT(in float4 vpos : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
	float3 A = (tex2D(CreateLUTsampler, texcoord - float2(X_Position,Y_Position)).rgb);
	float3 Orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float Mask = tex2D(CreateLUT_Mask_Sampler, texcoord - float2(X_Position,Y_Position)).r;
	
	if(ShowImage)
	{
	return lerp(Orig,A,Mask);
	//return Mask;
	}
	
	return A;
}

technique CreateLUT
{
	pass CreateLUT
	{
		VertexShader = PostProcessVS;
		PixelShader = CreateLUT;
	}
}
