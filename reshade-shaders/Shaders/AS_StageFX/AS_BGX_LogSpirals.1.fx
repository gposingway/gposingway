/**
 * AS_BGX_LogSpirals.1.fx - Dynamic Logarithmic Spiral Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *  * CREDITS:
 * Based on "Logarithmic spiral of spheres" by mrange
 * Shadertoy: https://www.shadertoy.com/view/msGXRD
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates an organic spiral pattern based on logarithmic growth with animated spheres
 * along the spiral arms. Features detailed customization of color, animation, and geometry.
 *
 * FEATURES:
 * - Precise control over spiral expansion rate and animation
 * - Customizable sphere size, fade effect, and specular highlights
 * - Color palette options with hue cycling and ambient glow
 * - Audio reactivity options for multiple parameters
 * - Position, scale, and rotation controls
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses coordinate transformations including Smith chart mapping for complex distortion
 * 2. Calculates logarithmic spiral parameters based on animated variables
 * 3. Implements sphere ray-marching for volumetric sphere rendering
 * 4. Applies modular polar coordinate mapping for spiral arm generation
 * 5. Uses ACES tone mapping and sRGB conversion for visual quality
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_LogSpirals_fx
#define __AS_BGX_LogSpirals_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"    // Custom header for AS utilities
#include "AS_Palette.1.fxh"  // Color palette system

namespace ASLogSpirals {

// ============================================================================
// CONSTANTS
// ============================================================================
static const float ALPHA_EPSILON = 0.00001f; // For safe division

// Define local constants as needed
#define LOCAL_PI AS_PI
#define LOCAL_TAU AS_TWO_PI
#define ROT(a) float2x2(cos(a), sin(a), -sin(a), cos(a))

// Additional constants to avoid magic numbers
static const float REFLECTION_Z_BASE = 0.1f; // Z value for reflection normal calculation
static const float TANH_COLOR_FACTOR = 8.0f; // Scaling for tanh color operation
static const float COLOR_CYCLE_RATE_SCALE = 0.1f; // Scaling factor for color cycle speed

// Helper Functions
float modPolar(inout float2 p, float repetitions) {
    float angle = LOCAL_TAU / repetitions;
    float a = atan2(p.y, p.x) + angle / 2.0f;
    float r = length(p);
    float c = floor(a / angle);
    a = frac(a / angle) * angle - angle / 2.0f; // Use frac instead of fmod for consistency
    p = float2(cos(a), sin(a)) * r;
    if (abs(c) >= (repetitions / 2.0f)) c = abs(c);
    return c;
}

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================
static const float ANIMATION_SCALE_MIN = 0.0;
static const float ANIMATION_SCALE_MAX = 2.0;
static const float ANIMATION_SCALE_DEFAULT = 0.75;

static const float SPIRAL_EXPANSION_MIN = 1.01;
static const float SPIRAL_EXPANSION_MAX = 2.5;
static const float SPIRAL_EXPANSION_DEFAULT = 1.2;

static const float TRANSFORM_SPEED_MIN = 0.0;
static const float TRANSFORM_SPEED_MAX = 1.0;
static const float TRANSFORM_SPEED1_DEFAULT = 0.12;
static const float TRANSFORM_SPEED2_DEFAULT = 0.23;

static const float ROTATION_SPEED_MIN = -0.5;
static const float ROTATION_SPEED_MAX = 0.5;
static const float ROTATION_SPEED_DEFAULT = -0.125;

static const float ARM_TWIST_MIN = 0.0;
static const float ARM_TWIST_MAX = 2.0;
static const float ARM_TWIST_DEFAULT = 0.66;

static const float COLOR_HUE_MIN = 0.0;
static const float COLOR_HUE_MAX = 2.0;
static const float COLOR_HUE_DEFAULT = 0.85;

static const float GLOW_INTENSITY_MIN = 0.0;
static const float GLOW_INTENSITY_MAX = 0.1;
static const float GLOW_INTENSITY_DEFAULT = 0.01;

static const float FADE_CYCLE_MIN = 0.0;
static const float FADE_CYCLE_MAX = 1.0;
static const float FADE_CYCLE_DEFAULT = 0.33;

static const float SPHERE_RADIUS_MIN = 0.01;
static const float SPHERE_RADIUS_MAX = 0.5;
static const float SPHERE_RADIUS_DEFAULT = 0.125;

static const float SPHERE_FADE_MIN = 0.0;
static const float SPHERE_FADE_MAX = 1.0;
static const float SPHERE_FADE_DEFAULT = 0.375;

static const float SPECULAR_POWER_MIN = 1.0;
static const float SPECULAR_POWER_MAX = 64.0;
static const float SPECULAR_POWER_DEFAULT = 10.0;

static const float SPECULAR_INTENSITY_MIN = 0.0;
static const float SPECULAR_INTENSITY_MAX = 2.0;
static const float SPECULAR_INTENSITY_DEFAULT = 0.5;

static const float AMBIENT_LIGHT_MIN = 0.0;
static const float AMBIENT_LIGHT_MAX = 1.0;
static const float AMBIENT_LIGHT_DEFAULT = 0.2;

static const float BRIGHTNESS_MIN = 0.1;
static const float BRIGHTNESS_MAX = 5.0;
static const float BRIGHTNESS_DEFAULT = 1.5;

static const float DETAIL_GLOW_MIN = 0.0;
static const float DETAIL_GLOW_MAX = 50.0;
static const float DETAIL_GLOW_DEFAULT = 10.0;

// ============================================================================
// UI DECLARATIONS - Organized by category
// ============================================================================

//------------------------------------------------------------------------------------------------
// Primary Spiral Controls
//------------------------------------------------------------------------------------------------

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Logarithmic spiral of spheres' by mrange\nLink: https://www.shadertoy.com/view/msGXRD\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform float AnimationScale < ui_type = "slider"; ui_label = "Animation Scale"; ui_min = ANIMATION_SCALE_MIN; ui_max = ANIMATION_SCALE_MAX; ui_step = 0.01; ui_tooltip = "Legacy animation control. Use Animation Speed in Animation Controls instead."; ui_category = "Spiral Controls"; > = ANIMATION_SCALE_DEFAULT;

uniform float SpiralExpansionRate < ui_type = "slider"; ui_label = "Spiral Expansion Rate"; ui_min = SPIRAL_EXPANSION_MIN; ui_max = SPIRAL_EXPANSION_MAX; ui_step = 0.01; ui_tooltip = "Controls how rapidly spirals expand/contract. Original: 1.2"; ui_category = "Spiral Controls"; > = SPIRAL_EXPANSION_DEFAULT;

uniform float GlobalRotationSpeed < ui_type = "slider"; ui_label = "Global Rotation Speed"; ui_min = ROTATION_SPEED_MIN; ui_max = ROTATION_SPEED_MAX; ui_step = 0.005; ui_tooltip = "Controls the rotation speed of the entire spiral structure."; ui_category = "Spiral Controls"; > = ROTATION_SPEED_DEFAULT;

uniform float ArmTwistFactor < ui_type = "slider"; ui_label = "Spiral Arm Twist Factor"; ui_min = ARM_TWIST_MIN; ui_max = ARM_TWIST_MAX; ui_step = 0.01; ui_tooltip = "Controls how much the spiral arms twist."; ui_category = "Spiral Controls"; > = ARM_TWIST_DEFAULT;

//------------------------------------------------------------------------------------------------
// Transform Controls
//------------------------------------------------------------------------------------------------
uniform float TransformSpeed1 < ui_type = "slider"; ui_label = "Transform Animation Speed 1"; ui_min = TRANSFORM_SPEED_MIN; ui_max = TRANSFORM_SPEED_MAX; ui_step = 0.01; ui_tooltip = "Controls the first coordinate transformation animation speed."; ui_category = "Transform Controls"; > = TRANSFORM_SPEED1_DEFAULT;

uniform float TransformSpeed2 < ui_type = "slider"; ui_label = "Transform Animation Speed 2"; ui_min = TRANSFORM_SPEED_MIN; ui_max = TRANSFORM_SPEED_MAX; ui_step = 0.01; ui_tooltip = "Controls the second coordinate transformation animation speed."; ui_category = "Transform Controls"; > = TRANSFORM_SPEED2_DEFAULT;

//------------------------------------------------------------------------------------------------
// Sphere Controls
//------------------------------------------------------------------------------------------------
uniform float SphereBaseRadiusScale < ui_type = "slider"; ui_label = "Sphere Base Radius Scale"; ui_min = SPHERE_RADIUS_MIN; ui_max = SPHERE_RADIUS_MAX; ui_step = 0.005; ui_tooltip = "Base radius for the spheres along spiral arms."; ui_category = "Sphere Controls"; > = SPHERE_RADIUS_DEFAULT;
uniform float SphereFadeRadiusScale < ui_type = "slider"; ui_label = "Sphere Fade Radius Scale"; ui_min = SPHERE_FADE_MIN; ui_max = SPHERE_FADE_MAX; ui_step = 0.01; ui_tooltip = "Max radius additional scale based on fade (added to base)"; ui_category = "Sphere Controls"; > = SPHERE_FADE_DEFAULT;
uniform float FadeCycleSpeed < ui_type = "slider"; ui_label = "Sphere Fade Cycle Speed"; ui_min = FADE_CYCLE_MIN; ui_max = FADE_CYCLE_MAX; ui_step = 0.01; ui_tooltip = "Controls how fast spheres fade in and out."; ui_category = "Sphere Controls"; > = FADE_CYCLE_DEFAULT;

//------------------------------------------------------------------------------------------------
// Lighting Controls
//------------------------------------------------------------------------------------------------
uniform float SpecularPower < ui_type = "slider"; ui_label = "Specular Power"; ui_min = SPECULAR_POWER_MIN; ui_max = SPECULAR_POWER_MAX; ui_step = 1.0; ui_tooltip = "Controls the tightness of specular highlights."; ui_category = "Lighting Controls"; > = SPECULAR_POWER_DEFAULT;
uniform float SpecularIntensity < ui_type = "slider"; ui_label = "Specular Intensity"; ui_min = SPECULAR_INTENSITY_MIN; ui_max = SPECULAR_INTENSITY_MAX; ui_step = 0.01; ui_tooltip = "Controls the brightness of specular highlights."; ui_category = "Lighting Controls"; > = SPECULAR_INTENSITY_DEFAULT;
uniform float AmbientLightLevel < ui_type = "slider"; ui_label = "Ambient Light Level"; ui_min = AMBIENT_LIGHT_MIN; ui_max = AMBIENT_LIGHT_MAX; ui_step = 0.01; ui_tooltip = "Controls the base lighting on spheres."; ui_category = "Lighting Controls"; > = AMBIENT_LIGHT_DEFAULT;
//------------------------------------------------------------------------------------------------
// Color Controls
//------------------------------------------------------------------------------------------------
uniform float ColorHueFactor < ui_type = "slider"; ui_label = "Primary Color Hue Factor"; ui_min = COLOR_HUE_MIN; ui_max = COLOR_HUE_MAX; ui_step = 0.01; ui_tooltip = "Controls the hue variation of the primary colors."; ui_category = "Color Controls"; > = COLOR_HUE_DEFAULT;
uniform float3 BackgroundColor < ui_type = "color"; ui_label = "Background Color"; ui_tooltip = "Base color for the background. Set all channels to 0 for black background."; ui_category = "Color Controls";> = float3(0.0, 0.0, 0.0);
uniform float GlowColorIntensity < ui_type = "slider"; ui_label = "Ambient Glow Intensity"; ui_min = GLOW_INTENSITY_MIN; ui_max = GLOW_INTENSITY_MAX; ui_step = 0.001; ui_tooltip = "Controls the intensity of the ambient glow effect."; ui_category = "Color Controls"; > = GLOW_INTENSITY_DEFAULT;
uniform float OutputBrightness < ui_type = "slider"; ui_label = "Output Brightness Boost"; ui_min = BRIGHTNESS_MIN; ui_max = BRIGHTNESS_MAX; ui_step = 0.01; ui_tooltip = "Overall brightness adjustment."; ui_category = "Color Controls"; > = BRIGHTNESS_DEFAULT;
uniform float DetailGlowStrength < ui_type = "slider"; ui_label = "Detail-based Glow Strength"; ui_min = DETAIL_GLOW_MIN; ui_max = DETAIL_GLOW_MAX; ui_step = 0.1; ui_tooltip = "Controls the strength of detail-based glow effects."; ui_category = "Color Controls"; > = DETAIL_GLOW_DEFAULT;
//------------------------------------------------------------------------------------------------
// Palette & Style
//------------------------------------------------------------------------------------------------
uniform bool UseOriginalColors < ui_label = "Use Original Colors"; ui_tooltip = "When enabled, uses the original mathematical colors. When disabled, uses palettes."; ui_category = "Palette & Style";> = true;

AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_ELECTRIC, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(Spiral_, "Palette & Style")

uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast palette colors cycle. 0 = static."; ui_min = -2.0; ui_max = 2.0; ui_step = 0.1; ui_category = "Palette & Style";> = 0.0;

//------------------------------------------------------------------------------------------------
// Audio Reactivity
//------------------------------------------------------------------------------------------------
AS_AUDIO_UI(Spiral_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(Spiral_AudioMultiplier, "Audio Intensity", 1.0, 2.0, "Audio Reactivity")
uniform int Spiral_AudioTarget < 
    ui_type = "combo"; 
    ui_label = "Audio Target Parameter"; 
    ui_items = "None\0Animation Speed\0Global Rotation\0Arm Twist\0Sphere Size\0Brightness\0"; 
    ui_category = "Audio Reactivity"; 
> = 0;

//------------------------------------------------------------------------------------------------
// Animation Controls
//------------------------------------------------------------------------------------------------
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

//------------------------------------------------------------------------------------------------
// Stage/Position
//------------------------------------------------------------------------------------------------
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)
AS_POSITION_SCALE_UI(Position, Scale)

//------------------------------------------------------------------------------------------------
// Final Mix
//------------------------------------------------------------------------------------------------
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

//------------------------------------------------------------------------------------------------
// Debug
//------------------------------------------------------------------------------------------------
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// Helper functions
float forward_exp(float l, float exp_base) { // Pass expansion base
    return exp2(log2(exp_base) * l);
}

float reverse_exp(float l, float exp_base) { // Pass expansion base
    if (abs(l) < ALPHA_EPSILON && l <= 0.0f) l = ALPHA_EPSILON;
    else if (abs(l) < ALPHA_EPSILON) l = ALPHA_EPSILON;
    float log2_exp_base = log2(exp_base);
    if (abs(log2_exp_base) < ALPHA_EPSILON) return l / (sign(log2_exp_base) * ALPHA_EPSILON);
    return log2(l) / log2_exp_base;
}

float3 pow_f3_f1(float3 base, float exponent) { return float3(pow(base.x, exponent), pow(base.y, exponent), pow(base.z, exponent)); }

float3 sphere(float3 col, float2x2 rot_matrix, float3 bcol, float2 p_sphere, float r_sphere, float aa_sphere,
              float in_spec_power, float in_spec_intensity, float in_ambient_level, float tanh_bcol_factor) { // Added new params
    float3 lightDir = normalize(float3(1.0f, 1.5f, 2.0f)); // Could be uniforms
    lightDir.xy = mul(rot_matrix, lightDir.xy); 
    float r_sq = r_sphere * r_sphere;
    float p_dot_p = dot(p_sphere, p_sphere);
    float z2 = r_sq - p_dot_p;
    float3 rd_norm = -normalize(float3(p_sphere, REFLECTION_Z_BASE)); // Use constant instead of magic number

    if (z2 > 0.0f) {
        float z = sqrt(z2);
        float3 cp = float3(p_sphere, z);
        float3 cn = normalize(cp);
        float3 cr = reflect(rd_norm, cn);
        float cd = max(dot(lightDir, cn), 0.0f);
        
        float3 cspe = pow_f3_f1(max(dot(lightDir, cr), 0.0f).xxx, in_spec_power) * tanh(tanh_bcol_factor * bcol) * in_spec_intensity;

        float3 ccol = lerp(in_ambient_level.xxx, 1.0f.xxx, cd * cd) * bcol;
        ccol += cspe;
        float d_dist = length(p_sphere) - r_sphere;

        if (aa_sphere > ALPHA_EPSILON) {
             col = lerp(col, ccol, 1.0f - smoothstep(-aa_sphere, 0.0f, d_dist));
        } else { 
             col = lerp(col, ccol, d_dist < 0.0f ? 1.0f : 0.0f);
        }
    }
    return col;
}

float2 toSmith(float2 p_smith) { /* ... same ... */ float d_s=(1.f-p_smith.x)*(1.f-p_smith.x)+p_smith.y*p_smith.y; d_s=abs(d_s)<ALPHA_EPSILON?sign(d_s)*ALPHA_EPSILON:d_s; return float2((1.f+p_smith.x)*(1.f-p_smith.x)-p_smith.y*p_smith.y,2.f*p_smith.y)/d_s; }
float2 fromSmith(float2 p_smith) { /* ... same, corrected ... */ float d_s=(p_smith.x+1.f)*(p_smith.x+1.f)+p_smith.y*p_smith.y; d_s=abs(d_s)<ALPHA_EPSILON?sign(d_s)*ALPHA_EPSILON:d_s; return float2((p_smith.x+1.f)*(p_smith.x-1.f)+p_smith.y*p_smith.y,2.f*p_smith.y)/d_s; }

float2 transform_coords(float2 p_in, float time_param, float speed1, float speed2) { // Added speed params
    float2 p_transformed = p_in;
    float2 const_vec_one = float2(1.0f, 1.0f);
    float2 sp0 = toSmith(p_transformed);
    float2 sp1 = toSmith(p_transformed + mul(ROT(speed1 * time_param), const_vec_one));
    float2 sp2 = toSmith(p_transformed - mul(ROT(speed2 * time_param), const_vec_one));
    p_transformed = fromSmith(sp0 + sp1 - sp2);
    return p_transformed;
}

float3 sRGB_convert(float3 t) { /* ... same ... */ t=max(t,0.f); float3 p=float3(pow(t.x,1.f/2.4f),pow(t.y,1.f/2.4f),pow(t.z,1.f/2.4f)); float3 l=12.92f*t; float3 nl=1.055f*p-0.055f; return float3(t.x<0.0031308f?l.x:nl.x,t.y<0.0031308f?l.y:nl.y,t.z<0.0031308f?l.z:nl.z); }
float3 aces_approx_convert(float3 v) { /* ... same ... */ v=max(v,0.f); v*=0.6f; float a=2.51f,b=0.03f,c=2.43f,d=0.59f,e=0.14f; float3 num=v*(a*v+b); float3 den=v*(c*v+d)+e; den=float3(abs(den.x)<ALPHA_EPSILON?sign(den.x)*ALPHA_EPSILON:den.x,abs(den.y)<ALPHA_EPSILON?sign(den.y)*ALPHA_EPSILON:den.y,abs(den.z)<ALPHA_EPSILON?sign(den.z)*ALPHA_EPSILON:den.z); return saturate(num/den); }

// Main rendering logic function, now using uniforms
float3 effect_render(float2 p_eff, float time_eff, 
                     float anim_scale, float spiral_exp_rate, float trans_speed1, float trans_speed2,
                     float global_rot_speed, float arm_twist_factor, float color_hue_factor,
                     float glow_intensity, float fade_speed, float sphere_base_r, float sphere_fade_r_scale,
                     float spec_pow, float spec_intens, float ambient_lvl,
                     float output_bright, float detail_glow_str,
                     float3 bg_color)
{
    // Note: time_eff is already scaled by AnimationSpeed through AS_getAnimationTime
    float2 p_initial_transformed = transform_coords(p_eff, time_eff, trans_speed1, trans_speed2);
    float2 np_eff = p_eff + float2(ReShade::PixelSize.x, ReShade::PixelSize.y);
    float2 ntp_eff = transform_coords(np_eff, time_eff, trans_speed1, trans_speed2);
    float aa = 2.0f * distance(p_initial_transformed, ntp_eff);
    
    float2 p_current = p_initial_transformed;

    float ltm = time_eff; // Now using properly scaled animation time from AS_getAnimationTime
    float2x2 rot0 = ROT(global_rot_speed * ltm); 
    p_current = mul(rot0, p_current);
    
    float mtm = frac(ltm);
    float ntm_floor = floor(ltm); // Renamed from ntm to avoid conflict
    float gd = dot(p_current, p_current);
    float zz = forward_exp(mtm, spiral_exp_rate); // Use uniform for expansion rate
    zz = abs(zz) < ALPHA_EPSILON ? sign(zz) * ALPHA_EPSILON : zz;

    float2 p0 = p_current / zz;
    float l0 = length(p0);
      
    float n0_val = ceil(reverse_exp(max(l0, ALPHA_EPSILON), spiral_exp_rate));
    float r0 = forward_exp(n0_val, spiral_exp_rate);
    float r1 = forward_exp(n0_val - 1.0f, spiral_exp_rate);
    float r_avg = (r0 + r1) / 2.0f;
    float w = r0 - r1;
    n0_val -= ntm_floor;

    float2 p1 = p0;
    float reps_calc = floor(LOCAL_TAU * r_avg / (w + ALPHA_EPSILON));
    reps_calc = max(reps_calc, 1.0f); 
    float2x2 rot1 = ROT(arm_twist_factor * n0_val); 
    p1 = mul(rot1, p1);
    float m1_polar = modPolar(p1, reps_calc); // p1 is inout
    if (abs(reps_calc) > ALPHA_EPSILON) m1_polar /= reps_calc; else m1_polar = 0.0f;
    p1.x -= r_avg;
    
    float3 ccol = (1.0f + cos(color_hue_factor * float3(0.0f, 1.0f, 2.0f) + LOCAL_TAU * (m1_polar) + 0.5f * n0_val)) * 0.5f; float3 gcol = (1.0f + cos(float3(0.0f, 1.0f, 2.0f) + global_rot_speed * 0.5f * ltm)) * glow_intensity; // Used global_rot_speed for glow color variation speed
    float2x2 rot2 = ROT(LOCAL_TAU * m1_polar);

    float3 col_out = bg_color; // Initialize with background color instead of black
    float fade = 0.5f + 0.5f * cos(LOCAL_TAU * m1_polar + fade_speed * ltm);
    
    float2x2 combined_rotation = mul(mul(rot0, rot1), rot2);

    // Calculate sphere radius based on uniforms
    float current_sphere_radius = lerp(sphere_base_r, sphere_base_r + sphere_fade_r_scale, fade) * w; col_out = sphere(col_out, combined_rotation, ccol * lerp(0.25f, 1.0f, sqrt(saturate(fade))), 
                     p1, current_sphere_radius, aa / zz,
                     spec_pow, spec_intens, ambient_lvl, TANH_COLOR_FACTOR); // Use constant instead of magic number
    col_out *= output_bright;
    col_out += gcol / max(gd, 0.001f);
    float aa_glow_val = aa * detail_glow_str; // Use DetailGlowStrength
    // Prevent aa_glow_val from becoming excessively huge if aa is large (e.g. on first frame or view change)
    aa_glow_val = min(aa_glow_val, glow_intensity * 100.0f); // Cap relative to glow_intensity
    col_out += gcol * aa_glow_val;

    col_out = aces_approx_convert(col_out);
    col_out = sRGB_convert(col_out);

    return col_out;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 LogSpiralsPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target0
{
    // Get original background color for blending and depth check
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    
    // Apply depth test - skip effect if pixel is closer than effect depth
    if (depth < EffectDepth) {
        return originalColor;
    }
      // Apply audio reactivity to selected parameters
    float anim_speed = AnimationSpeed;
    float rot_speed = GlobalRotationSpeed;
    float arm_twist = ArmTwistFactor;
    float sphere_radius = SphereBaseRadiusScale;
    float bright = OutputBrightness;
    
    float audioReactivity = AS_applyAudioReactivity(1.0, Spiral_AudioSource, Spiral_AudioMultiplier, true);
    
    // Apply audio reactivity to targeted parameter
    if (Spiral_AudioTarget == 1) anim_speed *= audioReactivity;
    else if (Spiral_AudioTarget == 2) rot_speed *= audioReactivity;
    else if (Spiral_AudioTarget == 3) arm_twist *= audioReactivity;
    else if (Spiral_AudioTarget == 4) sphere_radius *= audioReactivity;
    else if (Spiral_AudioTarget == 5) bright *= audioReactivity;
    
    // --- POSITION HANDLING ---
    // Step 1: Center and correct for aspect ratio
    float2 p_centered = (texcoord - AS_HALF) * 2.0; // Center coordinates (-1 to 1)
    p_centered.x *= ReShade::AspectRatio;   // Correct for aspect ratio
    
    // Step 2: Apply rotation around center (negative rotation for clockwise)
    float sinRot, cosRot;
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    sincos(-rotationRadians, sinRot, cosRot);
    float2 p_rotated = float2(
        p_centered.x * cosRot - p_centered.y * sinRot,
        p_centered.x * sinRot + p_centered.y * cosRot
    );
      // Step 3: Apply position and scale
    float2 p_final = p_rotated / Scale - Position; // Calculate the spiral effect
    // Ensure modPolar is resolved by using the fully qualified name ASLogSpirals::modPolar    // Get animated time using standard animation control with audio reactivity applied
    float animatedTime = AS_getAnimationTime(anim_speed, AnimationKeyframe);
      float3 col = effect_render(
        p_final, 
        animatedTime, // Use standardized animation time
        1.0, // Pass 1.0 for anim_scale since time is already scaled by AnimationSpeed
        SpiralExpansionRate, TransformSpeed1, TransformSpeed2,
        rot_speed, arm_twist, ColorHueFactor, GlowColorIntensity,
        FadeCycleSpeed, sphere_radius, SphereFadeRadiusScale,
        SpecularPower, SpecularIntensity, AmbientLightLevel,
        bright, DetailGlowStrength,
        BackgroundColor // Pass background color to the effect
    );
    
    // Apply additional effects to the raw output
    col = aces_approx_convert(col);
    
    // Apply palette if enabled
    float3 final_color;
    if (UseOriginalColors) {
        final_color = sRGB_convert(col);
    } else {
        // Get normalized brightness for palette
        float intensity = length(col) / sqrt(3.0);
        intensity = saturate(intensity); // Apply optional color cycling with standardized animation time
        float t = intensity;
        if (ColorCycleSpeed != 0.0) {
            float cycleRate = ColorCycleSpeed * COLOR_CYCLE_RATE_SCALE;
            t = frac(t + cycleRate * animatedTime); // Use animatedTime instead of AS_getTime()
        }
        
        // Get color from palette system
        if (PalettePreset == AS_PALETTE_CUSTOM) {
            final_color = AS_GET_INTERPOLATED_CUSTOM_COLOR(Spiral_, t);
        } else {
            final_color = AS_getInterpolatedColor(PalettePreset, t);
        }
        
        // Modulate palette color by spiral intensity
        final_color *= intensity;
    }
    
    // Create the effect color with alpha
    float4 effectColor = float4(final_color, 1.0f);
    
    // Apply blend mode and strength
    float4 finalColor = float4(AS_applyBlend(effectColor.rgb, originalColor.rgb, BlendMode), 1.0);
    finalColor = lerp(originalColor, finalColor, BlendStrength);
    
    // Show debug overlay if enabled
    if (DebugMode != AS_DEBUG_OFF) {
        if (DebugMode == 1) { // Show Audio Reactivity
            float2 debugPos = float2(0.05, 0.05);
            float debugSize = 0.15;
            if (all(abs(texcoord - debugPos) < debugSize)) {
                return float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
            }
        }
    }
    
    return finalColor;
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_LogSpirals_Tech < 
    ui_label = "[AS] BGX: Logarithmic Spirals";
    ui_tooltip = "Artistic logarithmic spiral pattern with customizable sphere elements and colors.\n"
                 "Original concept by nmz/stormoid (https://www.shadertoy.com/view/NdfyRM)";
>
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = LogSpiralsPS;
    }
}

} // end namespace ASLogSpirals

#endif // __AS_BGX_LogSpirals_fx
