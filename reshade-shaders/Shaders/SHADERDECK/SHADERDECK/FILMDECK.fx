///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                             ///
///    8888888888 8888888 888      888b     d888 8888888b.  8888888888  .d8888b.  888    d8P    ///
///    888          888   888      8888b   d8888 888  "Y88b 888        d88P  Y88b 888   d8P     ///
///    888          888   888      88888b.d88888 888    888 888        888    888 888  d8P      ///
///    8888888      888   888      888Y88888P888 888    888 8888888    888        888d88K       ///
///    888          888   888      888 Y888P 888 888    888 888        888        8888888b      ///
///    888          888   888      888  Y8P  888 888    888 888        888    888 888  Y88b     ///
///    888          888   888      888   "   888 888  .d88P 888        Y88b  d88P 888   Y88b    ///
///    888        8888888 88888888 888       888 8888888P"  8888888888  "Y8888P"  888    Y88b   ///
///                                                                                             ///
///    FILM EMULATION SUITE FOR RESHADE                                                         ///
///    <> BY TREYM                                                                              ///
///                                                                                             ///
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

/*  ///////////////////////////////////////////////////////////////////////////////////////////  **
**  ///////////////////////////////////////////////////////////////////////////////////////////  **

    DO NOT REDISTRIBUTE WITHOUT PERMISION!
    
    Welcome to FILMDECK, the spiritual successor to Film Workshop!

**  ///////////////////////////////////////////////////////////////////////////////////////////  **
**  ///////////////////////////////////////////////////////////////////////////////////////////  */


// FILE SETUP /////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#define   CATEGORIZE
#include "ReShade.fxh"
#include "SHADERDECK/Lib/Common.fxh"
#include "SHADERDECK/FILMDECK/Setup.fxh"


// USER INTERFACE /////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

#define CATEGORY "INTRODUCTION" /////////////////
/////////////////////////////////////////////////
UICL_MSG      (TUT1, 0,
"   Welcome to FILMDECK!\n\n"

"     FILMDECK was created to help people achieve cinematic color\n"
"   quickly and easily. This is done by emulating one of the color\n"
"   grading workflows used by colorists working in the film industry.\n\n"

"     When a movie is shot on actual film, there are multiple steps\n"
"   in achieving the final look. Initially, the negative captured in\n"
"   the camera must be scanned digitally for manipulation in a tool\n"
"   like Davinci Resolve.\n\n"

"     Once scanned, the film footage is similar to any other high-end\n"
"   digital cinema camera footage and can be graded in the same manner.\n"
"   Often color grading is done with a Film Print LUT at the end of the\n"
"   grading chain so that the colorist can get an idea of how their work\n"
"   will appear in the final result. These LUTs are often provided by\n"
"   the lab that will be creating the final film print.\n\n"

"     If the footage is going to be 'printed', the print emulation LUT\n"
"   is removed once the grading is complete and the digital file is sent\n"
"   to be 'printed' on a Film Print stock, such as Kodak 2383.\n\n"

"     For the purposes of FILMDECK, since we are entirely in the digital\n"
"   domain, we will be emulating the color reponse of both the negative\n"
"   and print stages, as well as the color grading stage which occurs in\n"
"   the middle. The beauty of this workflow is the volume of variations\n"
"   you can achieve by simply mixing and matching various negative and\n"
"   print combinations.\n\n"

"   Internal render order:\n"
"       Film Halation\n"
"       Film Negative\n"
"       Color Grade\n"
"       Film Print\n\n"

"   How to use:\n"
"       Select a film negative, select a film print, then adjust\n"
"       your color grade.\n\n\n"

"   Happy grading,\n"
"   TreyM")
#undef CATEGORY /////////////////////////////////
/////////////////////////////////////////////////


#define CATEGORY "FILM SETUP" ////////////////////
//////////////////////////////////////////////////
#if (CUSTOM_PRESET_ENABLED == 0)
UICL_COMBO    (FILM_NEGATIVE, "Negative",       "",  NEGATIVE_DEFAULT, 0,
                  NEGATIVE_LIST)
UICL_COMBO    (FILM_FORMATN, "Negative Format", "", 1, 0,
                    "16mm\0"
                    "Super 35\0"
                    "35mm Full Frame\0")
UICL_INT_S    (GRAIN_N,       "Negative Grain", "", 0, 100, 50, 0)
UICL_FLOAT_S  (NEG_EXP,       "Negative Exposure",    "", -4.0, 4.0,   0.0,   0)
UICL_INT_S    (N_TEMP,        "Negative Color Temperature", "", -100, 100, 0, 0)
UICL_COMBOOL  (AUTO_TEMP,     "Use Film Negative Whitebalance", "", 0, 0)
UICL_MSG      (WBMASG, 0,
" This will force FILMDECK to white balance\n"
" the image as it goes into the Negative profile\n"
" according to the real world white balance\n"
" of your selected film negative.")

UICL_COMBO    (FILM_PRINT, "Print",     "",  PRINT_DEFAULT, 0,
                  PRINT_LIST)
UICL_COMBO    (FILM_FORMATP, "Print Format", "", 2, 0,
                   "16mm\0"
                   "Super 35\0"
                   "35mm Full Frame\0")
UICL_INT_S    (GRAIN_P,       "Print Grain", "", 0, 100, 50, 0)
UICL_FLOAT_S  (PRT_EXP,       "Print Exposure",       "", -4.0, 4.0,   0.0,   0)
UICL_INT_S    (P_TEMP,        "Print Color Temperature", "", -100, 100, 0, 0)
#ifdef __PATREON_NAG
    UICL_MSG      (PATREON2,       0, __PATREON_NAG)
#endif
#else
UICL_COMBO    (FILM_NEGATIVE, "Negative",     "",  NEGATIVE_DEFAULT, 0,
                  CUSTOM_LIST_N)
UICL_COMBO    (FILM_FORMATN, "Negative Format", "", 1, 0,
                   "16mm\0"
                   "Super 35\0"
                   "35mm Full Frame\0")
UICL_INT_S    (GRAIN_N,       "Negative Grain", "", 0, 100, 50, 0)
UICL_FLOAT_S  (NEG_EXP,       "Negative Exposure",    "", -4.0, 4.0,   0.0,   0)
UICL_INT_S    (N_TEMP,        "Negative Color Temperature", "", -100, 100, 0, 0)
UICL_COMBOOL  (AUTO_TEMP,     "Use Film Negative Whitebalance", "", 1, 0)
UICL_MSG      (WBMASG, 0,
" This will force FILMDECK to white balance\n"
" the image as it goes into the Negative profile\n"
" according to the real world white balance\n"
" of your selected film negative.")

UICL_COMBO    (FILM_PRINT, "Print",     "",  PRINT_DEFAULT, 0,
                  CUSTOM_LIST_P)
UICL_COMBO    (FILM_FORMATP, "Print Format", "", 2, 0,
                   "16mm\0"
                   "Super 35\0"
                   "35mm Full Frame\0")
UICL_INT_S    (GRAIN_P,       "Print Grain", "", 0, 100, 50, 0)
UICL_FLOAT_S  (PRT_EXP,       "Print Exposure",       "", -4.0, 4.0,   0.0,   0)
UICL_INT_S    (P_TEMP,        "Print Color Temperature", "", -100, 100, 0, 0)
#ifdef __PATREON_NAG
    UICL_MSG      (PATREON2,       0, __PATREON_NAG)
#endif
#endif


#undef CATEGORY /////////////////////////////////
/////////////////////////////////////////////////


#define CATEGORY "GRADE" ////////////////////////
/////////////////////////////////////////////////
UICL_INT_S    (ENABLE_GRADE, "Quick Toggle",    "",    0,   1,   1, 0)

UICL_INT_S    (SATURATION,   "Saturation",      "",    0, 200, 100, 5)

UICL_COLOR    (GAIN,         "Highlights",      "",  0.5, 0.5, 0.5, 5)
UICL_COLOR    (GAMMA,        "Midtones",        "",  0.5, 0.5, 0.5, 0)
UICL_COLOR    (LIFT,         "Shadows",         "",  0.5, 0.5, 0.5, 0)

#define HSL_TOOLTIP \
"Be careful. Do not to push too far!\n" \
"You can only shift as far as the next\n" \
"or previous hue's current value.\n\n" \
"Editing is easiest using the widget\n" \
"Click the colored box to open it."
UICL_COLOR    (GREYS,        "Grey",            "Tint grey tones",  0.50, 0.50, 0.50, 5)
UICL_COLOR    (HUERed,       "Red",             HSL_TOOLTIP,        0.75, 0.25, 0.25, 0)
UICL_COLOR    (HUEOrange,    "Orange",          HSL_TOOLTIP,        0.75, 0.50, 0.25, 0)
UICL_COLOR    (HUEYellow,    "Yellow",          HSL_TOOLTIP,        0.75, 0.75, 0.25, 0)
UICL_COLOR    (HUEGreen,     "Green",           HSL_TOOLTIP,        0.25, 0.75, 0.25, 0)
UICL_COLOR    (HUECyan,      "Cyan",            HSL_TOOLTIP,        0.25, 0.75, 0.75, 0)
UICL_COLOR    (HUEBlue,      "Blue",            HSL_TOOLTIP,        0.25, 0.25, 0.75, 0)
UICL_COLOR    (HUEPurple,    "Purple",          HSL_TOOLTIP,        0.50, 0.25, 0.75, 0)
UICL_COLOR    (HUEMagenta,   "Magenta",         HSL_TOOLTIP,        0.75, 0.25, 0.75, 0)

UICL_INT_S    (CONTRAST,     "Contrast",        "", -100, 100,   0, 5)
UICL_FLOAT_S  (OUT_GAMMA,    "Gamma",           "Midtones brightness", 0.01, 2.0, 1.0, 0)
UICL_INT2_S   (LEVELS,       "Levels",          "Black Point | White point", -100, 100,   0, 0, 0)

UICL_COMBOOL  (CLIP_CAL,     "Clipping Guides",  "", 0, 5)
UICL_COMBOOL  (GREY_CAL,     "Grey Calibration", "", 0, 0)
UICL_MSG      (CALMSG, 0,
" These tools will help you with color grade\n"
" balance. The clipping guide will show where\n"
" your black and white points are clipping, and\n"
" the grey calibration guide will light up green\n"
" anywhere on the image that is near to perfect\n"
" grey saturation.")
#undef CATEGORY /////////////////////////////////
/////////////////////////////////////////////////


#define CATEGORY "MISC OPTIONS" /////////////////
/////////////////////////////////////////////////
UICL_COMBO    (PUSH_MODE,     "Exposure Push",   "",  0, 0,
                  "Automatic by ISO\0"
                  "Manual\0")
UICL_INT_S    (AUTO_PUSH,     "Automatic Push Range", "", 0, 100, 100, 0)
UICL_FLOAT_S  (PUSH,          "Manual Push",          "",  0.0, 3.0,   0.0,   0)
UICL_MSG      (PUSHMSG, 0,
" Exposure push will underexpose the film negative\n"
" while increasing exposure in the film print to\n"
" compensate. The affects color response and grain\n"
" response. Requires both negative and print to be\n"
" active.")

#if (ENABLE_HALATION)
UICL_COMBO    (ENABLE_HAL,    "Enable Halation",      "", 1, 0,
                  "Disabled\0"
                  "Automatic by Film Negative\0"
                  "Manual\0")
UICL_INT_S    (HAL_AMT,       "Manual Halation Intensity",   "",  0,   100,   33,    0)
UICL_INT_S    (HAL_SEN,       "Manual Halation Sensitivity", "",  10,  100,   85,    0)
UICL_INT_S    (HAL_WDT,       "Manual Halation Size",        "",  10,  100,   75,    0)
UICL_MSG      (HALMSG, 0,
" Halation is a film artifact that will cause highlights\n"
" to glow red. This effect actually has nothing to do\n"
" with bloom or other lens artifacts.")
#endif

UICL_COMBO    (ENABLE_RES,    "Use Film Format Resolution",  "", 1, 0,
                  "Disabled\0"
                  "Automatic by Film Format\0"
                  "Manual\0")
UICL_INT_S    (RESOLUTION,    "Manual Film Resolution",      "",  0.0, 200.0, 100.0, 0)
UICL_MSG      (RESMSG, 0,
" Enabling this will allow FILMDECK to adjust the\n"
" overall softness of the image based on the selected\n"
" film format (16mm, Super 35, or 35mm)")

UICL_COMBOOL  (ENABLE_GW,     "Gate Weave", "May cause motion sickness!", 0, 0)
UICL_INT_S    (WEAVE_AMT,     "Gate Weave Intensity", "May cause motion sickness!", 0, 100, 50, 0)
UICL_MSG      (WVMSG, 0,
" Gate weave is the effect of film being slightly\n"
" misaligned as it moves quickly through a projector.\n"
" in FILMDECK, this is represented as a slight\n"
" side-to-side wobble. Be careful, it may cause\n"
" motion sickness in gameplay.")

UICL_COMBOOL  (ENABLE_FLK,    "Image Flicker", "", 0, 0)
UICL_INT_S    (FLK_INT,       "Filcker Intensity", "", 0, 100, 50, 0)
UICL_MSG      (FLKMSG, 0,
" This enables a very subtle image flicker, mimicking\n"
" a film projector. Take care, it could cause headaches.")

#undef CATEGORY /////////////////////////////////
/////////////////////////////////////////////////


#define CATEGORY "PREPROCESSOR INFO" ////////////
/////////////////////////////////////////////////
UICL_MSG      (INFO1, 0,
"   ENABLE_GRAIN_DISPLACEMENT\n"
"       Enables FILMDECK to distort the image slightly\n"
"       based on the film grain texture. This provides\n"
"       a more realistic result.")
UICL_MSG      (INFO2, 0,
"   ENABLE_HALATION\n"
"       Enables a red glow around bright highlights\n"
"       based on the selected film negative or to be\n"
"       set manually. Disabling can increase performance.")
UICL_MSG      (INFO3, 0,
"   FORCE_8_BIT_OUTPUT\n"
"       Forces FILMDECK to dither the output to 8-bit.\n"
"       This is useful when you have an 8-bit monitor,\n"
"       but the game uses an RGB10A2 color buffer.")
UICL_MSG      (INFO4, 0,
"   SWAPCHAIN_PRECISION\n"
"       1 = Use game's internal bit depth (not recommended)\n"
"       2 = RGBA16  - 16-bit (default mode)\n"
"       3 = RGBA16F - 16-bit float")
#undef CATEGORY /////////////////////////////////
/////////////////////////////////////////////////


// FUNCTIONS //////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#include "SHADERDECK/Functions/AVGen.fxh"
#include "SHADERDECK/Functions/3DLUT.fxh"
#include "SHADERDECK/Functions/Contrast.fxh"
#include "SHADERDECK/Functions/BlendingModes.fxh"
#include "SHADERDECK/Functions/GaussianBlurBounds.fxh"
#include "SHADERDECK/Functions/Grain.fxh"
#include "SHADERDECK/Functions/HSLShift.fxh"
#include "SHADERDECK/Functions/TriDither.fxh"


// RENDERTARGETS //////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
RENDERTARGET(Swapchain1, BUFFER_WIDTH, BUFFER_HEIGHT, INTERNAL_DEPTH,     MIRROR)
RENDERTARGET(Swapchain2, BUFFER_WIDTH, BUFFER_HEIGHT, INTERNAL_DEPTH,     MIRROR)


// SHADERS ////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
VOID (Downscale, float4 scaled)
{
    // FILM SOFTENING ///////////////////////////
    /////////////////////////////////////////////
    if ((ENABLE_RES > 0) && ((FILM_NEGATIVE > 0) || (FILM_PRINT > 0)))
    {
        scaled = tex2Dbicub(TextureColor, SCALE(uv, 0.5)); // Linearized cbuffer
    }

    else
    {
        scaled = tex2D(TextureColor, uv); // Linearized cbuffer
    }

    scaled = SRGBToLinear(scaled);
}

VOID (Upscale, float4 color)
{
    float4 soften, blur1;
    float  mask, res, halsen;

    // LINEAR CBUFFER ///////////////////////////
    /////////////////////////////////////////////
    color  = SRGBToLinear(tex2D(TextureColor, uv));


    // FILM PROFILE ARRAY ///////////////////////
    /////////////////////////////////////////////
    #include FILM_PROFILES


    // FILM SOFTENING ///////////////////////////
    /////////////////////////////////////////////
    if ((ENABLE_RES > 0) && ((FILM_NEGATIVE > 0) || (FILM_PRINT > 0))) // We blend in linearspace to avoid darkening the edges where
    {                                                                  // softening is most noticeable
        res    = (ENABLE_RES == 1)
               ? lerp(0.0, 1.0, lerp(0.5, (FILM_FORMATN * 0.25), (FILM_NEGATIVE > 0)) + lerp(0.5, (FILM_FORMATP * 0.25), (FILM_PRINT > 0)))
               : (RESOLUTION * 0.005);
        soften = tex2Dbicub(TextureSwapchain1, SCALE(uv, (1.0 / 0.5)));
        mask   = pow(smoothstep(0.1, 1.0, GetLuma(LinearToSRGB(color.rgb))), 0.75);
        mask   = lerp(lerp(0.25, 1.0, mask), 0.0, res);
        color  = lerp(color, soften, mask);
    }


    // HALATION PREP ////////////////////////////
    /////////////////////////////////////////////
    #if (ENABLE_HALATION)
    if ((ENABLE_HAL > 0) && (FILM_NEGATIVE > 0))
    {
        halsen  = (ENABLE_HAL < 2)
                ? (NegativeProfile[FILM_NEGATIVE - 1].halation.y * 0.01)
                : (HAL_SEN * 0.01);
        // Pre-apply the negative lut to grab the correct colors for halation
        color.a = GetLuma(MultiLUT_Linear(tex2Dbicub(TextureColor, SCALE(uv, 0.25)).rgb, NegativeAtlas, FILM_NEGATIVE - 1));
        // Crush and linearize the result
        color.a = pow(SRGBToLinear(color.aaa).x, lerp(20.0, 4.0, halsen));
    }
    #endif
}

#if (ENABLE_HALATION)
VOID (Halate1, float4 color)
{
    float halation, width;

    // FILM PROFILE ARRAY ///////////////////////
    /////////////////////////////////////////////
    #include FILM_PROFILES


    // INPUT IMAGE //////////////////////////////
    /////////////////////////////////////////////
    color = tex2D(TextureSwapchain2, uv);


    // HALATION HORIZONTAL BLUR /////////////////
    /////////////////////////////////////////////
    if ((ENABLE_HAL > 0) && (FILM_NEGATIVE > 0))
    {
        width    = (ENABLE_HAL == 1)
                 ? (NegativeProfile[FILM_NEGATIVE - 1].halation.z * 0.01)
                 : (HAL_WDT * 0.01);
        halation = HalateH(color.a, TextureSwapchain2, width, BoundsMid, uv);
    }

    else
    {
        halation = 0.0;
    }

    color.a = halation;
}

VOID (Halate2, float4 color)
{
    float halation, width;

    // FILM PROFILE ARRAY ///////////////////////
    /////////////////////////////////////////////
    #include FILM_PROFILES


    // INPUT IMAGE //////////////////////////////
    /////////////////////////////////////////////
    color = tex2D(TextureSwapchain1, uv);


    // HALATION VERTICAL BLUR ///////////////////
    /////////////////////////////////////////////
    if ((ENABLE_HAL > 0) && (FILM_NEGATIVE > 0))
    {
        width    = (ENABLE_HAL == 1)
                 ? (NegativeProfile[FILM_NEGATIVE - 1].halation.z * 0.01)
                 : (HAL_WDT * 0.01);
        halation = HalateV(color.a, TextureSwapchain1, width, BoundsMid, uv);
    }

    else
    {
        halation = 0.0;
    }

    color.a = halation;
}
#endif

#if (ENABLE_GRAIN_DISPLACEMENT)
VOID (GrainDisplacement, float4 color)
{
    float  dist;
    float3 grain;

    dist      = lerp(150.0, 275.0, FILM_FORMATN * 0.5);

    grain     = GetGrainTexture(FILM_FORMATN, 1.0, uv) - 0.5;
    grain    *= (pow(GRAIN_N * 0.01, 0.333)) / (dist * (1440.0 / (BUFFER_HEIGHT * 1.0)));

    color.rgb = tex2D(TextureSwapchain2, uv + float2(grain.x / BUFFER_ASPECT_RATIO, grain.y)).rgb;
    color.a   = tex2D(TextureSwapchain2, uv).a;
}
#endif

VOID (FilmDeck, float4 film)
{
    float  dist, luma, pmask, avg, ntemp, ptemp;
    float3 halate;
    float3 orig, lift, gamma, gain, grain, grey, hsl;


    // INPUT TEXTURES ///////////////////////////
    /////////////////////////////////////////////
    #if (ENABLE_GRAIN_DISPLACEMENT)
    dist   = lerp(150.0, 275.0, FILM_FORMATP * 0.5);
    grain  = GetGrainTexture(FILM_FORMATP, -1.0, uv) - 0.5;
    grain *= (pow(GRAIN_P * 0.01, 0.333)) / (dist * (1440.0 / (BUFFER_HEIGHT * 1.0)));
    film   = tex2D(TextureSwapchain1, uv + float2(grain.z / BUFFER_ASPECT_RATIO, grain.y)).rgb;
    #else
    film = tex2D(TextureSwapchain2, uv); // Buffer from film softening stage
    #endif
    avg  = pow(GetLuma(avGen::get()), 0.75); // Scene average luma


    // FILM PROFILE ARRAY ///////////////////////
    /////////////////////////////////////////////
    #include FILM_PROFILES


    // HALATION /////////////////////////////////
    /////////////////////////////////////////////
    #if (ENABLE_HALATION)
    if ((ENABLE_HAL > 0) && (FILM_NEGATIVE > 0))
    {
        // Apply film halation (blended in linearspace)
        #if (ENABLE_GRAIN_DISPLACEMENT)
        halate.r = tex2Dbicub(TextureSwapchain1, SCALE(uv, 4.0)).a;
        #else
        halate.r = tex2Dbicub(TextureSwapchain2, SCALE(uv, 4.0)).a;
        #endif
        halate.y = (ENABLE_HAL == 1)
                 ? (NegativeProfile[FILM_NEGATIVE - 1].halation.x * 0.02)
                 : (HAL_AMT * 0.02);
        film.r   = lerp(film.r, BlendScreen(film.r, halate.r), halate.y);
    }
    #endif


    // EXPOSURE & PUSHING ///////////////////////
    /////////////////////////////////////////////
    // Normally, this would apply evenly to the entire image
    // but since I'm working with non-HDR input data,
    // I mask for luminance to preserve highlights
    // The effect is only applied to the shadows and mids
    pmask = GetLuma(SRGBToLinear(tex2D(TextureColor, uv)));
    if (FILM_NEGATIVE > 0)\
    {
        film *= exp2(NEG_EXP);

        if ((PUSH_MODE < 1) && (FILM_PRINT > 0)) // Automatic push
        {
            film *= lerp(1.0, lerp(lerp(NegativeProfile[FILM_NEGATIVE - 1].iso / 800.0, 1.0, avg), 1.0, pmask), AUTO_PUSH * 0.01);
        }

        else if (FILM_PRINT > 0) // Manual push
        {
            film *= exp2(lerp(-PUSH, 0.0, pmask));
        }
    }

    film = LinearToSRGB(saturate(film));


    if (FILM_NEGATIVE > 0)
    {
        // WHITE BALANCE ////////////////////////
        /////////////////////////////////////////
        ntemp = (N_TEMP > 0)
              ? lerp(6500.0, 40000.0, N_TEMP * 0.01)
              : lerp(3200.0, 6500.0, 1-abs(N_TEMP * 0.01));

        luma  = GetLuma(film.rgb);

        if ((AUTO_TEMP) && (FILM_NEGATIVE > 0))
        {
            film.rgb = lerp(WhiteBalance(film.rgb, ntemp, NegativeProfile[FILM_NEGATIVE - 1].temp), film.rgb, luma);
        }

        else
        {
            film.rgb = lerp(WhiteBalance(film.rgb, ntemp, 6500), film.rgb, luma);
        }


        // FILM GRAIN ///////////////////////////
        /////////////////////////////////////////
        film.rgb = FilmGrain(saturate(film.rgb), FILM_FORMATN, 1.0, GRAIN_N, uv);


        // FILM NEGATIVE LUT ////////////////////
        /////////////////////////////////////////
        #if (CUSTOM_PRESET_ENABLED != 0)
            if (FILM_NEGATIVE <= NEGATIVE_COUNT)
            {
                film.rgb = FilmNegative(saturate(film.rgb), 0, FILM_NEGATIVE - 1).rgb;
            }

            else
            {
                film.rgb = FilmNegative(saturate(film.rgb), 1, (FILM_NEGATIVE - NEGATIVE_COUNT) - 1).rgb;
            }
        #else
            film.rgb = FilmNegative(saturate(film.rgb), 0, FILM_NEGATIVE - 1).rgb;
        #endif
    }


    // COLOR GRADING //////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////
    if (ENABLE_GRADE)
    {
        // SATURATION ///////////////////////////
        /////////////////////////////////////////
        film.rgb = RGBToHSL(film.rgb);
        film.y   = (SATURATION < 100)
                 ? (lerp(0.0, film.y, SATURATION * 0.01))
                 : (pow(film.y, lerp(1.0, 0.66, (SATURATION - 100) * 0.01)));
        film.rgb = HSLToRGB(film.rgb);


        // LIFT GAMMA GAIN //////////////////////
        /////////////////////////////////////////
        lift     = (LIFT  - 0.5) * 0.5;
        gamma    = (GAMMA + 0.5);
        gain     = (GAIN  + 0.5);
        film.rgb = pow(saturate(gain * (film.rgb + lift * (1 - film.rgb))), 1.0 / gamma);


        // GREY COLORIZE ////////////////////////
        /////////////////////////////////////////
        hsl      = RGBToHSL(film.rgb);
        grey     = (GREYS * 2.0);
        film.rgb = saturate(lerp(film.rgb, film.rgb * grey, saturate(pow(1-hsl.y, 10.0) * pow(smoothstep(0.66, 0.0, hsl.z), 1.0))));


        // HUE SHIFT ////////////////////////////
        /////////////////////////////////////////
        film.rgb = HSLShift(film.rgb);


        // CONTRAST /////////////////////////////
        /////////////////////////////////////////
        film.rgb = ContrastCurve(film.rgb, CONTRAST);
    }


    // EXPOSURE & PUSHING ///////////////////////
    /////////////////////////////////////////////
    // Normally, this would apply evenly to the entire image
    // but since we're working with non-HDR input data,
    // We'll mask for luminance to preserve highlights
    // The effect is only applied to the shadows and mids
    film.rgb   = SRGBToLinear(film.rgb);
    if (FILM_PRINT > 0)
    {
        film      *= exp2(PRT_EXP);

        if ((PUSH_MODE < 1) && (FILM_NEGATIVE > 0)) // Automatic push
        {
            film /= lerp(1.0, lerp(lerp(NegativeProfile[FILM_NEGATIVE - 1].iso / 800.0, 1.0, avg), 1.0, pmask), AUTO_PUSH * 0.01);
        }

        else if (FILM_NEGATIVE > 0) // Manual push
        {
            film *= exp2(lerp(PUSH, 0.0, pmask));
        }
    }


    if (FILM_PRINT > 0)
    {
        // WHITE BALANCE ////////////////////////
        /////////////////////////////////////////
        ptemp    = (P_TEMP > 0)
                 ? lerp(6500.0, 40000.0, P_TEMP * 0.01)
                 : lerp(3200.0, 6500.0, 1-abs(P_TEMP * 0.01));
        luma     = GetLuma(film.rgb);
        film.rgb = lerp(WhiteBalance(saturate(film.rgb), ptemp, 6500), film.rgb, luma);

        // FILM GRAIN ///////////////////////////////
        /////////////////////////////////////////////
        film     = LinearToSRGB(film);
        film.rgb = FilmGrain(saturate(film.rgb), FILM_FORMATP, -0.75, GRAIN_P, uv);


        // FILM PRINT LUT ///////////////////////////
        /////////////////////////////////////////////
        #if (CUSTOM_PRESET_ENABLED != 0)
            if (FILM_PRINT <= PRINT_COUNT)
            {
                film.rgb = FilmPrint(saturate(film.rgb), 0, FILM_PRINT - 1).rgb;
            }

            else
            {
                film.rgb = FilmPrint(saturate(film.rgb), 1, (FILM_PRINT - PRINT_COUNT) - 1).rgb;
            }
        #else
            film.rgb = FilmPrint(saturate(film.rgb), 0, FILM_PRINT - 1).rgb;
        #endif
    }

    else
    {
        film.rgb = LinearToSRGB(film.rgb);
    }

    if (ENABLE_GRADE)
    {
        // OUTPUT LEVELS ////////////////////////
        /////////////////////////////////////////
        film = pow(film, 1.0 / OUT_GAMMA);
        film = saturate(lerp(LEVELS.x / 255.0, (LEVELS.y + 255) / 255.0, film));


        // CALIBRATION GUIDES ///////////////////
        /////////////////////////////////////////
        if (CLIP_CAL)
        {
            film.rgb = lerp(film.rgb, float3(1, 0, 0), (GetLuma(film.rgb) > (254.0 / 255.0)));
            film.rgb = lerp(film.rgb, float3(0, 0, 1), (GetLuma(film.rgb) == 0.0));
        }

        hsl = RGBToHSV(film.rgb);

        if (GREY_CAL)
        {
            hsl.z    = SRGBToLinear(hsl.zzz).x;
            film.rgb = lerp(film.rgb, float3(0, 1, 0), smoothstep(0.15, 0.05, hsl.y) * (1 - smoothstep(0.055, 0.0, hsl.z) - smoothstep(0.305, 1.0, hsl.z)));
        }
    }


    // FINAL DITHER /////////////////////////////
    /////////////////////////////////////////////
    film.rgb += TriDither(film.rgb, uv, FORCE_8_BIT_OUTPUT ? 8 : BUFFER_COLOR_BIT_DEPTH);
}

VOID (GateWeave, float4 color)
{
    float animate;

    animate = (ENABLE_GW)
            ? ((cos(Timer * (1.0 / 24.0)) * 0.0001) * (WEAVE_AMT * 0.015))
            : 0.0;

    color   = tex2D(TextureColor, uv + float2(animate, 0.0));

    if (ENABLE_FLK)
    {
        color = lerp(color, color * lerp(1.0, 0.975, FLK_INT * 0.01), ((cos(Timer * pi) + 1) * 0.5));
    }

    #if (LET_ME_COOK != 0)
        color.rgb = BlendScreen(color.rgb, tex2D(TextureCook, uv).rgb);
    #endif
}


// TECHNIQUES /////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
technique FILMDECK < ui_label = "FILMDECK"; ui_tooltip = "Film Emulation"; >
{
    pass // ADAPTATION TEXTURE GENERATION ///////
    {
        VertexShader = avGen::vs_main;
        PixelShader  = avGen::ps_main;
        RenderTarget = avGen::texLod;
    }

    pass // FILM SOFTENING //////////////////////
    {
        VertexShader = VS_Tri;
        PixelShader  = PS_Downscale;
        RenderTarget = RT_Swapchain1;
    }

    pass // FILM SOFTENING //////////////////////
    {
        VertexShader = VS_Tri;
        PixelShader  = PS_Upscale;
        RenderTarget = RT_Swapchain2;
    }

    #if (ENABLE_HALATION)
    pass // HALATION ////////////////////////////
    {
        VertexShader = VS_Tri;
        PixelShader  = PS_Halate1;
        RenderTarget = RT_Swapchain1;
    }

    pass // HALATION ////////////////////////////
    {
        VertexShader = VS_Tri;
        PixelShader  = PS_Halate2;
        RenderTarget = RT_Swapchain2;
    }
    #endif

    #if (ENABLE_GRAIN_DISPLACEMENT)
    pass // GRAIN DISPLACEMENT //////////////////
    {
        VertexShader = VS_Tri;
        PixelShader  = PS_GrainDisplacement;
        RenderTarget = RT_Swapchain1;
    }
    #endif

    pass // FILM PASS ///////////////////////////
    {
        VertexShader = VS_Tri;
        PixelShader  = PS_FilmDeck;
    }

    pass // GATE WEAVE //////////////////////////
    {
        VertexShader = VS_Tri;
        PixelShader  = PS_GateWeave;
    }
}