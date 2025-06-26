/**
 * AS_VFX_RainyWindow.1.fx - Realistic rainy window effect with dynamic blur and refraction
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *  * CREDITS:
 * Based on "Heartfelt" by Martijn Steinrucken (BigWings)
 * Shadertoy: https://www.shadertoy.com/view/ltffzl
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates an immersive rainy window effect with animated water droplets, realistic trails, and frost
 * on glass. The effect combines dynamic raindrop movement with customizable blur quality to simulate 
 * looking through a wet, frosted window during rainfall.
 *
 * FEATURES:
 * - Realistic water droplet animation with physics-based movement and trails
 * - Variable frost effect that mimics condensation on glass
 * - Customizable rain intensity and frost levels
 * - Adjustable blur quality to balance visual quality and performance
 * - Support for stage positioning, rotation, and depth
 * - Audio reactivity for dynamic storm intensity
 * - Optional lightning flash effects
 * - Resolution-independent rendering
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generate procedural rain patterns using multiple overlapping droplet layers
 * 2. Calculate water normals based on droplet coverage to simulate light refraction
 * 3. Apply variable blurring based on droplet coverage to create frosted glass effect
 * 4. Use trails to reduce blur in droplet path areas for realistic water flow
 * 5. Implement blur quality adjustments to support performance optimization
 * 6. Apply optional lightning effect for dramatic storm visuals
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_RainyWindow_1_fx
#define __AS_VFX_RainyWindow_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" 
#include "AS_Perspective.1.fxh" // Added for perspective controls

// ============================================================================
// CONSTANTS
// ============================================================================
// Blur configurations
static const float FROST_MIN_BLUR_PIXELS = 0.0f;  // Min blur in pixels
static const float FROST_MAX_BLUR_PIXELS = 25.0f; // Max blur in pixels
static const int MAX_BLUR_SAMPLES = 48;           // Max samples per side for blur
static const int MIN_BLUR_SAMPLES = 1;            // Min samples per side for blur (quality slider effect)

// Threshold configurations
static const float THRESHOLD_MIN = 0.0f;      
static const float THRESHOLD_MAX = 1.0f;      
static const float DROPLET_SPEED_MIN = 0.0f;  
static const float DROPLET_SPEED_MAX = 1.0f;  

// Lightning frequency multipliers
static const float LIGHTNING_FREQ_LIGHT_SUMMER = 0.2f;
static const float LIGHTNING_FREQ_MODERATE_STORM = 0.5f;
static const float LIGHTNING_FREQ_HEAVY_THUNDERSTORM = 1.0f;
static const float LIGHTNING_FREQ_RAGING_TEMPEST = 2.0f;
static const float LIGHTNING_FREQ_APOCALYPSE = 4.0f;

// ============================================================================
// TEXTURES AND SAMPLERS
// ============================================================================
// R=focus_val, GB=normal.xy, A=drop_coverage

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Heartfelt' by Martijn Steinrucken (BigWings)\nLink: https://www.shadertoy.com/view/ltffzl\nLicence: CC Share-Alike Non-Commercial\n\n";>;

AS_CREATE_TEX_SAMPLER(RainyWindow_EffectMapTarget, RainyWindow_EffectMapSampler, float2(BUFFER_WIDTH, BUFFER_HEIGHT), RGBA16F, 1, POINT, CLAMP)

AS_CREATE_TEX_SAMPLER(RainyWindow_HorizontalBlurTarget, RainyWindow_HorizontalBlurSampler, float2(BUFFER_WIDTH, BUFFER_HEIGHT), RGBA8, 1, POINT, CLAMP)

AS_CREATE_TEX_SAMPLER(RainyWindow_BlurredBackgroundTarget, RainyWindow_BlurredBackgroundSampler, float2(BUFFER_WIDTH, BUFFER_HEIGHT), RGBA8, 1, POINT, CLAMP)

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// Rain & Droplet Appearance

uniform float RainAmount < ui_type = "slider"; ui_label = "Rain Amount"; ui_tooltip = "Controls overall rain intensity and thus influences blur levels."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Rain Appearance"; > = 0.7;
uniform float DropAnimationSpeed < ui_type = "slider"; ui_label = "Drop Animation Speed"; ui_tooltip = "Controls how fast the raindrops move and animate."; ui_min = DROPLET_SPEED_MIN; ui_max = DROPLET_SPEED_MAX; ui_step = 0.01; ui_category = "Rain Appearance"; > = 0.2;

// Frosting Effect
uniform float Frost_MinBlur_Constant < ui_type = "slider"; ui_label = "Min Blur (Droplet Areas)"; ui_tooltip = "Blur radius in pixels for droplet areas. 0 for sharp."; ui_min = FROST_MIN_BLUR_PIXELS; ui_max = FROST_MAX_BLUR_PIXELS; ui_step = 0.1; ui_category = "Frosting"; > = 0.0f;
uniform float Frost_MaxBlur_BaseLowRain < ui_type = "slider"; ui_label = "Max Blur (Low Rain)"; ui_tooltip = "Max blur radius in pixels when Rain Amount is low."; ui_min = FROST_MIN_BLUR_PIXELS; ui_max = FROST_MAX_BLUR_PIXELS; ui_step = 0.1; ui_category = "Frosting"; > = 8.0f;
uniform float Frost_MaxBlur_BaseHighRain < ui_type = "slider"; ui_label = "Max Blur (High Rain)"; ui_tooltip = "Max blur radius in pixels when Rain Amount is high."; ui_min = FROST_MIN_BLUR_PIXELS; ui_max = FROST_MAX_BLUR_PIXELS; ui_step = 0.1; ui_category = "Frosting"; > = 12.0f;
uniform float BlurQuality < ui_type = "slider"; ui_label = "Glass Frosting"; ui_tooltip = "Adjusts blur quality (sample count). Lower values improve performance but reduce blur quality."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Frosting"; > = 1.0;
uniform float FrostThresholdLow < ui_type = "slider"; ui_label = "Low Coverage Threshold"; ui_tooltip = "Drop coverage BELOW this results in more frost/blur (towards Max Blur)."; ui_min = THRESHOLD_MIN; ui_max = THRESHOLD_MAX; ui_step = 0.01; ui_category = "Frosting"; > = 0.1f;
uniform float FrostThresholdHigh < ui_type = "slider"; ui_label = "High Coverage Threshold"; ui_tooltip = "Drop coverage ABOVE this results in less frost/blur (towards Min Blur)."; ui_min = THRESHOLD_MIN; ui_max = THRESHOLD_MAX; ui_step = 0.01; ui_category = "Frosting"; > = 0.2f;
uniform float NormalsCutoffThreshold < ui_type = "slider"; ui_label = "Normals: Min Coverage Cutoff"; ui_tooltip = "Drop coverage BELOW this will have zero normals (no refraction). Helps remove ghosting."; ui_min = 0.00; ui_max = 0.2; ui_step = 0.005; ui_category = "Frosting"; > = 0.05f;

// Special Effects
uniform bool EnableLightning < ui_label = "Enable Lightning Effect"; ui_tooltip = "Adds random lightning flashes to simulate a storm."; ui_category = "Special Effects"; > = true;
uniform int LightningFrequency < ui_type = "combo"; ui_label = "Lightning Frequency"; ui_items = "Light Summer Rain\0Moderate Storm\0Heavy Thunderstorm\0Raging Tempest\0World-Ending Mega-Tempest\0"; ui_tooltip = "How often lightning flashes occur, from occasional to apocalyptic."; ui_category = "Special Effects"; > = 2;
uniform float LightningIntensity < ui_type = "slider"; ui_label = "Lightning Intensity"; ui_tooltip = "Controls the brightness of lightning flashes."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Special Effects"; > = 0.5;

// Audio Reactivity
AS_AUDIO_UI(RainAmount_AudioSource, "Rain Amount Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(RainAmount_AudioMultiplier, "Rain Amount Audio Intensity", 1.0, 2.0, "Audio Reactivity")

AS_PERSPECTIVE_UI(PerspectiveAngles, PerspectiveZOffset, PerspectiveFocalLength, "Perspective") // Added Perspective Controls

// Position & Stage Controls
AS_STAGEDEPTH_UI(StageDepth)
AS_POSITION_SCALE_UI(PositionOffset, Scale)
AS_ROTATION_UI(SnapRotation, FineRotation)

// Final Mix
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// Debug Controls
AS_DEBUG_UI("Off\0Show Focus Val\0Show Normals\0Show Coverage\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
float S(float a, float b, float t) { return smoothstep(a, b, t); }
float3 N13(float p_noise) { 
    float3 p3 = frac(p_noise * float3(0.1031f, 0.11369f, 0.13787f)); 
    p3 += dot(p3, p3.yzx + 19.19f); 
    return frac(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x)); 
}
float N(float t_noise) { return frac(sin(t_noise * 12345.564f) * 7658.76f); }
float Saw(float b_saw, float t_saw) { return S(0.0f, b_saw, t_saw) * S(1.0f, b_saw, t_saw); }

float2 DropLayer2(float2 uv_layer, float time_layer) {
    float2 UV_orig = uv_layer; 
    uv_layer.y += time_layer * 0.75f; 
    float2 a_geom = float2(6.0f, 1.0f); 
    float2 grid = a_geom * 2.0f;
    float2 id = floor(uv_layer * grid); 
    float colShift = N(id.x); 
    uv_layer.y += colShift; 
    id = floor(uv_layer * grid);
    float3 n_detail = N13(id.x*35.2f + id.y*2376.1f); 
    float2 st = frac(uv_layer * grid) - float2(0.5f, 0.0f);
    float x_pos = n_detail.x - 0.5f; 
    float y_base_for_wiggle = UV_orig.y * 20.0f; 
    float wiggle = sin(y_base_for_wiggle + sin(y_base_for_wiggle));
    x_pos += wiggle * (0.5f - abs(x_pos)) * (n_detail.z - 0.5f); 
    x_pos *= 0.7f;
    float ti_saw_input = frac(time_layer + n_detail.z); 
    float y_drop_center = (Saw(0.85f, ti_saw_input) - 0.5f) * 0.9f + 0.5f;
    float2 p_drop_shape_center = float2(x_pos, y_drop_center); 
    float d_to_center = length((st - p_drop_shape_center) * a_geom.yx);
    float mainDrop = S(0.4f, 0.0f, d_to_center); 
    float r_trail_factor = sqrt(S(1.0f, y_drop_center, st.y)); 
    float cd_trail_dist = abs(st.x - x_pos); 
    float trail_val = S(0.23f * r_trail_factor, 0.15f * r_trail_factor * r_trail_factor, cd_trail_dist);
    float trailFront = S(-0.02f, 0.02f, st.y - y_drop_center); 
    trail_val *= trailFront * r_trail_factor * r_trail_factor;
    float y_uv_for_droplets = UV_orig.y; 
    float trail2 = S(0.2f * r_trail_factor, 0.0f, cd_trail_dist);
    float droplets = max(0.0f, (sin(y_uv_for_droplets * (1.0f - y_uv_for_droplets) * 120.0f) - st.y)) * trail2 * trailFront * n_detail.z;
    y_uv_for_droplets = frac(y_uv_for_droplets * 10.0f) + (st.y - 0.5f); 
    float dd_to_droplets = length(st - float2(x_pos, y_uv_for_droplets));
    droplets = S(0.3f, 0.0f, dd_to_droplets); 
    float m_final_drop_shape = mainDrop + droplets * r_trail_factor * trailFront;
    return float2(m_final_drop_shape, trail_val);
}

float StaticDrops(float2 uv_static, float time_static) {
    uv_static *= 40.0f; 
    float2 id = floor(uv_static); 
    uv_static = frac(uv_static) - 0.5f;
    float3 n_detail = N13(id.x * 107.45f + id.y * 3543.654f); 
    float2 p_center = (n_detail.xy - 0.5f) * 0.7f;
    float d_to_center = length(uv_static - p_center); 
    float fade = Saw(0.025f, frac(time_static + n_detail.z));
    return S(0.3f, 0.0f, d_to_center) * frac(n_detail.z * 10.0f) * fade;
}

float2 CalculateOverallDrops(float2 uv_main, float time_main, float static_intensity, float layer1_intensity, float layer2_intensity) {
    float static_contrib = StaticDrops(uv_main, time_main) * static_intensity;
    float2 layer1_contrib = DropLayer2(uv_main, time_main) * layer1_intensity;
    float2 layer2_contrib = DropLayer2(uv_main * 1.85f, time_main) * layer2_intensity;
    float total_coverage = static_contrib + layer1_contrib.x + layer2_contrib.x;
    total_coverage = S(0.3f, 1.0f, total_coverage); // This is 'drop_coverage'
    float max_trail = max(layer1_contrib.y, layer2_contrib.y);
    return float2(total_coverage, max_trail);
}

float GetGaussianWeight(int i, float sigma) { 
    float x = (float)i; 
    return exp(-(x*x) / (2.0f * sigma * sigma)); 
}

// Applies Gaussian blur with quality adjustment based on blur quality slider
float3 ApplyGaussianBlur(float2 uv, float2 direction, float radius_pixels, float2 refraction_offset, sampler sourceSampler) {
    // Early exit for no effective blur or if only refraction is needed without blur
    if (radius_pixels < 0.5f) { 
        if (dot(refraction_offset, refraction_offset) > 1e-6f) 
            return tex2D(sourceSampler, uv + refraction_offset).rgb; // Just apply refraction
        else
            return tex2D(sourceSampler, uv).rgb; // No blur, no refraction
    }

    // Calculate sigma based on radius
    float sigma = radius_pixels / 2.5f; 
    if (sigma < 0.1f) sigma = 0.1f; // Prevent sigma from being too small

    // Adjust sample count based on quality setting
    int quality_adjusted_max_samples = lerp(MIN_BLUR_SAMPLES, MAX_BLUR_SAMPLES, BlurQuality);
    int num_samples_one_side = clamp(int(ceil(sigma * 2.5f)), 1, quality_adjusted_max_samples); 

    // Calculate Gaussian weights
    float weights[MAX_BLUR_SAMPLES + 1]; 
    float weightSum = GetGaussianWeight(0, sigma);
    weights[0] = weightSum;
    
    for (int i = 1; i <= num_samples_one_side; i++) {
        weights[i] = GetGaussianWeight(i, sigma);
        weightSum += 2.0f * weights[i];
    }
    
    // Normalize weights
    if (weightSum < 1e-6f) weightSum = 1e-6f; 
    for (int i = 0; i <= num_samples_one_side; i++) {
        weights[i] /= weightSum;
    }
    
    // Apply blur using calculated weights
    float3 blurred_color = tex2D(sourceSampler, uv + refraction_offset).rgb * weights[0];
    
    for (int i = 1; i <= num_samples_one_side; i++) {
        float2 sample_offset_step = direction * ReShade::PixelSize * (float)i; // Pixel-correct steps
        blurred_color += tex2D(sourceSampler, uv + refraction_offset + sample_offset_step).rgb * weights[i];
        blurred_color += tex2D(sourceSampler, uv + refraction_offset - sample_offset_step).rgb * weights[i];
    }
    return blurred_color;
}

// ============================================================================
// NEW PIXEL SHADERS FOR SEPARATED APPROACH
// ============================================================================

// PASS 0: Generate Effect Maps
float4 GenerateEffectMapsPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Depth check (optional, if effect map generation should be culled by depth)
    // float depth = ReShade::GetLinearizedDepth(texcoord);
    // if (depth < StageDepth - AS_DEPTH_EPSILON) return float4(0,0,0,0); 

    float hiddenRotation = AS_PI; 
    float actualRotation = -AS_getRotationRadians(SnapRotation, FineRotation) + hiddenRotation;
    float2 centered_uv_no_perspective = AS_transformCoord(texcoord, PositionOffset, Scale, actualRotation); // Renamed to clarify
    
    // Apply perspective transform
    float2 aspect_corrected_centered_uv = centered_uv_no_perspective;
    aspect_corrected_centered_uv.x *= ReShade::AspectRatio; // Correct for aspect ratio for the perspective function

    float2 centered_uv = AS_applyPerspectiveTransform(
        aspect_corrected_centered_uv, 
        PerspectiveAngles, 
        PerspectiveZOffset, 
        PerspectiveFocalLength
    );
    centered_uv.x /= ReShade::AspectRatio; // Scale back if the perspective output is in a space where x was expanded

    float2 uv_for_drops = centered_uv + 0.5; // Uncenter: transform from (-0.5, 0.5) to (0,1) range
    
    float current_rain_amount = RainAmount;
    if (RainAmount_AudioSource != AS_AUDIO_OFF) {
        current_rain_amount = AS_applyAudioReactivity(RainAmount, RainAmount_AudioSource, RainAmount_AudioMultiplier, true);
    }
    
    float time_current_seconds = AS_getTime();
    float t_for_drops_animation = time_current_seconds * DropAnimationSpeed;
    
    // Calculate drop_coverage and trail_effect
    float static_drops_intensity = S(-0.5f, 1.0f, current_rain_amount) * 2.0f;
    float layer1_intensity = S(0.25f, 0.75f, current_rain_amount);
    float layer2_intensity = S(0.0f, 0.5f, current_rain_amount);
    float2 drop_effects = CalculateOverallDrops(uv_for_drops, t_for_drops_animation, static_drops_intensity, layer1_intensity, layer2_intensity);
    float drop_coverage = drop_effects.x; 
    float trail_effect = drop_effects.y;

    // Calculate original_drop_normals
    float2 normal_offset_e = float2(ReShade::PixelSize.x * 2.0, ReShade::PixelSize.y * 2.0); // Use pixel size for normal diff
    float coverage_dx = CalculateOverallDrops(uv_for_drops + normal_offset_e.xy, t_for_drops_animation, static_drops_intensity, layer1_intensity, layer2_intensity).x;
    float coverage_dy = CalculateOverallDrops(uv_for_drops + normal_offset_e.yx, t_for_drops_animation, static_drops_intensity, layer1_intensity, layer2_intensity).x;
    float2 original_drop_normals = float2(coverage_dx - drop_coverage, coverage_dy - drop_coverage) * 50.0; // Multiply normals for visible effect, tune 50.0

    // Calculate focus_val (blur radius in pixels)
    float effective_max_blur = lerp(Frost_MaxBlur_BaseLowRain, Frost_MaxBlur_BaseHighRain, current_rain_amount);
    float effective_min_blur = Frost_MinBlur_Constant;
    float blur_target_max_frost = effective_max_blur;
    blur_target_max_frost = max(blur_target_max_frost - (trail_effect * 10.0f * effective_max_blur), effective_min_blur); // Trail effect scales with max blur
    
    float drop_influence_for_lerp = saturate((drop_coverage - FrostThresholdLow) / max(0.01f, FrostThresholdHigh - FrostThresholdLow));
    float focus_val = lerp(blur_target_max_frost, effective_min_blur, drop_influence_for_lerp);
    focus_val = max(0.0f, focus_val);

    // Debug visualizations using standardized debug mode
    if (DebugMode == 1) return float4(focus_val / FROST_MAX_BLUR_PIXELS, 0, 0, 1); // Show Focus Val
    if (DebugMode == 2) return float4(original_drop_normals * 0.5 + 0.5, 0, 1);    // Show Normals
    if (DebugMode == 3) return float4(drop_coverage, drop_coverage, drop_coverage, 1); // Show Coverage

    // Output: R=focus_val, GB=normal.xy, A=drop_coverage
    return float4(focus_val, original_drop_normals.x, original_drop_normals.y, drop_coverage);
}

// PASS 1: Pure Horizontal Blur
float4 PureHorizontalBlurPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {    float depth = ReShade::GetLinearizedDepth(texcoord); // Depth check for blur pass
    if (depth < StageDepth - AS_DEPTH_EPSILON) 
        return tex2D(ReShade::BackBuffer, texcoord);

    float focus_val = tex2D(RainyWindow_EffectMapSampler, texcoord).r;
    float2 blur_direction = float2(1.0f, 0.0f);
    
    float3 blurred_color = ApplyGaussianBlur(texcoord, blur_direction, focus_val, float2(0.0f, 0.0f), ReShade::BackBuffer);
    return float4(blurred_color, 1.0f);
}

// PASS 2: Pure Vertical Blur
float4 PureVerticalBlurPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    float depth = ReShade::GetLinearizedDepth(texcoord); // Depth check for blur pass
    if (depth < StageDepth - AS_DEPTH_EPSILON) 
        return tex2D(RainyWindow_HorizontalBlurSampler, texcoord); // Pass through already H-blurred if culled

    float focus_val = tex2D(RainyWindow_EffectMapSampler, texcoord).r;
    float2 blur_direction = float2(0.0f, 1.0f);

    float3 blurred_color = ApplyGaussianBlur(texcoord, blur_direction, focus_val, float2(0.0f, 0.0f), RainyWindow_HorizontalBlurSampler);
    return float4(blurred_color, 1.0f);
}

// PASS 3: Final Composite
float4 FinalCompositePS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    float4 original_scene_color = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    
    if (depth < StageDepth - AS_DEPTH_EPSILON) return original_scene_color;

    float4 effect_map_data = tex2D(RainyWindow_EffectMapSampler, texcoord);
    // float focus_val_from_map = effect_map_data.r; // Not directly used here, but was used for blurring
    float2 original_drop_normals = effect_map_data.gb;
    float drop_coverage = effect_map_data.a;

    // Determine active normals for refraction
    float drop_influence_for_normals = saturate((drop_coverage - FrostThresholdLow) / max(0.01f, FrostThresholdHigh - FrostThresholdLow));
    float2 active_normals = original_drop_normals * drop_influence_for_normals;
    if (drop_coverage < NormalsCutoffThreshold) { // Use the UI tunable threshold
        active_normals = float2(0.0f, 0.0f);
    }
      // Get the purely blurred background (which already has correct blur levels for droplet vs frosted areas)
    float3 pure_blurred_bg = tex2D(RainyWindow_BlurredBackgroundSampler, texcoord).rgb;

    // Apply refraction to the (appropriately blurred or sharp) background
    float3 view_through_glass = tex2D(RainyWindow_BlurredBackgroundSampler, texcoord + active_normals * ReShade::PixelSize * 2.0).rgb; // Small pixel scale for normals offset, tune "2.0"

    // Lightning effect
    float3 final_pixel_color_lit = view_through_glass;
    if (EnableLightning) {
        float time_current_seconds = AS_getTime(); // Get time again for this pass if needed
        float frequencyMultiplier;
        switch (LightningFrequency) {
            case 0: frequencyMultiplier = LIGHTNING_FREQ_LIGHT_SUMMER; break;
            case 1: frequencyMultiplier = LIGHTNING_FREQ_MODERATE_STORM; break;
            case 2: frequencyMultiplier = LIGHTNING_FREQ_HEAVY_THUNDERSTORM; break;
            case 3: frequencyMultiplier = LIGHTNING_FREQ_RAGING_TEMPEST; break;
            case 4: frequencyMultiplier = LIGHTNING_FREQ_APOCALYPSE; break;
            default: frequencyMultiplier = LIGHTNING_FREQ_HEAVY_THUNDERSTORM; break;
        }
        float t_lightning = (time_current_seconds + 3.0f) * frequencyMultiplier; // Copied from old PS
        float lightning_flicker = sin(t_lightning * sin(t_lightning * 10.0f));
        float flashExponent = 10.0f + (frequencyMultiplier * 2.0f);
        lightning_flicker *= pow(max(0.0f, sin(t_lightning + sin(t_lightning))), flashExponent);
        final_pixel_color_lit += final_pixel_color_lit * lightning_flicker * LightningIntensity;
    }
    
    float3 result_blended = AS_applyBlend(final_pixel_color_lit, original_scene_color.rgb, BlendMode);
    return float4(lerp(original_scene_color.rgb, result_blended, BlendStrength), original_scene_color.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_VFX_RainyWindow <
    ui_label = "[AS] VFX: Rainy Window";
    ui_tooltip = "Realistic rainy window effect with droplets, blur, and frost.\n"
                 "Part of AS StageFX shader collection by Leon Aquitaine.";
>
{    pass GenerateMapsPass {
        VertexShader = PostProcessVS;
        PixelShader = GenerateEffectMapsPS;
        RenderTarget0 = RainyWindow_EffectMapTarget;
    }
    pass PureHorizontalBlurPass {
        VertexShader = PostProcessVS;
        PixelShader = PureHorizontalBlurPS;
        RenderTarget0 = RainyWindow_HorizontalBlurTarget;
    }
    pass PureVerticalBlurPass {
        VertexShader = PostProcessVS;
        PixelShader = PureVerticalBlurPS;
        RenderTarget0 = RainyWindow_BlurredBackgroundTarget;
    }
    pass FinalCompositePass {
        VertexShader = PostProcessVS;
        PixelShader = FinalCompositePS;
        // RenderTarget is implied to be ReShade::BackBuffer
    }
}

#endif // __AS_VFX_RainyWindow_1_fx
