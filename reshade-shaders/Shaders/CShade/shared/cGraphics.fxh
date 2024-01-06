#include "cMacros.fxh"

#if !defined(CGRAPHICS_FXH)
    #define CGRAPHICS_FXH

    /*
        [Buffer]
    */

    texture2D CShade_ColorTex : COLOR;

    sampler2D CShade_SampleColorTex
    {
        Texture = CShade_ColorTex;
        MagFilter = LINEAR;
        MinFilter = LINEAR;
        MipFilter = LINEAR;
        SRGBTexture = READ_SRGB;
    };

    sampler2D CShade_SampleGammaTex
    {
        Texture = CShade_ColorTex;
        MagFilter = LINEAR;
        MinFilter = LINEAR;
        MipFilter = LINEAR;
        SRGBTexture = FALSE;
    };

    /*
        [Simple Vertex Shader]
    */

    struct APP2VS
    {
        uint ID : SV_VERTEXID;
    };

    struct VS2PS_Quad
    {
        float4 HPos : SV_POSITION;
        float2 Tex0 : TEXCOORD0;
    };

    VS2PS_Quad VS_Quad(APP2VS Input)
    {
        VS2PS_Quad Output;
        Output.Tex0.x = (Input.ID == 2) ? 2.0 : 0.0;
        Output.Tex0.y = (Input.ID == 1) ? 2.0 : 0.0;
        Output.HPos = float4(Output.Tex0 * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
        return Output;
    }

    /*
        [Math Functions]
    */

    int GetFactorial(int N)
    {
        int O = N;
        for (int i = 1 ; i < N; i++)
        {
            O *= i;
        }
        return O;
    }

    float4 GetBlit(VS2PS_Quad Input, sampler2D SampleSource)
    {
        return tex2D(SampleSource, Input.Tex0);
    }

    float GetMod(float X, float Y)
    {
        return X - Y * floor(X / Y);
    }

    float2 GetLOD(float2 Tex)
    {
        float2 Ix = ddx(Tex);
        float2 Iy = ddy(Tex);
        float Lx = dot(Ix, Ix);
        float Ly = dot(Iy, Iy);
        return float2(0.0, 0.5) * max(0.0, log2(max(Lx, Ly)));
    }
#endif