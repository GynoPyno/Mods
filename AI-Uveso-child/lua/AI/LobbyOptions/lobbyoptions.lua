
AIOpts = {
    {
        default = 1,
        label = "AIx: Overwhelm+ Unit Cap",
        help = "Set an AI unit cap for the Overwhelm+ personality. Overrides the global AI Unit Cap for Overwhelm+ AIs only.",
        key = 'OWPlusUnitCap',
        value_text = "%s",
        value_help = "%s units per Overwhelm+ AI may be in play",
        values = {
            {
                text = "Same as AI Unit Cap",
                help = "Overwhelm+ AI uses the global AI Unit Cap setting.",
                key = '0',
            },
            '500', '600', '700', '800', '900',
            '1000', '1100', '1200', '1300', '1400', '1500', '1600', '1700', '1800', '1900', '2000',
            '2500', '3000'
        },
    },
}
