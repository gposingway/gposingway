/**
 * AS_VFX_VolumetricLight.1.fx - 2D Volumetric Light Shafts with Depth Occlusion and Color Selection
 * Author: Leon Aquitaine
 * Based on: 'fake volumetric 2d light wip' by int_45h (https://www.shadertoy.com/view/wftXzr)
 * License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
 * You are free to use, share, and adapt this shader for non-commercial purposes only, as long as you provide attribution and distribute any derivative works under the same license.
 * Commercial use is NOT permitted.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates 2D volumetric light shafts (god rays) of a selectable color, emanating from a user-defined light source.
 * The light source is considered to be at the specified 'EffectDepth'. Rays and direct light contributions are 
 * occluded by scene geometry closer to the camera than 'EffectDepth'.
 *
 * FEATURES:
 * - Interactive light source positioning with depth-based occlusion
 * - User-selectable light color via palette system or custom colors
 * - Adjustable light brightness, ray length, and number of ray samples
 * - Audio reactivity for light brightness, ray length, and jitter animation speed
 * - Optional direct lighting on scene elements behind the depth plane
 * - Standard blending options for final composite
 * - Resolution-independent rendering
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Threshold Pass: Calculates light intensity and occlusion based on distance from light source
 *    and scene depth, storing the result in a temporary buffer for ray sampling.
 * 2. Blur & Composite Pass: Samples light intensity along rays from each pixel toward the light source,
 *    applies user-selected colors, and composites the final god rays with the original scene.
 * 3. Audio Integration: Light brightness, ray length, and animation speed can react to audio input
 *    for dynamic, music-synchronized lighting effects.
 *
 * ===================================================================================
 */

#ifndef __AS_VFX_VolumetricLight_1_fx
#define __AS_VFX_VolumetricLight_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// Constants
// ============================================================================
static const float RAY_ATTENUATION_CURVE = 0.45; // Controls how rays fade along their length

// ============================================================================
// Render Target Textures & Samplers
// ============================================================================
texture VolumetricLight_ThresholdBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler VolumetricLight_ThresholdSampler { Texture = VolumetricLight_ThresholdBuffer; };

// ============================================================================
// UI Declarations
// ============================================================================

// Tunable Constants

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'fake volumetric 2d light wip' by int_45h\nLink: https://www.shadertoy.com/view/wftXzr\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform float LightBrightness < ui_type = "slider"; ui_label = "Light Source Brightness"; ui_tooltip = "Intensity of the light source for rays."; ui_min = 0.01; ui_max = 0.5; ui_category = "Tunable Constants"; > = 0.1;
uniform float ObjectLightFactor < ui_type = "slider"; ui_label = "Object Direct Light Factor"; ui_tooltip = "How much direct light illuminates objects close to the source."; ui_min = 0.0; ui_max = 0.2; ui_category = "Tunable Constants"; > = 0.05;
uniform float LightThresholdMin < ui_type = "slider"; ui_label = "Ray Visibility Threshold Min"; ui_min = 0.0; ui_max = 1.0; ui_category = "Tunable Constants"; > = 0.5;
uniform float LightThresholdMax < ui_type = "slider"; ui_label = "Ray Visibility Threshold Max"; ui_min = 0.0; ui_max = 1.0; ui_category = "Tunable Constants"; > = 0.51;

// Palette & Style
AS_PALETTE_SELECTION_UI(LightColorPalette, "Light Color Source", AS_PALETTE_CUSTOM, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(LightRay, "Palette & Style")

// Effect-Specific Parameters
uniform int RaySteps < ui_type = "slider"; ui_label = "Ray Sample Steps"; ui_tooltip = "Number of samples along each ray. Higher is smoother but more expensive."; ui_min = 5; ui_max = 120; ui_category = "Ray Properties"; > = 30;
uniform float RayLength < ui_type = "slider"; ui_label = "Ray Length Multiplier"; ui_tooltip = "Controls the length of the light rays."; ui_min = 0.05; ui_max = 0.5; ui_category = "Ray Properties"; > = 0.25;

// Animation Controls
uniform float RayRandomTimeScale < ui_type = "slider"; ui_label = "Ray Jitter Animation Speed"; ui_tooltip = "Speed of the random jitter animation for rays."; ui_min = 0.0; ui_max = 2000.0; ui_category = "Animation"; > = 1000.0;

// Audio Reactivity
uniform int AudioSource < ui_type = "combo"; ui_label = "Audio Source"; ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0Mid\0"; ui_category = "Audio Reactivity"; ui_category_closed = true; > = 3;
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_items = "None\0Light Brightness\0Ray Length\0Jitter Speed\0"; ui_category = "Audio Reactivity"; ui_category_closed = true; > = 0;
uniform float AudioMultiplier < ui_type = "slider"; ui_label = "Audio Multiplier"; ui_min = 0.0; ui_max = 2.0; ui_category = "Audio Reactivity"; ui_category_closed = true; > = 1.0;

// Stage/Position Controls
AS_POS_UI(LightSourcePos)
AS_STAGEDEPTH_UI(EffectDepth)

// Final Mix (Blend)
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// Helper Functions
// ============================================================================
float2 GetAspectCorrectedCenteredUV(float2 tc)
{
    float2 uv = tc - 0.5;
    if (ReShade::AspectRatio >= 1.0) 
    {
        uv.x *= ReShade::AspectRatio;
    }
    else 
    {
        uv.y /= ReShade::AspectRatio;
    }
    return uv;
}

// ============================================================================
// Pixel Shader: Threshold Pass
// ============================================================================
float4 PS_VolumetricLight_Threshold(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target0
{
    // Apply audio reactivity to light brightness
    float lightBrightness_final = LightBrightness;
    if (AudioTarget == 1) {
        float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true);
        lightBrightness_final = LightBrightness * audioValue;
    }

    float2 uvn = GetAspectCorrectedCenteredUV(texcoord);

    float2 light_pos_centered = LightSourcePos * 0.5;
    if (ReShade::AspectRatio >= 1.0) light_pos_centered.x *= ReShade::AspectRatio;
    else light_pos_centered.y /= ReShade::AspectRatio;

    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float depth_occlusion_factor = saturate(smoothstep(EffectDepth - AS_DEPTH_EPSILON, EffectDepth + AS_DEPTH_EPSILON, sceneDepth));

    float dist_sq = dot(uvn - light_pos_centered, uvn - light_pos_centered);
    float base_f_atten = lightBrightness_final / (dist_sq + AS_EPSILON);
    float f_atten = base_f_atten * depth_occlusion_factor;
    
    float4 scene_sample = tex2D(ReShade::BackBuffer, texcoord); 

    float3 face_lighting_contribution = clamp(ObjectLightFactor * f_atten, 0.0, ObjectLightFactor * 0.5) * scene_sample.rgb;
    float background_heuristic = 1.0 - saturate(scene_sample.a + dot(scene_sample.rgb, float3(0.33,0.33,0.33)));
    float3 final_color_rgb_part = lerp(face_lighting_contribution, float3(f_atten, f_atten, f_atten), background_heuristic);
    
    float ray_alpha_base = lerp(0.0, smoothstep(LightThresholdMin, LightThresholdMax, f_atten), background_heuristic);
    
    return float4(final_color_rgb_part, ray_alpha_base);
}

// ============================================================================
// Pixel Shader: Radial Blur & Composite Pass
// ============================================================================
float4 PS_VolumetricLight_Composite(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target0
{
    // Apply audio reactivity to ray parameters
    float rayLength_final = RayLength;
    float rayTimeScale_final = RayRandomTimeScale;
    
    if (AudioTarget == 2) {
        float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true);
        rayLength_final = RayLength * audioValue;
    } else if (AudioTarget == 3) {
        float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true);
        rayTimeScale_final = RayRandomTimeScale * audioValue;
    }

    float2 uvn = GetAspectCorrectedCenteredUV(texcoord); 

    float2 light_pos_centered = LightSourcePos * 0.5;
    if (ReShade::AspectRatio >= 1.0) light_pos_centered.x *= ReShade::AspectRatio;
    else light_pos_centered.y /= ReShade::AspectRatio;

    float4 accumulated_rays = float4(0.0, 0.0, 0.0, 0.0);
    float current_time_seed = AS_mod(AS_getTime() * rayTimeScale_final, 200.0);

    float2 dir_to_light = normalize(light_pos_centered - uvn);
    
    // Get the chosen light color
    float3 chosen_light_color;
    if (LightColorPalette == AS_PALETTE_CUSTOM)
    {
        chosen_light_color = LightRayCustomPaletteColor0; // Use the first custom color
    }
    else
    {
        // For predefined palettes, use the first color as a solid light color.
        chosen_light_color = AS_getPaletteColor(LightColorPalette, 0); 
    }

    for (int i = 0; i < RaySteps; i++)
    {
        float ray_progress = (float(i) / float(RaySteps));
        float2 sample_offset_along_ray = dir_to_light * ray_progress * rayLength_final;
        
        float2 random_jitter = (AS_hash22(pos.xy + current_time_seed + float(i)) - 0.5) * 0.01 * rayLength_final;

        float2 sample_pos_centered = uvn + sample_offset_along_ray + random_jitter;
        
        float2 sample_tc = sample_pos_centered;
        if (ReShade::AspectRatio >= 1.0) 
        {
            sample_tc.x /= ReShade::AspectRatio;
        }
        else 
        {
            sample_tc.y *= ReShade::AspectRatio;
        }
        sample_tc += 0.5;

        if (all(sample_tc >= 0.0) && all(sample_tc <= 1.0)) 
        {
            float light_intensity_at_sample = tex2D(VolumetricLight_ThresholdSampler, sample_tc).a;
            float attenuation_along_ray = 1.0 - pow(ray_progress, RAY_ATTENUATION_CURVE); 
            
            // Apply chosen color to the ray intensity
            accumulated_rays.rgb += chosen_light_color * light_intensity_at_sample * attenuation_along_ray;
            accumulated_rays.a += attenuation_along_ray; 
        }
    }

    if (accumulated_rays.a > AS_EPSILON)
    {
        accumulated_rays.rgb /= accumulated_rays.a;
    }
    
    float4 original_scene_color = tex2D(ReShade::BackBuffer, texcoord); 
    return AS_applyBlend(float4(accumulated_rays.rgb, 1.0), original_scene_color, BlendMode, BlendAmount);
}

// ============================================================================
// Technique Definition
// ============================================================================
technique AS_VFX_VolumetricLight 
    < ui_label = "[AS] VFX: Volumetric Light";    
     ui_tooltip = "Simulates 2D volumetric light shafts with selectable color. Light source at 'EffectDepth'; objects in front block light."; >
{
    pass ThresholdPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_VolumetricLight_Threshold;
        RenderTarget = VolumetricLight_ThresholdBuffer;
    }
    pass BlurAndCompositePass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_VolumetricLight_Composite;
    }
}

#endif // __AS_VFX_VolumetricLight_1_fx
