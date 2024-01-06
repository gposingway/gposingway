#pragma once
#include "Includes/vort_Defs.fxh"

namespace MotVectUtils {

/*******************************************************************************
    Globals
*******************************************************************************/

#ifndef V_MOT_VECT_DEBUG
    #define V_MOT_VECT_DEBUG 0
#endif

/*******************************************************************************
    Functions
*******************************************************************************/

float3 Debug(float2 uv, sampler mot_samp, float mult)
{
    float2 motion = Sample(mot_samp, uv).xy * mult;
    float angle = atan2(motion.y, motion.x);
    float3 rgb = saturate(3 * abs(2 * frac(angle / DOUBLE_PI + float3(0, -1.0/3.0, 1.0/3.0)) - 1) - 1);

    return lerp(0.5, rgb, saturate(length(motion) * 100));
}

} // namespace end
