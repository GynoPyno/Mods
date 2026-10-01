-- OWPlus Dispersed Base.lua
--
-- Costruisce le fabbriche nelle 4 sub-location diagonali registrate in FirstBaseFunction
-- (BASE_NE, BASE_SE, BASE_SW, BASE_NW) a ~65 unità dal CDR, schema 'x'.
--
-- MECCANISMO: tutti i builder usano PlatoonTemplate = 'OWPlusDispersedBuilder' (Plan = OWPlusDispersedBuildAI).
-- OWPlusDispersedBuildAI legge cons.LocationType, trova le coordinate in
-- aiBrain.OWPlusSubBases[locType] e passa targetPos come 'reference' tabella ad AIExecuteBuildStructure.
-- Uveso usa reference={x,y,z} come centro di ricerca → l'ingegnere costruisce vicino al nodo.
--
-- SEQUENZA land (round-robin, 2 giri su 4 nodi):
--   Giro 1: NE→SE→SW→NW (global land count 2→3→4→5)
--   Giro 2: NE→SE→SW→NW (global land count 6→7→8→9)
--   Prerequisito giro 1: MAIN ha costruito la sua (count ≥1)
--   Prerequisito giro 2: tutti i nodi hanno completato il giro 1 (count ≥5)
--
-- SEQUENZA air (round-robin, 4 giri su 4 nodi):
--   Giro 1: NE→SE→SW→NW (air count 1→4), prerequisito: land count ≥2..5
--   Giro 2: NE→SE→SW→NW (air count 5→8), prerequisito: air count ≥4
--   Giro 3: NE→SE→SW→NW (air count 9→12), prerequisito: air count ≥8
--   Giro 4: NE→SE→SW→NW (air count 13→16), prerequisito: air count ≥12
--
-- TOTALI risultanti: 9 land (1 MAIN + 4 nodi × 2) + 16 air (4 nodi × 4)

local categories = categories
local EBC  = '/lua/editor/EconomyBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'

local LAND_FAC = categories.STRUCTURE * categories.FACTORY * categories.LAND
local AIR_FAC  = categories.STRUCTURE * categories.FACTORY * categories.AIR
local ENG      = categories.MOBILE * categories.ENGINEER - categories.COMMAND

-- Sess.100 parte 9 (piano fabbriche approvato): 2 terra + 1 aria PER ANGOLO, contate col
-- censimento fisico per base (OWPlusFactoryTargets.lua) invece delle finestre di conteggio
-- GLOBALE esatto dei 24 builder storici qui sotto (es. NE parte solo se le terra totali sono
-- esattamente 1: appena MAIN o gli avamposti aggiungono una fabbrica la finestra salta e
-- l'angolo non costruisce piu'). I 24 builder storici restano in fondo al file, disattivati
-- da PriorityFunction finche' OWPlusMultiFactoryDisabled = false (rollback col flag a true).
local OWPlusFactoryTargetsFile = '/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua'
local OWPlusFactoryTargetsMod = import(OWPlusFactoryTargetsFile)

-- Sess.100 parte 11 (decisione utente, eccezione esplicita a 'ordine di priorita invariato' del piano):
-- i builder MultiFactory degli angoli erano a 15400/15200, SOTTO tutta l'economia (17800-19400): dopo
-- ~10 min gli angoli restavano a 1 terra + 1 aria con le condizioni vere (sospetto affamamento ingegneri).
-- Ora a 17880, come i MultiFactory di MAIN. Reversibile cambiando solo questa costante.
local OWPlusCornerFactoryPriority = 17880

BuilderGroup {
    BuilderGroupName = 'OWPlus Dispersed Base',
    BuildersType = 'EngineerBuilder',

    -- =========================================================
    -- MULTI-FABBRICA PER ANGOLO (nuovo): 4 terra + 4 aria, uno per angolo
    -- =========================================================

    Builder {
        BuilderName = 'OWPlus MultiFactory Land BASE_NE',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = OWPlusCornerFactoryPriority,
        PriorityFunction = OWPlusFactoryTargetsMod.OWPlusMultiFactoryPriority(OWPlusCornerFactoryPriority),
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, LAND_FAC } },  -- aspetta 1a fabbrica MAIN
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesBelowTarget', { 'BASE_NE', 'land', 'MultiFactory Land BASE_NE' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesNotBuilding', { 'BASE_NE', 'land', 'MultiFactory Land BASE_NE' } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NE',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus MultiFactory Land BASE_SE',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = OWPlusCornerFactoryPriority,
        PriorityFunction = OWPlusFactoryTargetsMod.OWPlusMultiFactoryPriority(OWPlusCornerFactoryPriority),
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, LAND_FAC } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesBelowTarget', { 'BASE_SE', 'land', 'MultiFactory Land BASE_SE' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesNotBuilding', { 'BASE_SE', 'land', 'MultiFactory Land BASE_SE' } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SE',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus MultiFactory Land BASE_SW',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = OWPlusCornerFactoryPriority,
        PriorityFunction = OWPlusFactoryTargetsMod.OWPlusMultiFactoryPriority(OWPlusCornerFactoryPriority),
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, LAND_FAC } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesBelowTarget', { 'BASE_SW', 'land', 'MultiFactory Land BASE_SW' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesNotBuilding', { 'BASE_SW', 'land', 'MultiFactory Land BASE_SW' } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SW',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus MultiFactory Land BASE_NW',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = OWPlusCornerFactoryPriority,
        PriorityFunction = OWPlusFactoryTargetsMod.OWPlusMultiFactoryPriority(OWPlusCornerFactoryPriority),
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, LAND_FAC } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesBelowTarget', { 'BASE_NW', 'land', 'MultiFactory Land BASE_NW' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesNotBuilding', { 'BASE_NW', 'land', 'MultiFactory Land BASE_NW' } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NW',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    -- Aria: solo dopo la prima terra dello STESSO angolo (come nello schema storico: aria dopo la terra del nodo)
    Builder {
        BuilderName = 'OWPlus MultiFactory Air BASE_NE',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = OWPlusCornerFactoryPriority,
        PriorityFunction = OWPlusFactoryTargetsMod.OWPlusMultiFactoryPriority(OWPlusCornerFactoryPriority),
        InstanceCount = 1,
        BuilderConditions = {
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesAtLeast', { 'BASE_NE', 1, 'land', 'MultiFactory Air BASE_NE' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesBelowTarget', { 'BASE_NE', 'air', 'MultiFactory Air BASE_NE' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesNotBuilding', { 'BASE_NE', 'air', 'MultiFactory Air BASE_NE' } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus MultiFactory Air BASE_SE',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = OWPlusCornerFactoryPriority,
        PriorityFunction = OWPlusFactoryTargetsMod.OWPlusMultiFactoryPriority(OWPlusCornerFactoryPriority),
        InstanceCount = 1,
        BuilderConditions = {
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesAtLeast', { 'BASE_SE', 1, 'land', 'MultiFactory Air BASE_SE' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesBelowTarget', { 'BASE_SE', 'air', 'MultiFactory Air BASE_SE' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesNotBuilding', { 'BASE_SE', 'air', 'MultiFactory Air BASE_SE' } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus MultiFactory Air BASE_SW',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = OWPlusCornerFactoryPriority,
        PriorityFunction = OWPlusFactoryTargetsMod.OWPlusMultiFactoryPriority(OWPlusCornerFactoryPriority),
        InstanceCount = 1,
        BuilderConditions = {
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesAtLeast', { 'BASE_SW', 1, 'land', 'MultiFactory Air BASE_SW' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesBelowTarget', { 'BASE_SW', 'air', 'MultiFactory Air BASE_SW' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesNotBuilding', { 'BASE_SW', 'air', 'MultiFactory Air BASE_SW' } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus MultiFactory Air BASE_NW',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = OWPlusCornerFactoryPriority,
        PriorityFunction = OWPlusFactoryTargetsMod.OWPlusMultiFactoryPriority(OWPlusCornerFactoryPriority),
        InstanceCount = 1,
        BuilderConditions = {
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesAtLeast', { 'BASE_NW', 1, 'land', 'MultiFactory Air BASE_NW' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesBelowTarget', { 'BASE_NW', 'air', 'MultiFactory Air BASE_NW' } },
            { OWPlusFactoryTargetsFile, 'OWPlusFactoriesNotBuilding', { 'BASE_NW', 'air', 'MultiFactory Air BASE_NW' } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    -- =========================================================
    -- BLOCCO STORICO: 24 builder a finestra di conteggio globale (disattivati dal flag, vedi fondo file)
    -- =========================================================

    -- =========================================================
    -- LAND FACTORIES — GIRO 1 (una per nodo, sequenziali)
    -- =========================================================

    Builder {
        BuilderName = 'OWPlus Land Factory BASE_NE',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15400,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, LAND_FAC } },  -- aspetta 1° fabbrica MAIN
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 2, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, LAND_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NE',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Land Factory BASE_SE',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15400,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 3, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, LAND_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SE',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Land Factory BASE_SW',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15400,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 4, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, LAND_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SW',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Land Factory BASE_NW',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15400,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 5, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, LAND_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NW',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    -- =========================================================
    -- LAND FACTORIES — GIRO 2 (seconda per nodo, dopo giro 1 completo)
    -- =========================================================

    Builder {
        BuilderName = 'OWPlus Land Factory BASE_NE R2',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15400,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, LAND_FAC } },  -- giro 1 completo (4 nodi + MAIN)
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 6, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, LAND_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NE',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Land Factory BASE_SE R2',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15400,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 7, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, LAND_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SE',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Land Factory BASE_SW R2',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15400,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 8, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, LAND_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SW',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Land Factory BASE_NW R2',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15400,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 7, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 9, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, LAND_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NW',
                BuildClose      = true,
                BuildStructures = { 'T1LandFactory' },
            }
        },
    },

    -- =========================================================
    -- AIR FACTORIES — GIRO 1 (una per nodo, dopo la land corrispondente)
    -- =========================================================

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_NE',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, LAND_FAC } },  -- NE land costruita (count ≥2)
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 1, AIR_FAC  } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_SE',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 2, AIR_FAC  } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_SW',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 3, AIR_FAC  } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_NW',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, LAND_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 4, AIR_FAC  } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    -- =========================================================
    -- AIR FACTORIES — GIRO 2 (gate: air count ≥4 = giro 1 completo)
    -- =========================================================

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_NE R2',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, AIR_FAC } },  -- giro 1 completo (≥4 air)
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 5, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_SE R2',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 6, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_SW R2',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 7, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_NW R2',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 8, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    -- =========================================================
    -- AIR FACTORIES — GIRO 3 (gate: air count ≥8 = giro 2 completo)
    -- =========================================================

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_NE R3',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 7, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 9, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_SE R3',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 8, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 10, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_SW R3',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 9, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 11, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_NW R3',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 12, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    -- =========================================================
    -- AIR FACTORIES — GIRO 4 (gate: air count ≥12 = giro 3 completo)
    -- =========================================================

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_NE R4',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 11, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 13, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_SE R4',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 12, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 14, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SE',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_SW R4',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 13, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 15, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_SW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },

    Builder {
        BuilderName = 'OWPlus Air Factory BASE_NW R4',
        PlatoonTemplate = 'OWPlusDispersedBuilder',
        Priority = 15200,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 14, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsWithCategory',   { 16, AIR_FAC } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, AIR_FAC * categories.TECH1 } },
            { UCBC, 'PoolGreaterAtLocation', { 'MAIN', 0, ENG } },
            { EBC,  'GreaterThanEconStorageRatio', { 0.10, 0.20 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                LocationType    = 'BASE_NW',
                BuildClose      = true,
                BuildStructures = { 'T1AirFactory' },
            }
        },
    },
}

-- ===========================================================================
-- Rollback (sess.100 parte 9): i 24 builder storici a finestra di conteggio globale sono attivi
-- SOLO col flag OWPlusMultiFactoryDisabled = true. 'Builder {...}' registra la spec in
-- Builders[nome] e restituisce il nome (GlobalBuilderTemplate.lua): la PriorityFunction si
-- aggancia li' (Builder.lua CalculatePriority la rilegge da Builders[BuilderName] ad ogni ciclo).
-- I builder 'MultiFactory' (nuovi) sono esclusi dal ciclo.
-- ===========================================================================
do
    local gated = 0
    local group = BuilderGroups and BuilderGroups['OWPlus Dispersed Base']
    if group and Builders then
        for _, builderName in group do
            if type(builderName) == 'string' and Builders[builderName]
                and not string.find(builderName, 'MultiFactory', 1, true) then
                Builders[builderName].PriorityFunction = OWPlusFactoryTargetsMod.OWPlusLegacyFactoryPriority(Builders[builderName].Priority)
                gated = gated + 1
            end
        end
    end
    LOG('[OWPlus-FACTORY] OWPlus Dispersed Base: ' .. gated .. ' builder storici (finestra globale) gated dal flag OWPlusMultiFactoryDisabled (attesi 24)')
end
