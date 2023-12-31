/*------------------.
| :: Description :: |
'-------------------/

Interlaced effect PS (version 1.0.4)

Copyright:
This code © 2018-2023 Jakub Maksymilian Fober
(blending fix thanks to Marty McFly)

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

/*---------------.
| :: Uniforms :: |
'---------------*/

uniform int FrameCount < source = "framecount"; >;

/*---------------.
| :: Textures :: |
'---------------*/

// Previous frame render target buffer
texture InterlacedTargetBuffer
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
};
sampler InterlacedBufferSampler
{
	Texture = InterlacedTargetBuffer;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
};

/*--------------.
| :: Shaders :: |
'--------------*/

// Preserve previous frame
void InterlacedTargetPass(
	float4 vpos       : SV_Position,
	float2 UvCoord    : TEXCOORD,
	out float4 Target : SV_Target
)
{
	// Interlaced rows boolean
	bool OddPixel = frac(int(BUFFER_SCREEN_SIZE.y * UvCoord.y) * 0.5) != 0f;
	bool OddFrame = frac(FrameCount * 0.5) != 0.0;
	bool BottomHalf = UvCoord.y > 0.5;

	// Flip flop saving texture between top and bottom half of the RenderTarget
	float2 Coordinates;
	Coordinates.x = UvCoord.x;
	Coordinates.y = UvCoord.y * 2f;
	// Adjust flip flop coordinates
	float hPixelSizeY = ReShade::PixelSize.y * 0.5;
	Coordinates.y -= BottomHalf ? 1f + hPixelSizeY : hPixelSizeY;
	// Flip flop save to Render Target texture
	Target = (OddFrame ? BottomHalf : UvCoord.y < 0.5) ?
		float4(tex2D(ReShade::BackBuffer, Coordinates).rgb, 1f) : 0f;
	// Outputs raw BackBuffer to InterlacedTargetBuffer for the next frame
}

// Combine previous and current frame
void InterlacedPS(
	float4 vpos      : SV_Position,
	float2 UvCoord   : TEXCOORD,
	out float3 Image : SV_Target
)
{
	// Interlaced rows boolean
	bool OddPixel = frac(int(BUFFER_SCREEN_SIZE.y * UvCoord.y) * 0.5) != 0f;
	bool OddFrame = frac(FrameCount * 0.5) != 0f;
	// Calculate coordinates of BackBuffer texture saved at previous frame
	float2 Coordinates = float2(UvCoord.x, UvCoord.y * 0.5);
	float qPixelSizeY = ReShade::PixelSize.y * 0.25;
	Coordinates.y += OddFrame ? qPixelSizeY : qPixelSizeY + 0.5;
	// Sample odd and even rows
	Image = OddPixel ? tex2D(ReShade::BackBuffer, UvCoord).rgb
	: tex2D(InterlacedBufferSampler, Coordinates).rgb;
}

/*-------------.
| :: Output :: |
'-------------*/

technique Interlaced
<
	ui_tooltip =
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 4.0";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = InterlacedTargetPass;
		RenderTarget = InterlacedTargetBuffer;
		ClearRenderTargets = false;
		BlendEnable = true;
			BlendOp = ADD; //mimic lerp
				SrcBlend = SRCALPHA;
				DestBlend = INVSRCALPHA;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = InterlacedPS;
	}
}
