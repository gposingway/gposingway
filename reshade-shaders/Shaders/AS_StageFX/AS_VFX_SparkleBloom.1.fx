/**
 * AS_VFX_SparkleBloom.1.fx - Dynamic Sparkle Effect Shader
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates a realistic glitter/sparkle effect that dynamically responds to scene
 * lighting, depth, and camera movement. It simulates tiny reflective particles that pop in,
 * glow, and fade out, creating the appearance of sparkles on surfaces.
 *
 * FEATURES:
 * - Multi-layered voronoi noise for natural sparkle distribution
 * - Dynamic sparkle animation with customizable lifetime
 * - Depth-based masking for placement control
 * - High-quality bloom with adjustable quality settings
 * - Normal-based fresnel effect for realistic light interaction
 * - Multiple blend modes and color options
 * - Audio-reactive sparkle intensity and animation via Listeningway
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader uses multiple layers of Voronoi noise at different scales to generate the base sparkle pattern
 * 2. Each sparkle has its own lifecycle (fade in, sustain, fade out) based on its position and the animation time
 * 3. Surface normals are reconstructed from the depth buffer to apply fresnel effects, making sparkles appear more prominently at glancing angles
 * 4. A two-pass gaussian bloom is applied for a soft, natural glow effect
 * 5. Multiple blend modes allow for different integration with the scene
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_SparkleBloom_1_fx
#define __AS_VFX_SparkleBloom_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float GLITTERDENSITY_MIN = 0.1;
static const float GLITTERDENSITY_MAX = 20.0;
static const float GLITTERDENSITY_DEFAULT = 10.0;

static const float GLITTERSIZE_MIN = 0.1;
static const float GLITTERSIZE_MAX = 10.0;
static const float GLITTERSIZE_DEFAULT = 5.0;

static const float GLITTERBRIGHTNESS_MIN = 0.1;
static const float GLITTERBRIGHTNESS_MAX = 12.0;
static const float GLITTERBRIGHTNESS_DEFAULT = 6.0;

static const float GLITTERSHARPNESS_MIN = 0.1;
static const float GLITTERSHARPNESS_MAX = 2.1;
static const float GLITTERSHARPNESS_DEFAULT = 1.1;

static const float GLITTERSPEED_MIN = 0.1;
static const float GLITTERSPEED_MAX = 1.5;
static const float GLITTERSPEED_DEFAULT = 0.8;

static const float GLITTERLIFETIME_MIN = 1.0;
static const float GLITTERLIFETIME_MAX = 20.0;
static const float GLITTERLIFETIME_DEFAULT = 10.0;

static const float BLOOMINTENSITY_MIN = 0.1;
static const float BLOOMINTENSITY_MAX = 3.1;
static const float BLOOMINTENSITY_DEFAULT = 0.3;

static const float BLOOMRADIUS_MIN = 1.0;
static const float BLOOMRADIUS_MAX = 10.2;
static const float BLOOMRADIUS_DEFAULT = 3.6;

static const float BLOOMDISPERSION_MIN = 1.0;
static const float BLOOMDISPERSION_MAX = 3.0;
static const float BLOOMDISPERSION_DEFAULT = 1.2;

static const float NEARPLANE_MIN = 0.0;
static const float NEARPLANE_MAX = 1.0;
static const float NEARPLANE_DEFAULT = 0.0;

static const float FARPLANE_MIN = 0.0;
static const float FARPLANE_MAX = 1.0;
static const float FARPLANE_DEFAULT = 1.0;

static const float DEPTHCURVE_MIN = 0.1;
static const float DEPTHCURVE_MAX = 10.0;
static const float DEPTHCURVE_DEFAULT = 1.0;

static const float BLENDAMOUNT_MIN = 0.0;
static const float BLENDAMOUNT_MAX = 1.0;
static const float BLENDAMOUNT_DEFAULT = 1.0;

static const float TIMESCALE_MIN = 1.0;
static const float TIMESCALE_MAX = 17.0;
static const float TIMESCALE_DEFAULT = 9.0;

// Normal reconstruction constants
static const float NORMAL_SAMPLE_DISTANCE = 2.0;    // Distance multiplier for sampling depth
static const float NORMAL_GRADIENT_SCALE = 4.0;     // Scale for computing depth gradients

// Fresnel constants
static const float FRESNEL_POWER_MIN = 1.0;
static const float FRESNEL_POWER_MAX = 10.0;
static const float FRESNEL_POWER_DEFAULT = 5.0;

// Time scale constants
static const float TIME_DIVISOR = 333.33;           // Divisor to normalize time scale

// Sparkle constants
static const float SPARKLE_THRESHOLD = 0.05;        // Alpha threshold for sparkle visibility
static const float SPARKLE_CONTRIBUTION_MULT = 5.0; // Multiplier for sparkle brightness
static const float SPARKLE_COORD_SCALE = 0.005;     // Scale for noise coordinate sampling
static const float SPARKLE_STAR_POINTS = 4.0;       // Number of points on star-shaped sparkles

// Bloom constants
static const float BLOOM_DITHER_SCALE = 0.001;      // Scale for dithering offset

// ============================================================================
// EFFECT-SPECIFIC PARAMETERS
// ============================================================================

// --- Sparkle Appearance ---
uniform float GlitterDensity < ui_type = "slider"; ui_label = "Density"; ui_tooltip = "Controls how many sparkles are generated on the screen. Higher values increase the number of sparkles."; ui_min = GLITTERDENSITY_MIN; ui_max = GLITTERDENSITY_MAX; ui_step = 0.1; ui_category = "Sparkle Appearance"; > = GLITTERDENSITY_DEFAULT;
uniform float GlitterSize < ui_type = "slider"; ui_label = "Size"; ui_tooltip = "Adjusts the size of each individual sparkle. Larger values make sparkles appear bigger."; ui_min = GLITTERSIZE_MIN; ui_max = GLITTERSIZE_MAX; ui_step = 0.1; ui_category = "Sparkle Appearance"; > = GLITTERSIZE_DEFAULT;
uniform float GlitterBrightness < ui_type = "slider"; ui_label = "Brightness"; ui_tooltip = "Sets the overall brightness of the sparkles. Higher values make sparkles more intense and visible."; ui_min = GLITTERBRIGHTNESS_MIN; ui_max = GLITTERBRIGHTNESS_MAX; ui_step = 0.1; ui_category = "Sparkle Appearance"; > = GLITTERBRIGHTNESS_DEFAULT;
uniform float GlitterSharpness < ui_type = "slider"; ui_label = "Sharpness"; ui_tooltip = "Controls how crisp or soft the edges of sparkles appear. Higher values make sparkles more defined."; ui_min = GLITTERSHARPNESS_MIN; ui_max = GLITTERSHARPNESS_MAX; ui_step = 0.05; ui_category = "Sparkle Appearance"; > = GLITTERSHARPNESS_DEFAULT;

// ============================================================================
// FRESNEL CONTROLS
// ============================================================================
uniform float FresnelPower < ui_type = "slider"; ui_label = "Edge Power"; ui_tooltip = "Controls how strongly edges are emphasized. Higher values make sparkles appear more prominently on edges."; ui_min = FRESNEL_POWER_MIN; ui_max = FRESNEL_POWER_MAX; ui_step = 0.1; ui_category = "Sparkle Appearance"; > = FRESNEL_POWER_DEFAULT;

// ============================================================================
// ANIMATION CONTROLS
// ============================================================================
uniform float GlitterSpeed < ui_type = "slider"; ui_label = "Speed"; ui_tooltip = "Sets how quickly sparkles animate and move. Higher values increase animation speed."; ui_min = GLITTERSPEED_MIN; ui_max = GLITTERSPEED_MAX; ui_step = 0.05; ui_category = "Animation Controls"; > = GLITTERSPEED_DEFAULT;
uniform float GlitterLifetime < ui_type = "slider"; ui_label = "Lifetime"; ui_tooltip = "Determines how long each sparkle remains visible before fading out."; ui_min = GLITTERLIFETIME_MIN; ui_max = GLITTERLIFETIME_MAX; ui_step = 0.1; ui_category = "Animation Controls"; > = GLITTERLIFETIME_DEFAULT;
uniform float TimeScale < ui_type = "slider"; ui_label = "Time Scale"; ui_tooltip = "Scales the overall animation timing for all sparkles. Use to speed up or slow down the effect globally."; ui_min = TIMESCALE_MIN; ui_max = TIMESCALE_MAX; ui_step = 0.5; ui_category = "Animation Controls"; > = TIMESCALE_DEFAULT;

// ============================================================================
// BLOOM EFFECT CONTROLS
// ============================================================================
uniform bool EnableBloom < ui_label = "Enable Bloom"; ui_tooltip = "Enables or disables the bloom (glow) effect around sparkles for a softer, more radiant look."; ui_category = "Bloom Effect"; > = true;
uniform float BloomIntensity < ui_type = "slider"; ui_label = "Intensity"; ui_tooltip = "Controls how strong the bloom (glow) effect appears around sparkles."; ui_min = BLOOMINTENSITY_MIN; ui_max = BLOOMINTENSITY_MAX; ui_step = 0.05; ui_category = "Bloom Effect"; ui_spacing = 1; ui_bind = "EnableBloom"; > = BLOOMINTENSITY_DEFAULT;
uniform float BloomRadius < ui_type = "slider"; ui_label = "Radius"; ui_tooltip = "Sets how far the bloom effect extends from each sparkle. Larger values create a wider glow."; ui_min = BLOOMRADIUS_MIN; ui_max = BLOOMRADIUS_MAX; ui_step = 0.2; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = BLOOMRADIUS_DEFAULT;
uniform float BloomDispersion < ui_type = "slider"; ui_label = "Dispersion"; ui_tooltip = "Adjusts how quickly the bloom fades at the edges. Higher values make the glow softer and more gradual."; ui_min = BLOOMDISPERSION_MIN; ui_max = BLOOMDISPERSION_MAX; ui_step = 0.05; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = BLOOMDISPERSION_DEFAULT;
uniform int BloomQuality < ui_type = "combo"; ui_label = "Quality"; ui_tooltip = "Selects the quality level for the bloom effect. Higher quality reduces artifacts but may impact performance."; ui_items = "Potato\0Low\0Medium\0High\0Ultra\0AI Overlord\0"; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = 3;
uniform bool BloomDither < ui_label = "Dither"; ui_tooltip = "Adds subtle noise to the bloom to reduce color banding and grid patterns."; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = true;

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================
AS_AUDIO_UI(Listeningway_SparkleSource, "Sparkle Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(Listeningway_SparkleMultiplier, "Sparkle Intensity", 1.5, 5.0, "Audio Reactivity")
AS_AUDIO_UI(Listeningway_BloomSource, "Bloom Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(Listeningway_BloomMultiplier, "Bloom Intensity", 10.0, 10.0, "Audio Reactivity")
AS_AUDIO_UI(Listeningway_TimeScaleSource, "Time Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(Listeningway_TimeScaleBand1Multiplier, "Time Intensity", 1.0, 5.0, "Audio Reactivity")

// ============================================================================
// COLOR SETTINGS
// ============================================================================
uniform float3 GlitterColor < ui_type = "color"; ui_label = "Color"; ui_tooltip = "Sets the base color of all sparkles."; ui_category = "Color Settings"; > = float3(1.0, 1.0, 1.0);
uniform bool DepthColoringEnable < ui_label = "Depth Color"; ui_tooltip = "If enabled, sparkles will change color based on their distance from the camera."; ui_category = "Color Settings"; > = true;
uniform float3 NearColor < ui_type = "color"; ui_label = "Near Color"; ui_tooltip = "Color for sparkles close to the camera."; ui_category = "Color Settings"; > = float3(1.0, 204/255.0, 153/255.0);
uniform float3 FarColor < ui_type = "color"; ui_label = "Far Color"; ui_tooltip = "Color for sparkles far from the camera."; ui_category = "Color Settings"; > = float3(153/255.0, 204/255.0, 1.0);

// ============================================================================
// DEPTH MASKING
// ============================================================================
uniform float NearPlane < ui_type = "slider"; ui_label = "Near"; ui_tooltip = "Controls the minimum distance from the camera where sparkles can appear. Lower values allow sparkles closer to the camera."; ui_min = NEARPLANE_MIN; ui_max = NEARPLANE_MAX; ui_step = 0.01; ui_category = "Depth Masking"; > = NEARPLANE_DEFAULT;
uniform float FarPlane < ui_type = "slider"; ui_label = "Far"; ui_tooltip = "Controls the maximum distance from the camera where sparkles can appear. Lower values bring the cutoff closer."; ui_min = FARPLANE_MIN; ui_max = FARPLANE_MAX; ui_step = 0.01; ui_category = "Depth Masking"; > = FARPLANE_DEFAULT;
uniform float DepthCurve < ui_type = "slider"; ui_label = "Curve"; ui_tooltip = "Adjusts how quickly sparkles fade out with distance. Higher values make the fade sharper."; ui_min = DEPTHCURVE_MIN; ui_max = DEPTHCURVE_MAX; ui_step = 0.1; ui_category = "Depth Masking"; > = DEPTHCURVE_DEFAULT;
uniform bool AllowInfiniteCutoff < ui_label = "Infinite Cutoff"; ui_tooltip = "If enabled, sparkles can appear all the way to the horizon. If disabled, sparkles beyond the cutoff distance are hidden."; ui_category = "Depth Masking"; > = true;
uniform bool ObeyOcclusion < ui_label = "Occlusion"; ui_tooltip = "If enabled, sparkles and bloom will be masked by scene depth, so they do not appear through objects."; ui_category = "Depth Masking"; > = true;

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_UI("Off\0Depth\0Normal\0Sparkle\0Mask\0Force On\0")

// ============================================================================
// TEXTURES AND SAMPLERS
// ============================================================================
AS_CREATE_TEX_SAMPLER(SparkleBloom_SparkleRT, SparkleBloom_SparkleSampler, float2(BUFFER_WIDTH, BUFFER_HEIGHT), RGBA16F, 1, POINT, CLAMP)
AS_CREATE_TEX_SAMPLER(SparkleBloom_BloomRT, SparkleBloom_BloomSampler, float2(BUFFER_WIDTH / 2, BUFFER_HEIGHT / 2), RGBA16F, 1, LINEAR, CLAMP)

/*-----------------------------.
| :: Helper Functions and Constants |
'-----------------------------*/

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
namespace AS_SparkleBloom {
    // Layer properties for multi-layered sparkle effect
    static const float SPARKLE_LAYER_SIZES[3]   = {0.05, 0.03, 0.02};
    static const float SPARKLE_LAYER_WEIGHTS[3] = {1.0, 0.7, 0.3};
    static const float SPARKLE_LAYER_SPEEDS[3]  = {1.0, 1.2, 0.8};
    static const float SPARKLE_LAYER_POWS[3]    = {0.5, 0.7, 0.9};

    // Gaussian distribution function for bloom
    float Gaussian(float x, float sigma) {
        return (1.0 / (sqrt(2.0 * AS_PI) * sigma)) * exp(-(x * x) / (2.0 * sigma * sigma));
    }
    
    // Get bloom step size based on quality setting
    float getBloomStepSize(int quality) {
        switch(quality) {
            case 0: return 4.0;  // Potato
            case 1: return 2.0;  // Low
            case 2: return 1.0;  // Medium
            case 3: return 0.5;  // High
            case 4: return 0.25; // Ultra
            case 5: return 0.125; // AI Overlord
            default: return 1.0; // Default to Medium
        }
    }

    // Calculate dither noise for bloom to reduce banding
    float2 calculateDitherNoise(float2 texcoord, float2 seeds, float stepSize) {
        float2 noise = frac(sin(dot(texcoord, seeds)) * 43758.5453);
        noise = noise * 2.0 - 1.0;
        noise *= 0.25 * stepSize;
        return noise;
    }
    
    // Voronoi noise generation for sparkle patterns
    float2 voronoi(float2 x, float offset) {
        float2 n = floor(x);
        float2 f = frac(x);
        float2 mg, mr;
        float md = 8.0;
        
        [unroll]
        for(int j = -1; j <= 1; j++) {
            [unroll]
            for(int i = -1; i <= 1; i++) {
                float2 g = float2(float(i), float(j));
                float2 o = AS_hash33(float3(n + g, AS_hash21(n + g).x * 10.0 + offset)).xy * 0.5 + 0.5;
                float2 r = g + o - f;
                float d = dot(r, r);
                if(d < md) { md = d; mr = r; mg = g; }
            }
        }
        return float2(sqrt(md), AS_hash21(n + mg).x);
    }
    
    // Calculate sparkle lifecycle (fade in/out)
    float calculateSparkleLifecycle(float time, float sparkleID, float speedMod, float lifeDuration) {
        float cycle = frac((time * speedMod + sparkleID * (10.0 + 5.0 * speedMod)) / lifeDuration);
        float fadeInEnd = 0.2;
        float fadeOutStart = 0.8;
        float brightness = 1.0;
        
        if (cycle < fadeInEnd) {
            brightness = smoothstep(0.0, fadeInEnd, cycle) / fadeInEnd;
        } else if (cycle > fadeOutStart) {
            brightness = 1.0 - smoothstep(fadeOutStart, 1.0, cycle) / (1.0 - fadeOutStart);
        }
        
        return brightness;
    }
    
    // Star shape generator for star-shaped sparkles
    float star(float2 p, float size, float points, float angle) {
        float2 uv = p;
        float a = atan2(uv.y, uv.x) + angle;
        float r = length(uv);
        float f = cos(a * points) * 0.5 + 0.5;
        return 1.0 - smoothstep(f * size, f * size + 0.01, r);
    }
    
    // Main sparkle generation function
    float sparkle(float2 uv, float time) {
        float sparkleSum = 0.0;
        float2 voronoiResult;
        float sparkleScale = GlitterSize * 0.4;
        float sharpnessFactor = GlitterSharpness;
        float lifeDuration = 1.0 + GlitterLifetime * 0.2;
        
        for (int layer = 0; layer < 3; ++layer) {
            // Scale density by layer (more detail in higher layers)
            float layerDensity = GlitterDensity * (layer == 0 ? 0.5 : (layer == 1 ? 1.0 : 2.0));
            
            // Get voronoi points, animated over time
            voronoiResult = voronoi(uv * layerDensity, time * (0.1 + 0.05 * layer));
            
            float sparkleID = voronoiResult.y;
            float dist = voronoiResult.x;
            
            // Calculate brightness based on lifecycle
            float brightness = calculateSparkleLifecycle(time, sparkleID, SPARKLE_LAYER_SPEEDS[layer], lifeDuration);
            brightness = pow(brightness, SPARKLE_LAYER_POWS[layer]);
            
            // Basic sparkle shape based on distance
            float sparkleShape = (1.0 - smoothstep(0.0, SPARKLE_LAYER_SIZES[layer] * sparkleScale / sharpnessFactor, dist)) * brightness;
            
            // Add star shape for the first layer
            if (layer == 0 && dist < SPARKLE_LAYER_SIZES[0] * sparkleScale / sharpnessFactor) {
                float starMask = star(uv - (uv - voronoiResult.xy), SPARKLE_LAYER_SIZES[0] * sparkleScale / sharpnessFactor, SPARKLE_STAR_POINTS, sparkleID * AS_TWO_PI);
                sparkleShape = max(sparkleShape, starMask * brightness * 2.0);
            }
            
            // Add this layer's contribution
            sparkleSum += sparkleShape * SPARKLE_LAYER_WEIGHTS[layer];
        }
        
        // Scale by density to allow more control
        sparkleSum *= GlitterDensity * 0.1;
        return saturate(sparkleSum);
    }
} // end namespace AS_SparkleBloom

// --- Audio Source Helper ---
float GetAudioSource(int source) {
    return AS_getAudioSource(source);
}

/*-----------------------------------.
| :: First Pass - Sparkle Generation |
'-----------------------------------*/

float4 PS_RenderSparkles(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Get background color and depth
    float4 color = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    
    // Handle debug/force enable mode
    bool forceEnable = (DebugMode == 5);
    if (forceEnable) { depth = 0.5; }
    
    // Create depth mask
    float depthMask = AS_depthMask(depth, NearPlane, FarPlane, DepthCurve);
    if (forceEnable) { depthMask = 1.0; }
    
    // Skip if beyond far plane cutoff
    if (!AllowInfiniteCutoff && depth >= FarPlane) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
    
    // Calculate normals and fresnel
    float3 normal = float3(0, 0, 1);
    float fresnel = 1.0;
    
    if (!forceEnable) {
        // Reconstruct normal from depth
        float3 offset = float3(ReShade::PixelSize.xy, 0.0);
        float2 posCenter = texcoord;
        
        // Sample depth in a cross pattern
        float depthCenter = ReShade::GetLinearizedDepth(posCenter);
        float depthLeft = ReShade::GetLinearizedDepth(posCenter - offset.xz * NORMAL_SAMPLE_DISTANCE);
        float depthRight = ReShade::GetLinearizedDepth(posCenter + offset.xz * NORMAL_SAMPLE_DISTANCE);
        float depthTop = ReShade::GetLinearizedDepth(posCenter - offset.zy * NORMAL_SAMPLE_DISTANCE);
        float depthBottom = ReShade::GetLinearizedDepth(posCenter + offset.zy * NORMAL_SAMPLE_DISTANCE);
        
        // Calculate normal from depth differences
        float3 dx = float3(offset.x * NORMAL_GRADIENT_SCALE, 0.0, depthRight - depthLeft);
        float3 dy = float3(0.0, offset.y * NORMAL_GRADIENT_SCALE, depthBottom - depthTop);
        normal = normalize(cross(dx, dy));
        
        // Remap normal from [-1,1] to [0,1] and back for consistent processing
        normal = normal * 0.5 + 0.5;
        normal = normal * 2.0 - 1.0;
    }
    
    // Calculate time with audio reactivity
    float actualTimeScale = TimeScale / TIME_DIVISOR;
    actualTimeScale += GetAudioSource(Listeningway_TimeScaleSource) * 
                        Listeningway_TimeScaleBand1Multiplier / TIME_DIVISOR;
    float time = AS_getTime() * actualTimeScale;
    
    // Generate sparkles
    float positionHash = AS_hash21(floor(texcoord * 10.0)).x * 10.0;
    float2 noiseCoord = texcoord * ReShade::ScreenSize * SPARKLE_COORD_SCALE;
    float sparkleIntensity = AS_SparkleBloom::sparkle(noiseCoord, positionHash + time);
    
    // Apply audio reactivity to sparkle intensity
    sparkleIntensity *= (1.0 + GetAudioSource(Listeningway_SparkleSource) * 
                        Listeningway_SparkleMultiplier);
    
    // Apply fresnel effect for edge highlighting
    float3 viewDir = float3(0.0, 0.0, 1.0);
    fresnel = pow(1.0 - saturate(dot(normal, viewDir)), FresnelPower);
    
    // Apply masking based on occlusion settings
    if (!forceEnable && ObeyOcclusion) {
        sparkleIntensity *= fresnel * depthMask;
    }
    else if (!forceEnable && !ObeyOcclusion) {
        sparkleIntensity *= fresnel;
    }
    
    // Apply brightness
    sparkleIntensity *= GlitterBrightness;
    
    // Debug visualizations
    if (DebugMode == 1) return float4(depth.xxx, 1.0);
    else if (DebugMode == 2) return float4(normal * 0.5 + 0.5, 1.0);
    else if (DebugMode == 3) return float4(sparkleIntensity.xxx, 1.0);
    else if (DebugMode == 4) return float4(depthMask.xxx, 1.0);
    
    // Calculate sparkle color
    float3 finalGlitterColor = GlitterColor;
    if (DepthColoringEnable && !forceEnable) {
        float depthFactor = smoothstep(NearPlane, FarPlane, depth);
        finalGlitterColor = lerp(NearColor, FarColor, depthFactor);
    }
    
    // Prepare final sparkle contribution
    float3 sparkleContribution = finalGlitterColor * sparkleIntensity * SPARKLE_CONTRIBUTION_MULT;
    
    // Output only the sparkles (on black), alpha as mask
    return float4(sparkleContribution, sparkleIntensity > SPARKLE_THRESHOLD ? 1.0 : 0.0);
}

/*-----------------------------------.
| :: Second Pass - Horizontal Bloom |
'-----------------------------------*/

float4 PS_BloomH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Early return for debug modes
    if (DebugMode > 0 && DebugMode < 5) {
        return tex2D(SparkleBloom_SparkleSampler, texcoord);
    }
    
    // Skip bloom calculation if disabled
    if (!EnableBloom) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
    
    // Initialize bloom accumulation
    float4 color = float4(0.0, 0.0, 0.0, 0.0);
    float weightSum = 0.0;
    float sigma = BloomRadius / BloomDispersion;
    
    // Calculate Gaussian blur parameters
    float range = ceil(BloomRadius * 2.0);
    float stepSize = AS_SparkleBloom::getBloomStepSize(BloomQuality);
    
    // Calculate dither noise if enabled
    float2 noise = float2(1.0, 1.0);
    if (BloomDither) {
        noise = AS_SparkleBloom::calculateDitherNoise(texcoord, float2(12.9898, 78.233), stepSize);
    }
    
    // Apply audio reactivity to bloom intensity
    float bloomIntensity = BloomIntensity;
    bloomIntensity += (GetAudioSource(Listeningway_BloomSource) * Listeningway_BloomMultiplier);
    
    // Horizontal Gaussian blur
    for (float x = -range; x <= range; x += stepSize) {
        float weight = AS_SparkleBloom::Gaussian(x, sigma);
        weightSum += weight;
        
        float2 sampleOffset = float2(x / BUFFER_WIDTH, 0.0) * BloomRadius;
        if (BloomDither) {
            sampleOffset += float2(noise.x * BLOOM_DITHER_SCALE, 0.0);        }
        
        color += tex2D(SparkleBloom_SparkleSampler, texcoord + sampleOffset) * weight;
    }
    
    // Normalize and apply intensity
    color /= max(weightSum, 1e-6);
    color *= bloomIntensity;
    
    return color;
}

/*-----------------------------------.
| :: Third Pass - Vertical Bloom and Final Blend |
'-----------------------------------*/

float4 PS_BloomV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Get original scene color
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
      // Early return for debug modes
    if (DebugMode > 0 && DebugMode < 5) {
        return tex2D(SparkleBloom_SparkleSampler, texcoord);
    }
    
    // Get sparkles from the first pass
    float3 sparkles = tex2D(SparkleBloom_SparkleSampler, texcoord).rgb;
    float3 bloom = float3(0.0, 0.0, 0.0);
    
    // Only process bloom if enabled
    if (EnableBloom) {
        // Initialize bloom accumulation
        float4 bloomColor = float4(0.0, 0.0, 0.0, 0.0);
        float weightSum = 0.0;
        float sigma = BloomRadius / BloomDispersion;
        
        // Calculate Gaussian blur parameters
        float range = ceil(BloomRadius * 2.0);
        float stepSize = AS_SparkleBloom::getBloomStepSize(BloomQuality);
        
        // Calculate dither noise if enabled
        float2 noise = float2(1.0, 1.0);
        if (BloomDither) {
            noise = AS_SparkleBloom::calculateDitherNoise(texcoord, float2(78.233, 12.9898), stepSize);
        }
        
        // Vertical Gaussian blur
        for (float y = -range; y <= range; y += stepSize) {
            float weight = AS_SparkleBloom::Gaussian(y, sigma);
            weightSum += weight;
            
            float2 sampleOffset = float2(0.0, y / BUFFER_HEIGHT) * BloomRadius;
            if (BloomDither) {
                sampleOffset += float2(0.0, noise.y * BLOOM_DITHER_SCALE);            }
            
            bloomColor += tex2D(SparkleBloom_BloomSampler, texcoord + sampleOffset) * weight;
        }
        
        // Normalize
        bloomColor /= max(weightSum, 1e-6);
        bloom = bloomColor.rgb;
    }
    
    // Composite sparkles and bloom over the original scene
    float3 result = originalColor.rgb;
    
    // Add sparkles and bloom
    result += sparkles + bloom;
    
    // Apply blend mode and amount
    float3 blendedColor = AS_applyBlend(result, originalColor.rgb, BlendMode);
    result = lerp(originalColor.rgb, blendedColor, DebugMode == 5 ? 1.0 : BlendAmount);
    
    return float4(result, originalColor.a);
}

/*-------------------------.
| :: Technique Definition |
'-------------------------*/

technique AS_SparkleBloom < ui_label = "[AS] VFX: Sparkle Bloom"; ui_tooltip = "Generates dynamic, lighting-responsive sparkles with bloom, depth masking, and audio reactivity."; >
{    pass RenderSparkles {
        VertexShader = PostProcessVS;
        PixelShader = PS_RenderSparkles;
        RenderTarget = SparkleBloom_SparkleRT;
    }
      pass BloomH {
        VertexShader = PostProcessVS;
        PixelShader = PS_BloomH;
        RenderTarget = SparkleBloom_BloomRT;
    }
    
    pass BloomV {
        VertexShader = PostProcessVS;
        PixelShader = PS_BloomV;
    }
}

#endif // __AS_VFX_SparkleBloom_1_fx
