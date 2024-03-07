#pragma once
#include "Includes/vort_Defs.fxh"

texture2D LDRTexVort : COLOR;
sampler2D sLDRTexVort { Texture = LDRTexVort; SRGBTexture = IS_SRGB && IS_8BIT && V_USE_HW_LIN; };
