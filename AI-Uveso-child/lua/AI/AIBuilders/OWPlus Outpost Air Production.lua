-- OWPlus Outpost Air Production.lua
--
-- Sess.100 parte 9 (piano fabbriche approvato): ogni avamposto ora costruisce 2 fabbriche terra +
-- 1 AEREA (OWPlusFactoryTargets.lua, ricetta iniziale). Fino a qui 'OWPlus Outpost Production'
-- conteneva SOLO builder di terra: una fabbrica aerea di avamposto sarebbe rimasta ferma.
-- Questo gruppo aggiunge la produzione aerea, agganciata accanto agli altri gruppi OWPlus di
-- avamposto (hook/lua/platoon.lua, stessi 3 punti di 'OWPlus Outpost Production').
--
-- Scelte di design:
--  * Solo unita' vanilla, ma per CATEGORIA: si usano i PlatoonTemplate nativi di fabbrica
--    (T1AirFighter, T1AirBomber, T1Gunship, T2FighterBomber, T2AirGunship, T3AirFighter,
--    T3AirBomber, T3AirGunship) che il motore risolve per fazione via FactionSquads. Aggiungere
--    un'unita' moddata = aggiungere una riga in OWPLUS_AIR_CANDIDATES (scalabile).
--  * Selezione casuale tra i candidati validi (Random() nella PriorityFunction, sync-safe, NON
--    math.random) come 'OWPlus Outpost Production' (terra): con Priority fissa uguale il motore
--    sceglierebbe sempre il primo registrato.
--  * NON si agganciano i gruppi nativi 'U123 Air Builders*': hanno soglie di conteggio GLOBALI
--    minime (es. "meno di 2 caccia in tutto") e con un esercito grosso non produrrebbero.
--  * Gate come la terra: OWPlusFactoryNotUpgrading, minimo ingegneri, tetto pool a livello di location.
--  * Disattivato dal flag OWPlusMultiFactoryDisabled (PriorityFunction = 0).

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local OWPlusLogCond = '/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua'
local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')

local OWPLUS_AIR_PRODUCTION_BASE_PRIORITY = 18670
local OWPLUS_AIR_PRODUCTION_MIN_ENGINEERS = 5
-- Tetto di unita' aeree d'attacco NON ancora inquadrate a livello di location (ArmyPool nel raggio):
-- sopra i minimi dei plotoni aria (15) cosi' da non bloccare mai la formazione dei plotoni.
local OWPLUS_AIR_PRODUCTION_MAX_POOL = 40

local OWPLUS_AIR_POOL_CATEGORY = categories.MOBILE * categories.AIR * (categories.ANTIAIR + categories.BOMBER + categories.GROUNDATTACK)
    - categories.TRANSPORTFOCUS - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL - categories.ANTINAVY

-- { nome breve, PlatoonTemplate nativo, tier fabbrica richiesto }
local OWPLUS_AIR_CANDIDATES = {
    { 'T1 Fighter',      'T1AirFighter',    1 },
    { 'T1 Bomber',       'T1AirBomber',     1 },
    { 'T1 Gunship',      'T1Gunship',       1 },
    { 'T2 FighterBomber','T2FighterBomber', 2 },
    { 'T2 Gunship',      'T2AirGunship',    2 },
    { 'T3 Fighter',      'T3AirFighter',    3 },
    { 'T3 Bomber',       'T3AirBomber',     3 },
    { 'T3 Gunship',      'T3AirGunship',    3 },
}

local function OWPlusOutpostAirBuilder(shortName, template, tier)
    local label = 'Air Production ' .. shortName
    return Builder {
        BuilderName = 'OWPlus Outpost ' .. label,
        PlatoonTemplate = template,
        Priority = OWPLUS_AIR_PRODUCTION_BASE_PRIORITY,
        PriorityFunction = function(self, aiBrain)
            if OWPlusFactoryTargetsMod.OWPlusMultiFactoryDisabled then
                return 0
            end
            return OWPLUS_AIR_PRODUCTION_BASE_PRIORITY + Random(1, 1000)
        end,
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusOutpostAttackEnabled', {} },
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusOutpostFactoryIsTech', { 'LocationType', tier } },
            { OWPlusLogCond, 'OWPlusFactoryNotUpgrading', { 'LocationType', label } },
            { OWPlusLogCond, 'OWPlusDebugEngineersAtLeast', { 'LocationType', OWPLUS_AIR_PRODUCTION_MIN_ENGINEERS, label } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', OWPLUS_AIR_PRODUCTION_MAX_POOL, OWPLUS_AIR_POOL_CATEGORY } },
        },
        BuilderType = 'Air',
    }
end

local owplusAirBuilders = {
    BuilderGroupName = 'OWPlus Outpost Air Production',
    BuildersType = 'FactoryBuilder',
}
for _, c in OWPLUS_AIR_CANDIDATES do
    table.insert(owplusAirBuilders, OWPlusOutpostAirBuilder(c[1], c[2], c[3]))
end
BuilderGroup(owplusAirBuilders)

LOG('[OWPlus-FACTORY] OWPlus Outpost Air Production: registrati ' .. table.getn(OWPLUS_AIR_CANDIDATES) .. ' builder aria per avamposto')
