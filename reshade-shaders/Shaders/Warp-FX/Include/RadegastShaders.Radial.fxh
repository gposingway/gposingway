uniform float radius <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_label="Radius";
    ui_category="Bounds";
    ui_tooltip="Controls the size of the distortion.";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float tension <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_label = "Tension";
    ui_category="Bounds";
    ui_tooltip="Controls how rapidly the effect reaches its maximum distortion.";
    ui_min = 0.; ui_max = 10.; ui_step = 0.001;
> = 1.0;
