-- OWPlus Main Land Production.lua
--
-- Sess.100 parte 12 (decisioni utente 2026-10-01): la produzione di terra di MAIN (e degli
-- angoli della X, che stanno nel manager di MAIN) usava solo 'OWPlus Land T2T3' = 5 template
-- vanilla, una sola unita' per fazione per tipo -> "costruisce sempre le stesse unita'".
-- Qui si riusa lo STESSO catalogo degli avamposti ('OWPlus Outpost Production', 172 candidati
-- vanilla + 9 mod) con gli stessi PlatoonTemplate (1 unita' per ordine, una sola fazione in
-- FactionSquads: per le altre fazioni il template risulta vuoto e il builder viene scartato).
-- Si riusa SOLO la scelta di cosa costruire: le unita' finiscono nell'ArmyPool di MAIN e da li'
-- nei plotoni misti batch 40/50 - 30/40 (OWPlus Formers.lua), non nel watcher degli avamposti.
--
-- Decisioni utente:
--  * proporzione come negli avamposti: ogni candidato ha la stessa probabilita' (Random() nella
--    PriorityFunction, sync-safe, mai math.random; con Priority fissa uguale il motore
--    sceglierebbe sempre il primo registrato);
--  * tutto il catalogo: bot, carri e artiglieria, T1/T2/T3;
--  * T1 SI', ma mai preferito a unita' piu' grosse e niente spam T1 a fine partita:
--      - fasce di priorita' per tier che non si sovrappongono (T3 > T2 > T1): una fabbrica che
--        puo' costruire T3 sceglie sempre un T3 (CanBuildPlatoon nativo scarta per fabbrica i
--        template che non puo' costruire, stesso meccanismo dei vecchi builder T2T3);
--      - il T1 si spegne del tutto appena l'IA ha UNA fabbrica di terra T2 o T3 (conteggio
--        globale, voluto: e' un interruttore di fase di gioco, non un obiettivo per base);
--  * i 5 vecchi builder vanilla sono spenti (OWPlus Land Naval.lua), rollback con
--    OWPlusMainCatalogProductionDisabled = true (OWPlusFactoryTargets.lua).
--
-- Fasce tutte SOTTO ingegneri/SACU di MAIN (18399+), come i vecchi builder (18100/18200).

local categories = categories
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local EBC  = '/lua/editor/EconomyBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'
local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')

-- base della fascia per tier; il roll aggiunge 1..OWPLUS_MAIN_LAND_RANDOM_SPAN (fasce disgiunte)
local OWPLUS_MAIN_LAND_TIER_PRIORITY = { 18000, 18100, 18200 }
local OWPLUS_MAIN_LAND_RANDOM_SPAN = 99
local OWPLUS_MAIN_LAND_T2PLUS_FACTORY = categories.STRUCTURE * categories.FACTORY * categories.LAND * (categories.TECH2 + categories.TECH3)

-- { tipo, tier, fazione, id } - generato dal catalogo di 'OWPlus Outpost Production.lua';
-- template = 'OWPlus Outpost <tipo> T<tier> <fazione> <id>' (OWPlus PlatoonTemplates Outpost.lua)
local OWPLUS_MAIN_LAND_CANDIDATES = {
    { 'Bot', 1, 'UEF', 'uel0106' },
    { 'Bot', 1, 'UEF', 'kel0101' },
    { 'Bot', 1, 'UEF', 'brnt1advbot' },
    { 'Bot', 1, 'UEF', 'brnt1bt' },
    { 'Bot', 1, 'UEF', 'brnt1btt2' },
    { 'Bot', 1, 'UEF', 'brnt1extk' },
    { 'Bot', 1, 'UEF', 'uel0108' },
    { 'Bot', 1, 'UEF', 'bel0109' },
    { 'Bot', 1, 'UEF', 'brnt1exm1' },
    { 'Bot', 1, 'UEF', 'brnt1exmob' },
    { 'Bot', 1, 'Aeon', 'ual0106' },
    { 'Bot', 1, 'Aeon', 'bal0110' },
    { 'Bot', 1, 'Aeon', 'brot1bt' },
    { 'Bot', 1, 'Aeon', 'brot1btt2' },
    { 'Bot', 1, 'Aeon', 'brot1btt2a' },
    { 'Bot', 1, 'Aeon', 'brot1btt3' },
    { 'Bot', 1, 'Aeon', 'brot1exm1' },
    { 'Bot', 1, 'Cybran', 'url0106' },
    { 'Bot', 1, 'Cybran', 'brl0110' },
    { 'Bot', 1, 'Cybran', 'brmt1advbot' },
    { 'Bot', 1, 'Cybran', 'brmt1at' },
    { 'Bot', 1, 'Cybran', 'brmt1beetle' },
    { 'Bot', 1, 'Cybran', 'brmt1exm1' },
    { 'Bot', 1, 'Cybran', 'orl0111' },
    { 'Bot', 1, 'Seraphim', 'bsl0106' },
    { 'Bot', 1, 'Seraphim', 'brpt1asta' },
    { 'Bot', 1, 'Seraphim', 'brpt1bt' },
    { 'Bot', 1, 'Seraphim', 'brpt1btbot' },
    { 'Bot', 1, 'Seraphim', 'brpt1exm1' },
    { 'Bot', 1, 'Seraphim', 'brpt1expbot' },
    { 'Bot', 1, 'Seraphim', 'brpt1htt3' },
    { 'Bot', 2, 'UEF', 'kel0201' },
    { 'Bot', 2, 'UEF', 'kel0202' },
    { 'Bot', 2, 'UEF', 'kel0204' },
    { 'Bot', 2, 'UEF', 'kel0205' },
    { 'Bot', 2, 'UEF', 'wel0207' },
    { 'Bot', 2, 'UEF', 'bel0211' },
    { 'Bot', 2, 'UEF', 'brnt2bm' },
    { 'Bot', 2, 'UEF', 'brnt2exlm' },
    { 'Bot', 2, 'UEF', 'brnt2exm1' },
    { 'Bot', 2, 'UEF', 'brnt2exmdf' },
    { 'Bot', 2, 'UEF', 'brnt2sniper' },
    { 'Bot', 2, 'Aeon', 'brot2exbm' },
    { 'Bot', 2, 'Aeon', 'brot2exm2' },
    { 'Bot', 2, 'Aeon', 'brot2asb' },
    { 'Bot', 2, 'Aeon', 'brot2exth' },
    { 'Bot', 2, 'Cybran', 'brmt2bm' },
    { 'Bot', 2, 'Seraphim', 'xsl0202' },
    { 'Bot', 2, 'Seraphim', 'ksl0201' },
    { 'Bot', 2, 'Seraphim', 'xsl0207' },
    { 'Bot', 2, 'Seraphim', 'wsl0205' },
    { 'Bot', 2, 'Seraphim', 'brpt2btbot' },
    { 'Bot', 2, 'Seraphim', 'brpt2exbot' },
    { 'Bot', 2, 'Seraphim', 'brpt2hvbot' },
    { 'Bot', 3, 'UEF', 'xel0305' },
    { 'Bot', 3, 'UEF', 'kel0301' },
    { 'Bot', 3, 'UEF', 'kel0302' },
    { 'Bot', 3, 'UEF', 'kel0303' },
    { 'Bot', 3, 'UEF', 'kel0306' },
    { 'Bot', 3, 'UEF', 'kel0307' },
    { 'Bot', 3, 'UEF', 'brnt3advbtbot' },
    { 'Bot', 3, 'UEF', 'wel0302' },
    { 'Bot', 3, 'UEF', 'wel0309' },
    { 'Bot', 3, 'UEF', 'bel0307' },
    { 'Bot', 3, 'UEF', 'bel0308' },
    { 'Bot', 3, 'UEF', 'brnt3abb' },
    { 'Bot', 3, 'UEF', 'brnt3ow' },
    { 'Bot', 3, 'Aeon', 'ual0303' },
    { 'Bot', 3, 'Aeon', 'kal0301' },
    { 'Bot', 3, 'Aeon', 'wal0305' },
    { 'Bot', 3, 'Aeon', 'eal0301' },
    { 'Bot', 3, 'Aeon', 'bal0310' },
    { 'Bot', 3, 'Aeon', 'brot3aa' },
    { 'Bot', 3, 'Aeon', 'brot3hm' },
    { 'Bot', 3, 'Aeon', 'brot3exm1' },
    { 'Bot', 3, 'Cybran', 'url0303' },
    { 'Bot', 3, 'Cybran', 'krl0301' },
    { 'Bot', 3, 'Cybran', 'krl0302' },
    { 'Bot', 3, 'Cybran', 'url0302' },
    { 'Bot', 3, 'Cybran', 'wrl0301' },
    { 'Bot', 3, 'Cybran', 'wrl0305' },
    { 'Bot', 3, 'Cybran', 'brmt3advbtbot' },
    { 'Bot', 3, 'Cybran', 'brmt3bt' },
    { 'Bot', 3, 'Cybran', 'brmt3garg' },
    { 'Bot', 3, 'Seraphim', 'xsl0305' },
    { 'Bot', 3, 'Seraphim', 'ksl0301' },
    { 'Bot', 3, 'Seraphim', 'wsl0405' },
    { 'Bot', 3, 'Seraphim', 'wsl0302' },
    { 'Bot', 3, 'Seraphim', 'wsl0308' },
    { 'Bot', 3, 'Seraphim', 'bsl0310' },
    { 'Bot', 3, 'Seraphim', 'brpt3bt' },
    { 'Tank', 1, 'UEF', 'uel0201' },
    { 'Tank', 1, 'UEF', 'brnt1ht' },
    { 'Tank', 1, 'UEF', 'brnt1htt2' },
    { 'Tank', 1, 'UEF', 'brnt1htt3' },
    { 'Tank', 1, 'UEF', 'brnt1mt' },
    { 'Tank', 1, 'UEF', 'brnt1mtt2' },
    { 'Tank', 1, 'UEF', 'brnt1mtt3' },
    { 'Tank', 1, 'Aeon', 'ual0201' },
    { 'Tank', 1, 'Aeon', 'brot1exm2' },
    { 'Tank', 1, 'Aeon', 'brot1extank' },
    { 'Tank', 1, 'Aeon', 'brot1lt' },
    { 'Tank', 1, 'Aeon', 'brot1mt' },
    { 'Tank', 1, 'Aeon', 'brot1mtt2' },
    { 'Tank', 1, 'Aeon', 'brot1mtt3' },
    { 'Tank', 1, 'Cybran', 'brmt1bt' },
    { 'Tank', 1, 'Cybran', 'brmt1btt2' },
    { 'Tank', 1, 'Cybran', 'brmt1btt3' },
    { 'Tank', 1, 'Cybran', 'brmt1extank' },
    { 'Tank', 1, 'Cybran', 'brmt1bm' },
    { 'Tank', 1, 'Cybran', 'brmt1bm2' },
    { 'Tank', 1, 'Cybran', 'brmt1ht' },
    { 'Tank', 1, 'Cybran', 'brmt1mt' },
    { 'Tank', 1, 'Seraphim', 'xsl0201' },
    { 'Tank', 1, 'Seraphim', 'brpt1extank2' },
    { 'Tank', 1, 'Seraphim', 'brpt1ht' },
    { 'Tank', 2, 'UEF', 'uel0202' },
    { 'Tank', 2, 'UEF', 'brnt2bt' },
    { 'Tank', 2, 'UEF', 'brnt2ht' },
    { 'Tank', 2, 'UEF', 'brnt2htt3' },
    { 'Tank', 2, 'Aeon', 'xal0203' },
    { 'Tank', 2, 'Aeon', 'lta3002' },
    { 'Tank', 2, 'Aeon', 'bal0206' },
    { 'Tank', 2, 'Aeon', 'brot2ht' },
    { 'Tank', 2, 'Aeon', 'brot2mt' },
    { 'Tank', 2, 'Cybran', 'url0202' },
    { 'Tank', 2, 'Cybran', 'wrl0302' },
    { 'Tank', 2, 'Cybran', 'brl0205' },
    { 'Tank', 2, 'Cybran', 'brmt2st' },
    { 'Tank', 2, 'Cybran', 'brmt2wildcat' },
    { 'Tank', 2, 'Cybran', 'brmt2abt' },
    { 'Tank', 2, 'Cybran', 'brmt2abtt3' },
    { 'Tank', 2, 'Cybran', 'brmt2ht' },
    { 'Tank', 2, 'Cybran', 'brmt2htt3' },
    { 'Tank', 2, 'Cybran', 'brmt2medm' },
    { 'Tank', 2, 'Seraphim', 'xsl0203' },
    { 'Tank', 3, 'UEF', 'wel0304' },
    { 'Tank', 3, 'UEF', 'brnt3bt' },
    { 'Tank', 3, 'UEF', 'brnt3ht' },
    { 'Tank', 3, 'Cybran', 'erl0301' },
    { 'Tank', 3, 'Cybran', 'brmt3bm2mk2' },
    { 'Tank', 3, 'Cybran', 'brmt3ht' },
    { 'Tank', 3, 'Cybran', 'brmt3lzt' },
    { 'Tank', 3, 'Cybran', 'brmt3rap' },
    { 'Tank', 3, 'Seraphim', 'xsl0303' },
    { 'Artillery', 1, 'UEF', 'uel0103' },
    { 'Artillery', 1, 'Aeon', 'ual0103' },
    { 'Artillery', 1, 'Aeon', 'brot1exmobart' },
    { 'Artillery', 1, 'Cybran', 'url0103' },
    { 'Artillery', 1, 'Seraphim', 'xsl0103' },
    { 'Artillery', 2, 'UEF', 'uel0111' },
    { 'Artillery', 2, 'UEF', 'brnt2exm2' },
    { 'Artillery', 2, 'UEF', 'brnt2potshot' },
    { 'Artillery', 2, 'Aeon', 'ual0111' },
    { 'Artillery', 2, 'Cybran', 'url0111' },
    { 'Artillery', 2, 'Cybran', 'umr_l0201' },
    { 'Artillery', 2, 'Cybran', 'brmt2beetle' },
    { 'Artillery', 2, 'Seraphim', 'xsl0111' },
    { 'Artillery', 3, 'UEF', 'uel0304' },
    { 'Artillery', 3, 'UEF', 'kel0304' },
    { 'Artillery', 3, 'UEF', 'kel0308' },
    { 'Artillery', 3, 'UEF', 'wel03041' },
    { 'Artillery', 3, 'UEF', 'brnt3ml' },
    { 'Artillery', 3, 'Aeon', 'ual0304' },
    { 'Artillery', 3, 'Aeon', 'kal0304' },
    { 'Artillery', 3, 'Cybran', 'url0304' },
    { 'Artillery', 3, 'Cybran', 'krl0304' },
    { 'Artillery', 3, 'Cybran', 'wrl1211' },
    { 'Artillery', 3, 'Cybran', 'brl0307' },
    { 'Artillery', 3, 'Cybran', 'brmt3ml' },
    { 'Artillery', 3, 'Seraphim', 'xsl0304' },
    { 'Artillery', 3, 'Seraphim', 'brpt3ml' },
}

local function OWPlusMainLandBuilder(c)
    local kind, tier, faction, unitId = c[1], c[2], c[3], c[4]
    local base = OWPLUS_MAIN_LAND_TIER_PRIORITY[tier]
    local conditions = {
        { MIBC, 'CanPathToCurrentEnemy', { true, 'LocationType' } },
        { EBC,  'GreaterThanEconTrend',  { 0.0, 0.0 } },
    }
    if tier == 1 then
        -- niente T1 appena esiste una fabbrica di terra T2/T3 (no spam T1 a fine partita)
        table.insert(conditions, { UCBC, 'HaveLessThanUnitsWithCategory', { 1, OWPLUS_MAIN_LAND_T2PLUS_FACTORY } })
    end
    return Builder {
        BuilderName = 'OWPlus Main Production ' .. kind .. ' T' .. tier .. ' ' .. faction .. ' ' .. unitId,
        PlatoonTemplate = 'OWPlus Outpost ' .. kind .. ' T' .. tier .. ' ' .. faction .. ' ' .. unitId,
        Priority = base,
        PriorityFunction = function(self, aiBrain)
            if OWPlusFactoryTargetsMod.OWPlusMainCatalogProductionDisabled then
                return 0
            end
            return base + Random(1, OWPLUS_MAIN_LAND_RANDOM_SPAN)
        end,
        BuilderConditions = conditions,
        BuilderType = 'Land',
    }
end

local owplusMainLandBuilders = {
    BuilderGroupName = 'OWPlus Main Land Production',
    BuildersType = 'FactoryBuilder',
}
for _, c in OWPLUS_MAIN_LAND_CANDIDATES do
    table.insert(owplusMainLandBuilders, OWPlusMainLandBuilder(c))
end
BuilderGroup(owplusMainLandBuilders)

LOG('[OWPlus-FACTORY] OWPlus Main Land Production: registrati ' .. table.getn(OWPLUS_MAIN_LAND_CANDIDATES)
    .. ' builder terra (catalogo avamposti) per MAIN, disattivato=' .. tostring(OWPlusFactoryTargetsMod.OWPlusMainCatalogProductionDisabled))
