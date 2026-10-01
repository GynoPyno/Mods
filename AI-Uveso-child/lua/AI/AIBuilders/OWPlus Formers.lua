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
-- ==  BATCHING MAIN (sess.100 parte 3) — vero fallback A/B    == --
-- ============================================================ --
-- Su MAIN i former Uveso PanicZone/MilitaryZone/EnemyZone/Trasher sono RIMOSSI dal
-- template OverwhelmPlus: l'attacco terra/aria passa SOLO da questo file. I builder
-- "Small/Solo/Rush/Medium/Group" qui sotto (min 1-3, priorita' 240-300) mandavano
-- all'attacco unita' singole o a coppie ("streaming"). Sono stati affiancati da
-- builder "batch" a soglia alta (terra 10/20-25/30-40, rush 3-6; aria caccia
-- 15/25/35, bombardieri+cannoniere 15/25), resi mutuamente esclusivi da questo flag:
--   false (default) = batching attivo   |   true = torna allo streaming originale.
-- Nessun gate NoRush1stPhaseActive, di proposito (scopo del file, vedi header).
-- I sistemi T4 ('OWPlus Experimental Formers') restano invariati.
local OWPlusMainAttackBatchingDisabled = false

-- Attivo solo con batching DISATTIVATO (builder originali a streaming)
local function OWPlusFallbackPriority(basePriority)
    return function(self, aiBrain)
        if OWPlusMainAttackBatchingDisabled then
            return basePriority
        end
        return 0
    end
end

-- Attivo solo con batching ATTIVO (default)
local function OWPlusBatchPriority(basePriority)
    return function(self, aiBrain)
        if OWPlusMainAttackBatchingDisabled then
            return 0
        end
        return basePriority
    end
end

-- Piu' soglie sullo stesso pool: la piu' bassa vincerebbe sempre la corsa
-- (Conoscenze_AI_54.md §54.5) -> priorita' statica UNIFORME tra i tier di uno stesso
-- pool + cooldown nativo condiviso DelayEqualBuildPlattons/CheckBuildPlattonDelay
-- (§54.6). Terra: i batch (270) stanno SOTTO il rush T1 (280), che prende i T1 a
-- gruppi di 3-6 lasciando ai batch l'accumulo di T2/T3. Aria: caccia e
-- bombardieri/cannoniere sono pool disgiunti -> due gruppi di cooldown separati.
local OWPlusMainLandBatchPriority = 270
-- Sess.100 parte 12: "countdown al contrario" sui batch terra di MAIN. Il GRANDE
-- (40-50) e' sempre ammesso e visitato per primo (priorita' piu' alta = ordine di
-- visita, §54.8); il MEDIO (30-40) e' ammesso solo se da OWPlusMainLandMediumUnlockSeconds
-- nessun plotone del gruppo si e' formato (CheckBuildPlattonDelay solo sul medio,
-- timer armato da entrambi nella sottoclasse PlatoonFormManager, §54.9). Con
-- produzione alta esce sempre il grande; con produzione bassa il medio fa da rete
-- di sicurezza. Il vecchio batch 10 (LandAttackHuntUveso 10 10) e il 20-25 sono
-- stati tolti su richiesta dell'utente (plotone minimo 30).
local OWPlusMainLandBigPriority = 272
local OWPlusMainLandMediumUnlockSeconds = 90
local OWPlusMainAirBatchPriority = 250
local OWPlusMainBatchCooldownSeconds = 30
local OWPlusMainLandBatchCooldown = 'OWPlusMainLandBatch'
local OWPlusMainAirAntiAirCooldown = 'OWPlusMainAirAntiAirBatch'
local OWPlusMainAirAntiGroundCooldown = 'OWPlusMainAirAntiGroundBatch'

-- BuilderData copiati dai builder originali (tabelle nuove ad ogni chiamata)
-- formationMarch (sess.100 parte 12): true = il plotone marcia in AttackFormation
-- invece di NoFormation (velocita' dell'unita' piu' lenta, niente "striscia"),
-- vedi SetPlatoonFormationOverride in hook/lua/platoon.lua.
local function OWPlusLandBatchData(formationMarch)
    return {
        OWPlusFormationMarch = formationMarch or false,
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
    }
end

local function OWPlusAirFighterBatchData()
    return {
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
    }
end

local function OWPlusAirGroundBatchData()
    return {
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
    }
end

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
        PriorityFunction = OWPlusFallbackPriority(300),
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
        PriorityFunction = OWPlusFallbackPriority(290),
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

    -- ===== BATCH (attivi con OWPlusMainAttackBatchingDisabled = false) ===== --
    -- 2 taglie miste T1/T2/T3 sullo stesso pool, "countdown al contrario" (vedi
    -- OWPlusMainLandMediumUnlockSeconds). Niente gate 'PoolGreaterAtLocation':
    -- il min del template e' gia' la soglia.
    -- GRANDE: sempre ammesso (nessun CheckBuildPlattonDelay), arma il timer del gruppo.
    Builder {
        BuilderName = 'OWPlus Land Batch 40 50',
        PlatoonTemplate = 'OWPlusLandAttackHunt 40 50',
        Priority = OWPlusMainLandBigPriority,
        PriorityFunction = OWPlusBatchPriority(OWPlusMainLandBigPriority),
        InstanceCount = 50,
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusMainLandBatchCooldown, OWPlusMainLandMediumUnlockSeconds },
        BuilderData = OWPlusLandBatchData(true),
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
        },
        BuilderType = 'Any',
    },
    -- MEDIO: rete di sicurezza, ammesso solo dopo OWPlusMainLandMediumUnlockSeconds
    -- senza plotoni del gruppo (il timer lo riarma anche la sua stessa formazione).
    Builder {
        BuilderName = 'OWPlus Land Batch 30 40',
        PlatoonTemplate = 'OWPlusLandAttackHunt 30 40',
        Priority = OWPlusMainLandBatchPriority,
        PriorityFunction = OWPlusBatchPriority(OWPlusMainLandBatchPriority),
        InstanceCount = 50,
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusMainLandBatchCooldown, OWPlusMainLandMediumUnlockSeconds },
        BuilderData = OWPlusLandBatchData(true),
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusMainLandBatchCooldown } },
        },
        BuilderType = 'Any',
    },

    -- T1 RUSH batch: 3-6 unita' (era 2-3) - fuori dal gruppo di cooldown, priorita' 280
    -- (sopra i batch): prende i T1 a gruppi di 3-6, l'early game resta un minimo aggressivo.
    Builder {
        BuilderName = 'OWPlus Land T1 Rush 3 6',
        PlatoonTemplate = 'OWPlusLandAttackIntercept 3 6',
        Priority = 280,
        PriorityFunction = OWPlusBatchPriority(280),
        InstanceCount = 50,
        FormRadius = 10000,
        BuilderData = OWPlusLandBatchData(),
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.MOBILE * categories.LAND * categories.TECH1 - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT } },
        },
        BuilderType = 'Any',
    },

    -- NB: 'Land Intercept Small', 'Land Attack Medium' (sopra) e questo 'Land T1 Rush'
    -- (2-3 unita') sono gli ORIGINALI a streaming: attivi solo con flag = true.

    -- T1 RUSH: 2 T1 bastano per la prima incursione early-game
    Builder {
        BuilderName = 'OWPlus Land T1 Rush',
        PlatoonTemplate = 'LandAttackInterceptUveso 2 3',
        Priority = 280,
        PriorityFunction = OWPlusFallbackPriority(280),
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

    -- ===== BATCH (attivi con OWPlusMainAttackBatchingDisabled = false) ===== --
    -- Caccia e bombardieri+cannoniere sono pool DISGIUNTI: 2 gruppi di cooldown separati,
    -- dentro ciascuno priorita' uniforme. Template basati su categoria (mai ID): coprono
    -- automaticamente anche unita' aeree moddate. Bombardieri: prima nessun former MAIN li
    -- includeva (Gunship Solo/Group filtrano solo GROUNDATTACK), ora rientrano nell'anti-terra.
    -- ANTI-ARIA (caccia)
    Builder {
        BuilderName = 'OWPlus Air AntiAir Batch 15',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiAir 15',
        Priority = OWPlusMainAirBatchPriority,
        PriorityFunction = OWPlusBatchPriority(OWPlusMainAirBatchPriority),
        InstanceCount = 50,
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusMainAirAntiAirCooldown, OWPlusMainBatchCooldownSeconds },
        BuilderData = OWPlusAirFighterBatchData(),
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusMainAirAntiAirCooldown } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Air AntiAir Batch 25',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiAir 25',
        Priority = OWPlusMainAirBatchPriority,
        PriorityFunction = OWPlusBatchPriority(OWPlusMainAirBatchPriority),
        InstanceCount = 50,
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusMainAirAntiAirCooldown, OWPlusMainBatchCooldownSeconds },
        BuilderData = OWPlusAirFighterBatchData(),
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusMainAirAntiAirCooldown } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Air AntiAir Batch 35',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiAir 35',
        Priority = OWPlusMainAirBatchPriority,
        PriorityFunction = OWPlusBatchPriority(OWPlusMainAirBatchPriority),
        InstanceCount = 50,
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusMainAirAntiAirCooldown, OWPlusMainBatchCooldownSeconds },
        BuilderData = OWPlusAirFighterBatchData(),
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusMainAirAntiAirCooldown } },
        },
        BuilderType = 'Any',
    },
    -- ANTI-TERRA (bombardieri + cannoniere)
    Builder {
        BuilderName = 'OWPlus Air AntiGround Batch 15',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiGround 15',
        Priority = OWPlusMainAirBatchPriority,
        PriorityFunction = OWPlusBatchPriority(OWPlusMainAirBatchPriority),
        InstanceCount = 50,
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusMainAirAntiGroundCooldown, OWPlusMainBatchCooldownSeconds },
        BuilderData = OWPlusAirGroundBatchData(),
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusMainAirAntiGroundCooldown } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Air AntiGround Batch 25',
        PlatoonTemplate = 'OWPlusAirAttackHunt AntiGround 25',
        Priority = OWPlusMainAirBatchPriority,
        PriorityFunction = OWPlusBatchPriority(OWPlusMainAirBatchPriority),
        InstanceCount = 50,
        FormRadius = 10000,
        DelayEqualBuildPlattons = { OWPlusMainAirAntiGroundCooldown, OWPlusMainBatchCooldownSeconds },
        BuilderData = OWPlusAirGroundBatchData(),
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { OWPlusMainAirAntiGroundCooldown } },
        },
        BuilderType = 'Any',
    },

    -- NB: 'Air Fighter Small', 'Air Gunship Solo', 'Air Gunship Group' (sotto) sono gli
    -- ORIGINALI a streaming (min 1-3): attivi solo con flag = true.

    -- CACCIA: 2+ fighter → attacca aria nemica e strutture
    Builder {
        BuilderName = 'OWPlus Air Fighter Small',
        PlatoonTemplate = 'U123-Fighter-Intercept 1 30',
        Priority = 260,
        PriorityFunction = OWPlusFallbackPriority(260),
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
        PriorityFunction = OWPlusFallbackPriority(250),
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
        PriorityFunction = OWPlusFallbackPriority(240),
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
