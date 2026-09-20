-- Override di 'U123 Air Formers EnemyZone' (stock AI-Uveso, mai toccato dal
-- child prima d'ora) — sess.100 seconda parte. Consolida i 9 Builder nativi
-- (2 AntiAir + 7 AntiLand, scopi tattici distinti) in 2 nuovi ruoli a
-- batching: AntiAir (caccia, 3 taglie: 15/25/35) e AntiGround (bombardieri+
-- cannoniere insieme, 2 taglie: 15/25). Stessa filosofia di
-- 'OWPlus Land Attack Batching.lua': nessuna logica di accumulo custom, solo
-- dati (template + builder) — il motore forma gia' un plotone appena
-- raggiunto il minimo del template.
--
-- Applicato FIN DA SUBITO il fix scoperto per terra (Conoscenze_AI_54.md
-- §54.5-54.6): priorita' statica UNIFORME sui builder batch + cooldown
-- nativo condiviso (DelayEqualBuildPlattons/CheckBuildPlattonDelay) tra le
-- taglie dello stesso ruolo, per evitare che la taglia piu' piccola dreni
-- sempre il pool prima che le piu' grandi possano accumulare. AntiAir e
-- AntiGround usano gruppi di cooldown SEPARATI (pool di categoria disgiunti,
-- non competono tra loro).
--
-- Flag di vero fallback: con OWPlusAirAttackBatchingDisabled = true, i 9
-- Builder ORIGINALI (fedeli, incluso il loro PriorityFunction/NoRush1stPhase
-- originale) tornano attivi e i 5 nuovi "batch" si spengono.
--
-- 3 dei 9 originali hanno un secondo gate 'HaveGreaterThanUnitsWithCategory'
-- (non formare finche' non hai gia' 30-60 unita' di quel tipo) scollegato
-- dalla taglia del proprio template — NON riportato sui nuovi builder batch
-- (renderebbe la taglia da 15 quasi inutile, bloccata fino a 60 unita' gia'
-- esistenti). Mantenuto intatto sui fallback nativi.
--
-- Riferimento originale: AI-Uveso/lua/AI/AIBuilders/Mobile Air.lua:2486-2901
-- Nuovi PlatoonTemplate: 'OWPlus PlatoonTemplates Air Attack.lua'

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local _, BaseMilitaryZone, BaseEnemyZone = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua').GetDangerZoneRadii()

-- true = disattiva il batching e torna al comportamento originale (streaming)
local OWPlusAirAttackBatchingDisabled = false

-- Sess.100 parte 3 (fix competizione ArmyPool): 75 perdeva sistematicamente
-- contro gli altri BuilderGroup nativi PlatoonFormBuilder attivi in parallelo
-- (PanicZone aria=90, MilitaryZone aria fino a 92 'Military AntiArty',
-- TorpedoBomber Formers fino a 90) -- l'ArmyPool reale (Conoscenze_AI_54.md
-- §54.6, misurato con GetNumCategoryUnits) restava quasi sempre a 0 anche con
-- decine di unita' possedute fisicamente, perche' quei gruppi le reclutavano
-- prima di noi. 95 = sopra il massimo dei concorrenti reali (92) confermato
-- nel codice nativo, senza eccedere.
local OWPlusAirAttackBatchPriority = 95
local OWPlusAirAttackBatchCooldownAntiAir = 'OWPlusAirAttackBatchAntiAir'         -- le 3 taglie AntiAir condividono
local OWPlusAirAttackBatchCooldownAntiGround = 'OWPlusAirAttackBatchAntiGround'   -- le 2 taglie AntiGround condividono
local OWPlusAirAttackBatchCooldownSeconds = 30

-- Attivo solo quando il batching e' DISATTIVATO (fallback ai builder originali)
local function OWPlusFallbackPriority(basePriority)
    return function(self, aiBrain)
        if not OWPlusAirAttackBatchingDisabled then
            return 0
        end
        if aiBrain.PriorityManager.NoRush1stPhaseActive then
            return 0
        end
        return basePriority
    end
end

-- Attivo solo quando il batching e' ATTIVO (default) - i nuovi builder consolidati
local function OWPlusBatchPriority(basePriority)
    return function(self, aiBrain)
        if OWPlusAirAttackBatchingDisabled then
            return 0
        end
        if aiBrain.PriorityManager.NoRush1stPhaseActive then
            return 0
        end
        return basePriority
    end
end

BuilderGroup {
    BuilderGroupName = 'U123 Air Formers EnemyZone',
    BuildersType = 'PlatoonFormBuilder',

    -- =========================================================== --
    -- ==  1-2. AntiAir originali (fedeli)                       == --
    -- =========================================================== --
    Builder {
        BuilderName = 'U123 Enemy ScoutHunter EnemyZone 1 2',
        PlatoonTemplate = 'U123-Fighter-Intercept 1 2',
        PlatoonAddBehaviors = { 'AirUnitRefit' },
        Priority = 66,
        InstanceCount = 1,
        PriorityFunction = OWPlusFallbackPriority(66),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AttackEnemyStrength = 200,
            AggressiveMove = false,
            IgnorePathing = true,
            TargetSearchCategory = categories.AIR * categories.SCOUT,
            MoveToCategories = {
                categories.SCOUT,
            },
            WeaponTargetCategories = {
                categories.SCOUT,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 60, categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR - categories.EXPERIMENTAL - categories.SCOUT } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U123 Enemy AntiAir EnemyZone',
        PlatoonTemplate = 'U123-Fighter-Intercept 3 5',
        PlatoonAddBehaviors = { 'AirUnitRefit' },
        Priority = 64,
        InstanceCount = 2,
        PriorityFunction = OWPlusFallbackPriority(64),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AttackEnemyStrength = 80,
            AggressiveMove = true,
            IgnorePathing = false,
            TargetSearchCategory = categories.AIR - categories.SCOUT - categories.POD,
            MoveToCategories = {
                categories.MOBILE * categories.EXPERIMENTAL * categories.AIR,
                categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR,
                categories.MOBILE * categories.AIR * categories.ANTIAIR,
                categories.MOBILE * categories.AIR * categories.BOMBER,
                categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS,
                categories.MOBILE * categories.AIR * categories.GROUNDATTACK,
                categories.MOBILE * categories.AIR * categories.DIRECTFIRE,
                categories.MOBILE * categories.AIR * categories.INDIRECTFIRE,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 60, categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR - categories.EXPERIMENTAL - categories.SCOUT } },
        },
        BuilderType = 'Any',
    },

    -- =========================================================== --
    -- ==  3-9. AntiLand originali (fedeli)                      == --
    -- =========================================================== --
    Builder {
        BuilderName = 'U12 Enemy AntiMass Gunship',
        PlatoonTemplate = 'U12-Gunship-Intercept 3 5',
        Priority = 67,
        InstanceCount = 4,
        PriorityFunction = OWPlusFallbackPriority(67),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 33,
            IgnorePathing = false,
            TargetSearchCategory = categories.ALLUNITS - categories.SCOUT - categories.POD,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.OPTICS,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.ALLUNITS,
            },
            WeaponTargetCategories = {
                categories.MASSEXTRACTION,
                categories.COMMAND,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.SHIELD,
                categories.ANTIAIR,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U12 Enemy AntiMass Bomber 3 5',
        PlatoonTemplate = 'U12-Bomber-Intercept 3 5',
        Priority = 67,
        InstanceCount = 3,
        PriorityFunction = OWPlusFallbackPriority(67),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 33,
            IgnorePathing = false,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR - categories.SCOUT,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.OPTICS,
            },
            WeaponTargetCategories = {
                categories.MASSEXTRACTION,
                categories.SHIELD,
                categories.ANTIAIR,
                categories.COMMAND,
                categories.INDIRECTFIRE,
                categories.DIRECTFIRE,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U12 Enemy Unprotected Gunship 3 5',
        PlatoonTemplate = 'U12-Gunship-Intercept 3 5',
        Priority = 68,
        InstanceCount = 3,
        PriorityFunction = OWPlusFallbackPriority(68),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 25,
            IgnorePathing = false,
            TargetSearchCategory = categories.ALLUNITS - categories.SCOUT - categories.POD,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.OPTICS,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
            WeaponTargetCategories = {
                categories.MASSEXTRACTION,
                categories.COMMAND,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.SHIELD,
                categories.ANTIAIR,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U12 Enemy Unprotected Bomber 1 3',
        PlatoonTemplate = 'U12-Bomber-Intercept 1 3',
        Priority = 68,
        InstanceCount = 2,
        PriorityFunction = OWPlusFallbackPriority(68),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 25,
            IgnorePathing = false,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR - categories.SCOUT,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.OPTICS,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
            WeaponTargetCategories = {
                categories.COMMAND,
                categories.ANTIAIR,
                categories.OPTICS,
                categories.MASSEXTRACTION,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.SHIELD,
                categories.ANTIAIR,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U123 Enemy AntiGround Bomber',
        PlatoonTemplate = 'U123-Bomber-Intercept 15 20',
        PlatoonAddBehaviors = { 'AirUnitRefit' },
        Priority = 62,
        InstanceCount = 1,
        PriorityFunction = OWPlusFallbackPriority(62),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 100,
            IgnorePathing = false,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR - categories.SCOUT,
            MoveToCategories = {
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.OPTICS,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
            WeaponTargetCategories = {
                categories.COMMAND,
                categories.ANTIAIR,
                categories.OPTICS,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 30, categories.MOBILE * categories.AIR * categories.BOMBER - categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U123 Enemy AntiGround Gunship',
        PlatoonTemplate = 'U123-Gunship-Intercept 15 20',
        PlatoonAddBehaviors = { 'AirUnitRefit' },
        Priority = 60,
        InstanceCount = 1,
        PriorityFunction = OWPlusFallbackPriority(60),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 100,
            IgnorePathing = false,
            TargetSearchCategory = categories.ALLUNITS - categories.SCOUT - categories.POD,
            MoveToCategories = {
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH3,
                categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH2,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.OPTICS,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
            WeaponTargetCategories = {
                categories.COMMAND,
                categories.ANTIAIR,
                categories.OPTICS,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 30, categories.MOBILE * categories.AIR * categories.GROUNDATTACK - categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U123 Enemy AntiEngineer Bomber',
        PlatoonTemplate = 'U123-Bomber-Intercept 1 2',
        PlatoonAddBehaviors = { 'AirUnitRefit' },
        Priority = 100,
        InstanceCount = 2,
        PriorityFunction = OWPlusFallbackPriority(100),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = false,
            AttackEnemyStrength = 100,
            IgnorePathing = false,
            TargetSearchCategory = categories.ENGINEER + categories.MASSEXTRACTION,
            MoveToCategories = {
                categories.ENGINEER,
                categories.MASSEXTRACTION,
                categories.ALLUNITS,
            },
            WeaponTargetCategories = {
                categories.ENGINEER,
                categories.MASSEXTRACTION,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {},
        BuilderType = 'Any',
    },

    -- =========================================================== --
    -- ==  10-12. AntiAir Batch (nuovi, 3 taglie: 15/25/35)      == --
    -- =========================================================== --
    Builder {
        BuilderName = 'OWPlus Enemy AntiAir Batch 15',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiAir 15',
        Priority = OWPlusAirAttackBatchPriority,
        InstanceCount = 3,
        PriorityFunction = OWPlusBatchPriority(OWPlusAirAttackBatchPriority),
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusAirAttackBatchCooldownAntiAir, OWPlusAirAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AttackEnemyStrength = 80,
            AggressiveMove = true,
            IgnorePathing = false,
            TargetSearchCategory = categories.AIR - categories.SCOUT - categories.POD,
            MoveToCategories = {
                categories.MOBILE * categories.EXPERIMENTAL * categories.AIR,
                categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR,
                categories.MOBILE * categories.AIR * categories.ANTIAIR,
                categories.MOBILE * categories.AIR * categories.BOMBER,
                categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS,
                categories.MOBILE * categories.AIR * categories.GROUNDATTACK,
                categories.MOBILE * categories.AIR * categories.DIRECTFIRE,
                categories.MOBILE * categories.AIR * categories.INDIRECTFIRE,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusAirAttackBatchCooldownAntiAir } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Enemy AntiAir Batch 25',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiAir 25',
        Priority = OWPlusAirAttackBatchPriority,
        InstanceCount = 2,
        PriorityFunction = OWPlusBatchPriority(OWPlusAirAttackBatchPriority),
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusAirAttackBatchCooldownAntiAir, OWPlusAirAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AttackEnemyStrength = 80,
            AggressiveMove = true,
            IgnorePathing = false,
            TargetSearchCategory = categories.AIR - categories.SCOUT - categories.POD,
            MoveToCategories = {
                categories.MOBILE * categories.EXPERIMENTAL * categories.AIR,
                categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR,
                categories.MOBILE * categories.AIR * categories.ANTIAIR,
                categories.MOBILE * categories.AIR * categories.BOMBER,
                categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS,
                categories.MOBILE * categories.AIR * categories.GROUNDATTACK,
                categories.MOBILE * categories.AIR * categories.DIRECTFIRE,
                categories.MOBILE * categories.AIR * categories.INDIRECTFIRE,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusAirAttackBatchCooldownAntiAir } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Enemy AntiAir Batch 35',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiAir 35',
        Priority = OWPlusAirAttackBatchPriority,
        InstanceCount = 1,
        PriorityFunction = OWPlusBatchPriority(OWPlusAirAttackBatchPriority),
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusAirAttackBatchCooldownAntiAir, OWPlusAirAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AttackEnemyStrength = 80,
            AggressiveMove = true,
            IgnorePathing = false,
            TargetSearchCategory = categories.AIR - categories.SCOUT - categories.POD,
            MoveToCategories = {
                categories.MOBILE * categories.EXPERIMENTAL * categories.AIR,
                categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR,
                categories.MOBILE * categories.AIR * categories.ANTIAIR,
                categories.MOBILE * categories.AIR * categories.BOMBER,
                categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS,
                categories.MOBILE * categories.AIR * categories.GROUNDATTACK,
                categories.MOBILE * categories.AIR * categories.DIRECTFIRE,
                categories.MOBILE * categories.AIR * categories.INDIRECTFIRE,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusAirAttackBatchCooldownAntiAir } },
        },
        BuilderType = 'Any',
    },

    -- =========================================================== --
    -- ==  13-14. AntiGround Batch (nuovi, 2 taglie: 15/25)      == --
    -- =========================================================== --
    Builder {
        BuilderName = 'OWPlus Enemy AntiGround Batch 15',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiGround 15',
        Priority = OWPlusAirAttackBatchPriority,
        InstanceCount = 2,
        PriorityFunction = OWPlusBatchPriority(OWPlusAirAttackBatchPriority),
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusAirAttackBatchCooldownAntiGround, OWPlusAirAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 60,
            IgnorePathing = false,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR - categories.SCOUT - categories.POD,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.OPTICS,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
            WeaponTargetCategories = {
                categories.COMMAND,
                categories.ANTIAIR,
                categories.OPTICS,
                categories.MASSEXTRACTION,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.SHIELD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusAirAttackBatchCooldownAntiGround } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Enemy AntiGround Batch 25',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiGround 25',
        Priority = OWPlusAirAttackBatchPriority,
        InstanceCount = 1,
        PriorityFunction = OWPlusBatchPriority(OWPlusAirAttackBatchPriority),
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusAirAttackBatchCooldownAntiGround, OWPlusAirAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 60,
            IgnorePathing = false,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR - categories.SCOUT - categories.POD,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.OPTICS,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
            WeaponTargetCategories = {
                categories.COMMAND,
                categories.ANTIAIR,
                categories.OPTICS,
                categories.MASSEXTRACTION,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.SHIELD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusAirAttackBatchCooldownAntiGround } },
        },
        BuilderType = 'Any',
    },
}
