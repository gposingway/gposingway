/*******************************************************************************
    Original authors: Jakob Wapenhensch (Jak0bW) and Pascal Gilcher / Marty McFly
    Modifications by: Vortigern

    License:
    Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)
    https://creativecommons.org/licenses/by-nc/4.0/

    Links to projects this was based on:
    https://github.com/JakobPCoder/ReshadeMotionEstimation
    https://gist.github.com/martymcmodding/69c775f844124ec2c71c37541801c053
*******************************************************************************/

#pragma once
#include "Includes/vort_Defs.fxh"
#include "Includes/vort_Filters.fxh"
#include "Includes/vort_Depth.fxh"
#include "Includes/vort_DownTex.fxh"
#include "Includes/vort_MotVectTex.fxh"
#include "Includes/vort_LDRTex.fxh"

namespace MotVect {

/*******************************************************************************
    Globals
*******************************************************************************/

#define MAX_MIP 6
#define MIN_MIP 1

#define CAT_MOT_VECT "Motion Vectors"

UI_FLOAT(
    CAT_MOT_VECT, UI_MV_WZMult, "Depth Delta Weight",
    "Enable Debug View and start rotating the camera\n"
    "Increase this value if your character/weapon is being covered by color",
    0.0, 5.0, 1.0
)

/*******************************************************************************
    Textures, Samplers
*******************************************************************************/

texture2D CurrFeatureTexVort { TEX_SIZE(MIN_MIP) TEX_RG16 MipLevels = 1 + MAX_MIP - MIN_MIP; };
texture2D PrevFeatureTexVort { TEX_SIZE(MIN_MIP) TEX_RG16 MipLevels = 1 + MAX_MIP - MIN_MIP; };

sampler2D sCurrFeatureTexVort { Texture = CurrFeatureTexVort; };
sampler2D sPrevFeatureTexVort { Texture = PrevFeatureTexVort; };

/*******************************************************************************
    Functions
*******************************************************************************/

float2 Rotate2D(float2 v, float4 r) { return float2(dot(v, r.xy), dot(v, r.zw)); }

float4 CalcLayer(VSOUT i, int mip, float2 total_motion)
{
    int feature_mip = max(0, mip - MIN_MIP);
    float2 texelsize = BUFFER_PIXEL_SIZE * exp2(feature_mip);
    float2 local_block[16]; // just use max size possible
    int block_size = mip > 1 ? 4 : 2;
    int block_area = block_size * block_size;

    float2 moments_local = 0;
    float2 moments_search = 0;
    float2 moments_cov = 0;

    //since we only use to sample the blocks now, offset by half a block so we can do it easier inline
    i.uv -= texelsize * (block_size / 2);

    [unroll]for(uint k = 0; k < block_area; k++)
    {
        float2 tuv = i.uv + float2(k % block_size, k / block_size) * texelsize;
        float2 t_local = Sample(sCurrFeatureTexVort, saturate(tuv), feature_mip).xy;
        float2 t_search = Sample(sPrevFeatureTexVort, saturate(tuv + total_motion), feature_mip).xy;

        local_block[k] = t_local;

        moments_local += t_local * t_local;
        moments_search += t_search * t_search;
        moments_cov += t_local * t_search;
    }

    float2 cossim = moments_cov * RSQRT(moments_local * moments_search);
    float best_sim = saturate(min(cossim.x, cossim.y));
    float variance = dot(sqrt(abs(moments_local * (block_area - 1) * RCP(block_area * block_area))), 1);

    float randseed = frac(GetNoise(i.uv) + (mip + MIN_MIP) * INV_PHI);
    float2 randdir; sincos(randseed * DOUBLE_PI, randdir.x, randdir.y);
    uint searches = mip + (mip % 2);

    while(searches-- > 0)
    {
        float2 local_motion = 0;
        uint samples = 4;

        while(samples-- > 0)
        {
            //rotate by 90 degrees
            randdir = float2(randdir.y, -randdir.x);

            float2 search_offset = randdir * texelsize;
            float2 search_center = i.uv + total_motion + search_offset;

            moments_search = 0;
            moments_cov = 0;

            [loop]for(uint k = 0; k < block_area; k++)
            {
                float2 tuv = search_center + float2(k % block_size, k / block_size) * texelsize;
                float2 t = Sample(sPrevFeatureTexVort, saturate(tuv), feature_mip).xy;

                moments_search += t * t;
                moments_cov += t * local_block[k];
            }

            cossim = moments_cov * RSQRT(moments_local * moments_search);
            float sim = saturate(min(cossim.x, cossim.y));

            if(sim < best_sim) continue;

            best_sim = sim;
            local_motion = search_offset;
        }

        total_motion += local_motion;
        randdir *= 0.5;
    }

    return float4(total_motion, variance, saturate(1.0 - acos(best_sim) / HALF_PI));
}

float2 AtrousUpscale(VSOUT i, int mip, sampler mot_samp)
{
    int feature_mip = max(0, mip - MIN_MIP);
    float2 texelsize = rcp(tex2Dsize(mot_samp));
    float randseed = frac(GetNoise(i.uv) + (mip + MIN_MIP) * INV_PHI);
    float2 rsc; sincos(randseed * HALF_PI, rsc.x, rsc.y);
    float4 rotator = float4(rsc.y, rsc.x, -rsc.x, rsc.y) * 4.0;
    float center_z = Sample(sCurrFeatureTexVort, i.uv, feature_mip).y;

    float2 gbuffer_sum = 0;
    float wsum = 1e-6;
    int rad = floor((mip + 2) * 0.5);

    [loop]for(int x = -rad; x <= rad; x++)
    [loop]for(int y = -rad; y <= rad; y++)
    {
        float2 sample_uv = saturate(i.uv + Rotate2D(float2(x, y), rotator) * texelsize);
        float4 sample_gbuf = Sample(mot_samp, sample_uv);
        float sample_z = Sample(sCurrFeatureTexVort, sample_uv, feature_mip).y;

        // depth delta
        float wz = saturate(abs(sample_z - center_z) * 200.0 * UI_MV_WZMult);

        // long motion vectors
        float wm = dot(sample_gbuf.xy, sample_gbuf.xy) * 4000.0;

        // blocks which had near 0 variance
        float wf = saturate(1.0 - sample_gbuf.z * 128.0);

        // bad block matching
        float ws = saturate(1.0 - sample_gbuf.w);

        float weight = exp2(-(wz + wm + wf + ws) * 4.0);

        weight *= all(saturate(sample_uv - sample_uv * sample_uv));
        gbuffer_sum += sample_gbuf.xy * weight;
        wsum += weight;
    }

    return gbuffer_sum / wsum;
}

/*******************************************************************************
    Shaders
*******************************************************************************/

void PS_WriteFeature(PS_ARGS2)
{
    float3 color = ApplyLinearCurve(Sample(sLDRTexVort, i.uv, MIN_MIP).rgb);

    o.x = dot(color, 0.333);
    o.y = GetLinearizedDepth(i.uv);
}

void PS_Motion6(PS_ARGS4) { o = CalcLayer(i, 6, Sample(sMotVectTexVort, i.uv).xy * 0.95); } // no upscaling for MAX_MIP
void PS_Motion5(PS_ARGS4) { o = CalcLayer(i, 5, AtrousUpscale(i, 5, sDownTexVort6)); }
void PS_Motion4(PS_ARGS4) { o = CalcLayer(i, 4, AtrousUpscale(i, 4, sDownTexVort5)); }
void PS_Motion3(PS_ARGS4) { o = CalcLayer(i, 3, AtrousUpscale(i, 3, sDownTexVort4)); }
void PS_Motion2(PS_ARGS4) { o = CalcLayer(i, 2, AtrousUpscale(i, 2, sDownTexVort3)); }
void PS_Motion1(PS_ARGS4) { o = CalcLayer(i, 1, AtrousUpscale(i, 1, sDownTexVort2)); }
void PS_Motion0(PS_ARGS2) { o = AtrousUpscale(i, 0, sDownTexVort1); } // only upscale for < MIN_MIP

/*******************************************************************************
    Passes
*******************************************************************************/

#define PASS_MOT_VECT \
    pass { VertexShader = PostProcessVS; PixelShader = MotVect::PS_WriteFeature; RenderTarget = MotVect::CurrFeatureTexVort; } \
    pass { VertexShader = PostProcessVS; PixelShader = MotVect::PS_Motion6; RenderTarget = DownTexVort6; } \
    pass { VertexShader = PostProcessVS; PixelShader = MotVect::PS_Motion5; RenderTarget = DownTexVort5; } \
    pass { VertexShader = PostProcessVS; PixelShader = MotVect::PS_Motion4; RenderTarget = DownTexVort4; } \
    pass { VertexShader = PostProcessVS; PixelShader = MotVect::PS_Motion3; RenderTarget = DownTexVort3; } \
    pass { VertexShader = PostProcessVS; PixelShader = MotVect::PS_Motion2; RenderTarget = DownTexVort2; } \
    pass { VertexShader = PostProcessVS; PixelShader = MotVect::PS_Motion1; RenderTarget = DownTexVort1; } \
    pass { VertexShader = PostProcessVS; PixelShader = MotVect::PS_Motion0; RenderTarget = MotVectTexVort; } \
    pass { VertexShader = PostProcessVS; PixelShader = MotVect::PS_WriteFeature; RenderTarget = MotVect::PrevFeatureTexVort; }

} // namespace end
