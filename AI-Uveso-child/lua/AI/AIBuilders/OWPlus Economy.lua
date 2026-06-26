-- OWPlus Economy.lua
-- Override economici per la personalità OverwhelmPlus.
-- Problema: con i moltiplicatori ×2/×3 di Overwhelm, l'energia è sempre spesa per costruzioni
-- e il serbatoio non raggiunge mai 100% (reclaim T1 pgen) né 90% (mass storage).
-- Soluzione: soglia ridotta al 50% per entrambe le operazioni.

local categories = categories
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'

local MaxCapMass = 0.10  -- 10% del cap unità per estrattori+storage (mirror di Base Mass.lua)

-- ============================================================== --
-- ==  Reclaim T1 Pgens — soglia energia 50% (originale: 100%)  == --
-- ============================================================== --
BuilderGroup {
    BuilderGroupName = 'OWPlus Economy T1 Reclaim',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'OWPlus Reclaim T1 Pgens',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ReclaimStructuresAI',
        Priority = 790,
        InstanceCount = 2,
        PriorityFunction = function(self, aiBrain)
            if aiBrain.PriorityManager.NeedEnergyTech1 then
                return 0    -- ancora in tech 1 energia: non demolire
            else
                return 790
            end
        end,
        BuilderConditions = {
            { EBC,  'GreaterThanEconStorageRatio',      { 0.00, 0.50 } },   -- energia > 50% (non 100%)
            { UCBC, 'UnitsGreaterAtLocation',           { 'LocationType', 0, categories.STRUCTURE * categories.TECH1 * categories.ENERGYPRODUCTION - categories.HYDROCARBON }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) }},
        },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = { categories.STRUCTURE * categories.TECH1 * categories.ENERGYPRODUCTION - categories.HYDROCARBON },
        },
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'OWPlus Reclaim T1 Pgens T2',
        PlatoonTemplate = 'T2EngineerBuilder',
        PlatoonAIPlan = 'ReclaimStructuresAI',
        Priority = 790,
        InstanceCount = 2,
        PriorityFunction = function(self, aiBrain)
            if aiBrain.PriorityManager.NeedEnergyTech1 then
                return 0
            else
                return 790
            end
        end,
        BuilderConditions = {
            { EBC,  'GreaterThanEconStorageRatio',      { 0.00, 0.50 } },   -- energia > 50% (non 100%)
            { UCBC, 'UnitsGreaterAtLocation',           { 'LocationType', 0, categories.STRUCTURE * categories.TECH1 * categories.ENERGYPRODUCTION - categories.HYDROCARBON }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) }},
        },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = { categories.STRUCTURE * categories.TECH1 * categories.ENERGYPRODUCTION - categories.HYDROCARBON },
        },
        BuilderType = 'Any',
    },
}

-- ============================================================== --
-- ==  Energia T2/T3 — priorità alta per bypassare loop T1     == --
-- ============================================================== --
-- Problema: U123 Energy Builders ha T2 a priority 17000 e T1 a 17900.
-- Gli ingegneri T2 scelgono sempre T1 (più alto) finché NeedEnergyTech1=true,
-- ma NeedEnergyTech1 rimane true finché non ci sono 2 T2 pgens → loop infinito.
-- Soluzione: builder OWPlus a priority 18100/18200, bypassano il gate Uveso.
BuilderGroup {
    BuilderGroupName = 'OWPlus Energy T2T3',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'OWPlus T2 Power Push',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 18100,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'GreaterThanGameTimeSeconds',           { 60 * 5 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory',     { 0, categories.STRUCTURE * categories.FACTORY * categories.TECH2 } },
            { UCBC, 'HaveLessThanUnitsWithCategory',        { 5, categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) } },
        },
        BuilderData = {
            Construction = {
                AdjacencyCategory = (categories.STRUCTURE * categories.SHIELD) + (categories.FACTORY * (categories.TECH2 + categories.TECH1)),
                AdjacencyDistance = 50,
                BuildClose = false,
                LocationType = 'LocationType',
                BuildStructures = { 'T2EnergyProduction' },
            }
        },
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'OWPlus T3 Power Push',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 18200,
        InstanceCount = 3,
        BuilderConditions = {
            { UCBC, 'GreaterThanGameTimeSeconds',           { 60 * 10 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory',     { 0, categories.STRUCTURE * categories.FACTORY * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsWithCategory',        { 8, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3 } },
        },
        BuilderData = {
            Construction = {
                AdjacencyCategory = (categories.STRUCTURE * categories.SHIELD) + (categories.FACTORY * (categories.TECH3 + categories.TECH2)),
                AdjacencyDistance = 50,
                BuildClose = false,
                LocationType = 'LocationType',
                BuildStructures = { 'T3EnergyProduction' },
            }
        },
        BuilderType = 'Any',
    },
}

-- ============================================================== --
-- ==  Mass Storage Adjacency — soglia energia 50% (orig: 90%)  == --
-- ============================================================== --
BuilderGroup {
    BuilderGroupName = 'OWPlus Mass Storage Adjacency',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'OWPlus Mass Storage T1 Eng',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 17879,
        DelayEqualBuildPlattons = { 'MASSSTORAGE', 5 },
        PriorityFunction = function(self, aiBrain)
            if aiBrain.PriorityManager.HasParagon then
                return 0
            else
                return 17879
            end
        end,
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay',           { 'MASSSTORAGE' }},
            { EBC,  'GreaterThanEconStorageRatio',      { 0.1, 0.50 } },    -- energia > 50% (non 90%)
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.MASSSTORAGE }},
            { UCBC, 'HaveLessThanUnitsWithCategory',    { 16, categories.STRUCTURE * categories.MASSSTORAGE }},
            { UCBC, 'HaveUnitRatioVersusCap',           { MaxCapMass, '<', categories.STRUCTURE * (categories.MASSEXTRACTION + categories.MASSFABRICATION + categories.MASSSTORAGE) }},
            { UCBC, 'AdjacencyCheck',                   { 'LocationType', categories.STRUCTURE * categories.MASSEXTRACTION * (categories.TECH2 + categories.TECH3), 60, 'ueb1106' }},
        },
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.STRUCTURE * categories.MASSEXTRACTION * (categories.TECH2 + categories.TECH3),
                AdjacencyDistance = 60,
                BuildClose = false,
                BuildStructures = { 'MassStorage' },
            }
        },
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'OWPlus Mass Storage T2 Eng',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 17878,
        DelayEqualBuildPlattons = { 'MASSSTORAGE', 5 },
        PriorityFunction = function(self, aiBrain)
            if aiBrain.PriorityManager.HasParagon then
                return 0
            else
                return 17878
            end
        end,
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay',           { 'MASSSTORAGE' }},
            { EBC,  'GreaterThanEconStorageRatio',      { 0.1, 0.50 } },    -- energia > 50% (non 90%)
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.MASSSTORAGE }},
            { UCBC, 'AdjacencyCheck',                   { 'LocationType', categories.MASSEXTRACTION * categories.TECH3, 60, 'ueb1106' }},
            { UCBC, 'HaveLessThanUnitsWithCategory',    { 32, categories.STRUCTURE * categories.MASSSTORAGE }},
            { UCBC, 'HaveUnitRatioVersusCap',           { MaxCapMass, '<', categories.STRUCTURE * (categories.MASSEXTRACTION + categories.MASSFABRICATION + categories.MASSSTORAGE) }},
        },
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'MASSEXTRACTION TECH3',
                AdjacencyDistance = 60,
                BuildClose = false,
                BuildStructures = { 'MassStorage' },
            }
        },
        BuilderType = 'Any',
    },
}
