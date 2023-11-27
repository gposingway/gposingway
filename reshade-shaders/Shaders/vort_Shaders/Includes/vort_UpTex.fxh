#pragma once
#include "Includes/vort_Defs.fxh"

#if IS_DX9
    texture2D UpTexVortA { TEX_SIZE(1) TEX_RGBA16 };
    sampler2D sUpTexVortA { Texture = UpTexVortA; };

    texture2D UpTexVortB { TEX_SIZE(1) TEX_RGBA16 };
    sampler2D sUpTexVortB { Texture = UpTexVortB; };

    #define UpTexVort1 UpTexVortA
    #define UpTexVort2 UpTexVortB
    #define UpTexVort3 UpTexVortA
    #define UpTexVort4 UpTexVortB
    #define UpTexVort5 UpTexVortA
    #define UpTexVort6 UpTexVortB
    #define UpTexVort7 UpTexVortA
    #define UpTexVort8 UpTexVortB

    #define sUpTexVort1 sUpTexVortA
    #define sUpTexVort2 sUpTexVortB
    #define sUpTexVort3 sUpTexVortA
    #define sUpTexVort4 sUpTexVortB
    #define sUpTexVort5 sUpTexVortA
    #define sUpTexVort6 sUpTexVortB
    #define sUpTexVort7 sUpTexVortA
    #define sUpTexVort8 sUpTexVortB
#else
    texture2D UpTexVort1 { TEX_SIZE(1) TEX_RGBA16 };
    texture2D UpTexVort2 { TEX_SIZE(2) TEX_RGBA16 };
    texture2D UpTexVort3 { TEX_SIZE(3) TEX_RGBA16 };
    texture2D UpTexVort4 { TEX_SIZE(4) TEX_RGBA16 };
    texture2D UpTexVort5 { TEX_SIZE(5) TEX_RGBA16 };
    texture2D UpTexVort6 { TEX_SIZE(6) TEX_RGBA16 };
    texture2D UpTexVort7 { TEX_SIZE(7) TEX_RGBA16 };

    sampler2D sUpTexVort1 { Texture = UpTexVort1; };
    sampler2D sUpTexVort2 { Texture = UpTexVort2; };
    sampler2D sUpTexVort3 { Texture = UpTexVort3; };
    sampler2D sUpTexVort4 { Texture = UpTexVort4; };
    sampler2D sUpTexVort5 { Texture = UpTexVort5; };
    sampler2D sUpTexVort6 { Texture = UpTexVort6; };
    sampler2D sUpTexVort7 { Texture = UpTexVort7; };

    #if BUFFER_HEIGHT >= 2160
        texture2D UpTexVort8 { TEX_SIZE(8) TEX_RGBA16 };
        sampler2D sUpTexVort8 { Texture = UpTexVort8; };
    #endif
#endif
