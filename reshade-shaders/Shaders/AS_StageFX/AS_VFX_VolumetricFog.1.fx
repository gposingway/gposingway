/**
 * AS_VFX_VolumetricFog.1.fx - Volumetric Fog Effect (Screen-Space Depth)
 * Author: Leon Aquitaine (Re-architected to avoid ReShade::ViewOrigin/ViewToWorld) 
 * License: Creative Commons Attribution 4.0 International
 * Original Source (Inspiration): https://www.shadertoy.com/view/Xls3D2 (Dave Hoskins)
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader generates a volumetric fog effect that blends with the existing scene
 * based on screen-space depth. It simulates fog accumulation by ray-marching through
 * 3D space derived from screen coordinates, stopping at the actual scene depth.
 * This creates realistic depth interaction, making the fog respond naturally to
 * subjects at different distances in the scene.
 *
 * FEATURES:
 * - Depth-aware volumetric fog for realistic atmospheric perspective.
 * - Ray-marched fog volume with proper depth interaction.
 * - Supports multiple procedural noise types (Triangle, Four-D, Texture, Value)
 * to define the fog's appearance (e.g., wispy, volumetric, uniform).
 * - Customizable fog color, overall density, and max visibility distance.
 * - Adjustable fog animation speed (horizontal and vertical flow).
 * - Tunable fog volume offset and rotation for creative positioning relative to the screen.
 * - Seamless integration with ReShade's linearized depth buffer.
 * - Standard AS-StageFX UI controls for easy parameter adjustment.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Derives a screen-space ray direction from `texcoord` and `ReShade::AspectRatio`.
 * 2. Fetches the linearized depth (`ReShade::GetLinearizedDepth`) of the scene
 * at the current pixel, and converts it to a world-like distance.
 * 3. Uses a ray-marching loop (`calculateFogDensity`) to step along
 * this screen-space ray, sampling fog density based on chosen noise type.
 * The loop stops when it hits the converted scene depth or max fog distance.
 * 4. Fog volume movement is achieved by applying time-based scrolling
 * and world-space offsets/rotations directly to the 3D sampling coordinates
 * within the noise functions, relative to the camera's assumed fixed forward vector.
 * 5. The accumulated fog density is used to `lerp` between the original
 * backbuffer color and the defined `Fog_Color`.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_VolumetricFog_1_fx
#define __AS_VFX_VolumetricFog_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh" // For Noise3d variations and AS_hash12

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

// Performance & Quality Constants
static const float FOG_PRECISION_MIN = 0.01;
static const float FOG_PRECISION_MAX = 0.5;
static const float FOG_PRECISION_DEFAULT = 0.1;

static const float FOG_MULTIPLIER_MIN = 0.1;
static const float FOG_MULTIPLIER_MAX = 1.0;
static const float FOG_MULTIPLIER_DEFAULT = 0.34;

static const int FOG_RAY_ITERATIONS_MIN = 10;
static const int FOG_RAY_ITERATIONS_MAX = 200;
static const int FOG_RAY_ITERATIONS_DEFAULT = 90;

// Appearance Constants
static const float FOG_COLOR_R_DEFAULT = 0.6;
static const float FOG_COLOR_G_DEFAULT = 0.65;
static const float FOG_COLOR_B_DEFAULT = 0.7;

static const int NOISE_TYPE_TRIANGLE = 0;
static const int NOISE_TYPE_FOUR_D = 1;
static const int NOISE_TYPE_TEXTURE = 2;
static const int NOISE_TYPE_VALUE = 3;

static const float FOG_MAX_DISTANCE_MIN = 0.0;
static const float FOG_MAX_DISTANCE_MAX = 1.0;
static const float FOG_MAX_DISTANCE_DEFAULT = 0.5;

static const float FOG_START_MIN = 0.0;
static const float FOG_START_MAX = 1.0;
static const float FOG_START_DEFAULT = 0.0;

static const float FOG_DENSITY_MIN = 0.0;
static const float FOG_DENSITY_MAX = 5.0; // Increased max density
static const float FOG_DENSITY_DEFAULT = 0.7;

static const float FOG_HEIGHT_MIN = 0.0;
static const float FOG_HEIGHT_MAX = 1.0;
static const float FOG_HEIGHT_DEFAULT = 1.0;
static const float FOG_HORIZON_MIN = 0.0;
static const float FOG_HORIZON_MAX = 1.0;
static const float FOG_HORIZON_DEFAULT = 0.5;

// Flow & Movement Constants
static const float FOG_TIME_WARP_MIN = -10.0; // Allow negative for reverse
static const float FOG_TIME_WARP_MAX = 10.0;
static const float FOG_TIME_WARP_DEFAULT = 7.0;

static const float FOG_VERT_SPEED_MIN = -2.0; // Allow negative
static const float FOG_VERT_SPEED_MAX = 2.0;
static const float FOG_VERT_SPEED_DEFAULT = 0.5;

static const float FOG_TURBULENCE_MIN = 0.0;
static const float FOG_TURBULENCE_MAX = 30.0;
static const float FOG_TURBULENCE_DEFAULT = 3.0;

// Position Constants
static const float FOG_OFFSET_WORLD_MIN = -500.0;
static const float FOG_OFFSET_WORLD_MAX = 500.0;

// ============================================================================
// UI UNIFORMS - Following AS-StageFX Standard Organization
// ============================================================================

// 1. TUNABLE CONSTANTS
uniform float Fog_Precision < ui_type = "slider"; ui_label = "Quality Level"; ui_min = FOG_PRECISION_MIN; ui_max = FOG_PRECISION_MAX; ui_step = 0.01; ui_category = "Tunable Constants"; ui_tooltip = "Fog rendering quality. Higher values = better quality but slower performance."; > = FOG_PRECISION_DEFAULT;

uniform float Fog_Multiplier < ui_type = "slider"; ui_label = "Speed Optimization"; ui_min = FOG_MULTIPLIER_MIN; ui_max = FOG_MULTIPLIER_MAX; ui_step = 0.01; ui_category = "Tunable Constants"; ui_tooltip = "Performance optimization. Higher values = faster rendering but less detail."; > = FOG_MULTIPLIER_DEFAULT;

uniform int Fog_RayIterations < ui_type = "slider"; ui_label = "Detail Complexity"; ui_min = FOG_RAY_ITERATIONS_MIN; ui_max = FOG_RAY_ITERATIONS_MAX; ui_step = 1; ui_category = "Tunable Constants"; ui_tooltip = "Fog detail complexity. Higher values = more detailed fog but slower performance."; > = FOG_RAY_ITERATIONS_DEFAULT;

// 2. PALETTE & STYLE
uniform float3 Fog_Color < ui_type = "color"; ui_label = "Fog Color"; ui_category = "Palette & Style"; ui_tooltip = "The main color of the fog effect."; > = float3(FOG_COLOR_R_DEFAULT, FOG_COLOR_G_DEFAULT, FOG_COLOR_B_DEFAULT);

uniform int Fog_NoiseType < ui_type = "combo"; ui_label = "Fog Pattern Type"; ui_items = "Wispy & Organic\0Flowing & Dynamic\0Custom Texture\0Soft & Smooth\0"; ui_category = "Palette & Style"; ui_tooltip = "Choose the visual pattern of your fog: Wispy for natural looks, Flowing for dynamic motion, Custom Texture for unique patterns, or Soft for gentle fog."; > = NOISE_TYPE_TRIANGLE;

// 3. EFFECT-SPECIFIC APPEARANCE
uniform float Fog_MaxDistance < ui_type = "slider"; ui_label = "Fog Reach Distance"; ui_min = FOG_MAX_DISTANCE_MIN; ui_max = FOG_MAX_DISTANCE_MAX; ui_step = 0.01; ui_category = "Effect Appearance"; ui_tooltip = "How far into the scene the fog extends. 0 = very close, 1 = maximum distance."; > = FOG_MAX_DISTANCE_DEFAULT;

uniform float Fog_Start < ui_type = "slider"; ui_label = "Fog Start Distance"; ui_min = FOG_START_MIN; ui_max = FOG_START_MAX; ui_step = 0.01; ui_category = "Effect Appearance"; ui_tooltip = "Where fog begins to appear. 0 = starts immediately, 1 = starts at maximum distance."; > = FOG_START_DEFAULT;

uniform float Fog_Density < ui_type = "slider"; ui_label = "Fog Thickness"; ui_min = FOG_DENSITY_MIN; ui_max = FOG_DENSITY_MAX; ui_step = 0.01; ui_category = "Effect Appearance"; ui_tooltip = "Controls how thick and opaque the fog appears."; > = FOG_DENSITY_DEFAULT;

uniform float2 Fog_HeightHorizon < ui_type = "slider"; ui_label = "Height & Horizon"; ui_min = FOG_HEIGHT_MIN; ui_max = FOG_HEIGHT_MAX; ui_step = 0.01; ui_category = "Effect Appearance"; ui_tooltip = "X: Fog height coverage (0 = no fog, 0.25 = ground fog, 0.5 = waist-high fog, 1.0 = full screen fog). Y: Horizon line position (0 = bottom, 0.5 = center, 1.0 = top)."; > = float2(FOG_HEIGHT_DEFAULT, FOG_HORIZON_DEFAULT);

// 4. ANIMATION CONTROLS
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// 5. FOG FLOW & MOVEMENT
uniform float Fog_XZ_ScrollSpeed < ui_type = "slider"; ui_label = "Flow Speed"; ui_min = FOG_TIME_WARP_MIN; ui_max = FOG_TIME_WARP_MAX; ui_step = 0.1; ui_category = "Fog Flow"; ui_tooltip = "Overall fog movement speed. Negative values reverse the flow direction."; > = FOG_TIME_WARP_DEFAULT;

uniform float Fog_VerticalSpeed < ui_type = "slider"; ui_label = "Vertical Flow Speed"; ui_min = FOG_VERT_SPEED_MIN; ui_max = FOG_VERT_SPEED_MAX; ui_step = 0.01; ui_category = "Fog Flow"; ui_tooltip = "Controls how fast the fog rises or falls. Negative values make it sink."; > = FOG_VERT_SPEED_DEFAULT;

uniform float Fog_Rotation < ui_type = "slider"; ui_label = "Fog Rotation"; ui_tooltip = "Rotate the fog volume for artistic positioning"; ui_min = -180.0; ui_max = 180.0; ui_step = 1.0; ui_category = "Fog Flow"; > = 0.0;

uniform float Fog_Turbulence < ui_type = "slider"; ui_label = "Flow Turbulence"; ui_min = FOG_TURBULENCE_MIN; ui_max = FOG_TURBULENCE_MAX; ui_step = 0.1; ui_category = "Fog Flow"; ui_tooltip = "Adds swirling, turbulent motion to the fog flow. Higher values = more chaotic movement."; > = FOG_TURBULENCE_DEFAULT;

// 6. STAGE/POSITION CONTROLS
uniform float Fog_Offset_World_X < ui_type = "slider"; ui_label = "Left/Right Position"; ui_min = FOG_OFFSET_WORLD_MIN; ui_max = FOG_OFFSET_WORLD_MAX; ui_step = 1.0; ui_category = "Stage Position"; ui_tooltip = "Shifts the fog cloud left (negative) or right (positive) relative to your view."; > = 0.0;
uniform float Fog_Offset_World_Y < ui_type = "slider"; ui_label = "Up/Down Position"; ui_min = FOG_OFFSET_WORLD_MIN; ui_max = FOG_OFFSET_WORLD_MAX; ui_step = 1.0; ui_category = "Stage Position"; ui_tooltip = "Shifts the fog cloud up (positive) or down (negative) relative to your view."; > = -130.0;
uniform float Fog_Offset_World_Z < ui_type = "slider"; ui_label = "Forward/Back Position"; ui_min = FOG_OFFSET_WORLD_MIN; ui_max = FOG_OFFSET_WORLD_MAX; ui_step = 1.0; ui_category = "Stage Position"; ui_tooltip = "Pushes the fog forward (positive) or backward (negative) in the scene."; > = -130.0;

// FOG PATTERN & TEXTURE
// TEXTURE PATTERN SPECIFIC (requires a texture)
#ifndef VolumetricFog_Texture_Path
#define VolumetricFog_Texture_Path "perlin512x8CNoise.png" // Example noise texture
#endif
#define VolumetricFog_Texture_WIDTH 512.0f
#define VolumetricFog_Texture_HEIGHT 512.0f

texture VolumetricFog_NoiseTexture <
    source = VolumetricFog_Texture_Path;
    ui_label = "Custom Fog Texture";
    ui_tooltip = "The texture used for 'Custom Texture' pattern type. Best with seamless noise textures.";
>{
    Width = VolumetricFog_Texture_WIDTH; Height = VolumetricFog_Texture_HEIGHT; Format = RGBA8;
};
sampler VolumetricFog_NoiseSampler { Texture = VolumetricFog_NoiseTexture; AddressU = REPEAT; AddressV = REPEAT; };

// 7. FINAL MIX
AS_BLENDMODE_UI_DEFAULT(VolumetricFog_BlendMode, AS_BLEND_NORMAL)
AS_BLENDAMOUNT_UI(VolumetricFog_BlendAmount)

// ============================================================================
// CONSTANTS & HELPERS (from original shader, minimal changes)
// ============================================================================

#define MOD3 float3(.16532,.17369,.15787)
#define MOD2 float2(.16632,.17369)

float tri(in float x){return abs(frac(x)-AS_HALF);}

// ============================================================================
// NOISE FUNCTIONS - Adapted from original shader
// ============================================================================

float3 tri3(in float3 p){return float3( tri(p.z+tri(p.y)), tri(p.z+tri(p.x)), tri(p.y+tri(p.x)));}

float Noise3d_Triangle(in float3 p)
{
    float z_val = 1.4;
	float rz = 0.0;
    float3 bp = p;
	for (int i=0; i<= 2; i++ )
	{
        float3 dg = tri3(bp);
        p += (dg);

        bp *= 2.0;
		z_val *= 1.5;
		p *= 1.3;
		
        rz += (tri(p.z+tri(p.x+tri(p.y))))/z_val;
        bp += 0.14;
	}
	return rz;
}

float4 quad(in float4 p){return abs(frac(p.yzwx+p.wzxy)-.5);}

float Noise3d_FourD(in float3 q, in float time_param)
{
    float z_val = 1.4;
    float4 p_val = float4(q, time_param * 0.1);
	float rz = 0.0;
    float4 bp = p_val;
	for (int i=0; i<= 2; i++ )
	{
        float4 dg = quad(bp);
        p_val += (dg);

		z_val *= 1.5;
		p_val *= 1.3;
		
        rz += (tri(p_val.z+tri(p_val.w+tri(p_val.y+tri(p_val.x)))))/z_val;
		
        bp = bp.yxzw*2.0+.14;
	}
	return rz;
}

float Noise3d_Texture(in float3 x)
{
    x *= 10.0;
    float h = 0.0;
    float a = 0.28;
    for (int i = 0; i < 4; i++)
    {
        float3 p_floor = floor(x);
        float3 f_frac = frac(x);
        f_frac = f_frac*f_frac*(3.0-2.0*f_frac);

        float2 uv_sampled = (p_floor.xy + float2(37.0,17.0)*p_floor.z) + f_frac.xy;
        float2 rg = tex2Dlod(VolumetricFog_NoiseSampler, float4((uv_sampled + 0.5) / float2(VolumetricFog_Texture_WIDTH, VolumetricFog_Texture_HEIGHT), 0.0, 0.0)).yx;
        h += lerp( rg.x, rg.y, f_frac.z )*a;
        a *= AS_HALF;
        x += x; // Equivalent to x *= 2.0
    }
    return h;
}

float Hash(float3 p){
	p = frac(p * MOD3);
    p += dot(p.xyz, p.yzx + 19.19);
    return frac(p.x * p.y * p.z);
}

float Noise3d_Value(in float3 p)
{
    float2 add = float2(1.0, 0.0);
	p *= 10.0;
    float h = 0.0;
    float a = 0.3;
    for (int n = 0; n < 4; n++)
    {
        float3 i_floor = floor(p);
        float3 f_frac = frac(p);
        f_frac *= f_frac * (3.0-2.0*f_frac);

        h += lerp(
            lerp(lerp(Hash(i_floor), Hash(i_floor + add.xyy),f_frac.x),
                lerp(Hash(i_floor + add.yxy), Hash(i_floor + add.xxy),f_frac.x),
                f_frac.y),
            lerp(lerp(Hash(i_floor + add.yyx), Hash(i_floor + add.xyx),f_frac.x),
                lerp(Hash(i_floor + add.yxx), Hash(i_floor + add.xxx),f_frac.x),
                f_frac.y),
            f_frac.z)*a;
        a *= AS_HALF;
        p += p; // Equivalent to p *= 2.0
    }
    return h;
}

// Unified noise function dispatch
float GetNoise3d(in float3 p, in float time_param)
{
    switch(Fog_NoiseType)
    {
        case NOISE_TYPE_TRIANGLE: return Noise3d_Triangle(p);
        case NOISE_TYPE_FOUR_D: return Noise3d_FourD(p, time_param);
        case NOISE_TYPE_TEXTURE: return Noise3d_Texture(p);
        case NOISE_TYPE_VALUE: return Noise3d_Value(p);
        default: return Noise3d_Triangle(p); // Fallback
    }
}

// ============================================================================
// FOG CALCULATION FUNCTIONS (re-purposed from original)
// ============================================================================

// Optimized fogmap with pre-calculated flow direction
float fogmap(in float3 p_world_offset, in float distance_from_camera_approx, in float time_param, in float2 flow_vector)
{
    // Apply fog movement with user-controlled direction (flow_vector pre-calculated)
    float2 horizontal_movement = time_param * Fog_XZ_ScrollSpeed * flow_vector;
    p_world_offset.x -= horizontal_movement.x;
    p_world_offset.z -= horizontal_movement.y;
    
    // Add turbulence for more natural, swirling motion (optimized)
    if (Fog_Turbulence > AS_EPSILON) // Skip turbulence calculation if very low
    {
        float turbulence_factor = Fog_Turbulence * 0.3;
        float2 turbulence_input = float2(p_world_offset.z * 0.3 + time_param * 0.5, 
                                        p_world_offset.x * 0.2 + time_param * 0.3);
        float2 turbulence_result = float2(sin(turbulence_input.x), cos(turbulence_input.y));
        p_world_offset.xz += turbulence_result * float2(turbulence_factor, turbulence_factor * 0.5);
    }
    
    // Apply vertical movement
    p_world_offset.y -= time_param * Fog_VerticalSpeed;
    
    // Original noise sampling logic for fog density
    return (max(GetNoise3d(p_world_offset*0.008+0.1, time_param)-0.1,0.0)*GetNoise3d(p_world_offset*0.1, time_param))*0.3 * Fog_Density;
}

// Original fogColour, for blending fog with scene
float3 fogColour( in float3 base_color, float distance_val )
{
    // This is the original shader's "fogging" of the scene based on distance
    // We can interpret base_color as the original scene color
    float3 extinction_factor = exp2(-distance_val*0.0001*float3(1.0,1.5,3.0));
    return base_color * extinction_factor + (1.0-extinction_factor)*float3(1.0,1.0,1.0); // Blends towards white based on distance
}

/**
 * calculateFogDensity
 * Accumulates fog density along a simplified screen-space ray up to a specified depth.
 * @param screen_uv The screen-space UV coordinate (0-1).
 * @param linearized_depth The linearized depth value from ReShade::GetLinearizedDepth.
 * @param time_param Current shader time for animation.
 * @return Accumulated fog density (0.0 to 1.0).
 */
float calculateFogDensity(in float2 screen_uv, in float linearized_depth, in float time_param)
{
    // Pre-calculate constants and repeated values
    const float WORLD_SCALE = 1000.0;
    float scene_world_distance = linearized_depth * WORLD_SCALE;
    float max_fog_distance = Fog_MaxDistance * WORLD_SCALE;
    float fog_start_distance = Fog_Start * WORLD_SCALE;
    
    // Pre-calculate step precision (was calculated every iteration)
    float step_precision = (FOG_PRECISION_MAX + FOG_PRECISION_MIN) - Fog_Precision;
    
    // Pre-calculate rotation values
    float fog_layer_rotation_radians = radians(Fog_Rotation);
    float cos_rot = cos(fog_layer_rotation_radians);
    float sin_rot = sin(fog_layer_rotation_radians);
    bool has_rotation = (fog_layer_rotation_radians != 0.0);

    float accumulated_fog_density = 0.0;
    float current_distance = fog_start_distance;
    float step_size_multiplier = Fog_Multiplier;

    // Simulate a ray_direction from screen UVs.
    float2 normalized_screen_coords = (screen_uv - AS_HALF) * float2(ReShade::AspectRatio, 1.0) * 2.0;
    float3 simulated_ray_direction = normalize(float3(normalized_screen_coords.x, normalized_screen_coords.y, -1.0));    // Calculate fog height mask based on screen position and depth (optimized)
    float screen_height_factor = 1.0 - screen_uv.y; // 0 at top of screen, 1 at bottom
    float horizon_line = 1.0 - Fog_HeightHorizon.y; // Convert to same coordinate system
    
    // Pre-calculate depth influence factors
    float depth_height_influence = saturate(linearized_depth * 2.0);
    float depth_adjusted_horizon = horizon_line + (linearized_depth * (1.0 - horizon_line) * 0.5);
    float relative_to_horizon = screen_height_factor - depth_adjusted_horizon;
    float effective_fog_height = Fog_HeightHorizon.x + (depth_height_influence * (1.0 - Fog_HeightHorizon.x) * 0.3);
    
    // Calculate height mask with optimized smoothstep
    float height_mask = 1.0 - smoothstep(-effective_fog_height * 0.2, effective_fog_height, relative_to_horizon);
    
    // Early exit if this pixel is above the fog height
    if (height_mask <= AS_EPSILON) return 0.0;    // Apply fog layer rotation to the simulated ray direction (optimized)
    if (has_rotation)
    {
        simulated_ray_direction.xz = float2(simulated_ray_direction.x * cos_rot - simulated_ray_direction.z * sin_rot,
                                            simulated_ray_direction.x * sin_rot + simulated_ray_direction.z * cos_rot);
    }    // Pre-calculate fog volume origin
    float3 fog_volume_origin = float3(Fog_Offset_World_X, Fog_Offset_World_Y, Fog_Offset_World_Z);
    
    // Pre-calculate flow direction vector (fixed rightward direction)
    float2 flow_vector = float2(1.0, 0.0);
      // Optimized ray marching loop
    for( int i=0; i<Fog_RayIterations; i++ )
    {
        // Stop if we hit the max fog distance or the actual scene geometry's distance
        if(current_distance > max_fog_distance || current_distance > scene_world_distance) break;

        // Only accumulate fog if we're past the start distance
        if(current_distance >= fog_start_distance)
        {
            // Calculate the 3D sampling point within the fog volume
            float3 current_fog_sample_pos = fog_volume_origin + simulated_ray_direction * current_distance;
              // Accumulate fog density at this point (pass pre-calculated flow_vector)
            accumulated_fog_density += fogmap(current_fog_sample_pos, current_distance, time_param, flow_vector);
        }
        
        // Advance the ray (optimized - step_precision pre-calculated)
        current_distance += (step_precision * (1.0 + current_distance * 0.05)) * step_size_multiplier;
        step_size_multiplier += 0.004;
    }
    
    // Apply height mask to final fog density
    accumulated_fog_density *= height_mask;
    
    return min(accumulated_fog_density, 1.0); // Clamp final density to 0-1
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_VolumetricFog(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);
    float scene_linear_depth = ReShade::GetLinearizedDepth(texcoord);
    
    // Get time values once
    float animated_time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);
    
    // Calculate fog density using the simulated ray and scene depth
    float fog_density_factor = calculateFogDensity(texcoord, scene_linear_depth, animated_time);

    // Consolidate world distance calculation (was repeated)
    const float WORLD_SCALE = 1000.0;
    float approximated_world_distance = scene_linear_depth * WORLD_SCALE;

    // Apply distance haze (from original shader) to the background color
    float3 distance_haze_color = fogColour(original_color.rgb, approximated_world_distance);

    // The core fog blend: Lerp between the distance_haze_color and the Fog_Color based on accumulated density.
    float3 final_color_rgb = lerp(distance_haze_color, Fog_Color.rgb, fog_density_factor);

	// Apply final blending over the original backbuffer.
    return AS_applyBlend(float4(final_color_rgb, 1.0), original_color, VolumetricFog_BlendMode, VolumetricFog_BlendAmount);
}

// ============================================================================
// TECHNIQUES
// ============================================================================

technique AS_VFX_VolumetricFog
<
    ui_label = "[AS] VFX: Volumetric Fog";
    ui_tooltip = "Volumetric fog effect with depth interaction and customizable noise patterns.\n"
                 "Creates atmospheric fog that interacts with scene geometry.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_VolumetricFog;
    }
}

#endif // __AS_VFX_VolumetricFog_1_fx
