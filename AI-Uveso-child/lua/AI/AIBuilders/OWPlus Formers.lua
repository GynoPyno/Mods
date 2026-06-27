-- OWPlus Formers.lua
-- Priority 240-500: bypassa i former Uveso che controllano NoRush1stPhaseActive (prio 60-260).
-- Obiettivo: mandare le unità all'attacco appena costruite, senza aspettare la logica NoRush.
--
-- Uveso former standard (land: 60-260, air experimental: 70-90):
--   tutti hanno PriorityFunction che restituisce 0 se NoRush1stPhaseActive = true.
--   Con NoRush attivo, nessuna unità viene mandata all'attacco.
--
-- OWPlus former (nessun gate NoRush):
--   - Sperimentali terra: prio 480-500 → appena 1 pronto, attacca
--   - Sperimentali aria: prio 460-470 → stessa logica
--   - Terra T1/T2/T3: prio 270-300 → gruppi frequenti, T1 Rush anche con 2 unità
--   - Aria caccia/gunship: prio 240-260 → formazioni per caccia e gunship

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'
local BasePanicZone, BaseMilitaryZone, BaseEnemyZone = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua').GetDangerZoneRadii()

-- ============================================================ --
-- ==      SPERIMENTALI TERRA — Attacco immediato            == --
-- ============================================================ --
BuilderGroup {
    BuilderGroupName = 'OWPlus Experimental Formers',
    BuildersType = 'PlatoonFormBuilder',

    -- SOLO: appena 1 sperimentale terra disponibile → manda subito
    Builder {
        BuilderName = 'OWPlus Exp Land Solo Attack',
        PlatoonTemplate = 'T4ExperimentalLandUveso 1 1',
        Priority = 500,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            DirectMoveEnemyBase = true,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 1000000,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
            MoveToCategories = {
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                categories.OPTICS,
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.NUKE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
        },
        BuilderType = 'Any',
    },

    -- DUO: quando ci sono 2+ sperimentali → manda in coppia
    Builder {
        BuilderName = 'OWPlus Exp Land Duo Attack',
        PlatoonTemplate = 'T4ExperimentalLandGroupUveso 2 2',
        Priority = 490,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            DirectMoveEnemyBase = true,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 1000000,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
            MoveToCategories = {
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                categories.OPTICS,
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.NUKE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
        },
        BuilderType = 'Any',
    },

    -- FLOOD: 3+ sperimentali → orde di 3-5
    Builder {
        BuilderName = 'OWPlus Exp Land Flood Attack',
        PlatoonTemplate = 'T4ExperimentalLandGroupUveso 3 5',
        Priority = 480,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            DirectMoveEnemyBase = true,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 1000000,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
            MoveToCategories = {
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                categories.OPTICS,
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.NUKE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
        },
        BuilderType = 'Any',
    },

    -- AIR SOLO: appena 1 sperimentale aria disponibile → attacca strutture
    Builder {
        BuilderName = 'OWPlus Exp Air Solo Attack',
        PlatoonTemplate = 'U4-ExperimentalInterceptor 1 1',
        Priority = 470,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 1000000,
            IgnorePathing = true,
            TargetSearchCategory = categories.STRUCTURE,
            TargetHug = true,
            MoveToCategories = {
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                categories.OPTICS,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.NUKE,
                categories.FACTORY * categories.TECH3,
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH3,
                categories.STRUCTURE,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE * categories.AIR } },
        },
        BuilderType = 'Any',
    },

    -- AIR GROUP: 3+ sperimentali aria → orde di 3-8
    Builder {
        BuilderName = 'OWPlus Exp Air Group Attack',
        PlatoonTemplate = 'U4-ExperimentalInterceptor 3 8',
        Priority = 460,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 1000000,
            IgnorePathing = true,
            TargetSearchCategory = categories.STRUCTURE,
            TargetHug = true,
            MoveToCategories = {
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                categories.OPTICS,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.NUKE,
                categories.FACTORY * categories.TECH3,
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH3,
                categories.STRUCTURE,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.EXPERIMENTAL * categories.MOBILE * categories.AIR } },
        },
        BuilderType = 'Any',
    },
}

-- ============================================================ --
-- ==     TERRA T1/T2/T3 — Gruppi frequenti senza NoRush     == --
-- ============================================================ --
BuilderGroup {
    BuilderGroupName = 'OWPlus Land Formers Aggressive',
    BuildersType = 'PlatoonFormBuilder',

    -- Piccoli gruppi frequenti (min 2, max 5) — 3+ unità combattimento qualsiasi tier
    Builder {
        BuilderName = 'OWPlus Land Intercept Small',
        PlatoonTemplate = 'LandAttackInterceptUveso 2 5',
        Priority = 300,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            DirectMoveEnemyBase = true,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 1000000,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
            MoveToCategories = {
                categories.STRUCTURE * categories.MASSEXTRACTION,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.FACTORY,
                categories.STRUCTURE * categories.DEFENSE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.MOBILE * categories.LAND * (categories.TECH1 + categories.TECH2 + categories.TECH3) - categories.EXPERIMENTAL - categories.ENGINEER } },
        },
        BuilderType = 'Any',
    },

    -- Gruppi medi (min 5, max 30) — attacchi più consistenti
    Builder {
        BuilderName = 'OWPlus Land Attack Medium',
        PlatoonTemplate = 'LandAttackHuntUveso 5 30',
        Priority = 290,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            DirectMoveEnemyBase = true,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 1000000,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
            MoveToCategories = {
                categories.STRUCTURE * categories.MASSEXTRACTION,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.FACTORY,
                categories.STRUCTURE * categories.DEFENSE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 4, categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT } },
        },
        BuilderType = 'Any',
    },

    -- T1 RUSH: 2 T1 bastano per la prima incursione early-game
    Builder {
        BuilderName = 'OWPlus Land T1 Rush',
        PlatoonTemplate = 'LandAttackInterceptUveso 2 3',
        Priority = 280,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            DirectMoveEnemyBase = true,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 1000000,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
            MoveToCategories = {
                categories.STRUCTURE * categories.MASSEXTRACTION,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.FACTORY,
                categories.STRUCTURE * categories.DEFENSE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND * categories.TECH1 - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT } },
        },
        BuilderType = 'Any',
    },
}

-- ============================================================ --
-- ==   ARIA T1/T2/T3 — Caccia e Gunship senza NoRush        == --
-- ============================================================ --
BuilderGroup {
    BuilderGroupName = 'OWPlus Air Formers',
    BuildersType = 'PlatoonFormBuilder',

    -- CACCIA: 2+ fighter → attacca aria nemica e strutture
    Builder {
        BuilderName = 'OWPlus Air Fighter Small',
        PlatoonTemplate = 'U123-Fighter-Intercept 1 30',
        Priority = 260,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 1000000,
            IgnorePathing = true,
            TargetHug = true,
            TargetSearchCategory = categories.ALLUNITS,
            MoveToCategories = {
                categories.MOBILE * categories.AIR * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.FACTORY * categories.AIR,
                categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH3,
                categories.STRUCTURE,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR - categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
    },

    -- GUNSHIP SOLO: 1+ gunship → incursione rapida su strutture terra
    Builder {
        BuilderName = 'OWPlus Air Gunship Solo',
        PlatoonTemplate = 'U123-Gunship-Intercept 1 2',
        Priority = 250,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 1000000,
            IgnorePathing = true,
            TargetHug = true,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
            MoveToCategories = {
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH3,
                categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                categories.FACTORY,
                categories.STRUCTURE * categories.MASSEXTRACTION,
                categories.STRUCTURE * categories.DEFENSE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.MOBILE * categories.AIR * categories.GROUNDATTACK - categories.EXPERIMENTAL - categories.HIGHALTAIR - categories.ANTINAVY } },
        },
        BuilderType = 'Any',
    },

    -- GUNSHIP GROUP: 3+ gunship → attacchi di gruppo più pesanti
    Builder {
        BuilderName = 'OWPlus Air Gunship Group',
        PlatoonTemplate = 'U123-Gunship-Intercept 3 5',
        Priority = 240,
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 1000000,
            IgnorePathing = true,
            TargetHug = true,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
            MoveToCategories = {
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH3,
                categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                categories.FACTORY,
                categories.STRUCTURE * categories.MASSEXTRACTION,
                categories.STRUCTURE * categories.DEFENSE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.MOBILE * categories.AIR * categories.GROUNDATTACK - categories.EXPERIMENTAL - categories.HIGHALTAIR - categories.ANTINAVY } },
        },
        BuilderType = 'Any',
    },
}
