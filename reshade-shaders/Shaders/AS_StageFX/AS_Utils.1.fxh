/**
 * AS_Utils.1.fxh - Common Utility Functions for AS StageFX Shader Collection
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 * * DESCRIPTION:
 * This header file provides common utility functions used across the AS StageFX
 * shader collection. It includes blend modes, audio processing, mathematical helpers,
 * and various convenience functions to maintain consistency across shaders.
 *
 * FEATURES:
 * - Standardized UI controls for consistent user interfaces
 * - Listeningway audio integration with standard sources and stereo controls
 * - Stereo audio spatialization and multi-channel format detection
 * - Debug visualization tools and helpers
 * - Common blend modes and mixing functions
 * - Mathematical and coordinate transformation helpers
 * - Depth, normal reconstruction, and surface effects functions
 * * IMPLEMENTATION OVERVIEW:
 * This file is organized in sections:
 * 1. UI standardization macros for consistent parameter layouts
 * 2. Audio integration and Listeningway support with stereo capabilities
 * 3. Visual effect helpers (blend modes, color operations)
 * 4. Mathematical functions (coordinate transforms)
 * 5. Advanced rendering helpers (depth, normals, etc.)
 *
 * Note: For procedural noise functions, see AS_Noise.1.fxh
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_Utils_1_fxh
#define __AS_Utils_1_fxh

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "Blending.fxh" // Make sure Blending.fxh from ReShade's common headers is available

// ============================================================================
// MATH CONSTANTS
// ============================================================================
// --- Math Constants ---
// Standard mathematical constants for consistent use across all shaders
// Core mathematical constants
static const float AS_PI = 3.1415926535897932384626433832795f;
static const float AS_TWO_PI = 6.2831853071795864769252867665590f;
static const float AS_HALF_PI = 1.5707963267948966192313216916398f;
static const float AS_QUARTER_PI = 0.7853981633974483096156608458199f;
static const float AS_INV_PI = 0.3183098861837906715377675267450f;
static const float AS_E = 2.7182818284590452353602874713527f;
static const float AS_GOLDEN_RATIO = 1.6180339887498948482045868343656f;

// Physics & graphics constants
static const float AS_EPSILON = 1e-6f;          // Very small number to avoid division by zero
static const float AS_EPS_SAFE = 1e-5f;      // Slightly larger epsilon for screen-space operations
static const float AS_DEGREES_TO_RADIANS = AS_PI / 180.0f;
static const float AS_RADIANS_TO_DEGREES = 180.0f / AS_PI;

// Common numerical constants
static const float AS_HALF = 0.5f;                          // 1/2 - useful for centered coordinates
static const float AS_QUARTER = 0.25f;                        // 1/4
static const float AS_THIRD = 0.3333333333333333333333333333333f;    // 1/3
static const float AS_TWO_THIRDS = 0.6666666666666666666666666666667f; // 2/3
static const float AS_SQRT_TWO = 1.4142135623730950488016887242097f; // Square root of 2, useful for diagonal calculations

// Depth testing constants 
static const float AS_DEPTH_EPSILON = 0.0005f;  // Standard depth epsilon for z-fighting prevention
static const float AS_EDGE_AA = 0.05f;        // Standard anti-aliasing edge size for smoothstep

// ============================================================================
// UI STANDARDIZATION & MACROS
// ============================================================================

// --- Listeningway Integration ---
// These macros help with consistent Listeningway integration across all shaders
// Define a complete fallback implementation for Listeningway
#ifndef __LISTENINGWAY_INSTALLED
    // Since we're not including ListeningwayUniforms.fxh anymore,
    // provide a complete compatible implementation directly here
    #define LISTENINGWAY_NUM_BANDS 32
    #define __LISTENINGWAY_INSTALLED 1

    // Create fallback uniforms with the same interface as the real Listeningway
    uniform float Listeningway_Volume < source = "listeningway_volume"; > = 0.0f;
    uniform float Listeningway_FreqBands[LISTENINGWAY_NUM_BANDS] < source = "listeningway_freqbands"; > = {
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f
    };
    uniform float Listeningway_Beat < source = "listeningway_beat"; > = 0.0f;

    // Time uniforms
    uniform float Listeningway_TimeSeconds < source = "listeningway_timeseconds"; > = 0.0f;
    uniform float Listeningway_TimePhase60Hz < source = "listeningway_timephase60hz"; > = 0.0f;
    uniform float Listeningway_TimePhase120Hz < source = "listeningway_timephase120hz"; > = 0.0f;
    uniform float Listeningway_TotalPhases60Hz < source = "listeningway_totalphases60hz"; > = 0.0f;
    uniform float Listeningway_TotalPhases120Hz < source = "listeningway_totalphases120hz"; > = 0.0f;

    // Stereo spatialization uniforms
    uniform float Listeningway_VolumeLeft < source = "listeningway_volumeleft"; > = 0.0f;
    uniform float Listeningway_VolumeRight < source = "listeningway_volumeright"; > = 0.0f;
    uniform float Listeningway_AudioPan < source = "listeningway_audiopan"; > = 0.0f;

    // Audio format uniform (0=none, 1=mono, 2=stereo, 6=5.1, 8=7.1)
    uniform float Listeningway_AudioFormat < source = "listeningway_audioformat"; > = 0.0f;
#endif

// Animation timing constants
static const float AS_ANIM_SLOW = 0.5f;      // Slow animation speed multiplier
static const float AS_ANIM_NORMAL = 1.0f;      // Normal animation speed multiplier  
static const float AS_ANIM_FAST = 2.0f;      // Fast animation speed multiplier

// Timing constants
static const float AS_TIME_1_SECOND = 1.0f;              // 1 second of animation time
static const float AS_TIME_HALF_SECOND = 0.5f;          // 0.5 seconds of animation time
static const float AS_TIME_QUARTER_SECOND = 0.25f;      // 0.25 seconds of animation time

// Animation patterns
static const float AS_PATTERN_FREQ_LOW = 2.0f;          // Low frequency for animation patterns
static const float AS_PATTERN_FREQ_MED = 5.0f;          // Medium frequency for animation patterns
static const float AS_PATTERN_FREQ_HIGH = 10.0f;         // High frequency for animation patterns

// Standard UI ranges for commonly used parameters
static const float AS_RANGE_ZERO_ONE_MIN = 0.0f;        // Common minimum for normalized parameters
static const float AS_RANGE_ZERO_ONE_MAX = 1.0f;        // Common maximum for normalized parameters

static const float AS_RANGE_NEG_ONE_ONE_MIN = -1.0f;    // Common minimum for bipolar normalized parameters
static const float AS_RANGE_NEG_ONE_ONE_MAX = 1.0f;      // Common maximum for bipolar normalized parameters

static const float AS_OP_MIN = 0.0f;          // Minimum for opacity parameters
static const float AS_OP_MAX = 1.0f;          // Maximum for opacity parameters
static const float AS_OP_DEFAULT = 1.0f;      // Default for opacity parameters

static const float AS_RANGE_BLEND_MIN = 0.0f;          // Minimum for blend amount parameters
static const float AS_RANGE_BLEND_MAX = 1.0f;          // Maximum for blend amount parameters
static const float AS_RANGE_BLEND_DEFAULT = 1.0f;      // Default for blend amount parameters

static const float AS_RANGE_AUDIO_MULT_MIN = 0.0f;      // Minimum for audio multiplier parameters
static const float AS_RANGE_AUDIO_MULT_MAX = 2.0f;      // Maximum for audio multiplier parameters
static const float AS_RANGE_AUDIO_MULT_DEFAULT = 1.0f;  // Default for audio multiplier parameters

// Scale range constants
static const float AS_RANGE_SCALE_MIN = 0.1f;          // Minimum for scale parameters
static const float AS_RANGE_SCALE_MAX = 5.0f;          // Maximum for scale parameters
static const float AS_RANGE_SCALE_DEFAULT = 1.0f;      // Default for scale parameters

// Speed range constants
static const float AS_RANGE_SPEED_MIN = 0.0f;          // Minimum for speed parameters 
static const float AS_RANGE_SPEED_MAX = 5.0f;          // Maximum for speed parameters
static const float AS_RANGE_SPEED_DEFAULT = 1.0f;      // Default for speed parameters

// Debug mode constants
static const int AS_DEBUG_OFF = 0;                // Debug mode off
static const int AS_DEBUG_MASK = 1;               // Debug mask display
static const int AS_DEBUG_DEPTH = 2;              // Debug depth display
static const int AS_DEBUG_AUDIO = 3;              // Debug audio display
static const int AS_DEBUG_PATTERN = 4;            // Debug pattern display

// --- Audio Constants ---
#define AS_AUDIO_OFF          0  // Audio source disabled
#define AS_AUDIO_SOLID        1  // Constant value (no audio reactivity)
#define AS_AUDIO_VOLUME       2  // Overall audio volume
#define AS_AUDIO_BEAT         3  // Beat detection
#define AS_AUDIO_BASS         4  // Low frequency band
#define AS_AUDIO_TREBLE       5  // High frequency band
#define AS_AUDIO_MID          6  // Mid frequency band
#define AS_AUDIO_VOLUME_LEFT  7  // Left channel volume
#define AS_AUDIO_VOLUME_RIGHT 8  // Right channel volume
#define AS_AUDIO_PAN          9  // Audio pan (-1 to 1)

// --- Blend Constants ---
#define AS_BLEND_NORMAL     0 // No blending
#define AS_BLEND_OPAQUE     0 // Opaque blending (same as normal for RGB, alpha handled separately)
#define AS_BLEND_LIGHTEN    5 // Lighter only (matches ComHeaders::Blending::Blend_Lighten_Only)

// --- Display and Resolution Constants ---
static const float AS_RESOLUTION_BASE_HEIGHT = 1080.0f;  // Standard height for scaling calculations
static const float AS_RESOLUTION_BASE_WIDTH = 1920.0f;   // Standard width for scaling calculations
static const float AS_STANDARD_ASPECT_RATIO = 16.0f/9.0f; // Standard aspect ratio for reference

// Common UI mapping constants
static const float AS_UI_POSITION_RANGE = 1.5f;  // Standard range for position UI controls (-1.5 to 1.5)
static const float AS_UI_CENTRAL_SQUARE = 1.0f;  // Range mapping to central square (-1.0 to 1.0)
static const float AS_UI_POSITION_SCALE = 0.5f;  // Position scaling factor for centered coordinates

// Common coordinate system values
static const float AS_SCREEN_CENTER_X = 0.5f;    // Screen center X coordinate
static const float AS_SCREEN_CENTER_Y = 0.5f;    // Screen center Y coordinate
// AS_RESOLUTION_SCALE is defined here, but it's better to calculate it dynamically if needed,
// as BUFFER_HEIGHT might not be known at compile time for all contexts.
// If used, ensure it's in a context where BUFFER_HEIGHT is defined.
// static const float AS_RESOLUTION_SCALE = 1080.0f / BUFFER_HEIGHT; // Resolution scaling factor

// Default number of frequency bands
#ifndef LISTENINGWAY_NUM_BANDS
    #define LISTENINGWAY_NUM_BANDS 32
#endif
#define AS_DEFAULT_NUM_BANDS LISTENINGWAY_NUM_BANDS

// --- Standard UI Strings ---
#define AS_AUDIO_SOURCE_ITEMS "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0Mid\0Volume Left\0Volume Right\0Pan\0"

// --- UI Control Macros ---
// Define standard audio source control (reuse this macro for each audio reactive parameter)
#define AS_AUDIO_UI(name, label, defaultSource, category) \
uniform int name < ui_type = "combo"; ui_label = label; ui_items = AS_AUDIO_SOURCE_ITEMS; ui_category = category; > = defaultSource;

// Define standard multiplier control for audio reactivity
#define AS_AUDIO_MULT_UI(name, label, defaultValue, maxValue, category) \
uniform float name < ui_type = "slider"; ui_label = label; ui_tooltip = "Controls how much the selected audio source affects this parameter."; ui_min = 0.0; ui_max = maxValue; ui_step = 0.05; ui_category = category; > = defaultValue;

// --- Debug Mode Standardization ---
// --- Debug UI Macro ---
#define AS_DEBUG_UI(items) \
uniform int DebugMode < ui_type = "combo"; ui_label = "Debug View"; ui_tooltip = "Show various visualization modes for debugging."; ui_items = items; ui_category = "Debug"; > = 0;

// --- Debug Helper Functions ---
bool AS_isDebugMode(int currentMode, int targetMode) {
    return currentMode == targetMode;
}

// Standard "Off" value for debug modes (already defined as const int AS_DEBUG_OFF)
// #define AS_DEBUG_OFF 0 // This is redundant

// --- Sway Animation UI Standardization ---
// --- Sway UI Macros ---
#define AS_SWAYSPEED_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Sway Speed"; ui_tooltip = "Controls the speed of the swaying animation"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; ui_category = category; > = 1.0;

#define AS_SWAYANGLE_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Sway Angle"; ui_tooltip = "Maximum angle of the swaying in degrees"; ui_min = 0.0; ui_max = 180.0; ui_step = 1.0; ui_category = category; > = 15.0;

// --- Position and Scale UI Standardization ---
// --- Position Constants ---
#define AS_POSITION_MIN -1.5f
#define AS_POSITION_MAX 1.5f
#define AS_POSITION_STEP 0.01f
#define AS_POSITION_DEFAULT 0.0f

#define AS_SCALE_MIN 0.1f
#define AS_SCALE_MAX 5.0f
#define AS_SCALE_STEP 0.01f
#define AS_SCALE_DEFAULT 1.0f

// --- Position UI Macros ---
// Creates a standardized position control (as float2)
#define AS_POS_UI(name) \
uniform float2 name < ui_type = "drag"; ui_label = "Position"; ui_tooltip = "Position of the effect center (X,Y)."; ui_min = AS_POSITION_MIN; ui_max = AS_POSITION_MAX; ui_step = AS_POSITION_STEP; ui_category = "Position"; > = float2(AS_POSITION_DEFAULT, AS_POSITION_DEFAULT);

// Creates a standardized scale control
#define AS_SCALE_UI(name) \
uniform float name < ui_type = "slider"; ui_label = "Scale"; ui_tooltip = "Size of the effect. Higher values zoom out, lower values zoom in."; ui_min = AS_SCALE_MIN; ui_max = AS_SCALE_MAX; ui_step = AS_SCALE_STEP; ui_category = "Position"; > = AS_SCALE_DEFAULT;

// Combined position and scale UI for convenience
#define AS_POSITION_SCALE_UI(posName, scaleName) \
uniform float2 posName < ui_type = "drag"; ui_label = "Position"; ui_tooltip = "Position of the effect center (X,Y)."; ui_min = AS_POSITION_MIN; ui_max = AS_POSITION_MAX; ui_step = AS_POSITION_STEP; ui_category = "Position"; > = float2(AS_POSITION_DEFAULT, AS_POSITION_DEFAULT); \
uniform float scaleName < ui_type = "slider"; ui_label = "Scale"; ui_tooltip = "Size of the effect. Higher values zoom out, lower values zoom in."; ui_min = AS_SCALE_MIN; ui_max = AS_SCALE_MAX; ui_step = AS_SCALE_STEP; ui_category = "Position"; > = AS_SCALE_DEFAULT;

// --- Position Helper Functions ---
// Applies position offset and scaling to centered coordinates
float2 AS_applyPosScale(float2 coord, float2 pos, float scale) {
    coord.x -= pos.x;
    coord.y += pos.y; 
    return coord / max(scale, AS_EPSILON); 
}

// Converts normalized texcoord to centered, aspect-corrected coordinates
float2 AS_centerCoord(float2 texcoord, float aspectRatio) {
    float2 centered = texcoord - 0.5;
    if (aspectRatio >= 1.0) {
        centered.x *= aspectRatio;
    } else {
        centered.y /= aspectRatio;
    }
    return centered;
}

// All-in-one function that handles the common position/scale pattern
float2 AS_transformCoord(float2 texcoord, float2 pos, float scale, float rotation) {
    float aspectRatio = ReShade::AspectRatio;
    float2 centered = AS_centerCoord(texcoord, aspectRatio);
    float2 positioned = AS_applyPosScale(centered, pos, scale);
    if (abs(rotation) > AS_EPSILON) {
        float s = sin(rotation);
        float c = cos(rotation);
        positioned = float2(
            positioned.x * c - positioned.y * s,
            positioned.x * s + positioned.y * c
        );
    }
    return positioned;
}

/**
 * Rotates a 2D point around the origin.
 * p: The float2 point to rotate.
 * a: The angle of rotation in radians.
 * Returns the rotated float2 point.
 */
float2 AS_rotate2D(float2 p, float a)
{
    float s = sin(a);
    float c = cos(a);
    return float2(
        p.x * c - p.y * s,
        p.x * s + p.y * c
    );
}

float2 AS_applyRotation(float2 coord, float rotation)
{ return AS_rotate2D(coord, rotation);}

// --- Math Helpers ---
float AS_mod(float x, float y) {
    if (abs(y) < AS_EPSILON) return x;
    return x - y * floor(x / y);
}

float fmod(float x, float y) { // Ensure fmod is available if AS_mod is used as a replacement
    return AS_mod(x, y);
}


// ============================================================================
// VISUAL EFFECTS & BLEND MODES
// ============================================================================

// --- Blend Functions ---
float3 AS_applyBlend(float3 fgColor, float3 bgColor, int blendMode) {
    // Assuming ComHeaders::Blending::Blend is available from Blending.fxh
    // The Blend function in Blending.fxh is:
    // float3 Blend(const int type, const float3 backdrop, const float3 source, const float opacity = 1.0)
    return ComHeaders::Blending::Blend(blendMode, bgColor, fgColor, 1.0).rgb; 
}

float4 AS_applyBlend(float4 fgColor, float4 bgColor, int blendMode, float blendOpacity) {
    float3 effect_rgb = AS_applyBlend(fgColor.rgb, bgColor.rgb, blendMode);
    float final_opacity = saturate(fgColor.a * blendOpacity);
    float3 final_rgb = lerp(bgColor.rgb, effect_rgb, final_opacity);
    return float4(final_rgb, bgColor.a); 
}

float3 AS_paletteLerp(float3 c0, float3 c1, float t) {
    return lerp(c0, c1, t);
}

// ============================================================================
// MATRIX & VECTOR MULTIPLICATION HELPERS (Use if intrinsic 'mul' causes issues)
// ============================================================================
float2 AS_mul_float2x2_float2(float2x2 M, float2 v)
{
    return float2( M[0][0] * v.x + M[1][0] * v.y, M[0][1] * v.x + M[1][1] * v.y );
}

float2 AS_mul_float2_float2x2(float2 v, float2x2 M)
{
    return float2( v.x * M[0][0] + v.y * M[0][1], v.x * M[1][0] + v.y * M[1][1] );
}

float2x2 AS_mul_float2x2_float2x2(float2x2 A, float2x2 B)
{
    float2x2 C;
    C[0][0] = A[0][0] * B[0][0] + A[1][0] * B[0][1];
    C[0][1] = A[0][1] * B[0][0] + A[1][1] * B[0][1];
    C[1][0] = A[0][0] * B[1][0] + A[1][0] * B[1][1];
    C[1][1] = A[0][1] * B[1][0] + A[1][1] * B[1][1];
    return C;
}

// ============================================================================
// AUDIO REACTIVITY FUNCTIONS
// ============================================================================

// --- Time Functions ---
uniform int frameCount < source = "framecount"; >; 

float AS_getTime() {
#if defined(__LISTENINGWAY_INSTALLED)
    if (Listeningway_TotalPhases120Hz > AS_EPSILON) {
        return Listeningway_TotalPhases120Hz * (1.0f / 120.0f); 
    }
    else if (Listeningway_TimeSeconds > AS_EPSILON) {
        return Listeningway_TimeSeconds;
    }
#endif
    return float(frameCount) * (1.0f / 60.0f);
}

// --- Listeningway Helpers ---
int AS_getFreqBands() {
#if defined(__LISTENINGWAY_INSTALLED) && defined(LISTENINGWAY_NUM_BANDS)
    return LISTENINGWAY_NUM_BANDS;
#else
    return AS_DEFAULT_NUM_BANDS;
#endif
}

float AS_getFreq(int index) {
#if defined(__LISTENINGWAY_INSTALLED)
    int numBands = AS_getFreqBands();
    int safeIndex = clamp(index, 0, numBands - 1);
    return Listeningway_FreqBands[safeIndex];
#else
    return 0.0;
#endif
}

int AS_mapAngleToBand(float angleRadians, int repetitions) {
    float normalizedAngle = AS_mod(angleRadians, AS_TWO_PI) / AS_TWO_PI;
    int numBands = AS_getFreqBands();
    if (numBands <= 0) return 0; 
    int totalBands = numBands * max(1, repetitions); 
    int bandIdx = int(floor(normalizedAngle * totalBands)) % numBands;
    return bandIdx;
}

float AS_getVU(int source) {
#if defined(__LISTENINGWAY_INSTALLED)
    if (source == 0) return Listeningway_Volume;
    if (source == 1) return Listeningway_Beat;
    if (source == 2) return Listeningway_FreqBands[min(0, LISTENINGWAY_NUM_BANDS - 1)]; 
    if (source == 3) return Listeningway_FreqBands[min(14, LISTENINGWAY_NUM_BANDS - 1)];
    if (source == 4) return Listeningway_FreqBands[min(28, LISTENINGWAY_NUM_BANDS - 1)]; 
#endif
    return 0.0;
}

float AS_getAudioSource(int source) {
    if (source == AS_AUDIO_OFF)   return 0.0;         
    if (source == AS_AUDIO_SOLID)  return 1.0;         
#if defined(__LISTENINGWAY_INSTALLED)
    if (source == AS_AUDIO_VOLUME) return Listeningway_Volume; 
    if (source == AS_AUDIO_BEAT)   return Listeningway_Beat;   

    int numBands = AS_getFreqBands();
    if (numBands <= 1 && (source == AS_AUDIO_BASS || source == AS_AUDIO_MID || source == AS_AUDIO_TREBLE)) return 0.0;

    if (source == AS_AUDIO_BASS)   return Listeningway_FreqBands[0];
    if (source == AS_AUDIO_MID)    return Listeningway_FreqBands[numBands / 2];
    if (source == AS_AUDIO_TREBLE) return Listeningway_FreqBands[numBands - 1];
    
    if (source == AS_AUDIO_VOLUME_LEFT) return Listeningway_VolumeLeft; 
    if (source == AS_AUDIO_VOLUME_RIGHT) return Listeningway_VolumeRight;
    if (source == AS_AUDIO_PAN) return (Listeningway_AudioPan + 1.0) * 0.5;
#endif
    return 0.0; 
}

float AS_applyAudioReactivity(float baseValue, int audioSource, float multiplier, bool enableFlag) {
    if (!enableFlag || audioSource == AS_AUDIO_OFF) return baseValue;
    float audioLevel = AS_getAudioSource(audioSource);
    return baseValue * (1.0 + audioLevel * multiplier);
}

float AS_applyAudioReactivityEx(float baseValue, int audioSource, float multiplier, bool enableFlag, int mode) {
    if (!enableFlag || audioSource == AS_AUDIO_OFF) return baseValue;
    float audioLevel = AS_getAudioSource(audioSource);
    if (mode == 1) { // Additive mode
        return baseValue + (audioLevel * multiplier);
    } else { // Multiplicative mode (default)
        return baseValue * (1.0 + audioLevel * multiplier);
    }
}


// ============================================================================
// STEREO AUDIO HELPER FUNCTIONS
// ============================================================================
int AS_getAudioFormat() {
#if defined(__LISTENINGWAY_INSTALLED)
    return int(Listeningway_AudioFormat);
#else
    return 0; 
#endif
}

bool AS_isStereoAvailable() {
    return AS_getAudioFormat() >= 2;
}

bool AS_isSurroundAvailable() {
    return AS_getAudioFormat() >= 6;
}

float2 AS_getStereoBalance() {
#if defined(__LISTENINGWAY_INSTALLED)
    if (!AS_isStereoAvailable()) {
        return float2(0.5, 0.5);
    }
    float pan = Listeningway_AudioPan; 
    float leftFactor = saturate(0.5 - pan * 0.5);  
    float rightFactor = saturate(0.5 + pan * 0.5); 
    return float2(leftFactor, rightFactor);
#else
    return float2(0.5, 0.5);
#endif
}

float AS_getStereoAudioReactivity(float position, int audioSource) {
    if (audioSource == AS_AUDIO_OFF) return 0.0;
    if (!AS_isStereoAvailable()) {
        return AS_getAudioSource(audioSource);
    }
#if defined(__LISTENINGWAY_INSTALLED)
    float2 stereoBalance = AS_getStereoBalance(); // This uses Listeningway_AudioPan
    float leftWeight = saturate(0.5 - position * 0.5);  
    float rightWeight = saturate(0.5 + position * 0.5); 
    
    if (audioSource == AS_AUDIO_VOLUME) 
        return Listeningway_VolumeLeft * leftWeight + Listeningway_VolumeRight * rightWeight;
    if (audioSource == AS_AUDIO_VOLUME_LEFT) 
        return Listeningway_VolumeLeft * leftWeight; 
    if (audioSource == AS_AUDIO_VOLUME_RIGHT) 
        return Listeningway_VolumeRight * rightWeight; 

    float generalAudioValue = AS_getAudioSource(audioSource);

    if (audioSource == AS_AUDIO_BASS || audioSource == AS_AUDIO_MID || audioSource == AS_AUDIO_TREBLE || audioSource == AS_AUDIO_BEAT) {
         float panEffect = (position < 0) ? stereoBalance.x : stereoBalance.y; 
         if (abs(position) < AS_EPSILON) panEffect = (stereoBalance.x + stereoBalance.y) * 0.5; 
         return generalAudioValue * panEffect;
    }
    if (audioSource == AS_AUDIO_PAN) { 
         return (Listeningway_AudioPan * position + 1.0) * 0.5; 
    }
    
    return generalAudioValue; 
#else     
    return AS_getAudioSource(audioSource);
#endif
}

/**
 * Converts the Listeningway audio pan value to a direction in radians.
 * -1.0 pan (full left) maps to -PI/2 radians (-90 degrees).
 * 0.0 pan (center) maps to 0 radians (0 degrees).
 * +1.0 pan (full right) maps to +PI/2 radians (+90 degrees).
 * Returns the audio direction in radians.
 */
float AS_getAudioDirectionRadians() {
#if defined(__LISTENINGWAY_INSTALLED)
    // Listeningway_AudioPan ranges from -1.0 (left) to +1.0 (right)
    // Multiplying by AS_HALF_PI maps this to -PI/2 to +PI/2
    return Listeningway_AudioPan * AS_HALF_PI;
#else
    // If Listeningway is not installed, the fallback definition for Listeningway_AudioPan is 0.0f.
    // So, 0.0 * AS_HALF_PI = 0.0, which is correct for no pan information.
    return 0.0f; 
#endif
}

// ============================================================================
// STEREO UI STANDARDIZATION
// ============================================================================
#define AS_AUDIO_STEREO_UI(name, label, defaultSource, category) \
uniform int name < ui_type = "combo"; ui_label = label; ui_items = AS_AUDIO_SOURCE_ITEMS; ui_tooltip = "Audio source for reactivity. Stereo options available when stereo audio detected."; ui_category = category; > = defaultSource;

#define AS_STEREO_POSITION_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Stereo Position"; ui_tooltip = "Stereo position for audio reactivity (-1.0 = left, 0.0 = center, 1.0 = right). Only effective with stereo audio."; ui_min = -1.0; ui_max = 1.0; ui_step = 0.01; ui_category = category; > = 0.0;

#define AS_AUDIO_STEREO_FULL_UI(sourceName, posName, multName, label, defaultSource, category) \
uniform int sourceName < ui_type = "combo"; ui_label = label " Source"; ui_items = AS_AUDIO_SOURCE_ITEMS; ui_tooltip = "Audio source for reactivity. Stereo options available when stereo audio detected."; ui_category = category; > = defaultSource; \
uniform float posName < ui_type = "slider"; ui_label = label " Stereo Position"; ui_tooltip = "Stereo position for audio reactivity (-1.0 = left, 0.0 = center, 1.0 = right). Only effective with stereo audio."; ui_min = -1.0; ui_max = 1.0; ui_step = 0.01; ui_category = category; > = 0.0; \
uniform float multName < ui_type = "slider"; ui_label = label " Multiplier"; ui_tooltip = "Controls how much the selected audio source affects this parameter."; ui_min = 0.0; ui_max = 2.0; ui_step = 0.05; ui_category = category; > = 1.0;

// ============================================================================
// ENHANCED AUDIO HELPER FUNCTIONS
// ============================================================================
float AS_applyAudioReactivityStereo(float baseValue, int audioSource, float multiplier, float stereoPosition, bool enableFlag) {
    if (!enableFlag || audioSource == AS_AUDIO_OFF) return baseValue;
    float audioLevel = AS_getStereoAudioReactivity(stereoPosition, audioSource);
    return baseValue * (1.0 + audioLevel * multiplier);
}

float AS_getAudioSourceSafe(int source, float fallbackValue = 0.0) {
#if defined(__LISTENINGWAY_INSTALLED)
    if (Listeningway_TotalPhases120Hz > AS_EPSILON || Listeningway_Volume > AS_EPSILON || Listeningway_AudioFormat > 0) { 
        return AS_getAudioSource(source);
    }
#endif
    return (source == AS_AUDIO_SOLID) ? 1.0 : fallbackValue;
}

float AS_getSmoothedAudio(int source, float smoothing = 0.1) {
    static float previousValue = 0.0; 
    float currentValue = AS_getAudioSourceSafe(source); 
    float smoothed = lerp(previousValue, currentValue, saturate(smoothing)); 
    previousValue = smoothed;
    return smoothed;
}

float AS_getFreqByPercent(float percent) {
#if defined(__LISTENINGWAY_INSTALLED)
    int numBands = AS_getFreqBands();
    if (numBands <= 1) return 0.0;
    int bandIndex = int(saturate(percent) * (numBands - 1));
    return Listeningway_FreqBands[bandIndex];
#else
    return 0.0;
#endif
}


// ============================================================================
// AUDIO DEBUG HELPERS
// ============================================================================
float4 AS_debugAudio(float2 texcoord, int debugMode) {
    if (debugMode != AS_DEBUG_AUDIO) return float4(0, 0, 0, 0); 
#if defined(__LISTENINGWAY_INSTALLED)
    float3 debugColor = float3(0, 0, 0);
    if (texcoord.x < 0.2 && texcoord.y < 0.1) {
        int format = AS_getAudioFormat();
        if (format == 0) debugColor = float3(1, 0, 0);      
        else if (format == 1) debugColor = float3(1, 1, 0); 
        else if (format == 2) debugColor = float3(0, 1, 0); 
        else debugColor = float3(0, 0, 1);                  
    }
    
    int numBands = AS_getFreqBands();
    if (numBands > 0 && texcoord.y > 0.2 && texcoord.y < 0.8) { 
        float bandWidth = 1.0 / numBands;
        int currentBand = int(texcoord.x / bandWidth);
        if (currentBand < numBands) {
            float bandValue = Listeningway_FreqBands[currentBand];
            if ((1.0 - texcoord.y) < bandValue * 0.6 + 0.2) { 
                 float hue = float(currentBand) / max(1,numBands-1); 
                 if (hue < 0.333) debugColor = float3(1.0 - hue * 3.0, hue * 3.0, 0);
                 else if (hue < 0.666) debugColor = float3(0, 1.0 - (hue - 0.333) * 3.0, (hue - 0.333) * 3.0);
                 else debugColor = float3((hue - 0.666) * 3.0, 0, 1.0 - (hue - 0.666) * 3.0);
            }
        }
    }
    
    if (AS_isStereoAvailable() && texcoord.y > 0.85) {
        float2 stereoBalance = AS_getStereoBalance();
        if (texcoord.x < 0.45) { 
            debugColor = float3(stereoBalance.x, stereoBalance.x * 0.5, 0); 
        } else if (texcoord.x > 0.55) { 
            debugColor = float3(0, stereoBalance.y * 0.5, stereoBalance.y); 
        } else { 
            float panNorm = (Listeningway_AudioPan + 1.0) * 0.5; 
            debugColor = float3(panNorm, panNorm, panNorm); 
        }
    }
    return float4(debugColor, 1.0);
#else
    if (texcoord.x > 0.4 && texcoord.x < 0.6 && texcoord.y > 0.4 && texcoord.y < 0.6)
      return float4(0.5, 0.2, 0.2, 1.0); 
    return float4(0.0, 0.0, 0.0, 0.0); 
#endif
}


// ============================================================================
// MATH & COORDINATE HELPERS (Continued from above, standard ones)
// ============================================================================

// --- Rotation UI Standardization ---
#define AS_ROTATION_UI(snapName, fineName) \
uniform int snapName < ui_category = "Stage"; ui_label = "Snap Rotation"; ui_type = "slider"; ui_min = -4; ui_max = 4; ui_step = 1; ui_tooltip = "Snap rotation in 45° steps (-180° to +180°)"; ui_spacing = 0; > = 0; \
uniform float fineName < ui_category = "Stage"; ui_label = "Fine Rotation"; ui_type = "slider"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_tooltip = "Fine rotation adjustment in degrees"; ui_same_line = true; > = 0.0;

float AS_getRotationRadians(int snapRotation, float fineRotation) {
    float snapAngle = float(snapRotation) * 45.0;
    return (snapAngle + fineRotation) * AS_DEGREES_TO_RADIANS;
}

// --- Animation UI Standardization ---
#define AS_ANIMATION_SPEED_MIN 0.0
#define AS_ANIMATION_SPEED_MAX 5.0
#define AS_ANIMATION_SPEED_STEP 0.01
#define AS_ANIMATION_SPEED_DEFAULT 1.0

#define AS_ANIMATION_KEYFRAME_MIN 0.0
#define AS_ANIMATION_KEYFRAME_MAX 100.0 
#define AS_ANIMATION_KEYFRAME_STEP 0.1
#define AS_ANIMATION_KEYFRAME_DEFAULT 0.0

#define AS_ANIMATION_SPEED_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect. Set to 0 to pause animation."; ui_min = AS_ANIMATION_SPEED_MIN; ui_max = AS_ANIMATION_SPEED_MAX; ui_step = AS_ANIMATION_SPEED_STEP; ui_category = category; > = AS_ANIMATION_SPEED_DEFAULT;

#define AS_ANIMATION_KEYFRAME_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = AS_ANIMATION_KEYFRAME_MIN; ui_max = AS_ANIMATION_KEYFRAME_MAX; ui_step = AS_ANIMATION_KEYFRAME_STEP; ui_category = category; > = AS_ANIMATION_KEYFRAME_DEFAULT;

#define AS_ANIMATION_UI(speedName, keyframeName, category) \
uniform float speedName < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect. Set to 0 to pause animation."; ui_min = AS_ANIMATION_SPEED_MIN; ui_max = AS_ANIMATION_SPEED_MAX; ui_step = AS_ANIMATION_SPEED_STEP; ui_category = category; > = AS_ANIMATION_SPEED_DEFAULT; \
uniform float keyframeName < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = AS_ANIMATION_KEYFRAME_MIN; ui_max = AS_ANIMATION_KEYFRAME_MAX; ui_step = AS_ANIMATION_KEYFRAME_STEP; ui_category = category; > = AS_ANIMATION_KEYFRAME_DEFAULT;

float AS_getAnimationTime(float speed, float keyframe) {
    if (abs(speed) < AS_EPSILON) { 
        return keyframe;
    }
    return (AS_getTime() * speed) + keyframe;
}

float2 AS_aspectCorrect(float2 uv, float width, float height) { // Corrected parameter name
    if (abs(height) < AS_EPSILON) return uv; 
    float aspect = width / height; 
    return float2((uv.x - 0.5) * aspect + 0.5, uv.y); 
}

float2 AS_aspectCorrectUV(float2 uv, float aspectRatio) {
    float2 centered_uv = uv - 0.5;
    centered_uv.x *= aspectRatio;
    return centered_uv + 0.5; 
}

float AS_radians(float deg) {
    return deg * AS_DEGREES_TO_RADIANS;
}

float AS_degrees(float rad) {
    return rad * AS_RADIANS_TO_DEGREES;
}

float2 AS_rescaleToScreen(float2 uv) {
    return uv * ReShade::ScreenSize.xy;
}

// ============================================================================
// DEPTH, SURFACE & VISUAL EFFECTS
// ============================================================================
float AS_depthMask(float depth, float nearPlane, float farPlane, float curve) {
    farPlane = max(nearPlane + AS_EPS_SAFE, farPlane); 
    float mask = smoothstep(nearPlane, farPlane, depth);
    return 1.0 - pow(mask, max(0.1f, curve)); 
}

float3 AS_reconstructNormal(float2 texcoord) {
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float px = max(abs(ReShade::PixelSize.x), AS_EPSILON);
    float py = max(abs(ReShade::PixelSize.y), AS_EPSILON);

    float depthX1 = ReShade::GetLinearizedDepth(texcoord + float2(px, 0.0));
    float depthY1 = ReShade::GetLinearizedDepth(texcoord + float2(0.0, py));
    
    float3 dx = float3(px, 0.0, depthX1 - depth);
    float3 dy = float3(0.0, py, depthY1 - depth);
    return normalize(cross(dy, dx)); 
}

float AS_fresnel(float3 normal, float3 viewDir, float power) {
    normal = normalize(normal); 
    viewDir = normalize(viewDir);
    return pow(1.0 - saturate(dot(normal, viewDir)), max(0.1f, power)); 
}

float stanh(float x, float safetyThreshold = 12.0) {
    if (abs(x) <= safetyThreshold) {
        return tanh(x);
    }
    return sign(x) * (1.0f - exp(-abs(x - sign(x) * safetyThreshold)) * (1.0f - tanh(safetyThreshold * sign(x))));
}

float2 stanh(float2 x, float safetyThreshold = 12.0) { return float2(stanh(x.x, safetyThreshold), stanh(x.y, safetyThreshold)); }
float3 stanh(float3 x, float safetyThreshold = 12.0) { return float3(stanh(x.x, safetyThreshold), stanh(x.y, safetyThreshold), stanh(x.z, safetyThreshold)); }
float4 stanh(float4 x, float safetyThreshold = 12.0) { return float4(stanh(x.x, safetyThreshold), stanh(x.y, safetyThreshold), stanh(x.z, safetyThreshold), stanh(x.w, safetyThreshold)); }

float AS_fadeInOut(float cycle, float fadeInEnd, float fadeOutStart) {
    fadeInEnd = saturate(fadeInEnd);
    fadeOutStart = saturate(fadeOutStart);
    if (fadeInEnd >= fadeOutStart) return (cycle < 0.5) ? smoothstep(0.0, 0.5, cycle) * 2.0 : (1.0 - smoothstep(0.5, 1.0, cycle)) * 2.0;

    float brightness = 1.0;
    if (cycle < fadeInEnd) {
        brightness = smoothstep(0.0, fadeInEnd, cycle);
    } else if (cycle > fadeOutStart) {
        brightness = 1.0 - smoothstep(fadeOutStart, 1.0, cycle);
    }
    return brightness;
}

float AS_applySway(float swayAngle, float swaySpeed) {
    float time = AS_getTime();
    float swayPhase = time * swaySpeed;
    return AS_radians(swayAngle) * sin(swayPhase);
}

float AS_applyAudioSway(float swayAngle, float swaySpeed, int audioSource, float audioMult) {
    float time = AS_getTime();
    float audioLevel = AS_getAudioSourceSafe(audioSource); 
    float reactiveAngle = swayAngle * (1.0 + audioLevel * audioMult);
    float swayPhase = time * swaySpeed;
    return AS_radians(reactiveAngle) * sin(swayPhase);
}

float4 AS_debugOutput(int mode, float4 orig, float4 value1, float4 value2, float4 value3) {
    if (mode == 1) return value1; 
    if (mode == 2) return value2; 
    if (mode == 3) return value3; 
    return orig; 
}

float AS_starMask(float2 p, float size, float points, float angle) {
    float2 uv = p / max(size, AS_EPS_SAFE); 
    float a = atan2(uv.y, uv.x) + AS_radians(angle); 
    float r = length(uv); 
    float f = cos(a * points) * 0.5 + 0.5; 
    return 1.0 - smoothstep(f, f + AS_EDGE_AA, r); 
}

// ============================================================================
// STAGE DEPTH & BLEND UI HELPERS
// ============================================================================
#define AS_STAGEDEPTH_UI(name) \
uniform float name < ui_type = "slider"; ui_label = "Effect Depth"; ui_tooltip = "Controls how far back the stage effect appears (Linear Depth 0-1)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Stage"; > = 0.05;

#define AS_BLENDMODE_UI_DEFAULT(name, defaultMode) \
BLENDING_COMBO(name, "Mode", "Select how the effect will mix with the background.", "Final Mix", false, 0, defaultMode)

#define AS_BLENDMODE_UI(name) \
    AS_BLENDMODE_UI_DEFAULT(name, 0) 

#define AS_BLENDAMOUNT_UI(name) \
uniform float name < ui_type = "slider"; ui_label = "Strength"; ui_tooltip = "Controls the overall intensity/opacity of the effect blend."; ui_min = 0.0; ui_max = 1.0; ui_category = "Final Mix"; > = 1.0;

// ============================================================================
// TEXTURE & SAMPLER CREATION
// ============================================================================
#define AS_CREATE_TEXTURE(TEXTURE_NAME, SIZE_XY, FORMAT_TYPE, MIP_LEVELS) \
    texture2D TEXTURE_NAME { Width = SIZE_XY.x; Height = SIZE_XY.y; Format = FORMAT_TYPE; MipLevels = MIP_LEVELS; };

#define AS_CREATE_SAMPLER(SAMPLER_NAME, TEXTURE_RESOURCE, FILTER_TYPE, ADDRESS_MODE) \
    sampler2D SAMPLER_NAME { Texture = TEXTURE_RESOURCE; MagFilter = FILTER_TYPE; MinFilter = FILTER_TYPE; MipFilter = FILTER_TYPE; AddressU = ADDRESS_MODE; AddressV = ADDRESS_MODE; };

#define AS_CREATE_TEX_SAMPLER(TEXTURE_NAME, SAMPLER_NAME, SIZE_XY, FORMAT_TYPE, MIP_LEVELS, FILTER_TYPE, ADDRESS_MODE) \
    texture2D TEXTURE_NAME { Width = SIZE_XY.x; Height = SIZE_XY.y; Format = FORMAT_TYPE; MipLevels = MIP_LEVELS; }; \
    sampler2D SAMPLER_NAME { Texture = TEXTURE_NAME; MagFilter = FILTER_TYPE; MinFilter = FILTER_TYPE; MipFilter = FILTER_TYPE; AddressU = ADDRESS_MODE; AddressV = ADDRESS_MODE; };

#endif // __AS_Utils_1_fxh