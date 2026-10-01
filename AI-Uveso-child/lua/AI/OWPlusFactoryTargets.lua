-- OWPlusFactoryTargets.lua
--
-- Sess.100 parte 9 (piano fabbriche, approvato dall'utente): obiettivi di fabbriche PER BASE
-- (MAIN, angoli della X, avamposti) e censimento FISICO delle fabbriche per base.
--
-- Perche' esiste: i conteggi nativi (HaveLessThanUnitsWithCategory & co.) sono GLOBALI e le
-- finestre esatte di OWPlus Dispersed Base (es. "terra totali == 1") saltano appena MAIN o gli
-- avamposti aggiungono fabbriche. Qui ogni fabbrica viva viene assegnata alla base PIU' VICINA
-- tra MAIN, le sotto-basi diagonali e gli avamposti rivendicati (aiBrain.OWPlusSubBases), e i
-- builder confrontano il conteggio della PROPRIA base con l'obiettivo.
--
-- Robustezza (nessun limite di raggio nell'assegnazione): ogni fabbrica viene contata in
-- esattamente UNA base, quindi il totale costruibile e' limitato dalla somma degli obiettivi.
-- Un errore di attribuzione puo' solo far costruire MENO fabbriche (mai un ciclo infinito).
--
-- Determinismo (regola 38t, desync lockstep): nessuna dipendenza dall'ordine di pairs() su
-- tabelle con chiavi-oggetto; le chiavi delle basi sono ordinate alfabeticamente e a parita' di
-- distanza vince la prima in ordine (MAIN, poi chiavi ordinate).
--
-- ROLLBACK: OWPlusMultiFactoryDisabled = true riporta esattamente il comportamento precedente
-- (builder nuovi a priorita' 0, vecchi builder degli angoli riattivati, ricetta avamposto
-- {T1LandFactory}, nessun gruppo produzione aria avamposto).

local categories = categories

-- Interruttore unico (checklist-sviluppo.md sez.2: sistema centrale, flag richiesto/concordato).
OWPlusMultiFactoryDisabled = false

-- Obiettivi nuovi (decisione utente): MAIN 3 terra + 2 aria, angoli 2+1, avamposti 2+1.
local TARGETS = {
    MAIN    = { land = 3, air = 2 },
    CORNER  = { land = 2, air = 1 },
    OUTPOST = { land = 2, air = 1 },
}

-- Valori "come prima" quando il flag e' true (solo per il log/le condizioni; i builder nuovi
-- sono comunque disattivati dal flag).
local LEGACY_TARGETS = {
    MAIN    = { land = 2, air = 0 },
    CORNER  = { land = 0, air = 0 },
    OUTPOST = { land = 1, air = 0 },
}

local LAND_FAC = categories.STRUCTURE * categories.FACTORY * categories.LAND
local AIR_FAC  = categories.STRUCTURE * categories.FACTORY * categories.AIR

local CENSUS_TTL_SECONDS = 1
local CENSUS_LOG_INTERVAL_SECONDS = 60
local COND_LOG_INTERVAL_SECONDS = 30

-- Ricetta iniziale avamposto (consumata al momento della generazione, vedi
-- OWPlusOutpostGenerator.lua / platoon.lua). Con il flag true: la vecchia ricetta a 1 fabbrica.
function OWPlusOutpostFactoryRecipe()
    if OWPlusMultiFactoryDisabled then
        return { 'T1LandFactory' }
    end
    local recipe = {}
    for i = 1, TARGETS.OUTPOST.land do
        table.insert(recipe, 'T1LandFactory')
    end
    for i = 1, TARGETS.OUTPOST.air do
        table.insert(recipe, 'T1AirFactory')
    end
    return recipe
end

-- Tipo di location dalla chiave: 'MAIN', 'CORNER' (BASE_NE/SE/SW/NW), 'OUTPOST' (OUT##), altro 'OTHER'.
function OWPlusFactoryKind(locationKey)
    if locationKey == 'MAIN' then
        return 'MAIN'
    end
    local prefix3 = string.sub(locationKey, 1, 3)
    if prefix3 == 'OUT' then
        return 'OUTPOST'
    end
    if string.sub(locationKey, 1, 5) == 'BASE_' then
        return 'CORNER'
    end
    return 'OTHER'
end

-- Obiettivo per una location. layer = 'land' | 'air'. nil se la location non ha obiettivo.
function OWPlusFactoryTarget(locationKey, layer)
    local kind = OWPlusFactoryKind(locationKey)
    local active = OWPlusMultiFactoryDisabled and LEGACY_TARGETS or TARGETS
    if active[kind] then
        return active[kind][layer]
    end
    return nil
end

-- Chiusure per PriorityFunction dei builder: 'nuovo' attivo solo col flag false, 'vecchio'
-- (finestre globali) attivo solo col flag true. Priority statico va comunque dichiarato nel Builder.
function OWPlusMultiFactoryPriority(base)
    return function(self, aiBrain)
        if OWPlusMultiFactoryDisabled then
            return 0
        end
        return base
    end
end

function OWPlusLegacyFactoryPriority(base)
    return function(self, aiBrain)
        if OWPlusMultiFactoryDisabled then
            return base
        end
        return 0
    end
end

-- Elenco delle basi candidate, in ordine deterministico: MAIN, poi le altre per chiave.
-- Avamposti: solo quelli davvero rivendicati (OWPlusSubBases contiene anche candidati mai
-- costruiti che cadono vicino agli angoli, vedi FactoryBuilderManager.lua sess.89).
local function OWPlusFactoryBases(aiBrain)
    local bases = {}
    local startX, startZ = aiBrain:GetArmyStartPos()
    table.insert(bases, { key = 'MAIN', kind = 'MAIN', x = startX, z = startZ })
    if aiBrain.OWPlusSubBases then
        local keys = {}
        for key, pos in aiBrain.OWPlusSubBases do
            local kind = OWPlusFactoryKind(key)
            if kind == 'OUTPOST' then
                if aiBrain.OWPlusOutpostClaimed and aiBrain.OWPlusOutpostClaimed[key] then
                    table.insert(keys, key)
                end
            else
                table.insert(keys, key)
            end
        end
        table.sort(keys)
        for _, key in keys do
            local pos = aiBrain.OWPlusSubBases[key]
            if pos then
                table.insert(bases, { key = key, kind = OWPlusFactoryKind(key), x = pos[1], z = pos[3] })
            end
        end
    end
    return bases
end

-- Chiave della base piu' vicina a un'unita' (stessa regola del censimento), o nil se non calcolabile.
-- Serve a scansioni a raggio (es. "fabbriche entro 20 dall'avamposto") che con 3 fabbriche per
-- avamposto e avamposti a 13-31 unita' l'uno dall'altro contano anche quelle dei vicini.
function OWPlusFactoryNearestBaseKey(aiBrain, unit)
    if not unit or unit.Dead then
        return nil
    end
    local pos = unit:GetPosition()
    local bestKey, bestDist
    for _, base in OWPlusFactoryBases(aiBrain) do
        local d = VDist2(pos[1], pos[3], base.x, base.z)
        if not bestDist or d < bestDist then
            bestDist = d
            bestKey = base.key
        end
    end
    return bestKey
end

local function OWPlusCensusLayer(aiBrain, bases, counts, layer, category, stats)
    for _, unit in aiBrain:GetListOfUnits(category, false) do
        if unit and not unit.Dead then
            local pos = unit:GetPosition()
            local bestBase, bestDist
            for _, base in bases do
                local d = VDist2(pos[1], pos[3], base.x, base.z)
                if not bestDist or d < bestDist then
                    bestDist = d
                    bestBase = base
                end
            end
            if bestBase then
                counts[bestBase.key][layer] = counts[bestBase.key][layer] + 1
                local complete = unit:GetFractionComplete() >= 1
                if not complete then
                    counts[bestBase.key].building[layer] = counts[bestBase.key].building[layer] + 1
                end
                -- Sess.100 parte 11 (sintomo utente: fabbriche ferme in base mentre altre producono): per ogni
                -- fabbrica COMPLETA di MAIN/angoli si tiene da quanto e' ferma (ne' produce ne' e' in upgrade).
                -- Il campo vive sull'unita' (si azzera da solo se produce/sale di tier) e serve solo al log.
                if complete and (bestBase.kind == 'MAIN' or bestBase.kind == 'CORNER') then
                    local now = GetGameTimeSeconds()
                    if unit:IsIdleState() and not unit:IsUnitState('Upgrading') then
                        unit.OWPlusIdleSince = unit.OWPlusIdleSince or now
                        if now - unit.OWPlusIdleSince >= 30 then
                            table.insert(counts[bestBase.key].idleList, tostring(unit.UnitId) .. ' ferma da ' .. string.format('%.0f', now - unit.OWPlusIdleSince) .. 's')
                        end
                    else
                        unit.OWPlusIdleSince = nil
                    end
                end
                -- Diagnostica: fabbrica d'avamposto gestita da un manager DIVERSO dal proprio (es. 'MAIN'):
                -- sintomo del furto/adozione sbagliata (regola 27), atteso 0.
                if bestBase.kind == 'OUTPOST' then
                    local fbm = unit.BuilderManagerData and unit.BuilderManagerData.FactoryBuildManager
                    if fbm and fbm.LocationType ~= bestBase.key then
                        counts[bestBase.key].wrongMgr = counts[bestBase.key].wrongMgr + 1
                    end
                end
                if bestDist > (stats.maxDist[bestBase.kind] or 0) then
                    stats.maxDist[bestBase.kind] = bestDist
                end
            end
        end
    end
end

local function OWPlusCensusLog(aiBrain, bases, counts, stats)
    local now = GetGameTimeSeconds()
    if aiBrain.OWPlusFactoryCensusLogTime and now - aiBrain.OWPlusFactoryCensusLogTime < CENSUS_LOG_INTERVAL_SECONDS then
        return
    end
    aiBrain.OWPlusFactoryCensusLogTime = now
    local main = counts['MAIN']
    local parts = { string.format('MAIN terra=%d aria=%d', main.land, main.air) }
    local outpostCount, outpostLand, outpostAir, outpostFull, outpostWrongMgr = 0, 0, 0, 0, 0
    for _, base in bases do
        local c = counts[base.key]
        if base.kind == 'CORNER' or base.kind == 'OTHER' then
            table.insert(parts, string.format('%s terra=%d aria=%d', base.key, c.land, c.air))
        elseif base.kind == 'OUTPOST' then
            outpostCount = outpostCount + 1
            outpostLand = outpostLand + c.land
            outpostAir = outpostAir + c.air
            outpostWrongMgr = outpostWrongMgr + c.wrongMgr
            if c.land >= TARGETS.OUTPOST.land and c.air >= TARGETS.OUTPOST.air then
                outpostFull = outpostFull + 1
            end
        end
    end
    table.insert(parts, string.format('avamposti=%d (terra=%d aria=%d, completi=%d, manager_errato=%d)', outpostCount, outpostLand, outpostAir, outpostFull, outpostWrongMgr))
    LOG('[OWPlus-FACTORY-CENSUS] [' .. tostring(aiBrain.Nickname) .. '] t=' .. string.format('%.0f', now) .. ' flag_disattivato=' .. tostring(OWPlusMultiFactoryDisabled)
        .. ' | ' .. table.concat(parts, ' | ')
        .. string.format(' | dist.max MAIN=%.0f angoli=%.0f avamposti=%.0f', stats.maxDist['MAIN'] or 0, stats.maxDist['CORNER'] or 0, stats.maxDist['OUTPOST'] or 0))
    -- Fabbriche complete di MAIN/angoli ferme da >= 30 s (id blueprint = tier e fazione: es. ueb0301 = T3 terra UEF)
    for _, base in bases do
        if (base.kind == 'MAIN' or base.kind == 'CORNER') and table.getn(counts[base.key].idleList) > 0 then
            LOG('[OWPlus-FACTORY-IDLE] [' .. tostring(aiBrain.Nickname) .. '] t=' .. string.format('%.0f', now) .. ' ' .. base.key .. ': '
                .. table.getn(counts[base.key].idleList) .. ' ferme -> ' .. table.concat(counts[base.key].idleList, ', '))
        end
    end
end

-- Censimento fisico per base, cachato ~1 s per brain. Ritorna
-- { [key] = { land=, air=, building = { land=, air= } } } (building = ancora in costruzione,
-- gia' incluse in land/air). Ogni fabbrica e' contata in UNA sola base (la piu' vicina).
function OWPlusFactoryCensus(aiBrain)
    local now = GetGameTimeSeconds()
    local cache = aiBrain.OWPlusFactoryCensusCache
    if cache and now - cache.time < CENSUS_TTL_SECONDS then
        return cache.counts
    end
    local bases = OWPlusFactoryBases(aiBrain)
    local counts = {}
    for _, base in bases do
        counts[base.key] = { land = 0, air = 0, wrongMgr = 0, building = { land = 0, air = 0 }, idleList = {} }
    end
    local stats = { maxDist = {} }
    OWPlusCensusLayer(aiBrain, bases, counts, 'land', LAND_FAC, stats)
    OWPlusCensusLayer(aiBrain, bases, counts, 'air', AIR_FAC, stats)
    aiBrain.OWPlusFactoryCensusCache = { time = now, counts = counts }
    OWPlusCensusLog(aiBrain, bases, counts, stats)
    return counts
end

local function OWPlusCondLog(aiBrain, key, msg)
    aiBrain.OWPlusFactoryCondLogTime = aiBrain.OWPlusFactoryCondLogTime or {}
    local now = GetGameTimeSeconds()
    local last = aiBrain.OWPlusFactoryCondLogTime[key]
    if not last or now - last >= COND_LOG_INTERVAL_SECONDS then
        aiBrain.OWPlusFactoryCondLogTime[key] = now
        LOG(msg)
    end
end

-- Condizione: la base ha MENO fabbriche del suo obiettivo. layer = 'land' | 'air'.
-- Fallimento rumoroso: base senza obiettivo o assente dal censimento -> false con log.
function OWPlusFactoriesBelowTarget(aiBrain, locationKey, layer, label)
    if OWPlusMultiFactoryDisabled then
        return false
    end
    local target = OWPlusFactoryTarget(locationKey, layer)
    if not target then
        OWPlusCondLog(aiBrain, 'notarget_' .. tostring(locationKey) .. layer,
            '[OWPlus-FACTORY-COND] WARN: nessun obiettivo per "' .. tostring(locationKey) .. '" (' .. tostring(layer) .. ') -- builder "' .. tostring(label) .. '" = false')
        return false
    end
    local base = OWPlusFactoryCensus(aiBrain)[locationKey]
    if not base then
        OWPlusCondLog(aiBrain, 'nobase_' .. tostring(locationKey) .. layer,
            '[OWPlus-FACTORY-COND] "' .. tostring(locationKey) .. '" assente dal censimento (slot non registrato?) -- builder "' .. tostring(label) .. '" = false')
        return false
    end
    local result = base[layer] < target
    if result then
        OWPlusCondLog(aiBrain, 'ok_' .. tostring(locationKey) .. layer .. tostring(label),
            '[OWPlus-FACTORY-COND] OK: ' .. tostring(locationKey) .. ' ' .. layer .. ' fabbriche=' .. base[layer] .. ' < obiettivo ' .. target .. ' -- builder "' .. tostring(label) .. '" abilitato')
    end
    return result
end

-- Condizione: nessuna fabbrica del layer e' in costruzione in QUESTA base. Sostituisce il gate
-- nativo HaveLessThanUnitsInCategoryBeingBuilt, che e' GLOBALE: con fino a 3 fabbriche per
-- avamposto in costruzione, MAIN e gli angoli resterebbero bloccati dagli avamposti.
function OWPlusFactoriesNotBuilding(aiBrain, locationKey, layer, label)
    if OWPlusMultiFactoryDisabled then
        return false
    end
    local base = OWPlusFactoryCensus(aiBrain)[locationKey]
    if not base then
        return false
    end
    return base.building[layer] < 1
end

-- Condizione: la base ha ALMENO n fabbriche del layer indicato (es. angolo: terra costruita prima dell'aria).
function OWPlusFactoriesAtLeast(aiBrain, locationKey, n, layer, label)
    if OWPlusMultiFactoryDisabled then
        return false
    end
    local base = OWPlusFactoryCensus(aiBrain)[locationKey]
    if not base then
        OWPlusCondLog(aiBrain, 'nobase_' .. tostring(locationKey) .. layer,
            '[OWPlus-FACTORY-COND] "' .. tostring(locationKey) .. '" assente dal censimento -- builder "' .. tostring(label) .. '" = false')
        return false
    end
    return base[layer] >= n
end
