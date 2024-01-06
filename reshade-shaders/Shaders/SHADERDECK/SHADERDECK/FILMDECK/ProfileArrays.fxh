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


// STRUCT ARRAYS //////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#ifdef __NEG_ARRAY_LIST
    #undef __NEG_ARRAY_LIST
#endif
#define __NEG_ARRAY_LIST \
        NegativeProfile[0] = K5207D(); \
        NegativeProfile[1] = K5213T(); \
        NegativeProfile[2] = FR500D();

#ifdef __PRI_ARRAY_LIST
    #undef __PRI_ARRAY_LIST
#endif
#define __PRI_ARRAY_LIST \
        PrintProfile[0] = K2383(); \
        PrintProfile[1] = F3521(); \
        PrintProfile[2] = K2302();

#if !CUSTOM_PRESET_ENABLED
    FilmStruct NegativeProfile[NEGATIVE_COUNT];
        __NEG_ARRAY_LIST

    FilmStruct PrintProfile[PRINT_COUNT];
        __PRI_ARRAY_LIST

#else
    FilmStruct NegativeProfile[NEGATIVE_COUNT + CUST_NEGATIVE_LUT_COUNT];
    FilmStruct PrintProfile[PRINT_COUNT       + CUST_PRINT_LUT_COUNT];
    FilmStruct GenericProfile[3];
        GenericProfile[0] = Generic35mm();
        GenericProfile[1] = GenericSuper35();
        GenericProfile[2] = Generic16mm();

    #if   (CUST_NEGATIVE_LUT_COUNT == 1)
            __NEG_ARRAY_LIST
            NegativeProfile[NEGATIVE_COUNT]    = GenericProfile[CUST_NEGATIVE_PROFILE_1 - 1];

    #elif (CUST_NEGATIVE_LUT_COUNT == 2)
            __NEG_ARRAY_LIST
            NegativeProfile[NEGATIVE_COUNT    ] = GenericProfile[CUST_NEGATIVE_PROFILE_1 - 1];
            NegativeProfile[NEGATIVE_COUNT + 1] = GenericProfile[CUST_NEGATIVE_PROFILE_2 - 1];

    #elif (CUST_NEGATIVE_LUT_COUNT == 3)
            __NEG_ARRAY_LIST
            NegativeProfile[NEGATIVE_COUNT    ] = GenericProfile[CUST_NEGATIVE_PROFILE_1 - 1];
            NegativeProfile[NEGATIVE_COUNT + 1] = GenericProfile[CUST_NEGATIVE_PROFILE_2 - 1];
            NegativeProfile[NEGATIVE_COUNT + 2] = GenericProfile[CUST_NEGATIVE_PROFILE_3 - 1];

    #elif (CUST_NEGATIVE_LUT_COUNT == 4)
            __NEG_ARRAY_LIST
            NegativeProfile[NEGATIVE_COUNT    ] = GenericProfile[CUST_NEGATIVE_PROFILE_1 - 1];
            NegativeProfile[NEGATIVE_COUNT + 1] = GenericProfile[CUST_NEGATIVE_PROFILE_2 - 1];
            NegativeProfile[NEGATIVE_COUNT + 2] = GenericProfile[CUST_NEGATIVE_PROFILE_3 - 1];
            NegativeProfile[NEGATIVE_COUNT + 3] = GenericProfile[CUST_NEGATIVE_PROFILE_4 - 1];

    #elif (CUST_NEGATIVE_LUT_COUNT == 5)
            __NEG_ARRAY_LIST
            NegativeProfile[NEGATIVE_COUNT    ] = GenericProfile[CUST_NEGATIVE_PROFILE_1 - 1];
            NegativeProfile[NEGATIVE_COUNT + 1] = GenericProfile[CUST_NEGATIVE_PROFILE_2 - 1];
            NegativeProfile[NEGATIVE_COUNT + 2] = GenericProfile[CUST_NEGATIVE_PROFILE_3 - 1];
            NegativeProfile[NEGATIVE_COUNT + 3] = GenericProfile[CUST_NEGATIVE_PROFILE_4 - 1];
            NegativeProfile[NEGATIVE_COUNT + 4] = GenericProfile[CUST_NEGATIVE_PROFILE_5 - 1];

    #else
            __NEG_ARRAY_LIST

    #endif

    #if   (CUST_PRINT_LUT_COUNT == 1)
            __PRI_ARRAY_LIST
            PrintProfile[PRINT_COUNT]          = GenericProfile[CUST_PRINT_PROFILE_1 - 1];

    #elif (CUST_PRINT_LUT_COUNT == 2)
            __PRI_ARRAY_LIST
            PrintProfile[PRINT_COUNT    ]       = GenericProfile[CUST_PRINT_PROFILE_1 - 1];
            PrintProfile[PRINT_COUNT + 1]       = GenericProfile[CUST_PRINT_PROFILE_2 - 1];

    #elif (CUST_PRINT_LUT_COUNT == 3)
            __PRI_ARRAY_LIST
            PrintProfile[PRINT_COUNT    ]       = GenericProfile[CUST_PRINT_PROFILE_1 - 1];
            PrintProfile[PRINT_COUNT + 1]       = GenericProfile[CUST_PRINT_PROFILE_2 - 1];
            PrintProfile[PRINT_COUNT + 2]       = GenericProfile[CUST_PRINT_PROFILE_3 - 1];

    #elif (CUST_PRINT_LUT_COUNT == 4)
            __PRI_ARRAY_LIST
            PrintProfile[PRINT_COUNT    ]       = GenericProfile[CUST_PRINT_PROFILE_1 - 1];
            PrintProfile[PRINT_COUNT + 1]       = GenericProfile[CUST_PRINT_PROFILE_2 - 1];
            PrintProfile[PRINT_COUNT + 2]       = GenericProfile[CUST_PRINT_PROFILE_3 - 1];
            PrintProfile[PRINT_COUNT + 3]       = GenericProfile[CUST_PRINT_PROFILE_4 - 1];

    #elif (CUST_PRINT_LUT_COUNT == 5)
            __PRI_ARRAY_LIST
            PrintProfile[PRINT_COUNT    ]       = GenericProfile[CUST_PRINT_PROFILE_1 - 1];
            PrintProfile[PRINT_COUNT + 1]       = GenericProfile[CUST_PRINT_PROFILE_2 - 1];
            PrintProfile[PRINT_COUNT + 2]       = GenericProfile[CUST_PRINT_PROFILE_3 - 1];
            PrintProfile[PRINT_COUNT + 3]       = GenericProfile[CUST_PRINT_PROFILE_4 - 1];
            PrintProfile[PRINT_COUNT + 4]       = GenericProfile[CUST_PRINT_PROFILE_5 - 1];

    #else
            __PRI_ARRAY_LIST

    #endif
    
#endif