-- OWPlus Engineer Builders.lua
-- Sostituisce 'U123 Engineer Builders' di Uveso nel template OverwhelmPlus.
--
-- Differenza chiave rispetto all'originale:
--   Tutti i builder T1 hanno la condizione aggiuntiva:
--     HaveLessThanUnitsWithCategory { 1, STRUCTURE * FACTORY * LAND * TECH3 }
--   → non appena esiste una T3 factory (HQ o support), nessun ingegnere T1
--     viene più prodotto. Le fabbriche si concentrano su T3 engineers.
--
-- I builder T1 "panic" (priority 19100) erano il problema principale:
--   senza gate, continuavano a rubare slot fabbrica anche con 30 T3 eng nel pool
--   perché controllavano solo il count di T1 engineers (che ovviamente è 0 a T3).
--
-- T2 e T3 builders sono identici all'originale Uveso.

local categories = categories
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'

local BasePanicZone, BaseMilitaryZone, BaseEnemyZone = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua').GetDangerZoneRadii()

local MaxCapEngineers = 0.15
-- Gate comune per tutti i builder T1: smetti se esiste una T3 factory (HQ o support)
local NoT3Factory = { UCBC, 'HaveLessThanUnitsWithCategory', { 1,
    categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } }

BuilderGroup {
    BuilderGroupName = 'OWPlus Engineer Builders',
    BuildersType = 'FactoryBuilder',

    -- ============ --
    --    TECH 1    --
    -- ============ --
    Builder {
        BuilderName = 'OWPlus U1 Engineer builder Panic1',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 19100,
        BuilderConditions = {
            NoT3Factory,
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.MOBILE * categories.ENGINEER * categories.TECH1 - categories.COMMAND } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * (categories.DIRECTFIRE + categories.INDIRECTFIRE) } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'OWPlus U1 Engineer builder Panic2',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 19100,
        BuilderConditions = {
            NoT3Factory,
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.MOBILE * categories.ENGINEER * categories.TECH1 - categories.COMMAND } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MOBILE * (categories.DIRECTFIRE + categories.INDIRECTFIRE) } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'OWPlus U1 Engineer builder Cap',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 18990,
        BuilderConditions = {
            NoT3Factory,
            { UCBC, 'HaveLessThanUnitsWithCategory', { 6, categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'OWPlus U1 Engineer noPool 10',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 18700,
        BuilderConditions = {
            NoT3Factory,
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 10, categories.MOBILE * categories.ENGINEER * categories.TECH1 - categories.STATIONASSISTPOD } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus U1 Engineer noPool land < 3',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 18700,
        BuilderConditions = {
            NoT3Factory,
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 3, categories.MOBILE * categories.ENGINEER * categories.TECH1 - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.STRUCTURE * categories.FACTORY * categories.LAND } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus U1 Engineer noPool land < 1',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 18500,
        BuilderConditions = {
            NoT3Factory,
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.ENGINEER * categories.TECH1 - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.FACTORY * categories.LAND } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus U1 Engineer noPool air',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 18400,
        BuilderConditions = {
            NoT3Factory,
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 5, categories.MOBILE * categories.ENGINEER * categories.TECH1 - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'OWPlus U1 Engineer naval 2x',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 18400,
        BuilderConditions = {
            NoT3Factory,
            { UCBC, 'EngineerManagerUnitsAtLocation', { 'LocationType', '<', 2, categories.MOBILE * categories.TECH1 } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH1 } },
        },
        BuilderType = 'Sea',
    },

    -- ============ --
    --    TECH 2    --
    -- ============ --
    Builder {
        BuilderName = 'OWPlus U2 Engineer builder Cap',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 18500,
        BuilderConditions = {
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech2' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ENGINEER * categories.TECH2 } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'OWPlus U2 Engineer noPool',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 18400,
        BuilderConditions = {
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
            { EBC, 'GreaterThanEconStorageRatio', { 0.20, 0.20 } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 2, categories.MOBILE * categories.ENGINEER * categories.TECH2 - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH2 } },
        },
        BuilderType = 'All',
    },

    -- ============ --
    --    TECH 3    --
    -- ============ --
    Builder {
        BuilderName = 'OWPlus U3 Engineer builder Cap',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 18500,
        BuilderConditions = {
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech3' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus U3 Engineer builder noPool min',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 18500,
        BuilderConditions = {
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.ENGINEER * categories.TECH3 - categories.SUBCOMMANDER - categories.STATIONASSISTPOD } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus U3 Engineer noPool Land',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 18400,
        BuilderConditions = {
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
            { EBC, 'GreaterThanEconStorageRatio', { 0.30, 0.30 } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 3, categories.MOBILE * categories.ENGINEER * categories.TECH3 - categories.SUBCOMMANDER - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH3 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus U3 Engineer noPool Air',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 18400,
        BuilderConditions = {
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
            { EBC, 'GreaterThanEconStorageRatio', { 0.40, 0.40 } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 3, categories.MOBILE * categories.ENGINEER * categories.TECH3 - categories.SUBCOMMANDER - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveUnitRatioVersusCap', { MaxCapEngineers / 3 , '<', categories.MOBILE * categories.ENGINEER * categories.TECH3 } },
        },
        BuilderType = 'Air',
    },
}
