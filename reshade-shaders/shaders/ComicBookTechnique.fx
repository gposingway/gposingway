// Reshade FX Comic Book Shader

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform float RESOLUTION_X = 3840.0; // Adjust to match your screen resolution
uniform float RESOLUTION_Y = 2160.0; // Adjust to match your screen resolution




// Define the size and spacing of the halftone dots
uniform float dotSize <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 500;
	ui_step = 2.0;
	ui_category = "Halftoning";
>;


uniform float dotSpacing <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 100.0;
	ui_step = 2.0;
	ui_tooltip = "lower values means closer dots";
	ui_category = "Halftoning";
>;


uniform float dotCutoff <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 50;
	ui_step = 1;
	ui_tooltip = "higher value isolate the dots to the highlights more";
	ui_category = "Halftoning";
>;


uniform float dotStrength <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.1;
	ui_tooltip = "lower values decrese opacity";
	ui_category = "Halftoning";
>;

uniform float dotClamp <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 20;
	ui_step = .5;
	ui_tooltip = "clamps the maximum dot size to avoid overlapping";
	ui_category = "Halftoning";
>;




uniform float hashWidth <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 5.0;
	ui_step = 0.1;
	ui_tooltip = "increases the thickness of the hashing";
	ui_category = "Hashing";
>;

uniform float hashAmount <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 200.0;
	ui_step = 5;
	ui_tooltip = "increases the thickness of the hashing";
	ui_category = "Hashing";
>;


uniform float hashCutoff <
	ui_type = "drag";
	ui_min = 0;
	ui_max = 50;
	ui_step = .5;
	ui_tooltip = "lower values bring the hashing into more of the image";
	ui_category = "Hashing";
>;


uniform float hashOpacity <
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.1;
	ui_tooltip = "lower values decrese opacity";
	ui_category = "Hashing";
>;



uniform float saturation <
        ui_label = "Saturation";
        ui_tooltip = "Saturation";
        ui_category = "Final Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;

uniform int UIHELP <
	ui_type = "radio";
	ui_label = " ";	
	ui_text ="\nGood Starting Settings:\n"
	"\n"
	"dotSize = 30\n"
	"dotSpacing = 14\n"
	"dotCutoff = 20\n"
	"dotStrength = 0.3\n"
	"dotClamp = 6.5\n"
	"\n"
	"hashWidth = 0.6\n"
	"hashAmount = 90\n"
	"hashCutoff = 11\n"
	"hashOpacity = .8";
	ui_category_closed = false;
>;





float4 PS_Main(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float4 color = tex2D(ReShade::BackBuffer, texcoord); // Get the input color    
    
    float3 reshadeLuminacne = float3(0.2126, 0.7152, 0.0722);
    // Calculate the grayscale value of the color
    float grayscale = dot(color.rgb, reshadeLuminacne);
    
    
    
    
    
    //DOTSSSSSSS: 
    
    float2 dotPosition = texcoord * float2(RESOLUTION_X, RESOLUTION_Y);
    
    float2 dotCoords = floor(dotPosition / dotSpacing) * dotSpacing + dotSpacing / 2.0;
    float2 delta = dotPosition - dotCoords;
    
    float distance = length(delta);
    float dotRadius = dotSize;
    
    
	
	float dotGrayscale = pow(abs(grayscale), dotCutoff);
	
    dotRadius *= dotGrayscale;
    dotRadius = clamp(dotRadius, 0, dotClamp);

    //find color of dots
    float3 dotColor = smoothstep(dotRadius, dotRadius - 1.0, distance) * color.rgb;
    
    
    
    
    
    //HASHHHHHHH:
    
    // Normalized pixel coordinates (from 0 to 1)
    float2 uv = .005 * texcoord * RESOLUTION_Y * hashAmount;
    
    uv.y += -uv.x;
    uv.x = uv.x % 0.01;
    
    // Time varying pixel color
    float3 col = cos(float3(uv.x, uv.y, 0));
    
    // Calculate the grayscale value of the color
    float3 hashGrayscale = dot(col.rgb, float3(0.2126, 0.7152, 0.0722));
    
    hashGrayscale = hashGrayscale > (grayscale * hashCutoff) - hashWidth ? hashOpacity : 0;
    
    float3 hashColor = color.rgb - hashGrayscale;
    
    
    
    
    
    // Add the isolated highlights and diagonal hash marks back into the original image
    float4 finalColor = float4((color.rgb + clamp(dotColor, 0, dotStrength) + hashColor) / 2.0, color.a);
	
	finalColor = saturate( lerp( grayscale, finalColor.rgb, saturation + 1.0f ));
    return float4(finalColor);
}



technique TrueSpiderVerse
{
    pass P0
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Main;
    }
}
