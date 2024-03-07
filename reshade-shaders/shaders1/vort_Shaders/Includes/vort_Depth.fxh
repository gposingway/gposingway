#pragma once
#include "Includes/vort_Defs.fxh"

texture2D DepthTexVort : DEPTH;
sampler2D sDepthTexVort { Texture = DepthTexVort; };

float GetLinearizedDepth(float2 texcoord)
{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
    texcoord.y = 1.0 - texcoord.y;
#endif
    texcoord.x /= RESHADE_DEPTH_INPUT_X_SCALE;
    texcoord.y /= RESHADE_DEPTH_INPUT_Y_SCALE;
#if RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
    texcoord.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
#else // Do not check RESHADE_DEPTH_INPUT_X_OFFSET, since it may be a decimal number, which the preprocessor cannot handle
    texcoord.x -= RESHADE_DEPTH_INPUT_X_OFFSET / 2.000000001;
#endif
#if RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
    texcoord.y += RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
#else
    texcoord.y += RESHADE_DEPTH_INPUT_Y_OFFSET / 2.000000001;
#endif
    float depth = Sample(sDepthTexVort, texcoord).x * RESHADE_DEPTH_MULTIPLIER;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
    static const float C = 0.01;
    depth = (exp(depth * LOG(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
    depth = 1.0 - depth;
#endif
    static const float N = 1.0;
    depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

    return saturate(depth);
}

float3 GetScreenSpaceNormal(float2 uv)
{
    float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
    float2 posCenter = uv;
    float2 posNorth = posCenter - offset.zy;
    float2 posEast = posCenter + offset.xz;

    float3 vertCenter = float3(posCenter - 0.5, 1) * GetLinearizedDepth(posCenter);
    float3 vertNorth = float3(posNorth - 0.5, 1) * GetLinearizedDepth(posNorth);
    float3 vertEast = float3(posEast - 0.5, 1) * GetLinearizedDepth(posEast);

    return NORMALIZE(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}
