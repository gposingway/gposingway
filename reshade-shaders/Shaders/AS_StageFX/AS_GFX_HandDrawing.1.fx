/**
 * AS_GFX_HandDrawing.1.fx - Stylized Hand-Drawn Artistic Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Transforms your game's visuals into a stylized, hand-drawn sketch or technical ink illustration.
 * Creates an organic, non-photorealistic aesthetic with distinct linework and cross-hatching patterns.
 *
 * FEATURES:
 * - Sophisticated line generation with customizable stroke directions and length
 * - Textured fills based on original image colors with noise-based variation
 * - Animated "wobble" effect for an authentic, hand-drawn feel
 * - Optional paper-like background pattern
 * - Comprehensive controls for fine-tuning every aspect of the effect
 * - Resolution-independent rendering
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Analyzes the source image by calculating local brightness gradients
 * 2. Generates simulated pen/brush strokes along different angles
 * 3. Combines strokes with processed color information and noise texture
 * 4. Applies subtle animation to create an organic, living sketch appearance
 * 5. Overlays optional paper texture grid for added traditional media feel
 *
 * CREDITS:
 * Based on: "notebook drawings" by Flockaroo (2016)
 * Original: https://www.shadertoy.com/view/XtVGD1
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_HandDrawing_fx
#define __AS_GFX_HandDrawing_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

namespace ASHandDrawing {

// ============================================================================
// CONSTANTS
// ============================================================================
static const float AS_HALF = 0.5;
static const float AS_PI2 = 6.28318530717959f;
static const float EPSILON = 0.0001f;

//--------------------------------------------------------------------------------------
// Texture Definition (User can change NOISE_TEXTURE_PATH_HANDDRAWN before compilation or in UI)
//--------------------------------------------------------------------------------------
// Define Noise Texture Dimensions (User should adjust these if NOISE_TEXTURE_PATH_HANDDRAWN points to a texture of different size)
#define NOISE_TEX_WIDTH 512.0f
#define NOISE_TEX_HEIGHT 512.0f
#ifndef NOISE_TEXTURE_PATH_HANDDRAWN
#define NOISE_TEXTURE_PATH_HANDDRAWN "perlin512x8CNoise.png" // Default noise texture
#endif

texture PencilDrawing_NoiseTex < source = NOISE_TEXTURE_PATH_HANDDRAWN; ui_label = "Noise Pattern Texture"; ui_tooltip = "Texture used for randomizing strokes and fills (e.g., Perlin, Blue Noise)."; >
{
    // Default attributes if texture not found or specified, actual size is less critical with defines below
    Width = NOISE_TEX_WIDTH; Height = NOISE_TEX_HEIGHT; Format = RGBA8;
};
sampler PencilDrawing_NoiseSampler { Texture = PencilDrawing_NoiseTex; AddressU = REPEAT; AddressV = REPEAT; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

//--------------------------------------------------------------------------------------
// Global Defines & Constants
//--------------------------------------------------------------------------------------

// Resolution Macros (used by helper functions)
#define Res1 float2(NOISE_TEX_WIDTH, NOISE_TEX_HEIGHT) // Noise Texture Resolution
#define Res_Screen float2(BUFFER_WIDTH, BUFFER_HEIGHT)    // Screen Resolution

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================
static const float ANIMATION_WOBBLE_STRENGTH_MIN = 0.0;
static const float ANIMATION_WOBBLE_STRENGTH_MAX = 20.0;
static const float ANIMATION_WOBBLE_STRENGTH_DEFAULT = 0.0;

static const float ANIMATION_WOBBLE_SPEED_MIN = 0.0;
static const float ANIMATION_WOBBLE_SPEED_MAX = 5.0;
static const float ANIMATION_WOBBLE_SPEED_DEFAULT = 0.0;

static const float ANIMATION_WOBBLE_FREQ_MIN = 0.1;
static const float ANIMATION_WOBBLE_FREQ_MAX = 5.0;
static const float2 ANIMATION_WOBBLE_FREQ_DEFAULT = float2(2.56, 1.78);

static const float EFFECT_SCALE_REF_HEIGHT_MIN = 100.0;
static const float EFFECT_SCALE_REF_HEIGHT_MAX = 2160.0;
static const float EFFECT_SCALE_REF_HEIGHT_DEFAULT = 1287.0;

static const int NUM_STROKE_DIRECTIONS_MIN = 1;
static const int NUM_STROKE_DIRECTIONS_MAX = 10;
static const int NUM_STROKE_DIRECTIONS_DEFAULT = 7;

static const int LINE_LENGTH_SAMPLES_MIN = 1;
static const int LINE_LENGTH_SAMPLES_MAX = 32;
static const int LINE_LENGTH_SAMPLES_DEFAULT = 16;

static const float MAX_LINE_OPACITY_MIN = 0.0;
static const float MAX_LINE_OPACITY_MAX = 0.2;
static const float MAX_LINE_OPACITY_DEFAULT = 0.069;

static const float LINE_LENGTH_SCALE_MIN = 0.1;
static const float LINE_LENGTH_SCALE_MAX = 5.0;
static const float LINE_LENGTH_SCALE_DEFAULT = 1.10;

static const float EDGE_DETECTION_EPSILON_MIN = 0.1;
static const float EDGE_DETECTION_EPSILON_MAX = 2.0;
static const float EDGE_DETECTION_EPSILON_DEFAULT = 0.4;

static const float LINE_DARKNESS_CURVE_MIN = 1.0;
static const float LINE_DARKNESS_CURVE_MAX = 5.0;
static const float LINE_DARKNESS_CURVE_DEFAULT = 3.0;

static const float LINE_DENSITY_MIN = 0.5;
static const float LINE_DENSITY_MAX = 4.0;
static const float LINE_DENSITY_DEFAULT = 1.33; // ~1/0.75 from original

static const float LINE_TEXTURE_INFLUENCE_MIN = 0.0;
static const float LINE_TEXTURE_INFLUENCE_MAX = 2.0;
static const float LINE_TEXTURE_INFLUENCE_DEFAULT = 0.0;

static const float LINE_TEXTURE_BASE_BRIGHTNESS_MIN = 0.0;
static const float LINE_TEXTURE_BASE_BRIGHTNESS_MAX = 1.0;
static const float LINE_TEXTURE_BASE_BRIGHTNESS_DEFAULT = 0.6;

static const float LINE_TEXTURE_NOISE_SCALE_MIN = 0.1;
static const float LINE_TEXTURE_NOISE_SCALE_MAX = 2.0;
static const float LINE_TEXTURE_NOISE_SCALE_DEFAULT = 0.7;

static const float MAIN_COLOR_DESAT_MIX_MIN = 0.0;
static const float MAIN_COLOR_DESAT_MIX_MAX = 5.0;
static const float MAIN_COLOR_DESAT_MIX_DEFAULT = 1.0;

static const float MAIN_COLOR_BRIGHTNESS_CAP_MIN = 0.1;
static const float MAIN_COLOR_BRIGHTNESS_CAP_MAX = 1.0;
static const float MAIN_COLOR_BRIGHTNESS_CAP_DEFAULT = 0.62;

static const float FILL_TEXTURE_EDGE_SOFT_MIN_DEFAULT = 0.65;
static const float FILL_TEXTURE_EDGE_SOFT_MAX_DEFAULT = 0.88;

static const float FILL_COLOR_BASE_FACTOR_MIN = 0.0;
static const float FILL_COLOR_BASE_FACTOR_MAX = 1.0;
static const float FILL_COLOR_BASE_FACTOR_DEFAULT = 0.37;

static const float FILL_COLOR_OFFSET_FACTOR_MIN = 0.0;
static const float FILL_COLOR_OFFSET_FACTOR_MAX = 1.0;
static const float FILL_COLOR_OFFSET_FACTOR_DEFAULT = 0.29;

static const float FILL_TEXTURE_NOISE_STRENGTH_MIN = 0.0;
static const float FILL_TEXTURE_NOISE_STRENGTH_MAX = 2.0;
static const float FILL_TEXTURE_NOISE_STRENGTH_DEFAULT = 0.96;

static const float FILL_TEXTURE_NOISE_SCALE_MIN = 0.1;
static const float FILL_TEXTURE_NOISE_SCALE_MAX = 2.0;
static const float FILL_TEXTURE_NOISE_SCALE_DEFAULT = 1.79;

static const float NOISE_LOOKUP_SCALE_MIN = 100.0;
static const float NOISE_LOOKUP_SCALE_MAX = 4000.0;
static const float NOISE_LOOKUP_SCALE_DEFAULT = 2500.0;

static const float PAPER_PATTERN_FREQ_MIN = 0.01;
static const float PAPER_PATTERN_FREQ_MAX = 0.5;
static const float PAPER_PATTERN_FREQ_DEFAULT = 0.01;

static const float PAPER_PATTERN_INTENSITY_MIN = 0.0;
static const float PAPER_PATTERN_INTENSITY_MAX = 1.0;
static const float PAPER_PATTERN_INTENSITY_DEFAULT = 0.36;

static const float PAPER_PATTERN_SHARPNESS_MIN = 10.0;
static const float PAPER_PATTERN_SHARPNESS_MAX = 200.0;
static const float PAPER_PATTERN_SHARPNESS_DEFAULT = 80.0;

static const float3 PAPER_PATTERN_TINT_DEFAULT = float3(64.0/255.0, 26.0/255.0, 26.0/255.0);

// ============================================================================
// UI DECLARATIONS - Organized by category
// ============================================================================

// --- Overall Effect & Animation ---
uniform float AnimationWobbleStrength < ui_type = "slider"; ui_label = "Animation Wobble Strength"; ui_min = ANIMATION_WOBBLE_STRENGTH_MIN; ui_max = ANIMATION_WOBBLE_STRENGTH_MAX; ui_step = 0.1; ui_tooltip = "Overall strength of the coordinate jitter effect, making the image 'wobble'"; ui_category = "Animation & Jitter"; > = ANIMATION_WOBBLE_STRENGTH_DEFAULT;
uniform float AnimationWobbleSpeed < ui_type = "slider"; ui_label = "Animation Wobble Speed"; ui_min = ANIMATION_WOBBLE_SPEED_MIN; ui_max = ANIMATION_WOBBLE_SPEED_MAX; ui_step = 0.01; ui_tooltip = "Speed of the wobble animation"; ui_category = "Animation & Jitter"; > = ANIMATION_WOBBLE_SPEED_DEFAULT;
uniform float2 AnimationWobbleFrequency < ui_type = "drag"; ui_label = "Animation Wobble Pattern (X, Y Freq)"; ui_min = ANIMATION_WOBBLE_FREQ_MIN; ui_max = ANIMATION_WOBBLE_FREQ_MAX; ui_step = 0.01; ui_tooltip = "Frequency of sine waves for X and Y axis wobble"; ui_category = "Animation & Jitter"; > = ANIMATION_WOBBLE_FREQ_DEFAULT;
uniform float EffectScaleReferenceHeight < ui_type = "slider"; ui_label = "Effect Scale Reference Height"; ui_min = EFFECT_SCALE_REF_HEIGHT_MIN; ui_max = EFFECT_SCALE_REF_HEIGHT_MAX; ui_step = 10.0; ui_tooltip = "Reference screen height for scaling effects like jitter and stroke length"; ui_category = "Animation & Jitter"; > = EFFECT_SCALE_REF_HEIGHT_DEFAULT;

// --- Line Work & Strokes ---
uniform int NumberOfStrokeDirections < ui_type = "slider"; ui_label = "Number of Stroke Directions"; ui_min = NUM_STROKE_DIRECTIONS_MIN; ui_max = NUM_STROKE_DIRECTIONS_MAX; ui_step = 1; ui_tooltip = "Number of different angles for hatching/strokes. Affects density and performance"; ui_category = "Line Work & Strokes"; > = NUM_STROKE_DIRECTIONS_DEFAULT;
uniform int LineLengthSamples < ui_type = "slider"; ui_label = "Line Length (Samples per Direction)"; ui_min = LINE_LENGTH_SAMPLES_MIN; ui_max = LINE_LENGTH_SAMPLES_MAX; ui_step = 1; ui_tooltip = "Number of samples along each stroke direction, effectively line length. Affects detail and performance"; ui_category = "Line Work & Strokes"; > = LINE_LENGTH_SAMPLES_DEFAULT;
uniform float MaxIndividualLineOpacity < ui_type = "slider"; ui_label = "Max Individual Line Opacity"; ui_min = MAX_LINE_OPACITY_MIN; ui_max = MAX_LINE_OPACITY_MAX; ui_step = 0.001; ui_tooltip = "Clamps the maximum opacity/intensity of a single calculated stroke fragment"; ui_category = "Line Work & Strokes"; > = MAX_LINE_OPACITY_DEFAULT;
uniform float OverallLineLengthScale < ui_type = "slider"; ui_label = "Overall Line Length Scale"; ui_min = LINE_LENGTH_SCALE_MIN; ui_max = LINE_LENGTH_SCALE_MAX; ui_step = 0.01; ui_tooltip = "General multiplier for the length of stroke sampling lines"; ui_category = "Line Work & Strokes"; > = LINE_LENGTH_SCALE_DEFAULT;
uniform float EdgeDetectionEpsilon < ui_type = "slider"; ui_label = "Edge Detection Sensitivity"; ui_min = EDGE_DETECTION_EPSILON_MIN; ui_max = EDGE_DETECTION_EPSILON_MAX; ui_step = 0.01; ui_tooltip = "Controls the sensitivity of edge detection. Lower values detect finer details but may increase noise"; ui_category = "Line Work & Strokes"; > = EDGE_DETECTION_EPSILON_DEFAULT;

// --- Line Shading & Texture ---
uniform float LineDarknessCurve < ui_type = "slider"; ui_label = "Line Darkness Curve (Exponent)"; ui_min = LINE_DARKNESS_CURVE_MIN; ui_max = LINE_DARKNESS_CURVE_MAX; ui_step = 0.1; ui_tooltip = "Exponent applied to the accumulated line color for darkening. Higher values = darker, sharper lines"; ui_category = "Line Shading & Texture"; > = LINE_DARKNESS_CURVE_DEFAULT;
uniform float LineWorkDensity < ui_type = "slider"; ui_label = "Line Work Density"; ui_min = LINE_DENSITY_MIN; ui_max = LINE_DENSITY_MAX; ui_step = 0.01; ui_tooltip = "Adjusts the overall density of lines. Higher values = denser/darker strokes"; ui_category = "Line Shading & Texture"; > = LINE_DENSITY_DEFAULT;
uniform float LineTextureInfluence < ui_type = "slider"; ui_label = "Line Texture Influence"; ui_min = LINE_TEXTURE_INFLUENCE_MIN; ui_max = LINE_TEXTURE_INFLUENCE_MAX; ui_step = 0.01; ui_tooltip = "Scales the effect of noise on line darkness variation"; ui_category = "Line Shading & Texture"; > = LINE_TEXTURE_INFLUENCE_DEFAULT;
uniform float LineTextureBaseBrightness < ui_type = "slider"; ui_label = "Line Texture Base Brightness"; ui_min = LINE_TEXTURE_BASE_BRIGHTNESS_MIN; ui_max = LINE_TEXTURE_BASE_BRIGHTNESS_MAX; ui_step = 0.01; ui_tooltip = "Base value added to noise for line darkness variation"; ui_category = "Line Shading & Texture"; > = LINE_TEXTURE_BASE_BRIGHTNESS_DEFAULT;
uniform float LineTextureNoiseScale < ui_type = "slider"; ui_label = "Line Texture Noise UV Scale"; ui_min = LINE_TEXTURE_NOISE_SCALE_MIN; ui_max = LINE_TEXTURE_NOISE_SCALE_MAX; ui_step = 0.01; ui_tooltip = "Scales UVs for the noise lookup that affects line darkness variation"; ui_category = "Line Shading & Texture"; > = LINE_TEXTURE_NOISE_SCALE_DEFAULT;

// --- Color Processing & Fill ---
uniform float MainColorDesaturationMix < ui_type = "slider"; ui_label = "Main Color Desaturation Mix"; ui_min = MAIN_COLOR_DESAT_MIX_MIN; ui_max = MAIN_COLOR_DESAT_MIX_MAX; ui_step = 0.01; ui_tooltip = "Mixing factor towards gray for the main colors extracted from the image"; ui_category = "Color Processing & Fill"; > = MAIN_COLOR_DESAT_MIX_DEFAULT;
uniform float MainColorBrightnessCap < ui_type = "slider"; ui_label = "Main Color Brightness Cap"; ui_min = MAIN_COLOR_BRIGHTNESS_CAP_MIN; ui_max = MAIN_COLOR_BRIGHTNESS_CAP_MAX; ui_step = 0.01; ui_tooltip = "Maximum brightness after initial color filtering"; ui_category = "Color Processing & Fill"; > = MAIN_COLOR_BRIGHTNESS_CAP_DEFAULT;
uniform float FillTextureEdgeSoftnessMin < ui_type = "slider"; ui_label = "Fill Texture Edge Softness (Min)"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_tooltip = "Lower edge for smoothstep creating the textured fill"; ui_category = "Color Processing & Fill"; > = FILL_TEXTURE_EDGE_SOFT_MIN_DEFAULT;
uniform float FillTextureEdgeSoftnessMax < ui_type = "slider"; ui_label = "Fill Texture Edge Softness (Max)"; ui_min = 0.5; ui_max = 1.5; ui_step = 0.01; ui_tooltip = "Upper edge for smoothstep creating the textured fill"; ui_category = "Color Processing & Fill"; > = FILL_TEXTURE_EDGE_SOFT_MAX_DEFAULT;
uniform float FillColorBaseFactor < ui_type = "slider"; ui_label = "Fill Color Base Factor"; ui_min = FILL_COLOR_BASE_FACTOR_MIN; ui_max = FILL_COLOR_BASE_FACTOR_MAX; ui_step = 0.01; ui_tooltip = "Base color multiplier for the textured fill"; ui_category = "Color Processing & Fill"; > = FILL_COLOR_BASE_FACTOR_DEFAULT;
uniform float FillColorOffsetFactor < ui_type = "slider"; ui_label = "Fill Color Offset Factor"; ui_min = FILL_COLOR_OFFSET_FACTOR_MIN; ui_max = FILL_COLOR_OFFSET_FACTOR_MAX; ui_step = 0.01; ui_tooltip = "Color offset added to the textured fill"; ui_category = "Color Processing & Fill"; > = FILL_COLOR_OFFSET_FACTOR_DEFAULT;
uniform float FillTextureNoiseStrength < ui_type = "slider"; ui_label = "Fill Texture Noise Strength"; ui_min = FILL_TEXTURE_NOISE_STRENGTH_MIN; ui_max = FILL_TEXTURE_NOISE_STRENGTH_MAX; ui_step = 0.01; ui_tooltip = "Scales the noise contribution to the textured fill"; ui_category = "Color Processing & Fill"; > = FILL_TEXTURE_NOISE_STRENGTH_DEFAULT;
uniform float FillTextureNoiseScale < ui_type = "slider"; ui_label = "Fill Texture Noise UV Scale"; ui_min = FILL_TEXTURE_NOISE_SCALE_MIN; ui_max = FILL_TEXTURE_NOISE_SCALE_MAX; ui_step = 0.01; ui_tooltip = "Scales UVs for the noise lookup affecting the textured fill"; ui_category = "Color Processing & Fill"; > = FILL_TEXTURE_NOISE_SCALE_DEFAULT;
uniform float NoiseLookupOverallScale < ui_type = "slider"; ui_label = "Noise Lookup Overall Scale Reference"; ui_min = NOISE_LOOKUP_SCALE_MIN; ui_max = NOISE_LOOKUP_SCALE_MAX; ui_step = 10.0; ui_tooltip = "Reference value for noise UV scaling. Larger means noise samples are smaller/denser"; ui_category = "Color Processing & Fill"; > = NOISE_LOOKUP_SCALE_DEFAULT;

// --- Paper & Background ---
uniform bool EnablePaperPattern < ui_category = "Background & Paper"; ui_label = "Enable Paper Pattern"; ui_tooltip = "Toggles the underlying paper-like grid pattern"; > = true;
uniform float PaperPatternFrequency < ui_type = "slider"; ui_label = "Paper Pattern Frequency"; ui_min = PAPER_PATTERN_FREQ_MIN; ui_max = PAPER_PATTERN_FREQ_MAX; ui_step = 0.001; ui_tooltip = "Frequency of the 'karo' paper pattern"; ui_category = "Background & Paper"; > = PAPER_PATTERN_FREQ_DEFAULT;
uniform float PaperPatternIntensity < ui_type = "slider"; ui_label = "Paper Pattern Intensity"; ui_min = PAPER_PATTERN_INTENSITY_MIN; ui_max = PAPER_PATTERN_INTENSITY_MAX; ui_step = 0.01; ui_tooltip = "Intensity of the 'karo' paper pattern"; ui_category = "Background & Paper"; > = PAPER_PATTERN_INTENSITY_DEFAULT;
uniform float3 PaperPatternTint < ui_type = "color"; ui_label = "Paper Pattern Color Tint"; ui_tooltip = "Color tint of the paper pattern"; ui_category = "Background & Paper"; > = PAPER_PATTERN_TINT_DEFAULT;
uniform float PaperPatternSharpness < ui_type = "slider"; ui_label = "Paper Pattern Sharpness"; ui_min = PAPER_PATTERN_SHARPNESS_MIN; ui_max = PAPER_PATTERN_SHARPNESS_MAX; ui_step = 1.0; ui_tooltip = "Sharpness of the paper pattern lines"; ui_category = "Background & Paper"; > = PAPER_PATTERN_SHARPNESS_DEFAULT;

//------------------------------------------------------------------------------------------------
// Stage & Depth
//------------------------------------------------------------------------------------------------
AS_STAGEDEPTH_UI(EffectDepth)
uniform bool ReverseDepth < ui_label = "Reverse Depth"; ui_tooltip = "Reverses the depth detection method"; ui_category = "Stage"; > = false;

//------------------------------------------------------------------------------------------------
// Final Mix
//------------------------------------------------------------------------------------------------
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

float4 getRand(float2 pos_param) {
    float2 uv_noise = pos_param / Res1 / Res_Screen.y * NoiseLookupOverallScale;
    return tex2Dlod(PencilDrawing_NoiseSampler, float4(uv_noise, 0.0, 0.0));
}

float4 getCol(float2 pos_param) {
    // Calculate UV coordinates for sampling
    float2 uv = pos_param / Res_Screen;
    
    // Sample the source image
    float4 c1 = tex2D(ReShade::BackBuffer, uv);
    
    // Apply border fade using smoothstep for clean edges
    float4 border_fade_edges = smoothstep(float4(-0.05f, -0.05f, -0.05f, -0.05f), 
                                         float4(0.0f, 0.0f, 0.0f, 0.0f), 
                                         float4(uv.x, uv.y, 1.0f - uv.x, 1.0f - uv.y));
    c1 = lerp(float4(1.0f, 1.0f, 1.0f, 0.0f), c1, 
             border_fade_edges.x * border_fade_edges.y * border_fade_edges.z * border_fade_edges.w);
    
    // Apply color filtering (emphasize green channel)
    float d = clamp(dot(c1.xyz, float3(-0.5f, 1.0f, -0.5f)), 0.0f, 1.0f);
    float4 c2 = MainColorBrightnessCap.xxxx; // Target gray color for mixing
    
    // Apply desaturation and brightness cap
    return min(lerp(c1, c2, MainColorDesaturationMix * d), MainColorBrightnessCap.xxxx);
}

float4 getColHT(float2 pos_param) {
    float4 col_val = getCol(pos_param);
    float4 rand_val = getRand(pos_param * FillTextureNoiseScale);
    return smoothstep(FillTextureEdgeSoftnessMin, FillTextureEdgeSoftnessMax, 
                     col_val * FillColorBaseFactor + FillColorOffsetFactor + rand_val * FillTextureNoiseStrength);
}

float getVal(float2 pos_param) {
    float4 c = getCol(pos_param);
    // Convert color to luminance
    return pow(dot(c.xyz, 0.333f.xxx), 1.0f) * 1.0f;
}

float2 getGrad(float2 pos_param, float eps) {
    float2 d_offset = float2(eps, 0.0f);
    return float2(
        getVal(pos_param + d_offset.xy) - getVal(pos_param - d_offset.xy),
        getVal(pos_param + d_offset.yx) - getVal(pos_param - d_offset.yx)
    ) / eps / 2.0f;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_HandDrawn(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // Get original color for blending
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Calculate animation time
    float time_s = AS_getTime() / 1000.0f;

    // Scale effect based on resolution to maintain consistency
    float norm_height_factor = Res_Screen.y / EffectScaleReferenceHeight;
    
    // Apply animation wobble to the sampling coordinates
    float2 pos_main = vpos.xy + AnimationWobbleStrength * 
                      sin(time_s * AnimationWobbleSpeed * AnimationWobbleFrequency) * 
                      norm_height_factor;
    
    float3 col_accum = 0.0f.xxx;     // Line accumulation
    float3 col2_accum = 0.0f.xxx;    // Fill color accumulation
    float sum_factor = 0.0f;         // Weight normalization factor
    
    // Scale stroke length based on screen resolution
    float stroke_len_normalized_scale = OverallLineLengthScale * norm_height_factor;

    // Generate strokes in multiple directions (cross-hatching)
    [loop]
    for (int i = 0; i < NumberOfStrokeDirections; i++)
    {
        // Calculate angle for this stroke direction
        float ang = AS_PI2 / (float)NumberOfStrokeDirections * ((float)i + 0.8f);
        float2 v_stroke_dir = float2(cos(ang), sin(ang));
        
        // Sample along the stroke direction
        [loop]
        for (int j = 0; j < LineLengthSamples; j++)
        {
            float j_float = (float)j;
            
            // Calculate offset for sampling along the stroke
            float2 dpos = v_stroke_dir.yx * float2(1.0f, -1.0f) * j_float * stroke_len_normalized_scale;
            
            // Calculate curvature offset (perpendicular to stroke direction)
            float stroke_curve_factor = (j_float * j_float) / (float)LineLengthSamples * 0.5f;
            float2 dpos2 = v_stroke_dir.xy * stroke_curve_factor * stroke_len_normalized_scale;
            
            float2 g;
            float fact;
            float fact2;

            // Sample in both directions from center point
            for (float s_loop = -1.0f; s_loop <= 1.0f; s_loop += 2.0f)
            {                // Calculate sampling positions
                float2 pos2 = pos_main + s_loop * dpos + dpos2;
                float2 pos3 = pos_main + (s_loop * dpos + dpos2).yx * float2(1.0f, -1.0f) * 2.0f;
                
                // Get gradient at this position using the user-configurable epsilon
                g = getGrad(pos2, EdgeDetectionEpsilon);
                
                // Calculate line intensity based on gradient alignment with stroke direction
                fact = dot(g, v_stroke_dir) - 0.5f * abs(dot(g, v_stroke_dir.yx * float2(1.0f, -1.0f)));
                fact2 = dot(normalize(g + EPSILON.xx), v_stroke_dir.yx * float2(1.0f, -1.0f));
                
                // Clamp and adjust line intensity
                fact = clamp(fact, 0.0f, MaxIndividualLineOpacity);
                fact2 = abs(fact2);
                
                // Fade line intensity based on distance from center
                fact *= 1.0f - j_float / (float)LineLengthSamples;
                
                // Accumulate line and fill values
                col_accum += fact;
                col2_accum += fact2 * getColHT(pos3).xyz;
                sum_factor += fact2;
            }
        }
    }

    // Normalize fill color accumulation
    if (sum_factor > EPSILON) 
        col2_accum /= sum_factor; 
    else 
        col2_accum = 0.0f.xxx;
    
    // Scale line accumulation based on sample count and density
    col_accum /= (float)(LineLengthSamples * NumberOfStrokeDirections) / LineWorkDensity / sqrt(Res_Screen.y);
    
    // Apply line texture variation using noise
    float rand_for_line = getRand(pos_main * LineTextureNoiseScale).x;
    col_accum.x *= (LineTextureBaseBrightness + LineTextureInfluence * rand_for_line);
    
    // Invert and apply darkness curve for final line intensity
    col_accum.x = 1.0f - col_accum.x;
    col_accum.x = pow(col_accum.x, LineDarknessCurve);

    // Initialize paper pattern
    float3 karo_pattern = 1.0f.xxx;
    
    // Apply optional paper grid pattern
    if (EnablePaperPattern) {
        float2 s_karo = sin(pos_main.xy * PaperPatternFrequency / 
                        sqrt(Res_Screen.y / EffectScaleReferenceHeight));
        karo_pattern -= PaperPatternIntensity * PaperPatternTint * 
                       dot(exp(-s_karo * s_karo * PaperPatternSharpness), 1.0f.xx);
    }
      // Combine line work, fill colors, and paper pattern
    float3 final_col = col_accum.x * col2_accum * karo_pattern;
      // Get scene depth
    float depth = ReShade::GetLinearizedDepth(texcoord);
    
    // Apply depth-based masking with optional reversal
    float depthMask = ReverseDepth ? (depth <= EffectDepth) : (depth >= EffectDepth);
    
    // Apply blend mode and strength with depth consideration
    float3 blended = AS_applyBlend(final_col, originalColor.rgb, BlendMode);
    return float4(lerp(originalColor.rgb, blended, BlendStrength * depthMask), 1.0f);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_GFX_HandDrawing <
    ui_label = "[AS] GFX: Hand Drawing";
    ui_tooltip = "Transforms your scene into a stylized hand-drawn sketch or technical illustration";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_HandDrawn;
    }
}

} // namespace ASHandDrawing

#endif // __AS_GFX_HandDrawing_fx


