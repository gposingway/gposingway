uniform float aspect_ratio <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_label="Aspect Ratio";
    ui_min = -100.0;
    ui_max = 100.0;
> = 0;
