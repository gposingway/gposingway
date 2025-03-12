#include "Include/RadegastShaders.Depth.fxh"
#include "Include/RadegastShaders.Positional.fxh"
#include "Include/RadegastShaders.Radial.fxh"
#include "Include/RadegastShaders.AspectRatio.fxh"
#include "Include/RadegastShaders.Offsets.fxh"
#include "Include/RadegastShaders.Transforms.fxh"
#include "Include/RadegastShaders.BlendingModes.fxh"

uniform float magnitude <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_label = "Magnitude";
    ui_min = -1.0; 
    ui_max = 1.0;
    ui_tooltip = "The magnitude of the distortion. Positive values cause the image to bulge out. Negative values cause the image to pinch in.";    
    ui_category = "Properties";
> = -0.5;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Animates the effect.";
    ui_category = "Properties";
> = 0;

uniform float anim_rate <
    source = "timer";
>;
