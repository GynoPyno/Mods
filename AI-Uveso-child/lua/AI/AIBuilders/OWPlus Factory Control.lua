local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local EBC  = '/lua/editor/EconomyBuildConditions.lua'

-- ===========================================================================
-- OWPlus Factory Builders — rimpiazza 'U1 Factory Builders ADAPTIVE' di Uveso
--
-- Uveso ADAPTIVE usa HaveUnitRatioVersusCap { 0.024, '<', FACTORY } che
-- permette 0.024 × unitCap fabbriche (es. 24 con unitCap=1000).
-- Questo gruppo usa invece un cap numerico fisso su TUTTE le fabbriche (HQ + support):
--   Land: max 5 factories totali
--   Air:  max 4 factories totali
-- IMPORTANTE: non escludere SUPPORTFACTORY dal conteggio — le support factory sono
-- T1 HQ aggiornati in-place. Escluderle crea un loop: upgrade T1→support abbassa il
-- count, il builder ricostruisce un T1, portando al doppio delle fabbriche volute.
-- ===========================================================================
BuilderGroup {
    BuilderGroupName = 'OWPlus Factory Builders',
    BuildersType = 'EngineerBuilder',

    -- ========================= --
    --   LAND — cap fisso a 5   --
    -- ========================= --
    Builder {
        BuilderName = 'OWPlus Land Factory Cap',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 15500,
        DelayEqualBuildPlattons = {'Factories', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'Factories' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.30 } },
            { EBC,  'GreaterThanEconTrend', { 0.0, 0.0 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 5,
                categories.STRUCTURE * categories.FACTORY * categories.LAND } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH1 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                AdjacencyCategory = categories.ENERGYPRODUCTION,
                AvoidCategory = categories.STRUCTURE * (categories.FACTORY + categories.MASSEXTRACTION),
                maxUnits = 0,
                maxRadius = 5,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Land Factory Cap Commander',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 15500,
        DelayEqualBuildPlattons = {'Factories', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'Factories' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.30 } },
            { EBC,  'GreaterThanEconTrend', { 0.0, 0.0 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2,
                categories.STRUCTURE * categories.FACTORY * categories.LAND } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH1 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                AdjacencyCategory = categories.ENERGYPRODUCTION,
                AvoidCategory = categories.STRUCTURE * (categories.FACTORY + categories.MASSEXTRACTION),
                maxUnits = 0,
                maxRadius = 2,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    -- ========================= --
    --   AIR — cap fisso a 4    --
    -- ========================= --
    Builder {
        BuilderName = 'OWPlus Air Factory Cap',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 15500,
        DelayEqualBuildPlattons = {'Factories', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'Factories' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.30 } },
            { EBC,  'GreaterThanEconTrend', { 0.0, 0.0 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4,
                categories.STRUCTURE * categories.FACTORY * categories.AIR } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH1 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2,
                categories.STRUCTURE * categories.FACTORY * categories.LAND } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory Cap Commander',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 15500,
        DelayEqualBuildPlattons = {'Factories', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'Factories' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.30 } },
            { EBC,  'GreaterThanEconTrend', { 0.0, 0.0 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.AIR } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH1 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3,
                categories.STRUCTURE * categories.FACTORY * categories.LAND } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },
}

-- ===========================================================================
-- OWPlus Factory Builders RECOVER — rimpiazza 'U1 Factory Builders RECOVER' di Uveso
--
-- I builder RECOVER di Uveso usano FACTORY * LAND - SUPPORTFACTORY e hanno
-- priorità 19300. Questo crea un loop identico al bug -SUPPORTFACTORY:
-- ogni upgrade T1→support abbassa il count HQ a 0, il RECOVER ricostruisce
-- immediatamente una T1 (19300 > 15500), che viene aggiornata, e così via.
--
-- Soluzione: contare TUTTE le fabbriche (HQ + support) senza esclusioni.
-- Cap a 1: basta per ricostruire se l'AI perde l'unica fabbrica in battaglia.
-- I builder normali portano poi al cap desiderato (5 land, 4 air).
-- ===========================================================================
BuilderGroup {
    BuilderGroupName = 'OWPlus Factory Builders RECOVER',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'OWPlus Land Factory RECOVER',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 19300,
        DelayEqualBuildPlattons = {'Factories', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'Factories' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.LAND } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH1 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            Construction = {
                BuildClose = false,
                AdjacencyCategory = categories.MASSEXTRACTION * (categories.TECH3 + categories.TECH2 + categories.TECH1),
                LocationType = 'LocationType',
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Land Factory RECOVER Commander',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 19300,
        DelayEqualBuildPlattons = {'Factories', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'Factories' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.LAND } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH1 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            Construction = {
                BuildClose = false,
                AdjacencyCategory = categories.MASSEXTRACTION * (categories.TECH3 + categories.TECH2 + categories.TECH1),
                LocationType = 'LocationType',
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory RECOVER',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 19300,
        DelayEqualBuildPlattons = {'Factories', 5},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'Factories' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.AIR } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,
                categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH1 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            Construction = {
                LocationType = 'LocationType',
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },
}
