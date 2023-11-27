////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                                  ///
///  .d8888b.  888    888        d8888 8888888b.  8888888888 8888888b.  8888888b.  8888888888  .d8888b.  888    d8P  ///
/// d88P  Y88b 888    888       d88888 888  "Y88b 888        888   Y88b 888  "Y88b 888        d88P  Y88b 888   d8P   ///
/// Y88b.      888    888      d88P888 888    888 888        888    888 888    888 888        888    888 888  d8P    ///
///  "Y888b.   8888888888     d88P 888 888    888 8888888    888   d88P 888    888 8888888    888        888d88K     ///
///     "Y88b. 888    888    d88P  888 888    888 888        8888888P"  888    888 888        888        8888888b    ///
///       "888 888    888   d88P   888 888    888 888        888 T88b   888    888 888        888    888 888  Y88b   ///
/// Y88b  d88P 888    888  d8888888888 888  .d88P 888        888  T88b  888  .d88P 888        Y88b  d88P 888   Y88b  ///
///  "Y8888P"  888    888 d88P     888 8888888P"  8888888888 888   T88b 8888888P"  8888888888  "Y8888P"  888    Y88b ///
///                                                                                                                  ///
///    <> BY TREYM                                                                                                   ///
///                                                                                                                  ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// API ////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
// Usage: #if(API == D3D9)
#define API  __RENDERER__
#define D3D9   0
#define D3D10  0
#define D3D11  0
#define D3D12  0
#define OpenGL 0
#define Vulkan 0

#if   ((API >= 0x9000)  && (API < 0xA000))
    #undef  D3D9
    #define D3D9 API
#elif ((API >= 0xA000)  && (API < 0xB000))
    #undef  D3D10
    #define D3D10 API
#elif ((API >= 0xB000)  && (API < 0xC000))
    #undef  D3D11
    #define D3D11 API
#elif ((API >= 0xC000)  && (API < 0xD000))
    #undef  D3D12
    #define D3D12 API
#elif ((API >= 0x10000) && (API < 0x20000))
    #undef  OpenGL
    #define OpenGL API
#elif ((API >= 0x20000) && (API < 0x30000))
    #undef  Vulkan
    #define Vulkan API
#endif


// APPLICATION ////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#define   App __APPLICATION__


// GPU VENDOR /////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
// Usage: #if(GPU == Nvidia)
#define GPU  __VENDOR__
#define AMD    0
#define Intel  0
#define Nvidia 0x10DE

#if   ((GPU == 0x1002) || (GPU == 0x1022))
    #undef  AMD
    #define AMD   GPU
#elif ((GPU == 0x163C) || (GPU == 0x8086) || (GPU == (0x8087)))
    #undef  Intel
    #define Intel GPU
#endif


// BACKBUFFER IMAGE FORMAT ////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#if (BUFFER_COLOR_BIT_DEPTH > 8)
    #define BUFFER_FORMAT RGB10A2
#else
    #define BUFFER_FORMAT RGBA8
#endif


// SAMPLER MACROS //////////////////////
#define SAMPLER(sname, tname) \
            sampler sname \
            { \
                Texture = tname; \
            };

#define SAMPLER_UV(sname, tname, uv) \
            sampler sname \
            { \
                Texture  = tname; \
                AddressU = uv; \
                AddressV = uv; \
                AddressW = uv; \
            };

#define SAMPLER_LIN(sname, tname, uv) \
            sampler sname \
            { \
                Texture     = tname; \
                AddressU    = uv; \
                AddressV    = uv; \
                AddressW    = uv; \
                SRGBTexture = true; \
            };

// TEXTURE MACROS //////////////////////
#define TEXTURE(tname) \
            texture tname \
            {  \
                Width  = BUFFER_WIDTH; \
                Height = BUFFER_HEIGHT; \
                Format = RGBA8; \
            };

#define TEXTURE_FULL(tname, width, height, format) \
            texture tname \
            { \
                Width  = width; \
                Height = height; \
                Format = format; \
            };

#define TEXTURE_SRC(tname, src) \
            texture tname < source = src; > \
            { \
                Width  = BUFFER_WIDTH; \
                Height = BUFFER_HEIGHT; \
                Format = RGBA8; \
            };

#define TEXTURE_FULL_SRC(tname, src, width, height, format) \
            texture tname < source = src; > \
            { \
                Width  = width; \
                Height = height; \
                Format = format; \
            };

// TECHNIQUE AND PASS MACROS ///////////
#define PASS(vs, ps) \
            pass \
            { \
                VertexShader  = vs; \
                PixelShader   = ps; \
            }

#define PASS_SRGB(vs, ps) \
            pass \
            { \
                VertexShader    = vs; \
                PixelShader     = ps; \
                SRGBWriteEnable = true; \
            }

#define PASS_SRGB_RT(vs, ps, rt) \
            pass \
            { \
                VertexShader    = vs; \
                PixelShader     = ps; \
                SRGBWriteEnable = true; \
                RenderTarget    = rt; \
            }

#define PASS_RT(vs, ps, rt) \
            pass \
            { \
                VertexShader  = vs; \
                PixelShader   = ps; \
                RenderTarget  = rt; \
            }

#define PASS_RT2(vs, ps, rt0, rt1) \
            pass \
            { \
                VertexShader  = vs; \
                PixelShader   = ps; \
                RenderTarget0 = rt0; \
                RenderTarget1 = rt1; \
            }

#define PASS_RT3(vs, ps, rt0, rt1, rt2) \
            pass \
            { \
                VertexShader  = vs; \
                PixelShader   = ps; \
                RenderTarget0 = rt0; \
                RenderTarget1 = rt1; \
                RenderTarget2 = rt2; \
            }

#define PASS_RT4(vs, ps, rt0, rt1, rt2, rt3) \
            pass \
            { \
                VertexShader  = vs; \
                PixelShader   = ps; \
                RenderTarget0 = rt0; \
                RenderTarget1 = rt1; \
                RenderTarget2 = rt2; \
                RenderTarget2 = rt3; \
            }

#define PASS_RT5(vs, ps, rt0, rt1, rt2, rt3, rt4) \
            pass \
            { \
                VertexShader  = vs; \
                PixelShader   = ps; \
                RenderTarget0 = rt0; \
                RenderTarget1 = rt1; \
                RenderTarget2 = rt2; \
                RenderTarget2 = rt3; \
                RenderTarget2 = rt4; \
            }

#define TECHNIQUE(name, label, tooltip, pass) \
            technique name < ui_label = label; ui_tooltip = tooltip; > \
            { \
                pass \
            }

#define TECH_FULL(name, annotations, pass) \
            technique name annotations \
            { \
                pass \
            }

#define TECH_PASS(name, label, tooltip, vs, ps) \
            technique name < ui_label = label; ui_tooltip = tooltip; > \
            { \
                PASS(vs, ps) \
            }

// SCALE MACRO /////////////////////////
#define SCALE(coord, scale) \
            (coord - 0.5) / scale + 0.5

#define SCALE_POS(coord, scale, pos) \
            (coord - pos) / scale + pos

// GET LUMA MACRO //////////////////////
// Rec.709_5
#define GetLuma(x) dot(x, float3(0.212395, 0.701049, 0.086556))
#define GetAvg(x) dot(x, 0.3333)


// UI MACROS //////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

// UNIFORM TEMPLATE ////////////////////
#define UI_UNIFORM(variable, name, annotations, defval) uniform variable name < annotations > = defval;


// ANNOTATIONS /////////////////////////
#define UI_SPACING(x)  ui_spacing         =  x;
#define UI_TYPE(x)     ui_type            = #x;
#define UI_LABEL(x)    ui_label           =  " "##x;
#define UI_TOOLTIP(x)  ui_tooltip         =  x;
#define UI_ITEMS(x)    ui_items           =  x;
#define UI_MIN(x)      ui_min             =  x;
#define UI_MAX(x)      ui_max             =  x;
#define UI_STEP(x)     ui_step            =  x;
#define UI_CLOSED(x)   ui_category_closed =  x;
#define UI_TEXT(x)     ui_text            =  x;


// CATEGORY SETUP //////////////////////
#ifdef CATEGORIZE
    #define UI_CATEGORY(x) ui_category = "\n"##x##"\n\n";
#else
    #define UI_CATEGORY(x) ui_category = "";
#endif

// MESSAGE /////////////////////////////
#define UI_MSG(name, spacing, text)    \
            UI_UNIFORM(int, _##name,   \
                UI_TYPE     (radio)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (" ")      \
                UI_TEXT     (text),    \
                             0)

#define UICL_MSG(name, spacing, text)  \
            UI_UNIFORM(int, _##name,   \
                UI_TYPE     (radio)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (" ")      \
                UI_TEXT     (text),    \
                             0)


// FOOTER //////////////////////////////
#define UI_FOOTER(name)    \
            UI_MSG(name, 0, " ")

#define UICL_FOOTER(name)  \
            UICL_MSG(name, 0, " ")

// BOOL ////////////////////////////////
#define UI_BOOL(name, label, tooltip, defval, spacing) \
            UI_UNIFORM(bool, name,     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                             defval)

#define UICL_BOOL(name, label, tooltip, defval, spacing) \
            UI_UNIFORM(bool, name,     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                             defval)


// COMBO ///////////////////////////////
#define UI_COMBO(name, label, tooltip, defval, spacing, items) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (combo)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_ITEMS    (items)    \
                UI_TOOLTIP  (tooltip), \
                             defval)

#define UICL_COMBO(name, label, tooltip, defval, spacing, items) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (combo)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_ITEMS    (items)    \
                UI_TOOLTIP  (tooltip), \
                             defval)


// COMBO STYLE BOOL ////////////////////
#define UI_COMBOOL(name, label, tooltip, defval, spacing) \
            UI_COMBO (name, label, tooltip, defval, spacing, "Disabled\0Enabled\0")

#define UICL_COMBOOL(name, label, tooltip, defval, spacing) \
            UICL_COMBO (name, label, tooltip, defval, spacing, "Disabled\0Enabled\0")


// RADIO ///////////////////////////////
#define UI_RADIO(name, label, defval, tooltip, spacing, items) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (radio)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_ITEMS    (items)    \
                UI_TOOLTIP  (tooltip), \
                             defval)

#define UICL_RADIO(name, label, defval, tooltip, spacing, items) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (radio)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_ITEMS    (items)    \
                UI_TOOLTIP  (tooltip), \
                             defval)


// INT /////////////////////////////////
#define UI_INT_I(name, label, tooltip, defval, spacing) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (input)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                            defval)

#define UICL_INT_I(name, label, tooltip, defval, spacing) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (input)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                             defval)

#define UI_INT_D(name, label, tooltip, minval, maxval, defval, spacing) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (drag)     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                             defval)

#define UICL_INT_D(name, label, tooltip, minval, maxval, defval, spacing) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (drag)     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                             defval)

#define UI_INT_S(name, label, tooltip, minval, maxval, defval, spacing) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (slider)   \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                             defval)

#define UICL_INT_S(name, label, tooltip, minval, maxval, defval, spacing) \
            UI_UNIFORM(int,  name,     \
                UI_TYPE     (slider)   \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                             defval)


// INT2 ////////////////////////////////
#define UI_INT2_I(name, label, tooltip, minval, maxval, defval1, defval2, spacing) \
            UI_UNIFORM(int2,  name,    \
                UI_TYPE     (input)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                       int2(defval1, defval2))

#define UICL_INT2_I(name, label, tooltip, minval, maxval, defval1, defval2, spacing) \
            UI_UNIFORM(int2,  name,    \
                UI_TYPE     (input)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                        int2(defval1, defval2))

#define UI_INT2_D(name, label, tooltip, minval, maxval, defval1, defval2, spacing) \
            UI_UNIFORM(int2,  name,    \
                UI_TYPE     (drag)     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int2(defval1, defval2))

#define UICL_INT2_D(name, label, tooltip, minval, maxval, defval1, defval2, spacing) \
            UI_UNIFORM(int2,  name,    \
                UI_TYPE     (drag)     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int2(defval1, defval2))

#define UI_INT2_S(name, label, tooltip, minval, maxval, defval1, defval2, spacing) \
            UI_UNIFORM(int2,  name,    \
                UI_TYPE     (slider)   \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int2(defval1, defval2))

#define UICL_INT2_S(name, label, tooltip, minval, maxval, defval1, defval2, spacing) \
            UI_UNIFORM(int2,  name,    \
                UI_TYPE     (slider)   \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int2(defval1, defval2))


// INT3 ////////////////////////////////
#define UI_INT3_I(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(int3,  name,    \
                UI_TYPE     (input)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                        int3(defval1, defval2, defval3))

#define UICL_INT3_I(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(int3,  name,    \
                UI_TYPE     (input)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                        int3(defval1, defval2, defval3))

#define UI_INT3_D(name, label, tooltip, minval, maxval, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(int3,  name,    \
                UI_TYPE     (drag)     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int3(defval1, defval2, defval3))

#define UICL_INT3_D(name, label, tooltip, minval, maxval, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(int3,  name,    \
                UI_TYPE     (drag)     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int3(defval1, defval2, defval3))

#define UI_INT3_S(name, label, tooltip, minval, maxval, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(int3,  name,    \
                UI_TYPE     (slider)   \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int3(defval1, defval2, defval3))

#define UICL_INT3_S(name, label, tooltip, minval, maxval, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(int3,  name,    \
                UI_TYPE     (slider)   \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int3(defval1, defval2, defval3))


// INT4 ////////////////////////////////
#define UI_INT4_I(name, label, tooltip, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(int4,  name,    \
                UI_TYPE     (input)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                        int4(defval1, defval2, defval3, defval4))

#define UICL_INT4_I(name, label, tooltip, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(int4,  name,    \
                UI_TYPE     (input)    \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip), \
                        int4(defval1, defval2, defval3, defval4))

#define UI_INT4_D(name, label, tooltip, minval, maxval, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(int4,  name,    \
                UI_TYPE     (drag)     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int4(defval1, defval2, defval3, defval4))

#define UICL_INT4_D(name, label, tooltip, minval, maxval, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(int4,  name,    \
                UI_TYPE     (drag)     \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int4(defval1, defval2, defval3, defval4))

#define UI_INT4_S(name, label, tooltip, minval, maxval, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(int4,  name,    \
                UI_TYPE     (slider)   \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int4(defval1, defval2, defval3, defval4))

#define UICL_INT4_S(name, label, tooltip, minval, maxval, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(int4,  name,    \
                UI_TYPE     (slider)   \
                UI_SPACING  (spacing)  \
                UI_CATEGORY (CATEGORY) \
                UI_CLOSED   (true)     \
                UI_LABEL    (label)    \
                UI_TOOLTIP  (tooltip)  \
                UI_MIN      (minval)   \
                UI_MAX      (maxval),  \
                        int4(defval1, defval2, defval3, defval4))


// FLOAT ///////////////////////////////
#define UI_FLOAT_I(name, label, tooltip, defval, spacing) \
            UI_UNIFORM(float, name,     \
                UI_TYPE      (input)    \
                UI_SPACING   (spacing)  \
                UI_CATEGORY  (CATEGORY) \
                UI_LABEL     (label)    \
                UI_TOOLTIP   (tooltip), \
                              defval)

#define UICL_FLOAT_I(name, label, tooltip, defval, spacing) \
            UI_UNIFORM(float, name,     \
                UI_TYPE      (input)    \
                UI_SPACING   (spacing)  \
                UI_CATEGORY  (CATEGORY) \
                UI_CLOSED    (true)     \
                UI_LABEL     (label)    \
                UI_TOOLTIP   (tooltip), \
                              defval)

#define UI_FLOAT_D(name, label, tooltip, minval, maxval, defval, spacing) \
            UI_UNIFORM(float, name,     \
                UI_TYPE      (drag)     \
                UI_SPACING   (spacing)  \
                UI_CATEGORY  (CATEGORY) \
                UI_LABEL     (label)    \
                UI_TOOLTIP   (tooltip)  \
                UI_MIN       (minval)   \
                UI_MAX       (maxval),  \
                              defval)

#define UICL_FLOAT_D(name, label, tooltip, minval, maxval, defval, spacing) \
            UI_UNIFORM(float, name,     \
                UI_TYPE      (drag)     \
                UI_SPACING   (spacing)  \
                UI_CATEGORY  (CATEGORY) \
                UI_CLOSED    (true)     \
                UI_LABEL     (label)    \
                UI_TOOLTIP   (tooltip)  \
                UI_MIN       (minval)   \
                UI_MAX       (maxval),  \
                              defval)

#define UI_FLOAT_S(name, label, tooltip, minval, maxval, defval, spacing) \
            UI_UNIFORM(float, name,     \
                UI_TYPE      (slider)   \
                UI_SPACING   (spacing)  \
                UI_CATEGORY  (CATEGORY) \
                UI_LABEL     (label)    \
                UI_TOOLTIP   (tooltip)  \
                UI_MIN       (minval)   \
                UI_MAX       (maxval),  \
                              defval)

#define UICL_FLOAT_S(name, label, tooltip, minval, maxval, defval, spacing) \
            UI_UNIFORM(float, name,     \
                UI_TYPE      (slider)   \
                UI_SPACING   (spacing)  \
                UI_CATEGORY  (CATEGORY) \
                UI_CLOSED    (true)     \
                UI_LABEL     (label)    \
                UI_TOOLTIP   (tooltip)  \
                UI_MIN       (minval)   \
                UI_MAX       (maxval),  \
                              defval)


// FLOAT2 //////////////////////////////
#define UI_FLOAT2_I(name, label, tooltip, defval1, defval2, spacing) \
            UI_UNIFORM(float2, name,     \
                UI_TYPE       (input)    \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float2(defval1, defval2))

#define UICL_FLOAT2_I(name, label, tooltip, defval1, defval2, spacing) \
            UI_UNIFORM(float2, name,     \
                UI_TYPE       (input)    \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float2(defval1, defval2))

#define UI_FLOAT2_D(name, label, tooltip, defval1, defval2, spacing) \
            UI_UNIFORM(float2, name,     \
                UI_TYPE       (drag)     \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float2(defval1, defval2))

#define UICL_FLOAT2_D(name, label, tooltip, defval1, defval2, spacing) \
            UI_UNIFORM(float2, name,     \
                UI_TYPE       (drag)     \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float2(defval1, defval2))

#define UI_FLOAT2_S(name, label, tooltip, minval, maxval, defval1, defval2, spacing) \
            UI_UNIFORM(float2, name,     \
                UI_TYPE       (slider)   \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float2(defval1, defval2))

#define UICL_FLOAT2_S(name, label, tooltip, minval, maxval, defval1, defval2, spacing) \
            UI_UNIFORM(float2, name,     \
                UI_TYPE       (slider)   \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float2(defval1, defval2))


// FLOAT3 //////////////////////////////
#define UI_FLOAT3_I(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(float3, name,     \
                UI_TYPE       (input)    \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float3(defval1, defval2, defval3))

#define UICL_FLOAT3_I(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(float3, name,     \
                UI_TYPE       (input)    \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float3(defval1, defval2, defval3))

#define UI_FLOAT3_D(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(float3, name,     \
                UI_TYPE       (drag)     \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float3(defval1, defval2, defval3))

#define UICL_FLOAT3_D(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(float3, name,     \
                UI_TYPE       (drag)     \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float3(defval1, defval2, defval3))

#define UI_FLOAT3_S(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(float3, name,     \
                UI_TYPE       (slider)   \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float3(defval1, defval2, defval3))

#define UICL_FLOAT3_S(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(float3, name,     \
                UI_TYPE       (slider)   \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float3(defval1, defval2, defval3))


// FLOAT4 //////////////////////////////
#define UI_FLOAT4_I(name, label, tooltip, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(float4, name,     \
                UI_TYPE       (input)    \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float4(defval1, defval2, defval3, defval4))

#define UICL_FLOAT4_I(name, label, tooltip, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(float4, name,     \
                UI_TYPE       (input)    \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float4(defval1, defval2, defval3, defval4))

#define UI_FLOAT4_D(name, label, tooltip, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(float4, name,     \
                UI_TYPE       (drag)     \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float4(defval1, defval2, defval3, defval4))

#define UICL_FLOAT4_D(name, label, tooltip, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(float4, name,     \
                UI_TYPE       (drag)     \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float4(defval1, defval2, defval3, defval4))

#define UI_FLOAT4_S(name, label, tooltip, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(float4, name,     \
                UI_TYPE       (slider)   \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float4(defval1, defval2, defval3, defval4))

#define UICL_FLOAT4_S(name, label, tooltip, defval1, defval2, defval3, defval4, spacing) \
            UI_UNIFORM(float4, name,     \
                UI_TYPE       (slider)   \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip)  \
                UI_MIN        (minval)   \
                UI_MAX        (maxval),  \
                        float4(defval1, defval2, defval3, defval4))


// COLOR WIDGET (FLOAT3) ///////////////
#define UI_COLOR(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(float3, name,     \
                UI_TYPE       (color)    \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float3(defval1, defval2, defval3))

#define UICL_COLOR(name, label, tooltip, defval1, defval2, defval3, spacing) \
            UI_UNIFORM(float3, name,     \
                UI_TYPE       (color)    \
                UI_SPACING    (spacing)  \
                UI_CATEGORY   (CATEGORY) \
                UI_CLOSED     (true)     \
                UI_LABEL      (label)    \
                UI_TOOLTIP    (tooltip), \
                        float3(defval1, defval2, defval3))

#ifdef CATEGORY
    #undef CATEGORY
#endif

// TEXTURE AND SAMPLER MACROS /////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#define RENDERTARGET(t, size_x, size_y, format, uv) \
    texture RT_##t     { Width   = size_x; Height = size_y; Format = format; }; \
    sampler Texture##t { Texture = RT_##t; AddressU = uv; AddressV = uv; AddressW = uv;};


// SHADER MACROS //////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#define PS_IN(v, c) float4 v : SV_Position, float2 c : TEXCOORD

#define VOID(name, rt) \
    void PS_##name##(PS_IN(vpos, uv), out rt  : SV_Target)

#define VOID2(name, rt0, rt1) \
    void PS_##name##(PS_IN(vpos, uv), out rt0 : SV_Target0, \
                                      out rt1 : SV_Target1)
#define VOID3(name, rt0, rt1, rt2) \
    void PS_##name##(PS_IN(vpos, uv), out rt0 : SV_Target0, \
                                      out rt1 : SV_Target1, \
                                      out rt2 : SV_Target2)