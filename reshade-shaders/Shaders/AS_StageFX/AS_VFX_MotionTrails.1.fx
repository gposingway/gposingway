/**
 * AS_VFX_MotionTrails.1.fx - Music-Reactive Depth-Based Trail Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates striking motion trails that persist over time, perfect for music videos.
 * Objects within a specified depth threshold leave behind colored trails that slowly fade,
 * creating dynamic visual paths ideal for dramatic footage and creative compositions.
 *
 * FEATURES:
 * - Depth-based subject tracking for dynamic trail effects
 * - Multiple capture modes: tempo-based, frame-based, audio beat, or manual trigger
 * - User-definable trail color, strength, and persistence
 * - Audio-reactive trail timing, intensity and colors through AS_Utils integration
 * - Multiple blend modes for scene integration
 * - Optional subject highlight modes: normal, pulse, or silhouette
 * - Precise depth control for targeting specific scene elements
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses multi-pass rendering with ping-pong buffers for accumulation and timing
 * 2. Pass 1: Updates timing and determines when to capture based on selected mode
 * 3. Pass 2: Accumulates trail information with fading for persistence
 * 4. Pass 3 & 5: Copy buffer contents for next frame processing
 * 5. Pass 4: Composites trails with original scene and applies subject overlay
 * 6. Audio reactivity can modulate timing intervals and trail intensity
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_MotionTrails_1_fx
#define __AS_VFX_MotionTrails_1_fx

#include "AS_Utils.1.fxh"

// --- Helper Functions and Namespace ---
namespace AS_DepthEcho {
    // Use AS_Utils' audio functions directly instead of creating a local wrapper
    float getAudioSource(int source) {
        return AS_getAudioSource(source);
    }
}

// --- Tunable Constants ---
static const float FECHO_DEPTHCUTOFF_MIN = 0.01;
static const float FECHO_DEPTHCUTOFF_MAX = 0.5;
static const float FECHO_DEPTHCUTOFF_DEFAULT = 0.04;
static const float FECHO_FADERATE_MIN = 0.8;
static const float FECHO_FADERATE_MAX = 0.99;
static const float FECHO_FADERATE_DEFAULT = 0.95;
static const float FECHO_STRENGTH_MIN = 0.1;
static const float FECHO_STRENGTH_MAX = 2.0;
static const float FECHO_STRENGTH_DEFAULT = 0.8;
static const float FECHO_TIMEINTERVAL_MIN = 0.0;
static const float FECHO_TIMEINTERVAL_MAX = 5000.0;
static const float FECHO_TIMEINTERVAL_DEFAULT = 50.0;
static const int IECHO_FRAMEINTERVAL_MIN = 1;
static const int IECHO_FRAMEINTERVAL_MAX = 60;
static const int IECHO_FRAMEINTERVAL_DEFAULT = 15;
static const float BLENDAMOUNT_MIN = 0.0;
static const float BLENDAMOUNT_MAX = 1.0;
static const float BLENDAMOUNT_DEFAULT = 1.0;

// --- UI Uniforms - Main Design Controls ---
uniform float fEcho_DepthCutoff < ui_type = "slider"; ui_min = FECHO_DEPTHCUTOFF_MIN; ui_max = FECHO_DEPTHCUTOFF_MAX; ui_step = 0.01; ui_label = "Subject Focus"; ui_tooltip = "Objects closer than this depth value will create trails"; ui_category = "Trail Design"; > = FECHO_DEPTHCUTOFF_DEFAULT;
uniform float fEcho_FadeRate < ui_type = "slider"; ui_min = FECHO_FADERATE_MIN; ui_max = FECHO_FADERATE_MAX; ui_step = 0.01; ui_label = "Trail Persistence"; ui_tooltip = "How slowly trails fade away (higher = longer lasting)"; ui_category = "Trail Design"; > = FECHO_FADERATE_DEFAULT;
uniform float3 fEcho_Color < ui_type = "color"; ui_label = "Trail Hue"; ui_tooltip = "Color of the trail effect"; ui_category = "Trail Design"; > = float3(0.2, 0.5, 1.0);
uniform float fEcho_Strength < ui_type = "slider"; ui_min = FECHO_STRENGTH_MIN; ui_max = FECHO_STRENGTH_MAX; ui_step = 0.1; ui_label = "Trail Intensity"; ui_tooltip = "Intensity of the trail effect"; ui_category = "Trail Design"; > = FECHO_STRENGTH_DEFAULT;
uniform int iEcho_SubjectOverlay < ui_type = "combo"; ui_label = "Subject Overlay"; ui_tooltip = "How to display the subject in front of the trail effect."; ui_items = "Show Character\0Pulse Character\0Show Silhouette\0"; ui_category = "Trail Design"; > = 0;
uniform float3 fEcho_SilhouetteColor < ui_type = "color"; ui_label = "Silhouette Color"; ui_tooltip = "Color to use for the subject silhouette when 'Show Silhouette' is selected."; ui_category = "Trail Design"; > = float3(0.0, 0.0, 0.0);
uniform bool bEcho_ForceClear < ui_type = "bool"; ui_label = "Clear All Trails"; ui_tooltip = "Set this to true and toggle once to force-clear all trails."; ui_category = "Trail Design"; > = false;

// --- Trail Timing ---
uniform int iEcho_CaptureMode < ui_type = "combo"; ui_label = "Timing Method"; ui_tooltip = "Controls how frequently trail markers are created"; ui_items = "Tempo-Based\0Every N Frames\0On Audio Beat\0Manual Trigger\0"; ui_category = "Trail Timing"; > = 0;
uniform float fEcho_TimeInterval < ui_type = "slider"; ui_min = FECHO_TIMEINTERVAL_MIN; ui_max = FECHO_TIMEINTERVAL_MAX; ui_step = 25; ui_label = "Beat Interval (ms)"; ui_tooltip = "Time between trail markers in milliseconds when using Tempo-Based mode (0 = continuous)"; ui_category = "Trail Timing"; > = FECHO_TIMEINTERVAL_DEFAULT;
uniform int iEcho_FrameInterval < ui_type = "slider"; ui_min = IECHO_FRAMEINTERVAL_MIN; ui_max = IECHO_FRAMEINTERVAL_MAX; ui_step = 1; ui_label = "Frame Spacing"; ui_tooltip = "Create a trail marker every N frames when using frame-based mode"; ui_category = "Trail Timing"; > = IECHO_FRAMEINTERVAL_DEFAULT;
uniform bool bEcho_ManualCapture < ui_type = "bool"; ui_label = "Drop Trail Marker"; ui_tooltip = "Toggle this to manually create a trail marker when in Manual Trigger mode"; ui_category = "Trail Timing"; > = false;

// --- Beat Synchronization ---

AS_AUDIO_UI(Echo_TimingSource, "Rhythm Source", AS_AUDIO_BEAT, "Beat Synchronization")
AS_AUDIO_MULT_UI(Echo_TimingMult, "Beat Impact", 0.5, 1.0, "Beat Synchronization")
AS_AUDIO_UI(Echo_IntensitySource, "Energy Source", AS_AUDIO_BEAT, "Beat Synchronization")
AS_AUDIO_MULT_UI(Echo_IntensityMult, "Energy Boost", 0.5, 2.0, "Beat Synchronization")

// --- Final Composition and Debug (moved to end) ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug Mode Uniform ---
AS_DEBUG_UI("Off\0Depth Mask\0Echo Buffer\0Linear Depth\0")

// Add frame counter for frame-based capture mode
// --- Variables to track beat detection ---
uniform float TimeBeatValue < source = "listeningway"; listeningway_property = "beat"; >;

// --- Textures and Samplers ---
AS_CREATE_TEX_SAMPLER(MotionTrails_AccumBuffer, MotionTrails_AccumBufferSampler, float2(BUFFER_WIDTH, BUFFER_HEIGHT), RGBA8, 1, POINT, CLAMP)

AS_CREATE_TEX_SAMPLER(MotionTrails_AccumTempBuffer, MotionTrails_AccumTempBufferSampler, float2(BUFFER_WIDTH, BUFFER_HEIGHT), RGBA8, 1, POINT, CLAMP)

AS_CREATE_TEX_SAMPLER(MotionTrails_TimingBuffer, MotionTrails_TimingBufferSampler, float2(BUFFER_WIDTH, BUFFER_HEIGHT), RG32F, 1, POINT, CLAMP)

AS_CREATE_TEX_SAMPLER(MotionTrails_TimingPrevBuffer, MotionTrails_TimingPrevBufferSampler, float2(BUFFER_WIDTH, BUFFER_HEIGHT), RG32F, 1, POINT, CLAMP)

// --- Pixel Shader: Pass 1 (Timing and Capture State Update) ---
void PS_TimingCaptureUpdate(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float2 out_TimingCapture : SV_Target0 // Output RG float to EchoTimingBuffer
) {
    // --- Read Previous Frame's State ---
    float2 prevTimingCapture = tex2D(MotionTrails_TimingPrevBufferSampler, texcoord).rg;
    float lastCapturePhase = prevTimingCapture.r; // Phase stored at the end of the last frame
    float captureStoredLastFrame = prevTimingCapture.g; // Previous capture state
    
    // Define variables
    float currentPhase = AS_getTime() * 60.0; // Use AS_Utils' time function which already handles Listeningway fallback
    bool capture = false;
    
    // Determine if we should capture based on the selected capture mode
    switch (iEcho_CaptureMode)
    {
        case 0: // Tempo-Based Mode
            // Special case: if interval is 0, capture every frame (continuous)
            if (fEcho_TimeInterval <= 0.0) {
                capture = true;
                break;
            }
            
            // Apply audio reactivity to the interval timing
            float baseInterval = fEcho_TimeInterval;
            float audioValue = AS_DepthEcho::getAudioSource(Echo_TimingSource);
            // Shorter intervals when audio is high (faster captures)
            baseInterval = max(25.0, fEcho_TimeInterval * (1.0 - audioValue * Echo_TimingMult));
            
            float intervalInPhases = baseInterval * (60.0 / 1000.0);
            
            // Force initialization if needed
            if (lastCapturePhase < 0.001f) {
                // Initialize with a value that will immediately trigger a capture
                lastCapturePhase = currentPhase - (intervalInPhases * 2.0f);
            }

            // --- Timing Check using Previous Frame's Phase ---
            float phaseDifference = currentPhase - lastCapturePhase;
            if (lastCapturePhase > 1.0f && phaseDifference < -100.0f) {
                phaseDifference += 65536.0f;
            }
            
            // Capture if phaseDifference exceeds our interval threshold
            capture = (phaseDifference >= intervalInPhases);
            break;
            
        case 1: // Frame-Based Mode
            // Capture every N frames where N is iEcho_FrameInterval
            capture = (frameCount % iEcho_FrameInterval == 0);
            break;
            
        case 2: // On Audio Beat Mode
            // Use AS_getAudioSource for better compatibility
            float beatValue = TimeBeatValue;
            
            // Use a static variable to track the on-beat flag
            static bool onBeat = false;
            
            // If not on beat and beat is high, trigger and set flag
            if (!onBeat && beatValue >= 0.9) {
                capture = true;
                onBeat = true;
            }
            // If on beat and beat drops below threshold, unset flag
            else if (onBeat && beatValue < 0.7) {
                onBeat = false;
            }
            break;
            
        case 3: // Manual Trigger Mode
            // Capture only when manually triggered
            capture = bEcho_ManualCapture;
            break;
    }

    // --- Determine values to store for *next* frame ---
    float phaseToStore = capture ? currentPhase : lastCapturePhase;
    float captureStateToStore = capture ? 1.0 : 0.0; // Store raw capture state (0 or 1)

    // --- Write Output ---
    out_TimingCapture = float2(phaseToStore, captureStateToStore);
}

// --- Pixel Shader: Pass 2 (Accumulation Update) ---
void PS_EchoAccum(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float4 out_Accum : SV_Target0 // Output RGBA8 to EchoAccumTempBuffer
) {
    // Check if we should force-clear the buffer
    if (bEcho_ForceClear) {
        // If force clear is active, reset everything to black
        out_Accum = float4(0.0, 0.0, 0.0, 0.0);
        return;
    }
      // --- Read Previous State from main buffer ---
    float4 prevAccum = tex2D(MotionTrails_AccumBufferSampler, texcoord);
    // Read the capture state calculated and stored in Pass 1 of *this* frame.
    float captureState = tex2D(MotionTrails_TimingBufferSampler, texcoord).g; // Read Green channel

    // --- Calculate Current Mask ---
    float linearDepth = ReShade::GetLinearizedDepth(texcoord);
    float currMask = step(linearDepth, fEcho_DepthCutoff);

    // --- Determine capture based on the state from timing pass ---
    bool capture = (captureState > 0.5);
    
    // --- Apply audio reactivity to echo strength ---
    float effectiveStrength = fEcho_Strength;
    float audioValue = AS_DepthEcho::getAudioSource(Echo_IntensitySource);
    effectiveStrength *= (1.0 + audioValue * Echo_IntensityMult);

    // --- Accumulation Logic ---
    float4 fadedAccum = prevAccum * fEcho_FadeRate;
    float4 newEcho = float4(fEcho_Color * currMask * effectiveStrength, currMask * effectiveStrength);
    float4 finalAccum = fadedAccum + (capture ? newEcho : 0.0);

    out_Accum = saturate(finalAccum);
}

// --- Pixel Shader: Pass 3 (Copy Back) ---
void PS_CopyBackAccum(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float4 out_Accum : SV_Target0 // Output RGBA8 to EchoAccumBuffer
) {    // Simply copy from temp buffer back to main buffer
    out_Accum = tex2D(MotionTrails_AccumTempBufferSampler, texcoord);
}

// --- Pixel Shader: Pass 4 (Compositing) ---
void PS_EchoComposite(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float4 out_Color : SV_Target0
) {    // Read necessary buffers
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float4 echoColor = tex2D(MotionTrails_AccumBufferSampler, texcoord);

    // --- Create the base echo effect ---
    float3 echoEffect = echoColor.rgb;
    
    // --- Apply blend mode using AS_Utils helper ---
    float3 blendedResult = AS_applyBlend(echoEffect, originalColor.rgb, BlendMode);
    
    // --- Final blend with original using user-defined strength ---
    float3 finalResult = lerp(originalColor.rgb, blendedResult, BlendAmount * echoColor.a);

    // --- Debug Modes ---
    if (DebugMode > 0)
    {
        float linearDepth = ReShade::GetLinearizedDepth(texcoord);
        float currMask = step(linearDepth, fEcho_DepthCutoff);

        // Simplified debug options
        if (DebugMode == 1) { finalResult = currMask.xxx; }
        else if (DebugMode == 2) { finalResult = echoColor.rgb; }
        else if (DebugMode == 3) { finalResult = linearDepth.xxx; }
    }

    // --- Subject Overlay Modes ---
    float linearDepth = ReShade::GetLinearizedDepth(texcoord);
    float currMask = step(linearDepth, fEcho_DepthCutoff);
    if (iEcho_SubjectOverlay == 0) {
        // Show Character: overlay the original color where masked
        finalResult = lerp(finalResult, originalColor.rgb, currMask);
    } else if (iEcho_SubjectOverlay == 1) {
        // Pulse Character: do nothing, just show the effect
        // (No overlay)
    } else if (iEcho_SubjectOverlay == 2) {
        // Show Silhouette: overlay the selected color where masked
        finalResult = lerp(finalResult, fEcho_SilhouetteColor, currMask);
    }

    out_Color = float4(saturate(finalResult), originalColor.a);
}

// --- Pixel Shader: Pass 5 (Copy Timing Buffer) ---
void PS_CopyTimingBuffer(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float2 out_TimingCapture : SV_Target0 // Output RG float to EchoTimingPrevBuffer
) {    // Simply copy the current frame's timing data to the previous frame buffer
    out_TimingCapture = tex2D(MotionTrails_TimingBufferSampler, texcoord).rg;
}

// --- Technique ---
technique AS_MotionTrails_1 <
    ui_label = "[AS] VFX: Motion Trails";
    ui_tooltip = "Creates dynamic motion trails perfect for music videos and creative compositions.";
>
{    pass TimingCapturePass {
        VertexShader = PostProcessVS;
        PixelShader = PS_TimingCaptureUpdate;
        RenderTarget0 = MotionTrails_TimingBuffer;
        ClearRenderTargets = false;
    }
    pass AccumPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_EchoAccum;
        RenderTarget0 = MotionTrails_AccumTempBuffer;
        ClearRenderTargets = false;
    }
    pass CopyBackPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyBackAccum;
        RenderTarget0 = MotionTrails_AccumBuffer;
        ClearRenderTargets = false;
    }
    pass CompositePass {
        VertexShader = PostProcessVS;
        PixelShader = PS_EchoComposite;
    }
    pass CopyTimingBufferPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyTimingBuffer;
        RenderTarget0 = MotionTrails_TimingPrevBuffer;
        ClearRenderTargets = false;
    }
}

#endif // __AS_VFX_MotionTrails_1_fx

