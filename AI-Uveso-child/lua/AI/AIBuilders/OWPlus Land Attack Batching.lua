-- Override di 'U123 Land Formers EnemyZone' (stock AI-Uveso, mai toccato dal
-- child prima d'ora) — sess.100. Oggi questo gruppo forma i plotoni offensivi
-- terra in streaming: bastano 1-2 unita' libere per partire verso la base
-- nemica. Questo file li sostituisce con varianti "a batching" (taglie
-- minime molto piu' alte), lasciando invariata tutta la logica di targeting
-- (BuilderData/BuilderConditions copiati fedeli dall'originale).
--
-- Nessuna logica di accumulo custom: il motore nativo forma gia' un plotone
-- solo al raggiungimento del minimo del PlatoonTemplate — alzare quel minimo
-- basta, niente PlatoonMerger/holding-pool parallelo (vedi piano sess.100).
--
-- Flag di vero fallback: con OWPlusLandAttackBatchingDisabled = true, i 5
-- Builder ORIGINALI (fedeli, incluso il loro PriorityFunction/NoRush1stPhase
-- originale) tornano attivi e i 5 nuovi "batch" si spengono — comportamento
-- identico a oggi, stesso pattern di OWPlusOutpostExpansionDisabled.
--
-- Riferimento originale: AI-Uveso/lua/AI/AIBuilders/Mobile Land.lua:1131-1319
-- Nuovi PlatoonTemplate: 'OWPlus PlatoonTemplates Land Attack.lua'

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local _, BaseMilitaryZone, BaseEnemyZone = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua').GetDangerZoneRadii(true)

-- true = disattiva il batching e torna al comportamento originale (streaming)
local OWPlusLandAttackBatchingDisabled = false

-- Sess.100 parte 2: i 5 builder "batch" condividono TUTTI la stessa priorita'
-- statica (invece di una gerarchia fissa a favore del piu' grande) + lo stesso
-- gruppo di cooldown nativo 'DelayEqualBuildPlattons'/'CheckBuildPlattonDelay'
-- (meccanismo nativo gia' usato in Uveso _Null.lua e nel nostro stesso
-- 'OWPlus Override Mobile Land.lua:514' per gli Scout - NON e' un sistema
-- custom). Appena UNO dei 5 forma un plotone, tutti restano bloccati per
-- OWPlusLandAttackBatchCooldown secondi, dando tempo al pool di riaccumulare;
-- alla riapertura, a parita' di priorita', quale soglia scatta dipende da
-- quali min sono gia' soddisfatti in quel momento - varieta' voluta
-- dall'utente invece di favorire sempre il plotone piu' grande possibile.
local OWPlusLandAttackBatchPriority = 150
local OWPlusLandAttackBatchCooldownGroup = 'OWPlusLandAttackBatch'
local OWPlusLandAttackBatchCooldownSeconds = 30

-- Attivo solo quando il batching e' DISATTIVATO (fallback ai builder originali)
local function OWPlusFallbackPriority(basePriority)
    return function(self, aiBrain)
        if not OWPlusLandAttackBatchingDisabled then
            return 0
        end
        if aiBrain.PriorityManager.NoRush1stPhaseActive then
            return 0
        end
        return basePriority
    end
end

-- Attivo solo quando il batching e' ATTIVO (default) - i nuovi builder grandi
local function OWPlusBatchPriority(basePriority)
    return function(self, aiBrain)
        if OWPlusLandAttackBatchingDisabled then
            return 0
        end
        if aiBrain.PriorityManager.NoRush1stPhaseActive then
            return 0
        end
        return basePriority
    end
end

BuilderGroup {
    BuilderGroupName = 'U123 Land Formers EnemyZone',
    BuildersType = 'PlatoonFormBuilder',

    -- =========================================================== --
    -- ==  1. Unprotected Mass Land (raid rapido massa/ingegneri) == --
    -- =========================================================== --
    Builder {
        BuilderName = 'U123 Enemy Unprotected Mass Land 2 2',
        PlatoonTemplate = 'LandAttackHuntUveso 2 2',
        Priority = 230,
        InstanceCount = 1,
        PriorityFunction = OWPlusFallbackPriority(260),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = true,
            AggressiveMove = true,
            AttackEnemyStrength = 100,
            TargetSearchCategory = categories.STRUCTURE + categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {},
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Enemy Unprotected Mass Land Batch 10',
        PlatoonTemplate = 'LandAttackHuntUveso 10 10',        -- template nativo, riusato (identico alla taglia voluta)
        Priority = OWPlusLandAttackBatchPriority,
        InstanceCount = 1,
        PriorityFunction = OWPlusBatchPriority(OWPlusLandAttackBatchPriority),
        DelayEqualBuildPlattons = { OWPlusLandAttackBatchCooldownGroup, OWPlusLandAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = true,
            AggressiveMove = true,
            AttackEnemyStrength = 100,
            TargetSearchCategory = categories.STRUCTURE + categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusLandAttackBatchCooldownGroup } },
        },
        BuilderType = 'Any',
    },

    -- =========================================================== --
    -- ==  2. Enemy Intercept (spinta offensiva principale)      == --
    -- =========================================================== --
    Builder {
        BuilderName = 'U123 Enemy Intercept 15 30 (200)',
        PlatoonTemplate = 'LandAttackHuntUveso 15 30',
        Priority = 140,
        InstanceCount = 10,
        PriorityFunction = OWPlusFallbackPriority(140),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = false,
            AggressiveMove = true,
            AttackEnemyStrength = 200,
            TargetSearchCategory = categories.MOBILE * categories.LAND - categories.SCOUT,
            MoveToCategories = {
                categories.EXPERIMENTAL * categories.LAND,
                categories.MOBILE * categories.LAND * categories.INDIRECTFIRE - categories.SCOUT,
                categories.MOBILE * categories.LAND * categories.DIRECTFIRE - categories.SCOUT,
                categories.MOBILE * categories.LAND * categories.ANTIAIR,
                categories.STRUCTURE * categories.ANTIAIR,
                categories.STRUCTURE * categories.DEFENSE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
            { UCBC, 'UnitsGreaterAtEnemy', { 0, categories.MOBILE * categories.LAND - categories.SCOUT } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Enemy Intercept Batch 30 40',
        PlatoonTemplate = 'OWPlusLandAttackHunt 30 40',
        Priority = OWPlusLandAttackBatchPriority,
        InstanceCount = 10,
        PriorityFunction = OWPlusBatchPriority(OWPlusLandAttackBatchPriority),
        DelayEqualBuildPlattons = { OWPlusLandAttackBatchCooldownGroup, OWPlusLandAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = false,
            AggressiveMove = true,
            AttackEnemyStrength = 200,
            TargetSearchCategory = categories.MOBILE * categories.LAND - categories.SCOUT,
            MoveToCategories = {
                categories.EXPERIMENTAL * categories.LAND,
                categories.MOBILE * categories.LAND * categories.INDIRECTFIRE - categories.SCOUT,
                categories.MOBILE * categories.LAND * categories.DIRECTFIRE - categories.SCOUT,
                categories.MOBILE * categories.LAND * categories.ANTIAIR,
                categories.STRUCTURE * categories.ANTIAIR,
                categories.STRUCTURE * categories.DEFENSE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
            { UCBC, 'UnitsGreaterAtEnemy', { 0, categories.MOBILE * categories.LAND - categories.SCOUT } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusLandAttackBatchCooldownGroup } },
        },
        BuilderType = 'Any',
    },

    -- =========================================================== --
    -- ==  3. Unprotected Land (raid cauto, AttackEnemyStrength=25) == --
    -- =========================================================== --
    Builder {
        BuilderName = 'U123 Enemy Unprotected Land 1 2',
        PlatoonTemplate = 'LandAttackHuntUveso 2 2',
        Priority = 130,
        InstanceCount = 1,
        PriorityFunction = OWPlusFallbackPriority(130),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = true,
            AggressiveMove = true,
            AttackEnemyStrength = 25,
            TargetSearchCategory = categories.LAND - categories.STATIONASSISTPOD - categories.POD,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Enemy Unprotected Land Batch 10',
        PlatoonTemplate = 'LandAttackHuntUveso 10 10',        -- template nativo, riusato
        Priority = OWPlusLandAttackBatchPriority,
        InstanceCount = 1,
        PriorityFunction = OWPlusBatchPriority(OWPlusLandAttackBatchPriority),
        DelayEqualBuildPlattons = { OWPlusLandAttackBatchCooldownGroup, OWPlusLandAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = true,
            AggressiveMove = true,
            AttackEnemyStrength = 25,
            TargetSearchCategory = categories.LAND - categories.STATIONASSISTPOD - categories.POD,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.ENGINEER - categories.STATIONASSISTPOD - categories.POD,
                categories.STRUCTURE * categories.EXPERIMENTAL * categories.SHIELD,
                categories.STRUCTURE * categories.ARTILLERY,
                categories.STRUCTURE * categories.NUKE,
                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                categories.STRUCTURE * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3,
                categories.STRUCTURE * categories.DEFENSE * categories.TECH3,
                categories.FACTORY * categories.TECH3,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusLandAttackBatchCooldownGroup } },
        },
        BuilderType = 'Any',
    },

    -- =========================================================== --
    -- ==  4. AntiDef+mex Early (artiglieria contro difese/mex)  == --
    -- =========================================================== --
    Builder {
        BuilderName = 'U123 AntiDef+mex Early 1 20 (300)',
        PlatoonTemplate = 'LandAttackHuntUveso Arty 1 20',
        Priority = 120,
        InstanceCount = 6,
        PriorityFunction = OWPlusFallbackPriority(120),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = false,
            AggressiveMove = true,
            AttackEnemyStrength = 300,
            TargetSearchCategory = categories.DEFENSE + categories.MASSEXTRACTION,
            MoveToCategories = {
                categories.DEFENSE,
            },
            WeaponTargetCategories = {
                categories.DEFENSE - categories.ANTIAIR,
                categories.DEFENSE,
                categories.MASSEXTRACTION,
                categories.ALLUNITS - categories.SCOUT,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
            { UCBC, 'UnitsGreaterAtEnemy', { 0, categories.DEFENSE } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus AntiDef+mex Batch 15 20',
        PlatoonTemplate = 'OWPlusLandAttackHunt Arty 15 20',
        Priority = OWPlusLandAttackBatchPriority,
        InstanceCount = 6,
        PriorityFunction = OWPlusBatchPriority(OWPlusLandAttackBatchPriority),
        DelayEqualBuildPlattons = { OWPlusLandAttackBatchCooldownGroup, OWPlusLandAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = false,
            AggressiveMove = true,
            AttackEnemyStrength = 300,
            TargetSearchCategory = categories.DEFENSE + categories.MASSEXTRACTION,
            MoveToCategories = {
                categories.DEFENSE,
            },
            WeaponTargetCategories = {
                categories.DEFENSE - categories.ANTIAIR,
                categories.DEFENSE,
                categories.MASSEXTRACTION,
                categories.ALLUNITS - categories.SCOUT,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
            { UCBC, 'UnitsGreaterAtEnemy', { 0, categories.DEFENSE } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusLandAttackBatchCooldownGroup } },
        },
        BuilderType = 'Any',
    },

    -- =========================================================== --
    -- ==  5. AntiMass Early (attacco a massa/difese nemiche)    == --
    -- =========================================================== --
    Builder {
        BuilderName = 'U123 AntiMass Early 6 8',
        PlatoonTemplate = 'LandAttackHuntUveso 6 8',
        Priority = 110,
        InstanceCount = 6,
        PriorityFunction = OWPlusFallbackPriority(110),
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = true,
            AggressiveMove = true,
            AttackEnemyStrength = 100,
            TargetSearchCategory = categories.MASSEXTRACTION + categories.DEFENSE,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.DEFENSE,
            },
            WeaponTargetCategories = {
                categories.DEFENSE - categories.ANTIAIR,
                categories.DEFENSE,
                categories.MASSEXTRACTION,
                categories.ALLUNITS - categories.SCOUT,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
            { UCBC, 'UnitsGreaterAtEnemy', { 0, categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus AntiMass Batch 20 25',
        PlatoonTemplate = 'OWPlusLandAttackHunt 20 25',
        Priority = OWPlusLandAttackBatchPriority,
        InstanceCount = 6,
        PriorityFunction = OWPlusBatchPriority(OWPlusLandAttackBatchPriority),
        DelayEqualBuildPlattons = { OWPlusLandAttackBatchCooldownGroup, OWPlusLandAttackBatchCooldownSeconds },
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            RequireTransport = true,
            AggressiveMove = true,
            AttackEnemyStrength = 100,
            TargetSearchCategory = categories.MASSEXTRACTION + categories.DEFENSE,
            MoveToCategories = {
                categories.MASSEXTRACTION,
                categories.DEFENSE,
            },
            WeaponTargetCategories = {
                categories.DEFENSE - categories.ANTIAIR,
                categories.DEFENSE,
                categories.MASSEXTRACTION,
                categories.ALLUNITS - categories.SCOUT,
            },
        },
        BuilderConditions = {
            { UCBC, 'EnemyUnitsLessAtLocationRadius', { BaseMilitaryZone, 'LocationType', 1, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
            { UCBC, 'UnitsGreaterAtEnemy', { 0, categories.MASSEXTRACTION } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusLandAttackBatchCooldownGroup } },
        },
        BuilderType = 'Any',
    },
}
