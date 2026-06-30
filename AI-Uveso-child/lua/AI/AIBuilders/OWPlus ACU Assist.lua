-- OWPlus ACU Assist.lua
-- Il commander (CDR) rimane in base e assiste le costruzioni.
-- Usa CommanderAssist (Plan=ManagerEngineerAssistAI, cattura categories.COMMAND).
-- UC ACU Attack Former rimosso dal template → CDR non attacca mai autonomamente.
--
-- Gerarchia priorità:
--   19000 → sperimentali in costruzione    (assist ingegnere builder)
--   18900 → strutture/fabbriche in cost.   (assist struttura)
--   18800 → fabbriche che producono unità  (assist fabbrica)
--   18700 → qualunque ingegnere attivo     (fallback generico)

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'

BuilderGroup {
    BuilderGroupName = 'OWPlus ACU Assist',
    BuildersType = 'PlatoonFormBuilder',

    Builder {
        BuilderName = 'OWPlus CDR Assist Experimental',
        PlatoonTemplate = 'CommanderAssist',
        Priority = 19000,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'CmdrHasUpgrade', { 'ExperimentalEngineering', true } },
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'EXPERIMENTAL' } },
        },
        BuilderData = {
            Assist = {
                AssisteeType = 'Engineer',
                AssistLocation = 'LocationType',
                AssistRange = 250,
                BeingBuiltCategories = { 'EXPERIMENTAL' },
                AssistUntilFinished = true,
                Time = 0,
            },
        },
    },

    Builder {
        BuilderName = 'OWPlus CDR Assist Factory Construction',
        PlatoonTemplate = 'CommanderAssist',
        Priority = 18900,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'CmdrHasUpgrade', { 'ExperimentalEngineering', true } },
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.STRUCTURE * categories.FACTORY } },
        },
        BuilderData = {
            Assist = {
                AssisteeType = 'Structure',
                AssistLocation = 'LocationType',
                AssistRange = 150,
                BeingBuiltCategories = { 'STRUCTURE FACTORY' },
                AssistUntilFinished = true,
                Time = 0,
            },
        },
    },

    Builder {
        BuilderName = 'OWPlus CDR Assist Factory Production',
        PlatoonTemplate = 'CommanderAssist',
        Priority = 18800,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'CmdrHasUpgrade', { 'ExperimentalEngineering', true } },
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'MOBILE' } },
        },
        BuilderData = {
            Assist = {
                AssisteeType = 'Factory',
                AssistLocation = 'LocationType',
                AssistRange = 150,
                BeingBuiltCategories = { 'MOBILE' },
                Time = 30,
            },
        },
    },

    Builder {
        BuilderName = 'OWPlus CDR Assist Engineers',
        PlatoonTemplate = 'CommanderAssist',
        Priority = 18700,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'CmdrHasUpgrade', { 'ExperimentalEngineering', true } },
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'ALLUNITS' } },
        },
        BuilderData = {
            Assist = {
                AssisteeType = 'Engineer',
                AssistLocation = 'LocationType',
                AssistRange = 150,
                BeingBuiltCategories = {
                    'STRUCTURE FACTORY',
                    'STRUCTURE SHIELD',
                    'STRUCTURE DEFENSE',
                    'EXPERIMENTAL',
                    'STRUCTURE NUKE',
                    'STRUCTURE STRATEGIC',
                    'STRUCTURE ANTIMISSILE',
                },
                Time = 30,
            },
        },
    },
}
