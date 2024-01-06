uniform bool use_offset_coords <
    ui_label = "Use Offset Coordinates";
    ui_tooltip = "Display the distortion in any location besides its original coordinates.";
    ui_category = "Offset";
> = 0;

uniform float offset_x <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else 
        ui_type = "slider";
    #endif
    ui_label = "X";
    ui_category = "Offset";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;


uniform float offset_y <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_label = "Y";
    ui_category = "Offset";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;
