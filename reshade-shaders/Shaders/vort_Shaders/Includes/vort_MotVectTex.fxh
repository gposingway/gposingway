#pragma once
#include "Includes/vort_Defs.fxh"

texture2D MotVectTexVort { TEX_SIZE(0) TEX_RG16 };
sampler2D sMotVectTexVort { Texture = MotVectTexVort; };
