-- OWPlus Naval Production.lua
--
-- Sess.102 (decisioni utente 2026-10-15/16, approccio A): navale di Overwhelm+. Tre gruppi, usati
-- da MAIN (Uveso MainBase OverwhelmPlus.lua) e dalle basi navali (OWPlus ExpansionNaval.lua):
--
--  * 'OWPlus Naval Expansion' (ingegneri, solo MAIN): copia dei builder nativi "Vacant NavalArea"
--    di 'U1 Expansion Builder' (gruppo tolto da MAIN in Fase 9-F20 perche' fondava anche le basi
--    di terra enormi). Al posto di IsNavalExpansionsAllowed usa OWPlusNavalExpansionAllowed
--    (tetto OWPLUS_NAVAL_BASES_MAX). Il cantiere costruito lontano dalle basi esistenti diventa
--    una base 'Naval Area' (AddFactoryToClosestManager di Uveso) con il template OWPlusExpansionNaval.
--  * 'OWPlus Naval Production' (cantieri): catalogo di OWPlusNavalCatalog.lua, fasce per tier che
--    non si sovrappongono (T3 > T2 > T1, Random() dentro la fascia, probabilita' uguale tra le navi
--    dello stesso tier). T1 spento appena l'IA ha un cantiere T2/T3. Fasce sotto gli ingegneri
--    costruiti dai cantieri (18400).
--  * 'OWPlus Naval Formers' (plotoni): superficie 10-30 e sottomarini 6-20, senza FormRadius, cioe'
--    raccolti nel raggio della base (navi di due mari diversi non possono riunirsi). Bersagli:
--    navi nemiche, difese navali, cantieri, difese costiere, poi strutture.
--
-- In fondo: builder e former navali nativi concorrenti spenti SOLO per Overwhelm+ (PanicZone e
-- siluranti restano). Rollback: OWPlusNavalCatalogDisabled = true (OWPlusFactoryTargets.lua).

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local EBC  = '/lua/editor/EconomyBuildConditions.lua'
local OWPlusNavalCond = '/mods/AI-Uveso-child/lua/AI/OWPlusNavalCatalog.lua'
local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')
local OWPlusNavalCatalogMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusNavalCatalog.lua')
local BasePanicZone, BaseMilitaryZone, BaseEnemyZone = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua').GetDangerZoneRadii()

-- ===========================================================================
-- Fondazione delle basi navali
-- ===========================================================================
local function OWPlusNavalExpansionBuilder(name, priority, radius, requireTransport, extraConditions)
    local conditions = {
        { EBC, 'GreaterThanEconIncome', { 1.0, 6.0 } },
        { OWPlusNavalCond, 'OWPlusNavalExpansionAllowed', {} },
        { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', radius, -1000, 100, 1, 'AntiSurface' } },
    }
    for _, c in ipairs(extraConditions or {}) do
        table.insert(conditions, 1, c)
    end
    return Builder {
        BuilderName = name,
        PlatoonTemplate = 'EngineerBuilder',
        Priority = priority,
        InstanceCount = 1,
        PriorityFunction = function(self, aiBrain)
            if OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled then
                return 0
            end
            if aiBrain.PriorityManager.NoRush1stPhaseActive then
                return 0
            end
            return priority
        end,
        BuilderConditions = conditions,
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = requireTransport,
            Construction = {
                BuildClose = false,
                BaseTemplate = 'ExpansionBaseTemplates',
                ExpansionBase = true,
                NearMarkerType = 'Naval Area',
                LocationRadius = radius,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 100,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                ExpansionRadius = 120,
                BuildStructures = {
                    'T1SeaFactory',
                    'T1SeaFactory',
                },
            },
        },
    }
end

BuilderGroup {
    BuilderGroupName = 'OWPlus Naval Expansion',
    BuildersType = 'EngineerBuilder',
    OWPlusNavalExpansionBuilder('OWPlus Vacant NavalArea 150', 17880, 150, true),
    OWPlusNavalExpansionBuilder('OWPlus Vacant NavalArea 250', 17880, 250, true),
    OWPlusNavalExpansionBuilder('OWPlus Vacant NavalArea 1000', 17860, 1000, true),
    -- mappe d'acqua senza percorso di terra verso il nemico: niente trasporto
    OWPlusNavalExpansionBuilder('OWPlus Vacant NavalArea Watermap', 17880, 1000, false,
        { { '/lua/editor/MiscBuildConditions.lua', 'CanPathToCurrentEnemy', { false, 'LocationType' } } }),
}

-- ===========================================================================
-- Sess.102 (test del 2026-10-16): cantieri, massimo OWPLUS_NAVAL_SHIPYARDS_PER_BASE per base
-- ===========================================================================
-- Sostituisce per Overwhelm+ 'U1 Factory Builders Naval' (spento in fondo al file). Il posto lo
-- sceglie l'hook di AIExecuteBuildStructure (distanza 32, dentro il raggio della base, nessun
-- ripiego nativo). Un builder per tier di ingegnere: 'EngineerBuilder' prende solo i T1.
local function OWPlusNavalShipyardBuilder(name, template)
    return Builder {
        BuilderName = name,
        PlatoonTemplate = template,
        Priority = 16600,
        InstanceCount = 1,
        PriorityFunction = function(self, aiBrain)
            if OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled then
                return 0
            end
            return 16600
        end,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.01, 0.01 } },
            { EBC, 'GreaterThanEconIncome', { 0.8, 0.1 } },
            { OWPlusNavalCond, 'OWPlusNavalShipyardNeeded', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                BuildStructures = {
                    'T1SeaFactory',
                },
            },
        },
    }
end

BuilderGroup {
    BuilderGroupName = 'OWPlus Naval Shipyards',
    BuildersType = 'EngineerBuilder',
    OWPlusNavalShipyardBuilder('OWPlus Naval Shipyard T1 engineer', 'EngineerBuilder'),
    OWPlusNavalShipyardBuilder('OWPlus Naval Shipyard T2 engineer', 'T2EngineerBuilder'),
    OWPlusNavalShipyardBuilder('OWPlus Naval Shipyard T3 engineer', 'T3EngineerBuilder'),
}

-- ===========================================================================
-- Sess.102 (decisione utente 2026-10-16): difese delle basi navali, formula degli avamposti
-- ===========================================================================
-- Un builder per tipo (antinave / AA / scudi) e per tier: la condizione e' vera solo se il tier
-- attivo della base e' quello del builder, cosi' ogni tier lo costruisce un ingegnere di quel
-- tier. Il token 'OWPlusNavalDef_<tipo>_<tier>' lo traduce l'hook di AIExecuteBuildStructure
-- (pool vanilla + moddate, posto vicino alla base lontano dai cantieri).
local OWPLUS_NAVAL_DEFENSE_PRIORITY = 17000
local OWPLUS_NAVAL_DEFENSE_TEMPLATE = { 'EngineerBuilder', 'T2EngineerBuilder', 'T3EngineerBuilder' }

local function OWPlusNavalDefenseBuilder(kind, tier)
    return Builder {
        BuilderName = 'OWPlus Naval Defense ' .. kind .. ' T' .. tier,
        PlatoonTemplate = OWPLUS_NAVAL_DEFENSE_TEMPLATE[tier],
        Priority = OWPLUS_NAVAL_DEFENSE_PRIORITY,
        InstanceCount = 2,
        PriorityFunction = function(self, aiBrain)
            if OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled then
                return 0
            end
            return OWPLUS_NAVAL_DEFENSE_PRIORITY
        end,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.05, 0.10 } },
            { OWPlusNavalCond, 'OWPlusNavalDefenseNeeded', { 'LocationType', kind, tier } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                BuildStructures = {
                    'OWPlusNavalDef_' .. kind .. '_' .. tier,
                },
            },
        },
    }
end

local owplusNavalDefenseBuilders = {
    BuilderGroupName = 'OWPlus Naval Base Defenses',
    BuildersType = 'EngineerBuilder',
}
for tier = 1, 3 do
    table.insert(owplusNavalDefenseBuilders, OWPlusNavalDefenseBuilder('antinavy', tier))
    table.insert(owplusNavalDefenseBuilders, OWPlusNavalDefenseBuilder('aa', tier))
    if tier >= 2 then
        table.insert(owplusNavalDefenseBuilders, OWPlusNavalDefenseBuilder('shield', tier))
    end
end
BuilderGroup(owplusNavalDefenseBuilders)

-- ===========================================================================
-- Produzione dal catalogo
-- ===========================================================================
-- base della fascia per tier; il roll aggiunge 1..OWPLUS_NAVAL_RANDOM_SPAN (fasce disgiunte)
local OWPLUS_NAVAL_TIER_PRIORITY = { 200, 240, 280 }
local OWPLUS_NAVAL_RANDOM_SPAN = 39
local OWPLUS_NAVAL_T2PLUS_SHIPYARD = categories.STRUCTURE * categories.FACTORY * categories.NAVAL
    * (categories.TECH2 + categories.TECH3) - categories.EXTERNALFACTORYUNIT

local function OWPlusNavalBuilder(c)
    local tier, faction, unitId = c[1], c[2], c[3]
    local base = OWPLUS_NAVAL_TIER_PRIORITY[tier]
    local conditions = {
        { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
    }
    if tier == 1 then
        -- T1 solo a inizio partita: niente T1 appena esiste un cantiere T2/T3
        table.insert(conditions, { UCBC, 'HaveLessThanUnitsWithCategory', { 1, OWPLUS_NAVAL_T2PLUS_SHIPYARD } })
    end
    return Builder {
        BuilderName = 'OWPlus Naval T' .. tier .. ' ' .. faction .. ' ' .. unitId,
        PlatoonTemplate = OWPlusNavalCatalogMod.OWPlusNavalTemplateName(c),
        Priority = base,
        PriorityFunction = function(self, aiBrain)
            if OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled then
                return 0
            end
            return base + Random(1, OWPLUS_NAVAL_RANDOM_SPAN)
        end,
        BuilderConditions = conditions,
        BuilderType = 'Sea',
    }
end

local owplusNavalBuilders = {
    BuilderGroupName = 'OWPlus Naval Production',
    BuildersType = 'FactoryBuilder',
}
for _, c in ipairs(OWPlusNavalCatalogMod.OWPLUS_NAVAL_CATALOG) do
    table.insert(owplusNavalBuilders, OWPlusNavalBuilder(c))
end
BuilderGroup(owplusNavalBuilders)

-- ===========================================================================
-- Plotoni d'attacco navali
-- ===========================================================================
local OWPLUS_NAVAL_FORMER_PRIORITY = 265

local function OWPlusNavalFormerPriority(self, aiBrain)
    if OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled then
        return 0
    end
    return OWPLUS_NAVAL_FORMER_PRIORITY
end

BuilderGroup {
    BuilderGroupName = 'OWPlus Naval Formers',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'OWPlus Naval Surface Attack',
        PlatoonTemplate = 'OWPlus Naval Surface 10 30',
        Priority = OWPLUS_NAVAL_FORMER_PRIORITY,
        PriorityFunction = OWPlusNavalFormerPriority,
        InstanceCount = 20,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 1000000,
            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
            MoveToCategories = {
                categories.MOBILE * categories.NAVAL,
                categories.STRUCTURE * categories.NAVAL * categories.DEFENSE,
                categories.STRUCTURE * categories.FACTORY * categories.NAVAL,
                categories.STRUCTURE * categories.DEFENSE,
                categories.STRUCTURE,
                categories.ALLUNITS - categories.AIR,
            },
        },
        BuilderConditions = {},
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Naval Sub Attack',
        PlatoonTemplate = 'OWPlus Naval Sub 6 20',
        Priority = OWPLUS_NAVAL_FORMER_PRIORITY,
        PriorityFunction = OWPlusNavalFormerPriority,
        InstanceCount = 20,
        BuilderData = {
            SearchRadius = BaseEnemyZone,
            GetTargetsFromBase = false,
            AggressiveMove = true,
            AttackEnemyStrength = 1000000,
            -- siluri: solo bersagli in acqua
            TargetSearchCategory = (categories.NAVAL + categories.AMPHIBIOUS) - categories.HOVER,
            MoveToCategories = {
                categories.MOBILE * categories.NAVAL,
                categories.STRUCTURE * categories.NAVAL * categories.DEFENSE,
                categories.STRUCTURE * categories.FACTORY * categories.NAVAL,
                categories.STRUCTURE * categories.NAVAL,
                categories.NAVAL,
            },
        },
        BuilderConditions = {},
        BuilderType = 'Any',
    },
}

LOG('[OWPlus-NAVAL] OWPlus Naval Production: registrati 4 builder di fondazione basi navali, 3 builder di cantieri, '
    .. (table.getn(owplusNavalDefenseBuilders)) .. ' builder di difese (attesi 8), '
    .. table.getn(OWPlusNavalCatalogMod.OWPLUS_NAVAL_CATALOG) .. ' builder navali (catalogo) e 2 former d\'attacco, disattivato='
    .. tostring(OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled))

-- ===========================================================================
-- Builder e former navali nativi: spenti solo per OverwhelmPlus (stesso schema dell'aria,
-- Conoscenze_AI_54 §54.33). Restano: 'U123 Naval Formers PanicZone' (difesa con nemici vicini
-- alla base) e 'U123 TorpedoBomber Formers'.
-- ===========================================================================
local function OWPlusGateNativeNavalGroupForPlus(groupName)
    local group = BuilderGroups and BuilderGroups[groupName]
    if not group or not Builders then
        return nil
    end
    local gated = 0
    for _, builderName in ipairs(group) do
        local spec = type(builderName) == 'string' and Builders[builderName]
        if spec then
            local original = spec.PriorityFunction
            local static = spec.Priority
            spec.PriorityFunction = function(self, aiBrain)
                if not OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled and OWPlusNavalCatalogMod.OWPlusIsPlusBrain(aiBrain) then
                    return 0
                end
                if original then
                    return original(self, aiBrain)
                end
                return static
            end
            gated = gated + 1
        end
    end
    return gated
end

do
    local expected = {
        { 'U1 Factory Builders Naval', 5 },     -- sess.102: sostituiti da 'OWPlus Naval Shipyards'
        { 'U123 Naval Builders', 14 },
        { 'U123 Naval Builders withPath', 14 },
        { 'U123 Naval Formers MilitaryZone', 2 },
        { 'U123 Naval Formers EnemyZone', 7 },
        { 'U123 Naval Formers Trasher', 1 },
    }
    for _, e in ipairs(expected) do
        local gated = OWPlusGateNativeNavalGroupForPlus(e[1])
        if gated then
            LOG('[OWPlus-NAVAL] ' .. e[1] .. ': OK, ' .. gated .. ' builder spenti per OverwhelmPlus (attesi ' .. e[2] .. ')')
        else
            WARN('[OWPlus-NAVAL] ' .. e[1] .. ' non trovato in BuilderGroups: i builder navali nativi NON sono spenti '
                .. '(Overwhelm+ produrrebbe/formerebbe navi anche con il sistema nativo)')
        end
    end
end
