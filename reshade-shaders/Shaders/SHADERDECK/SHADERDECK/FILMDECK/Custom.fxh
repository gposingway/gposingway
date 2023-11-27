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

    Welcome to FILMDECK, the spiritual successor to Film Workshop!

**  ///////////////////////////////////////////////////////////////////////////////////////////  **
**  ///////////////////////////////////////////////////////////////////////////////////////////  */


// This must be set to 1 for your custom preset to work!
#define CUSTOM_PRESET_ENABLED 0


/*  ///////////////////////////////////////////////////////////////////////////////////////////  **
**  ///////////////////////////////////////////////////////////////////////////////////////////  **

      Creating custom LUTs for FILMDECK is fairly straightforward. Unlike Film Workshop, FILMDECK
    only accepts luts designed for Rec.709 or sRGB input and output. This means that your custom
    LUTs for both the negative and print stages must accept full-range input and output. LOG is
    not supported in any way.

      This was done to minimize color precision loss in the limited non-HDR color range provided
    by ReShade from almost all games. If you want to add negative and print film LUTs that are
    designed for use in a LOG workflow, they will need to be converted to full-range input and
    output. Davinci Resolve has a convenient Colorspace Transform plugin that can help you with
    this if needed. Otherwise, any LUT that is designed for full-range input and output will work
    absolutely fine.

      If you are simply wanting to use a custom LUT that isn't emulating film at all, simply
    ignore one of the LUT stages (negative or print) and set the stage you ignored to "Bypass"
    in the FILMDECK UI. In this use case, where you place your custom LUT will determine where
    in the render chain the color grading stage is applied to the image.

      If you want to be able to grade AFTER your custom LUT, bypass the print stage and place
    your custom LUT in the negative stage. If you want your custom LUT to be rendered AFTER the
    color grade section, bypass the negative stage and place your custom LUT in the print stage.

    - TreyM

**  ///////////////////////////////////////////////////////////////////////////////////////////  **
**  ///////////////////////////////////////////////////////////////////////////////////////////  */


// CUSTOM PRESET NAME /////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

// This will define the custom preset prefix in the LUT lists
#define CUST_PRESET_NAME            "Custom"


// CUSTOM NEGATIVE ////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

// Enter the filename with the .png extension
#define CUST_NEGATIVE_FILENAME      "CustomNegative.png"

// Size in pixels of your custom negative texture
#define CUST_NEGATIVE_TEXTURE_WIDTH  1024
#define CUST_NEGATIVE_TEXTURE_HEIGHT 32

// Number of LUTs in your custom negative texture (maximum of 5)
#define CUST_NEGATIVE_LUT_COUNT      1

// Negative LUT Names
#define CUST_NEGATIVE_NAME_1        "Negative 1"
#define CUST_NEGATIVE_NAME_2        "Negative 2"
#define CUST_NEGATIVE_NAME_3        "Negative 3"
#define CUST_NEGATIVE_NAME_4        "Negative 4"
#define CUST_NEGATIVE_NAME_5        "Negative 5"

// Negative film profiles
//     1 = 35mm fine grain
//     2 = Super35 medium grain
//     3 = 16mm large grain
#define CUST_NEGATIVE_PROFILE_1      2
#define CUST_NEGATIVE_PROFILE_2      2
#define CUST_NEGATIVE_PROFILE_3      2
#define CUST_NEGATIVE_PROFILE_4      2
#define CUST_NEGATIVE_PROFILE_5      1


// CUSTOM PRINT ///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

// Enter the filename with the .png extention
#define CUST_PRINT_FILENAME         "CustomPrint.png"

// Size in pixels of your custom print texture
#define CUST_PRINT_TEXTURE_WIDTH     1024
#define CUST_PRINT_TEXTURE_HEIGHT    32

// Number of LUTs in your custom print texture (maximum of 5)
#define CUST_PRINT_LUT_COUNT         1

// Print LUT names
#define CUST_PRINT_NAME_1           "Print 1"
#define CUST_PRINT_NAME_2           "Print 2"
#define CUST_PRINT_NAME_3           "Print 3"
#define CUST_PRINT_NAME_4           "Print 4"
#define CUST_PRINT_NAME_5           "Print 5"

// Print film profiles
//     1 = 35mm fine grain
//     2 = Super35 medium grain
#define CUST_PRINT_PROFILE_1         1
#define CUST_PRINT_PROFILE_2         1
#define CUST_PRINT_PROFILE_3         1
#define CUST_PRINT_PROFILE_4         1
#define CUST_PRINT_PROFILE_5         1