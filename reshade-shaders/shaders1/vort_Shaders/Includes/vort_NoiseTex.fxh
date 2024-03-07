#pragma once
#include "Includes/vort_Defs.fxh"

texture2D GaussNoiseTexVort < source = "vort_GaussianNoise.png"; > { Width = 512; Height = 512; TEX_RGBA8 };
sampler2D sGaussNoiseTexVort { Texture = GaussNoiseTexVort; SAM_POINT SAM_WRAP };
