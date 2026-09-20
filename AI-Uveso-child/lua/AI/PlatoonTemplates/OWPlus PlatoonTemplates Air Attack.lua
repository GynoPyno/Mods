-- Nuovi PlatoonTemplate per il batching dei plotoni d'attacco aria
-- (override di 'U123 Air Formers EnemyZone', vedi 'OWPlus Air Attack Batching.lua').
-- Taglie ESATTE (min=max), filtri per CATEGORIA (mai ID) cosi' da restare
-- automaticamente compatibili con unita' aeree moddate.

PlatoonTemplate {
    Name = 'OWPlusAirAttackHunt AntiAir 15',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR - categories.GROUNDATTACK - categories.BOMBER - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL - categories.ANTINAVY, 15, 15, 'Attack', 'none' },
    }
}
PlatoonTemplate {
    Name = 'OWPlusAirAttackHunt AntiAir 25',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR - categories.GROUNDATTACK - categories.BOMBER - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL - categories.ANTINAVY, 25, 25, 'Attack', 'none' },
    }
}
PlatoonTemplate {
    Name = 'OWPlusAirAttackHunt AntiAir 35',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR - categories.GROUNDATTACK - categories.BOMBER - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL - categories.ANTINAVY, 35, 35, 'Attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'OWPlusAirAttackHunt AntiGround 15',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * ( categories.GROUNDATTACK + categories.BOMBER ) - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL - categories.ANTINAVY, 15, 15, 'Attack', 'GrowthFormation' },
    }
}
PlatoonTemplate {
    Name = 'OWPlusAirAttackHunt AntiGround 25',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * ( categories.GROUNDATTACK + categories.BOMBER ) - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL - categories.ANTINAVY, 25, 25, 'Attack', 'GrowthFormation' },
    }
}
