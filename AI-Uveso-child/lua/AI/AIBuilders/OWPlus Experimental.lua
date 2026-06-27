-- OWPlus Experimental.lua
-- Fase 7b (P-exp): scaling verso sperimentali senza il gate ItsTimeForGameender di Uveso
-- (che per default blocca i T4 fino al 25° minuto di partita).
--
-- Paradigma (Opzione C):
--   Le fabbriche continuano a produrre T2/T3 normalmente.
--   Gli ingegneri T3 scalano verso T4 man mano che la partita avanza:
--
--   FIRST (18300): primo sperimentale appena esiste una T3 factory + eco positiva
--   SCALE (18250): fino a 5 sperimentali se mass storage > 15%
--   FLOOD (18200): spam senza limite se mass storage > 30% (eco in overflow)
--
-- Il gate eco (GreaterThanEconStorageRatio) protegge dall'avvio prematuro:
-- se energy storage < soglia, la condizione fallisce → gli ingegneri restano liberi
-- per costruire pgens tramite OWPlus Energy T2T3 (priority 18100/18200).
--
-- Priority range: 18200-18300 (sopra Uveso max 1100, sotto OWPlus eco 18100-18200 solo per T4)

local categories = categories
local EBC  = '/lua/editor/EconomyBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'

-- ============================================================ --
-- ==           LAND EXPERIMENTALS — Terra T4                == --
-- ============================================================ --
BuilderGroup {
    BuilderGroupName = 'OWPlus Experimental Land',
    BuildersType = 'EngineerBuilder',

    -- FIRST: avvia il PRIMO sperimentale appena abbiamo una T3 factory + eco storage > 5%
    Builder {
        BuilderName = 'OWPlus Exp Land First',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18300,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExperimental', 5},
        BuilderConditions = {
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExperimental' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.05 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'T4LandExperimental1' },
                Location = 'LocationType',
            }
        }
    },

    -- SCALE: fino a 5 sperimentali in campo se mass+energy storage > 15%
    Builder {
        BuilderName = 'OWPlus Exp Land Scale',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        InstanceCount = 5,
        DelayEqualBuildPlattons = {'MobileExperimental', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExperimental' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'T4LandExperimental1' },
                Location = 'LocationType',
            }
        }
    },

    -- SCALE2: variante T4LandExperimental2 per varietà (Galactic Colossus / varianti)
    Builder {
        BuilderName = 'OWPlus Exp Land Scale2',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        InstanceCount = 3,
        DelayEqualBuildPlattons = {'MobileExperimental', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExperimental' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.20, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 8, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'T4LandExperimental2' },
                Location = 'LocationType',
            }
        }
    },

    -- FLOOD: eco in overflow (mass storage > 30%) → spam senza limite sperimentali
    Builder {
        BuilderName = 'OWPlus Exp Land Flood',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18200,
        InstanceCount = 25,
        DelayEqualBuildPlattons = {'MobileExperimental', 1},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExperimental' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.30, 0.20 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                BuildStructures = { 'T4LandExperimental1' },
                Location = 'LocationType',
            }
        }
    },
}

-- ============================================================ --
-- ==           AIR EXPERIMENTALS — Aria T4                  == --
-- ============================================================ --
BuilderGroup {
    BuilderGroupName = 'OWPlus Experimental Air',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'OWPlus Exp Air First',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18300,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExperimental', 5},
        BuilderConditions = {
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExperimental' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.20, 0.10 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                BuildStructures = { 'T4AirExperimental1' },
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Air Scale',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18200,
        InstanceCount = 3,
        DelayEqualBuildPlattons = {'MobileExperimental', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExperimental' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.35, 0.20 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                BuildStructures = { 'T4AirExperimental1' },
                Location = 'LocationType',
            }
        }
    },
}

-- ============================================================ --
-- ==   ASSIST SPERIMENTALI MOBILI — Fix bug Uveso           == --
-- ==   Uveso UC123 Assistees usa AssisteeType='Structure'   == --
-- ==   che NON trova T4 mobili (MOBILE, non STRUCTURE).     == --
-- ==   AssisteeType='Engineer' trova l'ingegnere che        == --
-- ==   costruisce il T4 — funziona per terra E aria.       == --
-- ============================================================ --
BuilderGroup {
    BuilderGroupName = 'OWPlus Assist Experimentals',
    BuildersType = 'PlatoonFormBuilder',

    -- T3 engineers assist qualsiasi T4 mobile (Colossus, Illuminate Pride, CZAR, Ahwassa...)
    Builder {
        BuilderName = 'OWPlus T3 Assist Exp Mobile',
        PlatoonTemplate = 'T3EngineerAssistNoSUB',
        Priority = 15000,
        InstanceCount = 30,
        BuilderConditions = {
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.05 } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 150,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE'},
                AssistUntilFinished = true,
                AssistClosestUnit = true,
                Time = 0,
            }
        },
    },

    -- T2 engineers assist T4 mobile (supporto extra quando tanti T4 in cantiere)
    Builder {
        BuilderName = 'OWPlus T2 Assist Exp Mobile',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 14900,
        InstanceCount = 20,
        BuilderConditions = {
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.05 } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.ENGINEER * categories.TECH2 - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 150,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE'},
                AssistUntilFinished = true,
                AssistClosestUnit = true,
                Time = 0,
            }
        },
    },
}
