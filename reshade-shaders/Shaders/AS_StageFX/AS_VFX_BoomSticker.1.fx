/**
 * AS_VFX_BoomSticker.1.fx - Simple sticker texture overlay with audio reactivity
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Inspired by "StageDepth.fx" by Marot Satil (2019)
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Displays up to 4 textures ("stickers") with controls for placement, scale, rotation, and audio reactivity.
 *
 * FEATURES:
 * - Up to 4 customizable texture overlays with independent position, scale, and rotation controls
 * - Audio reactivity for opacity and scale
 * - Customizable depth masking for each sticker
 * - Support for custom textures via preprocessor definition
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Applies transformation matrix to screen coordinates
 * 2. Samples from specified texture at transformed coordinates
 * 3. Applies audio reactivity to selected parameter (opacity or scale)
 * 4. Blends with scene based on texture alpha and opacity
 * 5. Handles multiple stickers with depth sorting for proper layering
 * 
 * USAGE:
 * To use custom textures, add these lines to your "PreprocessorDefinitions.h" file:
 * #define BoomSticker1_FileName "path/to/your/texture1.png"
 * #define BoomSticker1_Width 1920
 * #define BoomSticker1_Height 1080
 * #define BoomSticker2_FileName "path/to/your/texture2.png"
 * #define BoomSticker2_Width 1920
 * #define BoomSticker2_Height 1080
 * ...and so on for stickers 3 and 4.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_BoomSticker_1_fx
#define __AS_VFX_BoomSticker_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "AS_Utils.1.fxh"

// ============================================================================
// CONSTANTS
// ============================================================================
static const int STICKER_COUNT = 4;  // Number of sticker instances supported

// ============================================================================
// TEXTURE DEFINITIONS
// ============================================================================
// Default texture 1 if not defined by the user
#ifndef BoomSticker1_FileName
    #define BoomSticker1_FileName "LayerStage.png"
#endif

#ifndef BoomSticker1_Width
    #define BoomSticker1_Width BUFFER_WIDTH
#endif

#ifndef BoomSticker1_Height
    #define BoomSticker1_Height BUFFER_HEIGHT
#endif

// Main sticker texture and sampler 1
texture BoomSticker1_Texture <source=BoomSticker1_FileName;> { Width = BoomSticker1_Width; Height = BoomSticker1_Height; Format=RGBA8; };
sampler BoomSticker1_Sampler { Texture = BoomSticker1_Texture; };

// Default texture 2 if not defined by the user
#ifndef BoomSticker2_FileName
    #define BoomSticker2_FileName "LayerStage.png"
#endif

#ifndef BoomSticker2_Width
    #define BoomSticker2_Width BUFFER_WIDTH
#endif

#ifndef BoomSticker2_Height
    #define BoomSticker2_Height BUFFER_HEIGHT
#endif

// Main sticker texture and sampler 2
texture BoomSticker2_Texture <source=BoomSticker2_FileName;> { Width = BoomSticker2_Width; Height = BoomSticker2_Height; Format=RGBA8; };
sampler BoomSticker2_Sampler { Texture = BoomSticker2_Texture; };

// Default texture 3 if not defined by the user
#ifndef BoomSticker3_FileName
    #define BoomSticker3_FileName "LayerStage.png"
#endif

#ifndef BoomSticker3_Width
    #define BoomSticker3_Width BUFFER_WIDTH
#endif

#ifndef BoomSticker3_Height
    #define BoomSticker3_Height BUFFER_HEIGHT
#endif

// Main sticker texture and sampler 3
texture BoomSticker3_Texture <source=BoomSticker3_FileName;> { Width = BoomSticker3_Width; Height = BoomSticker3_Height; Format=RGBA8; };
sampler BoomSticker3_Sampler { Texture = BoomSticker3_Texture; };

// Default texture 4 if not defined by the user
#ifndef BoomSticker4_FileName
    #define BoomSticker4_FileName "LayerStage.png"
#endif

#ifndef BoomSticker4_Width
    #define BoomSticker4_Width BUFFER_WIDTH
#endif

#ifndef BoomSticker4_Height
    #define BoomSticker4_Height BUFFER_HEIGHT
#endif

// Main sticker texture and sampler 4
texture BoomSticker4_Texture <source=BoomSticker4_FileName;> { Width = BoomSticker4_Width; Height = BoomSticker4_Height; Format=RGBA8; };
sampler BoomSticker4_Sampler { Texture = BoomSticker4_Texture; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float OPACITY_MIN = 0.0;
static const float OPACITY_MAX = 1.0;
static const float OPACITY_DEFAULT = 1.0;

static const float SCALE_MIN = 0.001;
static const float SCALE_MAX = 5.0;
static const float SCALE_DEFAULT = 0.5;

static const float POSITION_MIN = -2.0;
static const float POSITION_MAX = 2.0;
static const float POSITION_DEFAULT = 0.5;

static const float AUDIO_INTENSITY_MIN = 0.0;
static const float AUDIO_INTENSITY_MAX = 2.0;
static const float AUDIO_INTENSITY_DEFAULT = 0.5;

// ============================================================================
// STICKER UI MACRO
// ============================================================================
// Define a macro for the UI controls of each sticker to avoid repetition
#define STICKER_UI(index, defaultEnable, defaultPosition, defaultScale, defaultScaleXY, \
                  defaultOpacity, defaultDepth) \
uniform bool Sticker##index##_Enable < ui_label = "Enable Sticker " #index; ui_tooltip = "Toggle this sticker on or off."; ui_category = "Sticker " #index; ui_category_closed = index > 1; > = defaultEnable; \
uniform float2 Sticker##index##_PosXY < ui_category = "Sticker " #index; ui_label = "Position"; ui_type = "slider"; ui_min = POSITION_MIN; ui_max = POSITION_MAX; ui_step = 0.001; > = defaultPosition; \
uniform float Sticker##index##_Scale < ui_category = "Sticker " #index; ui_label = "Scale"; ui_type = "slider"; ui_min = SCALE_MIN; ui_max = SCALE_MAX; ui_step = 0.001; > = defaultScale; \
uniform float2 Sticker##index##_ScaleXY < ui_category = "Sticker " #index; ui_label = "Scale X/Y"; ui_type = "slider"; ui_min = SCALE_MIN; ui_max = SCALE_MAX; ui_step = 0.001; > = defaultScaleXY; \
uniform float Sticker##index##_Opacity < ui_category = "Sticker " #index; ui_label = "Opacity"; ui_type = "slider"; ui_min = OPACITY_MIN; ui_max = OPACITY_MAX; ui_step = 0.002; > = defaultOpacity; \
uniform int Sticker##index##_SnapRotate < ui_category = "Sticker " #index; ui_type = "slider"; ui_label = "Snap Rotation"; ui_tooltip = "Snap to 45-degree increments"; ui_min = 0; ui_max = 7; ui_step = 1; > = 0; \
uniform float Sticker##index##_Rotate < ui_category = "Sticker " #index; ui_type = "slider"; ui_label = "Fine Rotation"; ui_tooltip = "Fine rotation adjustment in degrees"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; > = 0; \
uniform float Sticker##index##_SwaySpeed < ui_category = "Sticker " #index; ui_type = "slider"; ui_label = "Sway Speed"; ui_tooltip = "Speed of automatic rotation sway"; ui_min = 0.0; ui_max = 10.0; ui_step = 0.1; > = 1.0; \
uniform float Sticker##index##_SwayAngle < ui_category = "Sticker " #index; ui_type = "slider"; ui_label = "Sway Angle"; ui_tooltip = "Maximum angle of rotation sway in degrees"; ui_min = 0.0; ui_max = 45.0; ui_step = 0.1; > = 0.0; \
uniform float Sticker##index##_Depth < ui_category = "Sticker " #index; ui_type = "slider"; ui_label = "Depth"; ui_tooltip = "Depth plane for this sticker (0.0-1.0). Lower values are closer to the camera."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = defaultDepth;

// ============================================================================
// STICKER CONTROLS (Using the macro)
// ============================================================================

// Sticker 1 controls (enabled by default, centered)
STICKER_UI(1, true, float2(POSITION_DEFAULT, POSITION_DEFAULT), SCALE_DEFAULT, float2(1.0, 1.0), 
           OPACITY_DEFAULT, 0.05)

// Sticker 2 controls (disabled by default, slightly offset)
STICKER_UI(2, false, float2(POSITION_DEFAULT + 0.2, POSITION_DEFAULT), SCALE_DEFAULT * 0.9, float2(1.0, 1.0), 
           OPACITY_DEFAULT, 0.05)

// Sticker 3 controls (disabled by default, slightly offset)
STICKER_UI(3, false, float2(POSITION_DEFAULT - 0.2, POSITION_DEFAULT), SCALE_DEFAULT * 0.8, float2(1.0, 1.0), 
           OPACITY_DEFAULT, 0.05)

// Sticker 4 controls (disabled by default, slightly offset)
STICKER_UI(4, false, float2(POSITION_DEFAULT, POSITION_DEFAULT - 0.2), SCALE_DEFAULT * 0.7, float2(1.0, 1.0), 
           OPACITY_DEFAULT, 0.05)

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================
uniform int BoomSticker_AudioAffect < ui_type = "combo"; ui_label = "Audio Affects"; ui_items = "Opacity\0Scale\0"; ui_category = "Audio Reactivity"; > = 1;

// Use the standard AS_AUDIO_UI macro to select audio source
AS_AUDIO_UI(BoomSticker_AudioSource, "Audio Source", AS_AUDIO_VOLUME, "Audio Reactivity")
AS_AUDIO_MULT_UI(BoomSticker_AudioIntensity, "Audio Intensity", AUDIO_INTENSITY_DEFAULT, AUDIO_INTENSITY_MAX, "Audio Reactivity")

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_UI("Off\0Beat\0Depth\0Audio Source\0")

// ============================================================================
// BLENDING
// ============================================================================
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// NAMESPACE & HELPERS
// ============================================================================
namespace AS_BoomSticker {

// Structure to hold sticker parameters
struct StickerParams {
    bool enable;
    float2 position;
    float scale;
    float2 scaleXY;
    float opacity;
    int snapRotate;
    float rotate;
    float swaySpeed;
    float swayAngle;
    float depth;
};

// Helper function to get sticker parameters for a given index
// IMPORTANT: stickerIndex is 1-based (1-4), matching the UI labels
StickerParams GetStickerParams(int stickerIndex) {
    StickerParams params;
    
    // Set sticker-specific parameters based on index
    if (stickerIndex == 1) {
        params.enable = Sticker1_Enable;
        params.position = Sticker1_PosXY;
        params.scale = Sticker1_Scale;
        params.scaleXY = Sticker1_ScaleXY;
        params.opacity = Sticker1_Opacity;
        params.snapRotate = Sticker1_SnapRotate;
        params.rotate = Sticker1_Rotate;
        params.swaySpeed = Sticker1_SwaySpeed;
        params.swayAngle = Sticker1_SwayAngle;
        params.depth = Sticker1_Depth;
    }
    else if (stickerIndex == 2) {
        params.enable = Sticker2_Enable;
        params.position = Sticker2_PosXY;
        params.scale = Sticker2_Scale;
        params.scaleXY = Sticker2_ScaleXY;
        params.opacity = Sticker2_Opacity;
        params.snapRotate = Sticker2_SnapRotate;
        params.rotate = Sticker2_Rotate;
        params.swaySpeed = Sticker2_SwaySpeed;
        params.swayAngle = Sticker2_SwayAngle;
        params.depth = Sticker2_Depth;
    }
    else if (stickerIndex == 3) {
        params.enable = Sticker3_Enable;
        params.position = Sticker3_PosXY;
        params.scale = Sticker3_Scale;
        params.scaleXY = Sticker3_ScaleXY;
        params.opacity = Sticker3_Opacity;
        params.snapRotate = Sticker3_SnapRotate;
        params.rotate = Sticker3_Rotate;
        params.swaySpeed = Sticker3_SwaySpeed;
        params.swayAngle = Sticker3_SwayAngle;
        params.depth = Sticker3_Depth;
    }
    else { // stickerIndex == 4
        params.enable = Sticker4_Enable;
        params.position = Sticker4_PosXY;
        params.scale = Sticker4_Scale;
        params.scaleXY = Sticker4_ScaleXY;
        params.opacity = Sticker4_Opacity;
        params.snapRotate = Sticker4_SnapRotate;
        params.rotate = Sticker4_Rotate;
        params.swaySpeed = Sticker4_SwaySpeed;
        params.swayAngle = Sticker4_SwayAngle;
        params.depth = Sticker4_Depth;
    }
    
    return params;
}

// Helper function to sample the appropriate texture based on sticker index
// IMPORTANT: stickerIndex is 1-based (1-4), matching the UI labels
float4 SampleStickerTexture(float2 uv, int stickerIndex) {
    if (stickerIndex == 1) return tex2D(BoomSticker1_Sampler, uv);
    else if (stickerIndex == 2) return tex2D(BoomSticker2_Sampler, uv);
    else if (stickerIndex == 3) return tex2D(BoomSticker3_Sampler, uv);
    else return tex2D(BoomSticker4_Sampler, uv); // stickerIndex == 4
}

// Helper function to get the texture dimensions for a given sticker
// IMPORTANT: stickerIndex is 1-based (1-4), matching the UI labels
float2 GetStickerDimensions(int stickerIndex) {
    if (stickerIndex == 1) return float2(BoomSticker1_Width, BoomSticker1_Height);
    else if (stickerIndex == 2) return float2(BoomSticker2_Width, BoomSticker2_Height);
    else if (stickerIndex == 3) return float2(BoomSticker3_Width, BoomSticker3_Height);
    else return float2(BoomSticker4_Width, BoomSticker4_Height); // stickerIndex == 4
}

// Helper function to rotate UVs
float2 rotateUV(float2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float2 center = float2(0.5, 0.5);
    uv -= center;
    float2 rotated = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    return rotated + center;
}

// Helper function to apply a sticker to the original color
float4 ApplySticker(float4 originalColor, float2 texCoord, int stickerIndex, float audioValue) {
    StickerParams params = GetStickerParams(stickerIndex);
    
    // Apply audio reactivity
    float opacity = params.opacity;
    float scale = params.scale;
    
    // Apply the audio to the selected parameter - properly additive
    if (BoomSticker_AudioAffect == 0) {
        opacity = opacity + audioValue;
    }
    else if (BoomSticker_AudioAffect == 1) {
        scale = scale + audioValue;
    }
    
    // Safety clamp
    scale = max(scale, 0.01);
    opacity = saturate(opacity);
    
    // Setup transformation variables
    float3 pivot = float3(0.5, 0.5, 0.0);
    float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT));
    float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH));
    float3 mulUV = float3(texCoord.x, texCoord.y, 1);
    
    // Calculate texture aspect ratio correction
    float2 dimensions = GetStickerDimensions(stickerIndex);
    float textureAspect = float(dimensions.x) / float(dimensions.y);
    float screenAspect = float(BUFFER_WIDTH) / float(BUFFER_HEIGHT);
    float aspectCorrection = textureAspect / screenAspect;
    
    // Calculate scale with aspect ratio preservation
    float2 ScaleSize = float2(BUFFER_WIDTH, BUFFER_HEIGHT) * scale / BUFFER_SCREEN_SIZE;
    // Apply aspect ratio correction to maintain texture proportions
    ScaleSize.x *= aspectCorrection;
    float ScaleX = ScaleSize.x * AspectX * params.scaleXY.x;
    float ScaleY = ScaleSize.y * AspectY * params.scaleXY.y;
    
    // Calculate rotation
    float SnapAngle = float(params.snapRotate) * 45.0;
    float Rotate = (params.rotate + SnapAngle) * AS_DEGREES_TO_RADIANS;
    
    // Apply sway
    float sway = AS_applySway(params.swayAngle, params.swaySpeed);
    
    // Add sway to rotation (sway is already in radians)
    Rotate += sway;
    
    // Build transformation matrices
    float3x3 positionMatrix = float3x3(
        1, 0, 0,
        0, 1, 0,
        -params.position.x, -params.position.y, 1
    );
    
    float3x3 scaleMatrix = float3x3(
        1/ScaleX, 0, 0,
        0, 1/ScaleY, 0,
        0, 0, 1
    );
    
    float3x3 rotateMatrix = float3x3(
        (cos(Rotate) * AspectX), (sin(Rotate) * AspectX), 0,
        (-sin(Rotate) * AspectY), (cos(Rotate) * AspectY), 0,
        0, 0, 1
    );
    
    // Apply transformations
    float3 SumUV = mul(mul(mul(mulUV, positionMatrix), rotateMatrix), scaleMatrix);
    
    // Sample the sticker texture and apply it only if we're within its bounds
    float4 stickerColor = SampleStickerTexture(SumUV.rg + pivot.rg, stickerIndex) * all(SumUV + pivot == saturate(SumUV + pivot));
    
    // Mix with background based on opacity and sticker alpha
    float4 result;
    result.rgb = lerp(originalColor.rgb, stickerColor.rgb, stickerColor.a * opacity);
    result.a = originalColor.a;
    
    return result;
}

} // namespace AS_BoomSticker

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
void PS_BoomSticker(in float4 position : SV_Position, in float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
    // Get original pixel color first
    float4 originalColor = tex2D(ReShade::BackBuffer, texCoord);
    
    // Handle debug modes
    if (DebugMode == 1) {
        // Debug audio beat - use AS_getAudioSource instead of direct Listeningway reference
        float beat = AS_getAudioSource(AS_AUDIO_BEAT);
        passColor = float4(beat, beat, beat, 1.0);
        return;
    }
    else if (DebugMode == 2) {
        // Debug depth visualization
        float depth = ReShade::GetLinearizedDepth(texCoord);
        passColor = float4(depth.xxx, 1.0);
        return;
    }
    else if (DebugMode == 3) {
        // Debug selected audio source
        float audioValue = AS_getAudioSource(BoomSticker_AudioSource);
        passColor = float4(audioValue, audioValue, audioValue, 1.0);
        return;
    }
    
    // Get scene depth
    float sceneDepth = ReShade::GetLinearizedDepth(texCoord);
      // Get the raw audio value without scaling it by a base value
    float audioSourceValue = AS_getAudioSource(BoomSticker_AudioSource);
    float audioValue = audioSourceValue * BoomSticker_AudioIntensity;
    
    // Initialize output color with original color
    float4 finalResult = originalColor;
      // Process each sticker in predefined order (sticker 4 to 1, assuming depth increases with sticker number)
    // This eliminates the need for complex sorting which might cause compilation issues
    
    // Sticker 4 (background)
    AS_BoomSticker::StickerParams params4 = AS_BoomSticker::GetStickerParams(4);
    if (params4.enable && sceneDepth >= params4.depth - AS_DEPTH_EPSILON) {
        finalResult = AS_BoomSticker::ApplySticker(finalResult, texCoord, 4, audioValue);
    }
    
    // Sticker 3
    AS_BoomSticker::StickerParams params3 = AS_BoomSticker::GetStickerParams(3);
    if (params3.enable && sceneDepth >= params3.depth - AS_DEPTH_EPSILON) {
        finalResult = AS_BoomSticker::ApplySticker(finalResult, texCoord, 3, audioValue);
    }
    
    // Sticker 2
    AS_BoomSticker::StickerParams params2 = AS_BoomSticker::GetStickerParams(2);
    if (params2.enable && sceneDepth >= params2.depth - AS_DEPTH_EPSILON) {
        finalResult = AS_BoomSticker::ApplySticker(finalResult, texCoord, 2, audioValue);
    }
    
    // Sticker 1 (foreground)
    AS_BoomSticker::StickerParams params1 = AS_BoomSticker::GetStickerParams(1);
    if (params1.enable && sceneDepth >= params1.depth - AS_DEPTH_EPSILON) {
        finalResult = AS_BoomSticker::ApplySticker(finalResult, texCoord, 1, audioValue);
    }
    
    passColor = finalResult;
}
// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BoomSticker < ui_label = "[AS] VFX: BoomSticker"; ui_tooltip = "Multi-layer sticker overlays with audio reactivity"; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_BoomSticker;
    }
}

#endif // __AS_VFX_BoomSticker_1_fx

