-- OWPlus Land Naval.lua
-- Fase 6 (P1/P4): tech progression terra e navale.
--
-- Problema:
--   TERRA: Le fabbriche T2/T3 esistenti producono con priority 250/350 (Uveso).
--          Con ×6 eco l'AI ha T2/T3 factories disponibili ma i builder vanilla
--          rischiano di essere soppressi da condizioni ratio vs nemico.
--
--   NAVALE: Il panic builder Uveso 'U1 Sub PANIC' a priority 18600 non usa il gate
--           PriorityManager — produce fino a 20 T1 sub ogni volta c'è un nemico
--           navale entro 60 range. Le fabbriche T2/T3 navali devono avere priority
--           superiore (18700/18800) per produrre unità di tier alto invece dei sub.
--
-- Soluzione:
--   Builder OWPlus a priority > 18600 per navale, > 350 per terra.
--   Usano solo condizioni dirette (conteggio fabbriche) senza gate PriorityManager.
--   Le fabbriche T1 che non possono costruire T2/T3 cadono sui builder Uveso normali.

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local EBC  = '/lua/editor/EconomyBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'

-- ===================================================-======================================================== --
-- ==                         OWPlus Land T2/T3 — alta priorità per fabbriche T2/T3                         == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'OWPlus Land T2T3',
    BuildersType = 'FactoryBuilder',

    -- Fabbriche T2: producono carri T2 a priority 18100
    -- (T1 factories valutano questo builder ma non possono costruire T2 units → fallback Uveso)
    Builder {
        BuilderName = 'OWPlus T2 Land Assault',
        PlatoonTemplate = 'T2AttackTank',
        Priority = 18100,
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconTrend',  { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH2 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus T2 Land DFTank',
        PlatoonTemplate = 'T2LandDFTank',
        Priority = 18100,
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconTrend',  { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH2 } },
            { UCBC, 'HaveUnitRatioUveso', { 0.4, categories.MOBILE * categories.LAND * categories.DIRECTFIRE * categories.TECH2 * categories.BOT, '<', categories.MOBILE * categories.LAND * categories.DIRECTFIRE * categories.TECH2 - categories.BOT } },
        },
        BuilderType = 'Land',
    },

    -- Fabbriche T3: producono unità T3 a priority 18200
    Builder {
        BuilderName = 'OWPlus T3 Land Armored',
        PlatoonTemplate = 'T3ArmoredAssault',
        Priority = 18200,
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconTrend',  { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus T3 Land SiegeBot',
        PlatoonTemplate = 'T3LandBot',
        Priority = 18200,
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { MIBC, 'FactionIndex', { 1, 3, 4, 5 } },
            { EBC,  'GreaterThanEconTrend',  { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus T3 Land Sniper',
        PlatoonTemplate = 'T3SniperBots',
        Priority = 18200,
        BuilderConditions = {
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconTrend',  { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveUnitRatioUveso', { 0.3, categories.MOBILE * categories.LAND * categories.INDIRECTFIRE * categories.TECH3, '<', categories.MOBILE * categories.LAND * categories.DIRECTFIRE * categories.TECH3 } },
        },
        BuilderType = 'Land',
    },
}

-- ===================================================-======================================================== --
-- ==                OWPlus Naval T2/T3 — bypassa panic builder Uveso (18600) per T2/T3                     == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'OWPlus Naval T2T3',
    BuildersType = 'FactoryBuilder',

    -- Fabbriche T2+: producono cacciatorpedinieri/incrociatori a 18700
    -- Priority > 18600 (panic Uveso) → T2 factories scelgono questo
    -- NB: CanPathNavalBaseToNavalTargets rimossa — crasha con GetPlan nil su certe mappe
    Builder {
        BuilderName = 'OWPlus T2 Naval Destroyer',
        PlatoonTemplate = 'T2SeaDestroyer',
        Priority = 18700,
        BuilderConditions = {
            { EBC,  'GreaterThanEconTrend',           { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.NAVAL * (categories.TECH2 + categories.TECH3) } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'OWPlus T2 Naval Cruiser',
        PlatoonTemplate = 'T2SeaCruiser',
        Priority = 18700,
        BuilderConditions = {
            { EBC,  'GreaterThanEconTrend',           { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.NAVAL * (categories.TECH2 + categories.TECH3) } },
            { UCBC, 'UnitsGreaterAtEnemy', { 0, categories.NAVAL } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'OWPlus T2 Naval SubKiller',
        PlatoonTemplate = 'T2SubKiller',
        Priority = 18700,
        BuilderConditions = {
            { EBC,  'GreaterThanEconTrend',           { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.NAVAL * (categories.TECH2 + categories.TECH3) } },
            { UCBC, 'HaveUnitRatioUveso', { 0.1, categories.MOBILE * categories.NAVAL * categories.TECH2 * categories.ANTINAVY, '<', categories.MOBILE * categories.NAVAL * categories.TECH2 * categories.DIRECTFIRE } },
        },
        BuilderType = 'Sea',
    },

    -- Fabbriche T3: producono corazzate/navi da guerra a 18800
    Builder {
        BuilderName = 'OWPlus T3 Naval Battleship',
        PlatoonTemplate = 'T3SeaBattleship',
        Priority = 18800,
        BuilderConditions = {
            { EBC,  'GreaterThanEconTrend',           { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.NAVAL * categories.TECH3 } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'OWPlus T3 Naval Battlecruiser',
        PlatoonTemplate = 'T3Battlecruiser',
        Priority = 18800,
        BuilderConditions = {
            { EBC,  'GreaterThanEconTrend',           { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.NAVAL * categories.TECH3 } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'OWPlus T3 Naval MissileBoat',
        PlatoonTemplate = 'T3MissileBoat',
        Priority = 18800,
        BuilderConditions = {
            { EBC,  'GreaterThanEconTrend',           { 0.0, 0.0 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.NAVAL * categories.TECH3 } },
            { UCBC, 'UnitsGreaterAtEnemy', { 0, categories.NAVAL } },
        },
        BuilderType = 'Sea',
    },
}
