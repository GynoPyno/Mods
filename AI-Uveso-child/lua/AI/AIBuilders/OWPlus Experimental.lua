-- OWPlus Experimental.lua
-- Fase 7b (P-exp): scaling verso sperimentali senza il gate ItsTimeForGameender di Uveso
-- (che per default blocca i T4 fino al 25° minuto di partita).
--
-- Paradigma (Opzione C):
--   Le fabbriche continuano a produrre T2/T3 normalmente.
--   Gli ingegneri T3 scalano verso T4 man mano che la partita avanza:
--
--   FIRST (18300): primo sperimentale appena esiste una T3 factory + eco positiva
--   SCALE (18250): fino a cap sperimentali se mass storage > 15%
--   FLOOD (18200): spam overflow quando mass > 30%
--
-- LIMITI COSTRUZIONI PARALLELE:
--   Tutti i SCALE builder hanno HaveLessThanUnitsInCategoryBeingBuilt { 3, EXPERIMENTAL MOBILE }
--   → massimo 2 T4 in costruzione contemporaneamente.
--   Con 2 leader impegnati, tutti gli altri ingegneri T3 rimangono nel pool
--   e vengono assegnati dai builder assist (InstanceCount=30) → 5-15 assist per T4.
--
-- PESI ARIA/TERRA (BONUS):
--   I builder SCALE aria usano PriorityFunction dinamica:
--   se airCount * 2 <= landCount → priority 18255-18265 (sopra i terra a 18240-18260)
--   altrimenti → priority 18190-18210 (sotto i terra, frequenza normale)
--   Target: almeno 1 sperimentale aria ogni 2 terra (ratio 1:2).
--
-- Priority range: 18200-18300 (sopra Uveso max 1100, sotto OWPlus eco 18100-18200 solo per T4)

local categories = categories
local EBC  = '/lua/editor/EconomyBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'


-- ============================================================ --
-- ==           LAND EXPERIMENTALS — Terra T4                == --
-- ============================================================ --
BuilderGroup {
    BuilderGroupName = 'OWPlus Experimental Land',
    BuildersType = 'EngineerBuilder',

    -- FIRST: avvia il PRIMO sperimentale appena abbiamo una T3 factory + eco storage > 5%
    Builder {
        BuilderName = 'OWPlus Exp Land First',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18300,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.05 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'T4LandExperimental1' },
                Location = 'LocationType',
            }
        }
    },

    -- SCALE vanilla + 4 varianti mod — selezione random tramite PriorityFunction
    -- Tutti usano lo stesso DelayEqualBuildPlattons → solo 1 parte ogni 5 secondi.
    -- PriorityFunction restituisce un valore casuale nel range 18240-18260:
    -- ogni ciclo il BuilderManager valuta tutti e sceglie quello con priority più alta
    -- → varietà pseudo-random senza logica esplicita.
    -- HaveLessThanUnitsInCategoryBeingBuilt { 3 } → max 2 T4 totali in costruzione
    -- → concentra gli assist su pochi T4 invece di spalmarli su 16 costruzioni parallele.

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Vanilla',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'T4LandExperimental1' },
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Vanilla2',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'T4LandExperimental2' },  -- Cybran:url0401 Monkeylord; altri:identico a Vanilla
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Vanilla3',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'T4LandExperimental3' },  -- Cybran:xrl0403; altre fazioni:fail silenzioso
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Mod1',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'OWPlusExp1' },  -- UEF:oel0401 Aeon:gmal0401 Cybran:wrl0404 Sera:zxl0401
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Mod2',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'OWPlusExp2' },  -- UEF:oel0402 Aeon:wza7401 Cybran:wrl04044
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Mod3',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'OWPlusExp3' },  -- UEF:uelb0401 Aeon:ual0402
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Mod4',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'OWPlusExp4' },  -- Aeon:lduc11 (Planetary Colossus)
                Location = 'LocationType',
            }
        }
    },

    -- SCALE TotalMayhem: 8 slot terra (TMExpLand1-8)
    -- Stessa logica random degli altri SCALE — failback silenzioso per fazioni senza entry
    Builder {
        BuilderName = 'OWPlus Exp Land Scale TM1',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'TMExpLand1' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale TM2',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'TMExpLand2' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale TM3',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'TMExpLand3' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale TM4',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'TMExpLand4' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale TM5',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'TMExpLand5' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale TM6',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'TMExpLand6' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale TM7',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'TMExpLand7' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale TM8',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'TMExpLand8' }, Location = 'LocationType',
        }},
    },

    -- SACU scale: i Sub-Commandos costruiscono T4 come ingegneri potenziati (build rate ~3x T3 eng)
    Builder {
        BuilderName = 'OWPlus Exp Land Scale SACU',
        PlatoonTemplate = 'SACUEngineerBuilder',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.SUBCOMMANDER } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
                BuildStructures = { 'T4LandExperimental1' },
                Location = 'LocationType',
            }
        }
    },

    -- SCALE Wyvern Battle Pack: 4 slot terra (WyvernExpLand1-4)
    -- Stessa logica random degli altri SCALE — failback silenzioso per fazioni senza entry
    Builder {
        BuilderName = 'OWPlus Exp Land Scale Wyvern1',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'WyvernExpLand1' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Wyvern2',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'WyvernExpLand2' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Wyvern3',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'WyvernExpLand3' }, Location = 'LocationType',
        }},
    },

    Builder {
        BuilderName = 'OWPlus Exp Land Scale Wyvern4',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18250,
        PriorityFunction = function(self, aiBrain) return math.random(18240, 18260) end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpLand', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.15, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = { Construction = {
            DesiresAssist = true, NumAssistees = 10, BuildClose = false,
            AdjacencyCategory = categories.STRUCTURE * categories.SHIELD,
            BuildStructures = { 'WyvernExpLand4' }, Location = 'LocationType',
        }},
    },

    -- FLOOD: eco in overflow (mass storage > 30%) → spam senza limite sperimentali
    -- Non ha il limite BeingBuilt: in overflow l'AI deve costruire quanti T4 può
    Builder {
        BuilderName = 'OWPlus Exp Land Flood',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18200,
        InstanceCount = 25,
        DelayEqualBuildPlattons = {'MobileExpLand', 1},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpLand' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.30, 0.20 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                BuildStructures = { 'T4LandExperimental1' },
                Location = 'LocationType',
            }
        }
    },
}

-- ============================================================ --
-- ==           AIR EXPERIMENTALS — Aria T4                  == --
-- ============================================================ --
--
-- PriorityFunction pesata per bilanciare la scarsità delle sperimentali aria:
--   Con pochi slot aria (3-4 builder) vs molti terra (16), i builder aria
--   avrebbero priority troppo bassa per competere.
--   La PriorityFunction conta gli sperimentali aria e terra attivi:
--   se airCount * 2 <= landCount (aria < 50% del totale) → priority 18255-18265
--     → sopra i builder terra (18240-18260) → aria viene costruita per prima
--   altrimenti → priority 18190-18210 → sotto terra → frequenza normale
--   Target: 1 sperimentale aria ogni 2 terra (ratio 1:2).
--   Cap aria SCALE=12, FLOOD=20; eco gate SCALE=25%/15%, FLOOD=45%/25%.
-- ============================================================ --
BuilderGroup {
    BuilderGroupName = 'OWPlus Experimental Air',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'OWPlus Exp Air First',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18300,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpAir', 2},
        BuilderConditions = {
            { UCBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpAir' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.20, 0.10 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                BuildStructures = { 'T4AirExperimental1' },
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Air Scale',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18200,
        PriorityFunction = function(self, aiBrain)
            local airExp = table.getn(aiBrain:GetListOfUnits(
                categories.MOBILE * categories.AIR * categories.EXPERIMENTAL, false, false))
            local landExp = table.getn(aiBrain:GetListOfUnits(
                categories.MOBILE * categories.EXPERIMENTAL * categories.LAND, false, false))
            if airExp * 2 <= landExp then
                return math.random(18255, 18265)
            end
            return math.random(18190, 18210)
        end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpAir', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpAir' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.25, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 12, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                BuildStructures = { 'T4AirExperimental1' },
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Air Scale Mod1',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18200,
        PriorityFunction = function(self, aiBrain)
            local airExp = table.getn(aiBrain:GetListOfUnits(
                categories.MOBILE * categories.AIR * categories.EXPERIMENTAL, false, false))
            local landExp = table.getn(aiBrain:GetListOfUnits(
                categories.MOBILE * categories.EXPERIMENTAL * categories.LAND, false, false))
            if airExp * 2 <= landExp then
                return math.random(18255, 18265)
            end
            return math.random(18190, 18210)
        end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpAir', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpAir' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.25, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 12, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                BuildStructures = { 'OWPlusAirExp1' },  -- UEF:oea0401 (Antares air exp)
                Location = 'LocationType',
            }
        }
    },

    Builder {
        BuilderName = 'OWPlus Exp Air Scale TM1',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18200,
        PriorityFunction = function(self, aiBrain)
            local airExp = table.getn(aiBrain:GetListOfUnits(
                categories.MOBILE * categories.AIR * categories.EXPERIMENTAL, false, false))
            local landExp = table.getn(aiBrain:GetListOfUnits(
                categories.MOBILE * categories.EXPERIMENTAL * categories.LAND, false, false))
            if airExp * 2 <= landExp then
                return math.random(18255, 18265)
            end
            return math.random(18190, 18210)
        end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpAir', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpAir' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.25, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 12, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                BuildStructures = { 'TMAirExp1' },  -- Aeon:broat3pride; altre fazioni:fail silenzioso
                Location = 'LocationType',
            }
        }
    },

    -- FLOOD aria: eco in overflow (mass > 45%) → costruisce fino a 20 aria
    -- Stessa logica del FLOOD terra, ma dedicata all'aria.
    -- InstanceCount alto: molti ingegneri possono costruire sperimentali aria in parallelo.
    Builder {
        BuilderName = 'OWPlus Exp Air Flood',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18200,
        InstanceCount = 10,
        DelayEqualBuildPlattons = {'MobileExpAir', 1},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpAir' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.45, 0.25 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 20, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                BuildStructures = { 'T4AirExperimental1' },
                Location = 'LocationType',
            }
        }
    },

    -- Wyvern Battle Pack aria — solo Cybran (WRA0401: Experimental Gunship)
    Builder {
        BuilderName = 'OWPlus Exp Air Scale Wyvern1',
        PlatoonTemplate = 'T3EngineerBuilderNoSUB',
        Priority = 18200,
        PriorityFunction = function(self, aiBrain)
            local airExp = table.getn(aiBrain:GetListOfUnits(
                categories.MOBILE * categories.AIR * categories.EXPERIMENTAL, false, false))
            local landExp = table.getn(aiBrain:GetListOfUnits(
                categories.MOBILE * categories.EXPERIMENTAL * categories.LAND, false, false))
            if airExp * 2 <= landExp then
                return math.random(18255, 18265)
            end
            return math.random(18190, 18210)
        end,
        InstanceCount = 1,
        DelayEqualBuildPlattons = {'MobileExpAir', 2},
        BuilderConditions = {
            { UCBC, 'CheckBuildPlattonDelay', { 'MobileExpAir' } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.25, 0.15 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.EXPERIMENTAL } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 12, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'UnitCapCheckLess', { 0.99 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                BuildStructures = { 'WyvernExpAir1' },  -- Cybran:wra0401; altre fazioni:fail silenzioso
                Location = 'LocationType',
            }
        }
    },
}

-- ============================================================ --
-- ==   ASSIST SPERIMENTALI MOBILI — Fix bug Uveso           == --
-- ==   Uveso UC123 Assistees usa AssisteeType='Structure'   == --
-- ==   che NON trova T4 mobili (MOBILE, non STRUCTURE).     == --
-- ==   AssisteeType='Engineer' trova l'ingegnere che        == --
-- ==   costruisce il T4 — funziona per terra E aria.       == --
-- ============================================================ --
BuilderGroup {
    BuilderGroupName = 'OWPlus Assist Experimentals',
    BuildersType = 'PlatoonFormBuilder',

    -- SACU assist: Sub-Commandos assistono i T4 in costruzione con priorità massima
    -- Build rate SACU ~3x T3 eng → equivale a 3 ingegneri in un singolo slot
    Builder {
        BuilderName = 'OWPlus SACU Assist Exp Mobile',
        PlatoonTemplate = 'SACUEngineerAssist',
        Priority = 17600,
        InstanceCount = 10,
        BuilderConditions = {
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.05 } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.SUBCOMMANDER } },
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 250,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE'},
                AssistUntilFinished = true,
                AssistClosestUnit = true,
                Time = 0,
            }
        },
    },

    -- T3 engineers assist qualsiasi T4 mobile (Colossus, Illuminate Pride, CZAR, Ahwassa...)
    -- Con max 2 T4 in costruzione (gate BeingBuilt sui SCALE), il pool T3 è più grande
    -- → InstanceCount=30 garantisce che molti ingegneri assistano le 1-2 costruzioni attive
    Builder {
        BuilderName = 'OWPlus T3 Assist Exp Mobile',
        PlatoonTemplate = 'T3EngineerAssistNoSUB',
        Priority = 17500,
        InstanceCount = 30,
        BuilderConditions = {
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.05 } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.ENGINEER * categories.TECH3 - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 250,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE'},
                AssistUntilFinished = true,
                AssistClosestUnit = true,
                Time = 0,
            }
        },
    },

    -- T2 engineers assist T4 mobile (supporto extra quando tanti T4 in cantiere)
    Builder {
        BuilderName = 'OWPlus T2 Assist Exp Mobile',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 17400,
        InstanceCount = 20,
        BuilderConditions = {
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.05 } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.ENGINEER * categories.TECH2 - categories.STATIONASSISTPOD } },
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 250,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE'},
                AssistUntilFinished = true,
                AssistClosestUnit = true,
                Time = 0,
            }
        },
    },
}
