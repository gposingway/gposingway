uniform bool use_mouse_point <
    ui_label="Use Mouse Coordinates";
    ui_category="Coordinates";
> = false;

uniform float x_coord <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_label="X";
    ui_category="Coordinates";
    ui_tooltip="The X position of the center of the effect.";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;

uniform float y_coord <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_label="Y";
    ui_category="Coordinates";
    ui_tooltip="The Y position of the center of the effect.";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;

uniform float2 mouse_coordinates < 
source= "mousepoint";
>;
