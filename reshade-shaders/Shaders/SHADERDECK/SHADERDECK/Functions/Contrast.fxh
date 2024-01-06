float3 ContrastCurve(float3 colorInput, int Contrast)
{
	float3 lumCoeff = float3(0.2126, 0.7152, 0.0722);  //Values to calculate luma with
	float Contrast_blend = Contrast; 
	const float PI = 3.1415927;

	/*-----------------------------------------------------------.
	/               Separation of Luma and Chroma                 /
	'-----------------------------------------------------------*/

	// -- Calculate Luma and Chroma if needed --
	//calculate luma (grey)
	float luma = dot(lumCoeff, colorInput.rgb);
	//calculate chroma
	float3 chroma = colorInput.rgb - luma;

	// -- Which value to put through the contrast formula? --
	// I name it x because makes it easier to copy-paste to Graphtoy or Wolfram Alpha or another graphing program
	float3 x;
	x = luma; //if the curve should be applied to Luma
    x = x - 0.5;
    x = (x / (0.5 + abs(x))) + 0.5;

	x = lerp(luma, x, Contrast_blend * 0.02); //Blend by Contrast
	colorInput.rgb = x + chroma; //Luma + Chroma

	return saturate(colorInput);
}