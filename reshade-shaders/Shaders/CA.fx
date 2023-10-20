//Chromatic Aberration for ReShade3.0
//Version 08.09.17

#if !defined CA_Blurring
	#define CA_Blurring 0
#endif

#if !defined CA_VignetteBlurring
	#define CA_VignetteBlurring 0
#endif

#include "ReShade.fxh"

uniform float RedFocalOffset
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Offset value for the red channel";
> = -0.5;

uniform float Red_X_Offset
<
	ui_type = "drag";
	ui_min = -10.00; ui_max = 10.00;
	ui_tooltip = "Horizontal Offset value for the red channel";
> = -1;

uniform float Red_Y_Offset
<
	ui_type = "drag";
	ui_min = -10.00; ui_max = 10.00;
	ui_tooltip = "Vertical Offset value for the red channel";
> = -1;

uniform float GreenFocalOffset
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Offset value for the green channel";
> = 0.00;

uniform float Green_X_Offset
<
	ui_type = "drag";
	ui_min = -10.00; ui_max = 10.00;
	ui_tooltip = "Horizontal Offset value for the green channel";
> = 1.00;

uniform float Green_Y_Offset
<
	ui_type = "drag";
	ui_min = -10.00; ui_max = 10.00;
	ui_tooltip = "Vertical Offset value for the green channel";
> = -1.00;

uniform float BlueFocalOffset
<
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_tooltip = "Offset value for the blue channel";
> = 0.5;

uniform float Blue_X_Offset
<
	ui_type = "drag";
	ui_min = -10.00; ui_max = 10.00;
	ui_tooltip = "Horizontal Offset value for the blue channel";
> = -1;

uniform float Blue_Y_Offset
<
	ui_type = "drag";
	ui_min = -10.00; ui_max = 10.00;
	ui_tooltip = "Vertical Offset value for the blue channel";
> = 1;

uniform int OffsetSamples
<
	ui_type = "drag";
	ui_min = 1; ui_max = 5;
	ui_tooltip = "Number of samples used for the offsets. More samples results in a smoother look.";
> = 2;

uniform float LensShape
<
	ui_type = "drag";
	ui_min = 1.00; ui_max = 2.00;
	ui_tooltip = "The shape of the CA";
> = 1.00;

uniform float LensFocus
<
	ui_type = "drag";
	ui_min = 0.1; ui_max = 5.00;
	ui_tooltip = "Determines how far frome the middle of the screen the CA begins";
> = 1.3;

uniform float Strength
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Strength of the effect.";
> = 0.5;

#if CA_VignetteBlurring == 1
uniform int VignetteBlur
<
	ui_type = "drag";
	ui_min = 1; ui_max = 4;
	ui_tooltip = "Blur radius used in the blur pass. Use 'CA_VignetteBlurring=0' in preprocessor settings to disable blurring.";
> = 2;

uniform float VignetteBlurFocus
<
	ui_type = "drag";
	ui_min = 0.10; ui_max = 5.00;
	ui_tooltip = "Strength of the effect.";
> = 1.7;

uniform float VignetteBlurStrength
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Strength of the effect.";
> = 0.5;
#else 
uniform int VignetteBlur
<
	ui_type = "combo";
	ui_min = 1; ui_max = 4;
	ui_items = "\Currently Disabled\0Currently Disabled\0Currently Disabled\0Currently Disabled\0Currently Disabled\0";
	ui_tooltip = "Add CA_VignetteBlurring=1 to preprocessor settings to enable";
> = 1;
#endif 

#if CA_Blurring == 1
uniform int CABlur
<
	ui_type = "drag";
	ui_min = 1; ui_max = 4;
	ui_tooltip = "Blur radius used in the blur pass. Use 'CA_Blurring=0' in preprocessor settings to disable blurring.";
> = 2;

uniform float BlurFocus
<
	ui_type = "drag";
	ui_min = 0.10; ui_max = 5.00;
	ui_tooltip = "Strength of the effect.";
> = 1;

uniform float BlurStrength
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Strength of the effect.";
> = 0.4;
#else 
uniform int CABlur
<
	ui_type = "combo";
	ui_min = 1; ui_max = 4;
	ui_items = "\Currently Disabled\0Currently Disabled\0Currently Disabled\0Currently Disabled\0Currently Disabled\0";
	ui_tooltip = "Add CA_Blurring=1 to preprocessor settings to enable";
> = 1;
#endif 

uniform int DebugMode
<
	ui_type = "combo";
	ui_items = "\None\0CALensMask\0VignetteBlurLensMask\0BlurLensMask\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;

float3 CA_Offset(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	
	float2 RedCoords = texcoord - float2(0.5+(texcoord.x*Red_X_Offset*ReShade::PixelSize.x),0.5+(texcoord.y*Red_Y_Offset*ReShade::PixelSize.y));
	float2 GreenCoords = texcoord - float2(0.5+(texcoord.x*Green_X_Offset*ReShade::PixelSize.x),0.5+(texcoord.y*Green_Y_Offset*ReShade::PixelSize.y));
	float2 BlueCoords = texcoord - float2(0.5+(texcoord.x*Blue_X_Offset*ReShade::PixelSize.x),0.5+(texcoord.y*Blue_Y_Offset*ReShade::PixelSize.y));
			
	float3 CA;
	
	CA.r = (tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (RedFocalOffset*0.01))) + 0.5).r);
	CA.b = (tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (BlueFocalOffset*0.01))) + 0.5).b);
	CA.g = (tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (GreenFocalOffset*0.01))) + 0.5).g);
	
	if(OffsetSamples == 2)
	{
		#define TwoSampleOffset 2
		RedCoords = texcoord - float2(0.5+(texcoord.x*Red_X_Offset*ReShade::PixelSize.x*TwoSampleOffset),0.5+(texcoord.y*Red_Y_Offset*ReShade::PixelSize.y*TwoSampleOffset));
		GreenCoords = texcoord - float2(0.5+(texcoord.x*Green_X_Offset*ReShade::PixelSize.x*TwoSampleOffset),0.5+(texcoord.y*Green_Y_Offset*ReShade::PixelSize.y*TwoSampleOffset));
		BlueCoords = texcoord - float2(0.5+(texcoord.x*Blue_X_Offset*ReShade::PixelSize.x*TwoSampleOffset),0.5+(texcoord.y*Blue_Y_Offset*ReShade::PixelSize.y*TwoSampleOffset));
		
		float Offset = (abs(RedFocalOffset) + abs(BlueFocalOffset) + abs(GreenFocalOffset))*0.25;
		
		CA *= 0.667;
		
		if(RedFocalOffset == 0)
		{
			CA.r += (tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offset*0.01*0.5))) + 0.5).r)*0.1665;
			CA.r += (tex2D(ReShade::BackBuffer,(RedCoords*(1.0 - (Offset*0.01*0.5))) + 0.5).r)*0.1665;
		}
		else
		{
			CA.r += (tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (RedFocalOffset*0.01*0.5))) + 0.5).r)*0.333;
		}
		
		if(GreenFocalOffset == 0)
		{
			CA.g += (tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offset*0.01*0.5))) + 0.5).g)*0.1665;
			CA.g += (tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 - (Offset*0.01*0.5))) + 0.5).g)*0.1665;
		}
		else
		{
			CA.g += (tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (GreenFocalOffset*0.01*0.5))) + 0.5).g)*0.333;
		}
		
		if(BlueFocalOffset == 0)
		{
			CA.b += (tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offset*0.01*0.5))) + 0.5).b)*0.1665;
			CA.b += (tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 - (Offset*0.01*0.5))) + 0.5).b)*0.1665;
		}
		else
		{
			CA.b += (tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (BlueFocalOffset*0.01*0.5))) + 0.5).b)*0.333;
		}	
	}
	
	if(OffsetSamples == 3)
	{
		float Offsets[3] = { 0.0, 0.5, 0.25 };
		float Weights[3] = { 0.0, 0.333, 0.1666 };
		float xyOffsets[3] = { 0.0, 2, 4};
		float Offset = (abs(RedFocalOffset) + abs(BlueFocalOffset) + abs(GreenFocalOffset))*0.25;
		
		CA *= 0.5;
		
		for(int i = 1; i < 3; ++i)
		{
			RedCoords = texcoord - float2(0.5+(texcoord.x*Red_X_Offset*ReShade::PixelSize.x*xyOffsets[i]),0.5+(texcoord.y*Red_Y_Offset*ReShade::PixelSize.y*xyOffsets[i]));
			GreenCoords = texcoord - float2(0.5+(texcoord.x*Green_X_Offset*ReShade::PixelSize.x*xyOffsets[i]),0.5+(texcoord.y*Green_Y_Offset*ReShade::PixelSize.y*xyOffsets[i]));
			BlueCoords = texcoord - float2(0.5+(texcoord.x*Blue_X_Offset*ReShade::PixelSize.x*xyOffsets[i]),0.5+(texcoord.y*Blue_Y_Offset*ReShade::PixelSize.y*xyOffsets[i]));
			
			if(RedFocalOffset == 0.000)
			{
				CA.r += tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).r*Weights[i]*0.5; //(Offset + (Offset*Offsets[i]))
				CA.r += tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).r*Weights[i]*0.5; //(Offset*0.1*Offsets[i])
			}
			else
			{
				CA.r += tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offsets[i]*RedFocalOffset*0.01))) + 0.5).r*Weights[i]; //((Offset + (Offset*Offsets[i]))*0.1)
			}
		
			if(GreenFocalOffset == 0.000)
			{
				CA.g += tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).g*Weights[i]*0.5;
				CA.g += tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).g*Weights[i]*0.5;
			}
			else
			{
				CA.g += tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offsets[i]*GreenFocalOffset*0.01))) + 0.5).g*Weights[i];
			}
		
			if(BlueFocalOffset == 0.000)
			{
				CA.b += tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).b*Weights[i]*0.5;
				CA.b += tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).b*Weights[i]*0.5;
			}
			else
			{
				CA.b += tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offsets[i]*BlueFocalOffset*0.01))) + 0.5).b*Weights[i];
			}
		}
	}
	
	if(OffsetSamples == 4)
	{
		float Offsets[4] = { 0.0, 0.667, 0.333, 0.1665 };
		float Offset = (abs(RedFocalOffset) + abs(BlueFocalOffset) + abs(GreenFocalOffset))*0.25;
		float xyOffsets[4] = { 0.0, 1.5, 3, 6};
		float Weights[4] = { 0.4, 0.3, 0.2, 0.1 };
		
		CA *= Weights[0];
		
		for(int i = 1; i < 4; ++i)
		{
		RedCoords = texcoord - float2(0.5+(texcoord.x*Red_X_Offset*ReShade::PixelSize.x*xyOffsets[i]),0.5+(texcoord.y*Red_Y_Offset*ReShade::PixelSize.y*xyOffsets[i]));
		GreenCoords = texcoord - float2(0.5+(texcoord.x*Green_X_Offset*ReShade::PixelSize.x*xyOffsets[i]),0.5+(texcoord.y*Green_Y_Offset*ReShade::PixelSize.y*xyOffsets[i]));
		BlueCoords = texcoord - float2(0.5+(texcoord.x*Blue_X_Offset*ReShade::PixelSize.x*xyOffsets[i]),0.5+(texcoord.y*Blue_Y_Offset*ReShade::PixelSize.y*xyOffsets[i]));
		
		if(RedFocalOffset == 0.000)
			{
				CA.r += tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).r*Weights[i]*0.5; //(Offset + (Offset*Offsets[i]))
				CA.r += tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).r*Weights[i]*0.5; //(Offset*0.1*Offsets[i])
			}
			else
			{
				CA.r += tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offsets[i]*RedFocalOffset*0.01))) + 0.5).r*Weights[i]; //((Offset + (Offset*Offsets[i]))*0.1)
			}
		
			if(GreenFocalOffset == 0.000)
			{
				CA.g += tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).g*Weights[i]*0.5;
				CA.g += tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).g*Weights[i]*0.5;
			}
			else
			{
				CA.g += tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offsets[i]*GreenFocalOffset*0.01))) + 0.5).g*Weights[i];
			}
		
			if(BlueFocalOffset == 0.000)
			{
				CA.b += tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).b*Weights[i]*0.5;
				CA.b += tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).b*Weights[i]*0.5;
			}
			else
			{
				CA.b += tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offsets[i]*BlueFocalOffset*0.01))) + 0.5).b*Weights[i];
			}
		}
	}
	
	if(OffsetSamples >= 5)
	{
		float Offsets[5] = { 0.0, 0.75, 0.5, 0.25, 0.125 };
		float Offset = (abs(RedFocalOffset) + abs(BlueFocalOffset) + abs(GreenFocalOffset))*0.25;
		float xyOffsets[5] = { 0.0, 1.333, 2, 4, 8};
		float Weights[5] = { 0.333, 0.2666, 0.2, 0.1333, 0.0666 };
		
		CA *= 0.333;
		
		for(int i = 1; i < 5; ++i)
		{
		RedCoords = texcoord - float2(0.5+(texcoord.x*Red_X_Offset*ReShade::PixelSize.x*xyOffsets[i]),0.5+(texcoord.y*Red_Y_Offset*ReShade::PixelSize.y*xyOffsets[i]));
		GreenCoords = texcoord - float2(0.5+(texcoord.x*Green_X_Offset*ReShade::PixelSize.x*xyOffsets[i]),0.5+(texcoord.y*Green_Y_Offset*ReShade::PixelSize.y*xyOffsets[i]));
		BlueCoords = texcoord - float2(0.5+(texcoord.x*Blue_X_Offset*ReShade::PixelSize.x*xyOffsets[i]),0.5+(texcoord.y*Blue_Y_Offset*ReShade::PixelSize.y*xyOffsets[i]));
		
		if(RedFocalOffset == 0.000)
			{
				CA.r += tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).r*Weights[i]*0.5; //(Offset + (Offset*Offsets[i]))
				CA.r += tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).r*Weights[i]*0.5; //(Offset*0.1*Offsets[i])
			}
			else
			{
				CA.r += tex2D(ReShade::BackBuffer,(RedCoords*(1.0 + (Offsets[i]*RedFocalOffset*0.01))) + 0.5).r*Weights[i]; //((Offset + (Offset*Offsets[i]))*0.1)
			}
		
			if(GreenFocalOffset == 0.000)
			{
				CA.g += tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).g*Weights[i]*0.5;
				CA.g += tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).g*Weights[i]*0.5;
			}
			else
			{
				CA.g += tex2D(ReShade::BackBuffer,(GreenCoords*(1.0 + (Offsets[i]*GreenFocalOffset*0.01))) + 0.5).g*Weights[i];
			}
		
			if(BlueFocalOffset == 0.000)
			{
				CA.b += tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).b*Weights[i]*0.5;
				CA.b += tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offsets[i]*Offset*0.01))) + 0.5).b*Weights[i]*0.5;
			}
			else
			{
				CA.b += tex2D(ReShade::BackBuffer,(BlueCoords*(1.0 + (Offsets[i]*BlueFocalOffset*0.01))) + 0.5).b*Weights[i];
			}
		}
	}
  
	float3 orig = tex2D(ReShade::BackBuffer,texcoord).rgb;
		
	float2 distance_xy = texcoord - float2(0.5,0.5);
	distance_xy *= float2((ReShade::PixelSize.y / ReShade::PixelSize.x),LensShape);
	float dist = dot(distance_xy,distance_xy);
	dist = (1.0 - pow(dist,0.25));
	
	if(DebugMode == 1)
	{
		return smoothstep(0.0,LensFocus,dist);
	}
	
	CA = lerp(CA,orig,smoothstep(0.0,LensFocus,dist));
		
	return lerp(orig,CA,Strength);	
}

#if CA_Blurring == 1
float3 CA_Blur(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float3 color = tex2D(ReShade::BackBuffer,texcoord).rgb;
	float3 blur;
	
	if (CABlur == 1)
	{
		int sampleOffsetsX[5] = {  0.0, 	 1, 	  0, 	 1,     1};
		int sampleOffsetsY[5] = {  0.0,     0, 	  1, 	 1,    -1};	
		
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		blur = color*sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			blur += tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y)).rgb * sampleWeights[i];
			blur += tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y)).rgb * sampleWeights[i];
		}
	}
	
	if (CABlur == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		blur = color * sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			blur += tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y)).rgb * sampleWeights[i];
			blur += tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y)).rgb * sampleWeights[i];
		}
	}

	if (CABlur == 3)
	{
		float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		blur = color*sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			blur += tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y)).rgb * sampleWeights[i];
			blur += tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y)).rgb * sampleWeights[i];
		}
	}

	if (CABlur == 4)
	{
		float sampleOffsetsX[25] = { 				  0.0, 			       1.4584295168, 			 		   0, 	 		  1.4584295168,     	   	 1.4584295168,     		    3.4039848067,     		  			  0,     		 3.4039848067,     		   3.4039848067,     		 1.4584295168,    		   1.4584295168,     		  3.4039848067,     		  3.4039848067,		5.3518057801,			 0.0,	5.3518057801,	5.3518057801,   5.3518057801,	5.3518057801,	   1.4584295168,	    1.4584295168,	3.4039848067,	3.4039848067, 5.3518057801, 5.3518057801};
		float sampleOffsetsY[25] = {  				  0.0,   					   0, 	  		   1.4584295168, 	 		  1.4584295168,     		-1.4584295168,     					   0,     		   3.4039848067,     		    1.4584295168,    		     -1.4584295168,     	  3.4039848067,   	   -3.4039848067,     		  3.4039848067,    		     -3.4039848067, 		     0.0,	5.3518057801,	   1.4584295168,	  -1.4584295168,	3.4039848067,  -3.4039848067,	5.3518057801,	-5.3518057801,	5.3518057801,  -5.3518057801, 5.3518057801, -5.3518057801};
		float sampleWeights[25] = {0.05299184990795840687999609498603,              0.09256069846035847440860469965371,           0.09256069846035847440860469965371,           0.02149960564023589832299078385165,           0.02149960564023589832299078385165,                 0.05392678246987847562647201766774,              0.05392678246987847562647201766774,             0.01252588384627371007425549277902,             0.01252588384627371007425549277902,          0.01252588384627371007425549277902,         0.01252588384627371007425549277902,             0.00729770438775005041467389567467,               0.00729770438775005041467389567467, 	0.02038530184304811960185734706054,	0.02038530184304811960185734706054,	0.00473501127359426108157733854484,	0.00473501127359426108157733854484,	0.00275866461027743062478492361799,	0.00275866461027743062478492361799,	0.00473501127359426108157733854484,	 0.00473501127359426108157733854484,	0.00275866461027743062478492361799,	0.00275866461027743062478492361799, 0.00104282525148620420024312363461, 0.00104282525148620420024312363461};
		
		blur = color*sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 25; ++i) {
			blur += tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y)).rgb * sampleWeights[i];
			blur += tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y)).rgb * sampleWeights[i];
		}
		
	}
	
	float2 distance_xy = texcoord - float2(0.5,0.5);
	distance_xy *= float2((ReShade::PixelSize.y / ReShade::PixelSize.x),LensShape);
	float dist = dot(distance_xy,distance_xy);
	dist = (1.0 - pow(dist,0.25));
	
	if(DebugMode == 3)
	{
		return smoothstep(0.0,BlurFocus,dist);
	}
	
	blur = lerp(blur,color,smoothstep(0.0,BlurFocus,dist));
	
	return lerp(color,blur,BlurStrength);
}
#endif

#if CA_VignetteBlurring == 1
float3 CA_VignetteBlur(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
				
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float2 Coords = texcoord - float2(0.5,0.5);
	float3 blur;
	#define xyz 0.965551535
	
	if(VignetteBlur == 1)
	{
		float weight[3] = {0.5, 0.3, 0.2};
		float sampleOffsets[3] = { 0.9995, 0.999, 0.9985 };
		
		blur = color * weight[0];
		[loop]
		for(int i = 1; i < 3; ++i) {
			blur += (tex2D(ReShade::BackBuffer, (Coords*sampleOffsets[i])+0.5)).rgb*weight[i];	
		}
	}	
	
	if(VignetteBlur == 2)
	{
		float weight[5] = { 0.2879768, 0.46703928, 0.2001597, 0.04120935, 0.003614855 };
		float sampleOffsets[5] = { 0.999, 0.998, 0.997, 0.996, 0.995 };
		
		blur = color * weight[0];
		[loop]
		for(int i = 1; i < 5; ++i) {
			blur += (tex2D(ReShade::BackBuffer, (Coords*sampleOffsets[i])+0.5)).rgb*weight[i];	
		}
	}
	
	if(VignetteBlur == 3)
	{
		float weight[11] = {0.1486926, 0.1457586, 0.1372968, 0.1242738, 0.1080882, 0.0903366, 0.0725508, 0.055989, 0.0415188, 0.0295848, 0.0202572 };
		float sampleOffsets[11] = { 0.999, 0.998, 0.997, 0.996, 0.995, 0.994, 0.993, 0.992, 0.991, 0.990, 0.989 };
		
		blur = color * weight[0];
		[loop]
		for(int i = 1; i < 11; ++i) {
			blur += (tex2D(ReShade::BackBuffer, (Coords*sampleOffsets[i])+0.5)).rgb*weight[i];	
		}
	}
	
	if(VignetteBlur == 4)
	{
		float weight[21] = { 0.082607*xyz, 0.081792*xyz, 0.080977*xyz, 0.0786265*xyz, 0.076276*xyz, 0.0726585*xyz, 0.069041*xyz, 0.064545*xyz, 0.060049*xyz, 0.055118*xyz, 0.050187*xyz, 0.0452465*xyz, 0.040306*xyz, 0.0357055*xyz, 0.031105*xyz, 0.0270855*xyz, 0.023066*xyz, 0.019751*xyz, 0.016436*xyz, 0.013845*xyz, 0.011254*xyz };
		float sampleOffsets[21] = { 0.999, 0.998, 0.997, 0.996, 0.995, 0.994, 0.993, 0.992, 0.991, 0.990, 0.989, 0.988, 0.987,0.986, 0.985, 0.984, 0.983, 0.982, 0.981, 0.980, 0.979 };
		
		blur = color * weight[0];
		[loop]
		for(int i = 1; i < 21; ++i) {
			blur += (tex2D(ReShade::BackBuffer, (Coords*sampleOffsets[i])+0.5)).rgb*weight[i];	
		}
	}
	
	float2 distance_xy = texcoord - float2(0.5,0.5);
	distance_xy *= float2((ReShade::PixelSize.y / ReShade::PixelSize.x),LensShape);
	float dist = dot(distance_xy,distance_xy);
	dist = 1-(1.0 - pow(dist,0.25));
	
	if(DebugMode == 2)
	{
		return smoothstep(0.0,VignetteBlurFocus,dist);
	}
	
	color.rgb = lerp(blur,color,smoothstep(0.0,VignetteBlurFocus,dist));
	color.rgb = lerp(color,blur,VignetteBlurStrength);
	return color.rgb;
}
#endif
	
technique ChromaticAberration
{
	pass Offset
	{
		VertexShader = PostProcessVS;
		PixelShader = CA_Offset;
	}

#if CA_VignetteBlurring == 1
	pass Offset
	{
		VertexShader = PostProcessVS;
		PixelShader = CA_VignetteBlur;
	}
#endif

#if CA_Blurring == 1	
	pass Blur
	{
		VertexShader = PostProcessVS;
		PixelShader = CA_Blur;
	}
#endif
}
