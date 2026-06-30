-- OWPlus CDR Upgrades.lua
-- Il CDR (Commander) si potenzia fino al livello massimo BlackOpsFAF-ACUs
-- prima di fare qualsiasi altra cosa (assist, ecc.).
--
-- Catena upgrade (identica per tutte e 4 le fazioni BlackOps):
--   ImprovedEngineering  (T2 engineering, 750 mass / 30k energy)
--   AdvancedEngineering  (T3 engineering, 2100 mass / 105k energy)
--   ExperimentalEngineering (T4 engineering, 4050 mass / 270k energy)
--
-- Gate di avvio: almeno un generatore T3 (PGen T3) deve esistere prima dell'ImprovedEngineering.
-- Motivo: l'intera catena consuma 6900 mass e 405k energy — il PGen T3 garantisce l'economia.
-- Flusso: T2 eng upgrada fabbrica T2→T3 → T3 eng costruisce PGen T3 → CDR inizia upgrade.
--
-- Priorità: 20000/19900/19800 > qualsiasi builder OWPlus ACU Assist (19000-18700)
-- OWPlus ACU Assist.lua ha il gate CmdrHasUpgrade('ExperimentalEngineering', true)
-- → il CDR non può essere catturato dall'assist finché non ha tutti e 3 gli upgrade.

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local EBC  = '/lua/editor/EconomyBuildConditions.lua'
local SAI  = '/lua/ScenarioPlatoonAI.lua'

BuilderGroup {
    BuilderGroupName = 'OWPlus CDR Upgrades',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'OWPlus CDR ImprovedEngineering',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 20000,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'} },
        BuilderConditions = {
            -- Gate: almeno un generatore T3 costruito prima di avviare la catena.
            -- I 3 upgrade costano fino a 270k energia — il PGen T3 garantisce l'economia.
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'CmdrHasUpgrade', { 'ImprovedEngineering', false } },
        },
        BuilderData = {
            Enhancement = { 'ImprovedEngineering' },
        },
    },

    Builder {
        BuilderName = 'OWPlus CDR AdvancedEngineering',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 19900,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'} },
        BuilderConditions = {
            { UCBC, 'CmdrHasUpgrade', { 'ImprovedEngineering', true } },
            { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false } },
            { EBC,  'GreaterThanEconIncome', { 0.5, 50.0 } },
        },
        BuilderData = {
            Enhancement = { 'AdvancedEngineering' },
        },
    },

    Builder {
        BuilderName = 'OWPlus CDR ExperimentalEngineering',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 19800,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'} },
        BuilderConditions = {
            { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', true } },
            { UCBC, 'CmdrHasUpgrade', { 'ExperimentalEngineering', false } },
            { EBC,  'GreaterThanEconIncome', { 1.5, 150.0 } },
        },
        BuilderData = {
            Enhancement = { 'ExperimentalEngineering' },
        },
    },
}
