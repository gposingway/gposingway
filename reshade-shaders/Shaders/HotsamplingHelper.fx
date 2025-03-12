///////////////////////////////////////////////////////////////////////////////
//
//ReShade Shader: HotsamplingHelper
//https://github.com/Daodan317081/reshade-shaders
//
//BSD 3-Clause License
//
//Copyright (c) 2018-2019, Alexander Federwisch
//All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//
//* Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//* Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//* Neither the name of the copyright holder nor the names of its
//  contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
///////////////////////////////////////////////////////////////////////////////
//
// Version History:
// 15-nov-2018:     v1.0.0
//
// Lightly optimized by Marot Satil for the GShade project.
///////////////////////////////////////////////////////////////////////////////

#include "ReShade.fxh"

uniform float2 fUIOverlayPos <
	ui_type = "slider";
	ui_label = "Overlay Position";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = float2(0.5, 0.5);

uniform float fUIOverlayScale <
    ui_type = "slider";
    ui_label = "Overlay Scale";
    ui_min = 0.1; ui_max = 1.0;
    ui_step = 0.001;
> = 0.2;

float3 HotsamplingHelperPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {

    const float2 overlayPos = fUIOverlayPos * (1.0 - fUIOverlayScale) * BUFFER_SCREEN_SIZE;

    if(all(vpos.xy >= overlayPos) && all(vpos.xy < overlayPos + BUFFER_SCREEN_SIZE * fUIOverlayScale))
    {
        texcoord = frac((texcoord - overlayPos / BUFFER_SCREEN_SIZE) / fUIOverlayScale);
    }

    return tex2D(ReShade::BackBuffer, texcoord).rgb;
}

technique HotsamplingHelper {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = HotsamplingHelperPS;
        /* RenderTarget = BackBuffer */
    }
}