-- OWPlus Main Air Production.lua
--
-- Sess.101 (decisioni utente 2026-10-10 / 2026-10-14): la produzione aerea d'attacco di MAIN (e
-- degli angoli della X, che stanno nel manager di MAIN) passa dal catalogo OWPlusAirCatalog.lua
-- (57 unita' vanilla + moddate) invece dei builder nativi 'U123 Air Builders ADAPTIVE', che
-- decidono per rapporti tra tipi di unita' e con l'economia satura restano fermi.
--
--  * Fasce di priorita' per tier che non si sovrappongono (T3 > T2 > T1, Random() dentro la
--    fascia): ogni fabbrica costruisce il tier piu' alto che sa fare (CanBuildPlatoon nativo
--    scarta per fabbrica i template che non puo' costruire). Fasce SOTTO trasporti (400-600,
--    il primo a 18500), scout (20000) e anti-sperimentale (345-370): quelli continuano a uscire
--    quando le loro condizioni li chiedono.
--  * Il T1 si spegne appena l'IA ha una fabbrica aerea T2 o T3 (stessa regola della terra).
--  * Ruolo caccia/attacco al suolo scelto da OWPlusAirRoleAllowed (scaglioni adattivi).
--  * Tetto globale di aerei in attesa di plotone (OWPlusAirWaitingBelow).
--  * In fondo: i 14 builder nativi d'attacco di 'U123 Air Builders ADAPTIVE' si spengono SOLO
--    per le IA OverwhelmPlus; i 6 siluranti restano attivi; le altre IA non cambiano.
--
-- Rollback: OWPlusAirCatalogDisabled = true (OWPlusFactoryTargets.lua).

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local EBC  = '/lua/editor/EconomyBuildConditions.lua'
local OWPlusAirCond = '/mods/AI-Uveso-child/lua/AI/OWPlusAirCatalog.lua'
local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')
local OWPlusAirCatalogMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusAirCatalog.lua')

-- base della fascia per tier; il roll aggiunge 1..OWPLUS_MAIN_AIR_RANDOM_SPAN (fasce disgiunte)
local OWPLUS_MAIN_AIR_TIER_PRIORITY = { 200, 240, 280 }
local OWPLUS_MAIN_AIR_RANDOM_SPAN = 39
local OWPLUS_MAIN_AIR_T2PLUS_FACTORY = categories.STRUCTURE * categories.FACTORY * categories.AIR * (categories.TECH2 + categories.TECH3)

local function OWPlusMainAirBuilder(c)
    local role, tier, faction, unitId = c[1], c[2], c[3], c[4]
    local base = OWPLUS_MAIN_AIR_TIER_PRIORITY[tier]
    local conditions = {
        { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
        { OWPlusAirCond, 'OWPlusAirWaitingBelow', { OWPlusAirCatalogMod.OWPLUS_AIR_WAITING_MAX } },
    }
    if tier == 1 then
        -- niente T1 appena esiste una fabbrica aerea T2/T3 (no spam T1 a fine partita)
        table.insert(conditions, { UCBC, 'HaveLessThanUnitsWithCategory', { 1, OWPLUS_MAIN_AIR_T2PLUS_FACTORY } })
    end
    return Builder {
        BuilderName = 'OWPlus Main Air ' .. role .. ' T' .. tier .. ' ' .. faction .. ' ' .. unitId,
        PlatoonTemplate = OWPlusAirCatalogMod.OWPlusAirTemplateName(c),
        Priority = base,
        PriorityFunction = function(self, aiBrain)
            if OWPlusFactoryTargetsMod.OWPlusAirCatalogDisabled then
                return 0
            end
            if not OWPlusAirCatalogMod.OWPlusAirRoleAllowed(aiBrain, role) then
                return 0
            end
            return base + Random(1, OWPLUS_MAIN_AIR_RANDOM_SPAN)
        end,
        BuilderConditions = conditions,
        BuilderType = 'Air',
    }
end

local owplusMainAirBuilders = {
    BuilderGroupName = 'OWPlus Main Air Production',
    BuildersType = 'FactoryBuilder',
}
for _, c in ipairs(OWPlusAirCatalogMod.OWPLUS_AIR_CATALOG) do
    table.insert(owplusMainAirBuilders, OWPlusMainAirBuilder(c))
end
BuilderGroup(owplusMainAirBuilders)

LOG('[OWPlus-AIR] OWPlus Main Air Production: registrati ' .. table.getn(OWPlusAirCatalogMod.OWPLUS_AIR_CATALOG)
    .. ' builder aerei (catalogo) per MAIN, disattivato=' .. tostring(OWPlusFactoryTargetsMod.OWPlusAirCatalogDisabled))

-- ===========================================================================
-- Builder aerei nativi di Uveso: spenti solo per OverwhelmPlus (siluranti esclusi).
-- 'Builder {...}' registra la spec in Builders[nome] e Builder.lua CalculatePriority rilegge
-- Builders[nome].PriorityFunction ad ogni ciclo (chiamata come metodo: self = la spec).
-- Un builder senza PriorityFunction originale torna alla sua Priority statica.
-- ===========================================================================
-- Spegne per le sole IA OverwhelmPlus i builder del gruppo nativo 'groupName' il cui nome NON
-- contiene 'keepPattern' (nil = tutti). Restituisce (spenti, mantenuti), oppure nil se il gruppo
-- non e' ancora registrato.
local function OWPlusGateNativeGroupForPlus(groupName, keepPattern)
    local group = BuilderGroups and BuilderGroups[groupName]
    if not group or not Builders then
        return nil
    end
    local gated, kept = 0, 0
    for _, builderName in ipairs(group) do
        local spec = type(builderName) == 'string' and Builders[builderName]
        if spec then
            if keepPattern and string.find(builderName, keepPattern, 1, true) then
                kept = kept + 1
            else
                local original = spec.PriorityFunction
                local static = spec.Priority
                spec.PriorityFunction = function(self, aiBrain)
                    if not OWPlusFactoryTargetsMod.OWPlusAirCatalogDisabled and OWPlusAirCatalogMod.OWPlusIsPlusBrain(aiBrain) then
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
    end
    return gated, kept
end

do
    local gated, kept = OWPlusGateNativeGroupForPlus('U123 Air Builders ADAPTIVE', 'TorpedoBomber')
    if gated then
        LOG('[OWPlus-AIR] U123 Air Builders ADAPTIVE: OK, ' .. gated .. ' builder d\'attacco spenti per OverwhelmPlus (attesi 14), '
            .. kept .. ' siluranti mantenuti (attesi 6)')
    else
        WARN('[OWPlus-AIR] U123 Air Builders ADAPTIVE non trovato in BuilderGroups: i builder aerei nativi NON sono spenti '
            .. '(MAIN produrrebbe aria sia dal catalogo sia dai nativi)')
    end
end

-- ===========================================================================
-- Sess.101 (decisione utente 2026-10-14, "via di mezzo"): former aerei nativi delle basi
-- d'espansione Uveso (template UvesoExpansionArea*, MAIN non li usa). Si spegne solo il gruppo
-- d'attacco/sfogo 'U123 Air Formers Trasher' (Cap, Bomber > 50, engineer Bomber, cacciatori di
-- ACU): template con minimo 1, partivano in plotoni da 1-3 aerei sottraendoli ai batch (105 aerei
-- su 1115 nel test del 2026-10-14). Restano attivi i difensivi PanicZone/MilitaryZone (scattano
-- solo con nemici vicini alla base) ed EnemyZone (gia' sostituito dai batch, OWPlus Air Attack Batching.lua).
-- ===========================================================================
do
    local gated = OWPlusGateNativeGroupForPlus('U123 Air Formers Trasher', nil)
    if gated then
        LOG('[OWPlus-AIR] U123 Air Formers Trasher: OK, ' .. gated .. ' former d\'attacco spenti per OverwhelmPlus (attesi 10)')
    else
        WARN('[OWPlus-AIR] U123 Air Formers Trasher non trovato in BuilderGroups: i former aerei d\'attacco delle basi d\'espansione NON sono spenti')
    end
end
