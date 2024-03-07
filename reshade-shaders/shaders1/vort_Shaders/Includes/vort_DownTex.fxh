#pragma once
#include "Includes/vort_Defs.fxh"

texture2D DownTexVort1 { TEX_SIZE(1) TEX_RGBA16 };
texture2D DownTexVort2 { TEX_SIZE(2) TEX_RGBA16 };
texture2D DownTexVort3 { TEX_SIZE(3) TEX_RGBA16 };
texture2D DownTexVort4 { TEX_SIZE(4) TEX_RGBA16 };
texture2D DownTexVort5 { TEX_SIZE(5) TEX_RGBA16 };
texture2D DownTexVort6 { TEX_SIZE(6) TEX_RGBA16 };
texture2D DownTexVort7 { TEX_SIZE(7) TEX_RGBA16 };
texture2D DownTexVort8 { TEX_SIZE(8) TEX_RGBA16 };

sampler2D sDownTexVort1 { Texture = DownTexVort1; };
sampler2D sDownTexVort2 { Texture = DownTexVort2; };
sampler2D sDownTexVort3 { Texture = DownTexVort3; };
sampler2D sDownTexVort4 { Texture = DownTexVort4; };
sampler2D sDownTexVort5 { Texture = DownTexVort5; };
sampler2D sDownTexVort6 { Texture = DownTexVort6; };
sampler2D sDownTexVort7 { Texture = DownTexVort7; };
sampler2D sDownTexVort8 { Texture = DownTexVort8; };

#if BUFFER_HEIGHT >= 2160
    texture2D DownTexVort9 { TEX_SIZE(9) TEX_RGBA16 };
    sampler2D sDownTexVort9 { Texture = DownTexVort9; };
#endif
