/*------------------.
| :: Description :: |
'-------------------/

	DropShadow

	Authors: CeeJay.dk, seri14, Marot Satil, Uchu Suzume, prod80, originalnicodr
	License: MIT

	See DropShadow.fx for more information.


	The MIT License (MIT)

	Copyright (c) 2014 CeeJayDK

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/

#define DROPSHADOW_SUMMONING(DropShadow_Texture, DropShadow_Sampler, DropShadowCategory, fTargetDepth, fColor, fPosX, fPosY, DROPSHADOW_SCALE, fScaleX, fScaleY, fCutoffMaxX, fCutoffMinX, fCutoffMaxY, fCutoffMinY, iSnapRotate, iRotate, PS_DropShadowBack, PS_DropShadow, DROPSHADOW_TECHNIQUE) \
texture DropShadow_Texture { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; }; \
sampler DropShadow_Sampler { \
	Texture = DropShadow_Texture; \
	AddressU = CLAMP; \
	AddressV = CLAMP; \
}; \
\
uniform float fTargetDepth < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "Target Depth"; \
	ui_min = 0.0; \
	ui_max = 1.0; \
	ui_step = 0.0001; \
> = 0.02; \
\
uniform float4 fColor <  \
	ui_category = DropShadowCategory; \
	ui_label = "Color"; \
	ui_type = "color"; \
> = float4(0, 1.0, 0, 1.0); \
\
uniform float fPosX < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "Position X"; \
	ui_min = -2.0; ui_max = 2.0; \
	ui_step = 0.001; \
> = 0.505; \
\
uniform float fPosY < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "Position Y"; \
	ui_min = -2.0; ui_max = 2.0; \
	ui_step = 0.001; \
> = 0.5; \
\
uniform float DROPSHADOW_SCALE < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "Scale X & Y"; \
	ui_min = 0.001; ui_max = 5.0; \
	ui_step = 0.001; \
> = 1.001; \
\
uniform float fScaleX < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "Scale X"; \
	ui_min = 0.001; ui_max = 5.0; \
	ui_step = 0.001; \
> = 1.0; \
\
uniform float fScaleY < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "Scale Y"; \
	ui_min = 0.001; ui_max = 5.0; \
	ui_step = 0.001; \
> = 1.0; \
\
uniform float fCutoffMaxX < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "X Cutoff Max"; \
	ui_min = 0.001; ui_max = 1.0; \
	ui_step = 0.001; \
> = 1.0; \
\
uniform float fCutoffMinX < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "X Cutoff Min"; \
	ui_min = 0.001; ui_max = 1.0; \
	ui_step = 0.001; \
> = 0.0; \
\
uniform float fCutoffMaxY < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "Y Cutoff Max"; \
	ui_min = 0.001; ui_max = 1.0; \
	ui_step = 0.001; \
> = 1.0; \
\
uniform float fCutoffMinY < \
	ui_category = DropShadowCategory; \
	ui_type = "slider"; \
	ui_label = "Y Cutoff Min"; \
	ui_min = 0.001; ui_max = 1.0; \
	ui_step = 0.001; \
> = 0.0; \
\
uniform int iSnapRotate < \
	ui_category = DropShadowCategory; \
	ui_type = "combo"; \
	ui_label = "Snap Rotation"; \
	ui_items = "None\0" \
			   "90 Degrees\0" \
			   "-90 Degrees\0" \
			   "180 Degrees\0" \
			   "-180 Degrees\0"; \
	ui_tooltip = "Snap rotation to a specific angle."; \
> = false; \
\
uniform float iRotate < \
	ui_category = DropShadowCategory; \
	ui_label = "Rotate"; \
	ui_type = "slider"; \
	ui_min = -180.0; \
	ui_max = 180.0; \
	ui_step = 0.01; \
> = 0; \
\
void PS_DropShadowBack(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) { \
	if (ReShade::GetLinearizedDepth(texCoord) < fTargetDepth) \
	{ \
		passColor = fColor; \
	} \
	else \
	{ \
		passColor = 0.0; \
	} \
} \
\
void PS_DropShadow(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) { \
	if (ReShade::GetLinearizedDepth(texCoord) > fTargetDepth && \
	texCoord.x <= fCutoffMaxX && \
	texCoord.x >= fCutoffMinX && \
	texCoord.y <= fCutoffMaxY && \
	texCoord.y >= fCutoffMinY) \
	{ \
		const float3 pivot = float3(0.5, 0.5, 0.0); \
		const float3 mulUV = float3(texCoord.x, texCoord.y, 1); \
		const float2 ScaleSize = (float2(BUFFER_WIDTH, BUFFER_HEIGHT) * DROPSHADOW_SCALE); \
		const float ScaleX =  ScaleSize.x * fScaleX; \
		const float ScaleY =  ScaleSize.y * fScaleY; \
		float Rotate = iRotate * (3.1415926 / 180.0); \
\
		switch(iSnapRotate) \
		{ \
			default: \
				break; \
			case 1: \
				Rotate = -90.0 * (3.1415926 / 180.0); \
				break; \
			case 2: \
				Rotate = 90.0 * (3.1415926 / 180.0); \
				break; \
			case 3: \
				Rotate = 0.0; \
				break; \
			case 4: \
				Rotate = 180.0 * (3.1415926 / 180.0); \
				break; \
		} \
\
		const float3x3 positionMatrix = float3x3 ( \
			1, 0, 0, \
			0, 1, 0, \
			-fPosX, -fPosY, 1 \
		); \
		const float3x3 scaleMatrix = float3x3 ( \
			1/ScaleX, 0, 0, \
			0,  1/ScaleY, 0, \
			0, 0, 1 \
		); \
		const float3x3 rotateMatrix = float3x3 ( \
			cos (Rotate), -sin(Rotate), 0, \
			sin(Rotate), cos(Rotate), 0, \
			0, 0, 1 \
		); \
\
		const float3 SumUV = mul (mul (mul (mulUV, positionMatrix) * float3(BUFFER_SCREEN_SIZE, 1.0), rotateMatrix), scaleMatrix); \
		const float4 backColor = tex2D(ReShade::BackBuffer, texCoord); \
		passColor = tex2D(DropShadow_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot)); \
		 \
		passColor = lerp(backColor.rgb, passColor.rgb, passColor.a); \
	} \
	else \
	{ \
		discard; \
	} \
} \
\
\
technique DROPSHADOW_TECHNIQUE { \
	pass \
	{ \
		VertexShader = PostProcessVS; \
		PixelShader  = PS_DropShadowBack; \
		RenderTarget = DropShadow_Texture; \
	} \
	pass \
	{ \
		VertexShader = PostProcessVS; \
		PixelShader  = PS_DropShadow; \
	} \
} \