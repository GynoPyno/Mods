-- OWPlusLogConditions.lua
-- Piccole funzioni BuildCondition custom usate dai builder OWPlus per la forward base:
-- alcune sono diagnostiche (LOG + return true, condizione neutra), altre sono
-- condizioni reali (verificano stato su aiBrain.OWPlusSubBases/OWPlusForwardBaseMarkers).

local categories = categories
local AIUtils = import('/lua/ai/aiutilities.lua')
local UCBCMod = import('/lua/editor/UnitCountBuildConditions.lua')
local EBCMod = import('/lua/editor/EconomyBuildConditions.lua')
local MABCMod = import('/lua/editor/MarkerBuildConditions.lua')
local OWPlusProductionAvailableMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusOutpostProductionAvailable.lua')
local OWPlusOutpostOwnership = import('/mods/AI-Uveso-child/lua/AI/OWPlusOutpostOwnership.lua')
-- Sess.100 parte 9: flag OWPlusMultiFactoryDisabled + obiettivi fabbriche (modulo puro, nessun import ciclico)
local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')

-- Test dedicato sess.79 (richiesta esplicita utente): flag temporaneo per
-- disattivare SOLO l'upgrade di tier della fabbrica avamposto (i builder in
-- 'OWPlus Outpost Factory Upgrade.lua'), lasciando invariata la produzione
-- ingegneri/difese. Serviva a isolare se il "buco" di strutture osservato in
-- game (12 difese T1 costruite, solo 7 sopravvissute a fine test) dipendesse
-- dal ciclo di upgrade tier o si presentasse comunque con la fabbrica ferma a
-- T1. Isolamento concluso (Fase C confermata stabile, sess.81) — rimesso a
-- false sess.82: senza tier-up, nessun evento fa mai scattare l'upgrade delle
-- difese (T2/T3 point-defense/AA) ne' l'unica ricetta prevista per scudi/
-- artiglieria/anti-missile.
OWPlusOutpostTierUpDisabled = false

function OWPlusOutpostTierUpAllowed(aiBrain, label)
    if OWPlusOutpostTierUpDisabled then
        if OWPlusDebugThrottle(aiBrain, 'TierUpDisabled_' .. tostring(label), 15) then
            LOG('[OWPlus-DBG] OWPlusOutpostTierUpAllowed: bloccato (test disattivazione tier-up attivo) -- builder "' .. tostring(label) .. '"')
        end
        return false
    end
    return true
end

-- Fase D1 (B24): flag globale per disattivare la produzione unita' d'attacco
-- degli avamposti senza rimuovere il codice — richiesto esplicitamente
-- dall'utente (checklist-sviluppo.md sez.2: sistema centrale, serve un
-- interruttore per isolare eventuali regressioni nei test senza dover
-- commentare/rimuovere codice).
OWPlusOutpostAttackDisabled = false

function OWPlusOutpostAttackEnabled(aiBrain)
    return not OWPlusOutpostAttackDisabled
end

-- Sess.98 (richiesta esplicita utente): flag per disattivare la GENERAZIONE di
-- nuovi avamposti (OWPlusOutpostScanThread, forkato da overwhelmplusai.lua)
-- senza toccare gli avamposti gia' esistenti in partita -- stesso pattern e
-- stesso motivo dei due flag sopra (interruttore per isolare test senza dover
-- commentare/rimuovere codice, checklist-sviluppo.md sez.2).
-- Sess.99: riattivato (richiesta esplicita utente) -- serve la generazione
-- avamposti attiva per poter riprodurre il sospetto desync (sess.98, ancora
-- non diagnosticato) e ottenerne il log.
OWPlusOutpostExpansionDisabled = false

function OWPlusOutpostExpansionAllowed()
    if OWPlusOutpostExpansionDisabled then
        LOG('[OWPlus-DBG] OWPlusOutpostScanThread: NON avviato (test disattivazione espansione avamposti attivo)')
        return false
    end
    return true
end

-- Fase D1 (B24): assegna il "tipo" di produzione dell'avamposto UNA sola volta
-- (mono-categoria: bot/carri/artiglieria, 1/3 di probabilita' ciascuna — la
-- distinzione carri vs bot decisa in sess.90 dopo aver verificato che
-- categories.BOT esiste davvero nel motore, gia' usato in OWPlus Land Naval.lua).
-- Il tipo "composito" (B24 punto 1-2, mix 60/40 di due categorie) e' rimandato
-- alla Fase D2 — per ora ogni avamposto e' sempre mono.
-- Fix sess.91 (richiesta esplicita utente, domanda bonus): terzo valore
-- 'generic' accanto al mono-tipo esistente -- roll preliminare 50/50 prima
-- del roll 1/3 bot/carro/artiglieria (invariato per il ramo mono). Un
-- avamposto 'generic' non si limita a una sola categoria (vedi
-- OWPlusOutpostEffectiveType sotto, ramo dedicato).
function OWPlusAssignOutpostType(aiBrain, locationType)
    aiBrain.OWPlusOutpostType = aiBrain.OWPlusOutpostType or {}
    if not aiBrain.OWPlusOutpostType[locationType] then
        local chosenType
        if Random(1, 2) == 1 then
            chosenType = 'generic'
        else
            local roll = Random(1, 3)
            chosenType = 'bot'
            if roll == 2 then
                chosenType = 'tank'
            elseif roll == 3 then
                chosenType = 'artillery'
            end
        end
        aiBrain.OWPlusOutpostType[locationType] = chosenType
        LOG('[OWPlus] Outpost (' .. tostring(locationType) .. '): OK, tipo produzione assegnato = "' .. chosenType .. '" (Fase D1)')
    end
end

function OWPlusOutpostTypeIs(aiBrain, locationType, wantedType)
    return aiBrain.OWPlusOutpostType ~= nil and aiBrain.OWPlusOutpostType[locationType] == wantedType
end

-- Fix Fase D1 (2026-07-26): il roster vanilla non ha bot/carro per ogni fazione
-- a ogni tier (vedi commenti in OWPlus PlatoonTemplates Outpost.lua) — un
-- avamposto assegnato a un tipo senza unita' per la propria fazione a un dato
-- tier produceva zero unita' per tutta la durata di quel tier (bug reale
-- osservato in test: UEF "carro" bloccato a T3, UEF "bot" bloccato a T2). Se
-- il tipo assegnato non ha un'unita' per la fazione a questo tier, proviamo
-- gli altri due tipi in un ordine fisso (bot->carro->artiglieria).
--
-- Fix (2026-07-29, espansione catalogo unita' modded): la disponibilita' per
-- cella e' ora una tabella statica precomputata
-- (OWPlusOutpostProductionAvailable.lua, generata dallo stesso catalogo
-- vanilla+modded usato per i Builder) invece di interrogare GetFactoryTemplate
-- a runtime — con decine di candidati per cella, chiamare il motore per
-- ognuno solo per sapere "esiste qualcosa?" e' inutile, lo sappiamo gia' dai
-- dati usati per generare i Builder stessi. Elimina anche il rischio di
-- ripetere l'errore di parametro (GetFactoryTemplate si aspetta un'unita'
-- fabbrica vera, non un indice di fazione numerico) che ha causato "nessun
-- avamposto produce" il 2026-07-26 — resta un solo, singolo, uso di
-- GetFactoryFaction (stessa API nativa, stesso parametro fabbrica corretto)
-- solo per sapere la fazione, non per risolvere template per ogni candidato.
local OWPLUS_OUTPOST_TYPE_FALLBACK_ORDER = { 'bot', 'tank', 'artillery' }

function OWPlusOutpostEffectiveType(aiBrain, locationType, techLevel, wantedType)
    local assignedType = aiBrain.OWPlusOutpostType and aiBrain.OWPlusOutpostType[locationType]
    if not assignedType then
        return nil
    end
    local mgr = aiBrain.BuilderManagers[locationType]
    if not (mgr and mgr.FactoryManager) then
        return nil
    end
    local liveFactory = nil
    for _, factory in mgr.FactoryManager.FactoryList do
        if not factory.Dead then
            liveFactory = factory
            break
        end
    end
    if not liveFactory then
        return nil
    end
    local ok, faction = pcall(function() return mgr.FactoryManager:GetFactoryFaction(liveFactory) end)
    if not ok or not faction then
        if OWPlusDebugThrottle(aiBrain, 'EffectiveTypeFactionFail_' .. tostring(locationType), 30) then
            LOG('[OWPlus-WARN] OWPlusOutpostEffectiveType(' .. tostring(locationType) .. '): GetFactoryFaction fallita: ' .. tostring(faction))
        end
        return nil
    end

    local function IsAvailable(candidateType)
        local byTier = OWPlusProductionAvailableMod.OWPlusProductionAvailable[candidateType]
        return byTier and byTier[techLevel] and byTier[techLevel][faction] == true
    end

    -- Fix sess.91 (domanda bonus utente): avamposto 'generic' non e'
    -- limitato a un solo tipo -- ogni builder (uno per wantedType) resta
    -- candidato indipendentemente se la propria categoria e' disponibile
    -- per fazione/tier; la scelta tra loro resta affidata alla stessa
    -- randomizzazione Priority/Random() gia' in uso tra i 172 Builder,
    -- nessun meccanismo nuovo di selezione.
    if assignedType == 'generic' then
        if wantedType and IsAvailable(wantedType) then
            return wantedType
        end
        return nil
    end

    if IsAvailable(assignedType) then
        return assignedType
    end

    for _, candidateType in OWPLUS_OUTPOST_TYPE_FALLBACK_ORDER do
        if candidateType ~= assignedType and IsAvailable(candidateType) then
            if OWPlusDebugThrottle(aiBrain, 'EffectiveTypeFallback_' .. tostring(locationType) .. '_T' .. tostring(techLevel), 30) then
                LOG('[OWPlus] Outpost (' .. tostring(locationType) .. '): OK, tipo assegnato "' .. assignedType
                    .. '" senza unita\' a T' .. tostring(techLevel) .. ', fallback su "' .. candidateType .. '" (Fase D1 fix)')
            end
            return candidateType
        end
    end

    -- Fallimento rumoroso (checklist-sviluppo.md sez.3): nessuno dei 3 tipi ha
    -- un'unita' per questa fazione a questo tier — oggi capita solo per Aeon
    -- Carro T3 (unico buco residuo anche dopo il catalogo modded).
    if OWPlusDebugThrottle(aiBrain, 'EffectiveTypeNone_' .. tostring(locationType) .. '_T' .. tostring(techLevel), 30) then
        LOG('[OWPlus-WARN] Outpost (' .. tostring(locationType) .. '): nessun tipo (bot/carro/artiglieria) ha un\'unita\' per la fazione '
            .. tostring(faction) .. ' a T' .. tostring(techLevel) .. ' — produzione impossibile a questo tier')
    end
    return nil
end

function OWPlusOutpostEffectiveTypeIs(aiBrain, locationType, wantedType, techLevel)
    return OWPlusOutpostEffectiveType(aiBrain, locationType, techLevel, wantedType) == wantedType
end

-- Instrumentazione diagnostica (sess.72): il fix di sess.71 (AddGlobalBuilderGroup)
-- ha confermato che i BuilderGroup di Fase A/B vengono correttamente agganciati ai
-- manager avamposto, ma un test in game ha mostrato che vengono comunque quasi mai
-- SELEZIONATI davvero (1 sola selezione reale Fase A in 9 minuti, 0 per Fase B).
-- Queste funzioni loggano (con throttle, altrimenti il builder system le valuta
-- troppo spesso) il risultato REALE di ogni singola condizione vanilla usata dai
-- builder avamposto, cosi' da capire QUALE condizione blocca la selezione invece
-- di dedurlo da un log finale inaffidabile (un log-sempre-vero come ultima
-- condizione si era gia' dimostrato un falso positivo, vedi OWPlusClaimFactoryUpgrade
-- piu' sotto per il caso concreto). Da rimuovere/silenziare una volta diagnosticato.
function OWPlusDebugThrottle(aiBrain, key, interval)
    aiBrain.OWPlusDebugLastLog = aiBrain.OWPlusDebugLastLog or {}
    local now = GetGameTimeSeconds()
    if not aiBrain.OWPlusDebugLastLog[key] or now - aiBrain.OWPlusDebugLastLog[key] >= interval then
        aiBrain.OWPlusDebugLastLog[key] = now
        return true
    end
    return false
end

function OWPlusDebugPoolLessAtLocation(aiBrain, locationType, unitCount, unitCategory, label)
    local result = UCBCMod.PoolLessAtLocation(aiBrain, locationType, unitCount, unitCategory)
    if OWPlusDebugThrottle(aiBrain, 'PoolLess_' .. tostring(locationType) .. '_' .. tostring(label), 8) then
        -- Diagnostica sess.78 (quinquies): PoolLessAtLocation (vanilla,
        -- UnitCountBuildConditions.lua) NON conta le unita' fisicamente presenti
        -- all'avamposto — conta quante unita' della categoria risultano ancora
        -- nel plotone speciale 'ArmyPool' entro EngineerManager.Radius dal punto
        -- EngineerManager:GetLocationCoords(). Osservato in game: 13+ ingegneri T3
        -- costruiti a un avamposto, eppure il cap=5 non scatta mai. Due ipotesi:
        -- (a) IssueGuard (Fase A) e' un comando nativo che non passa dal sistema
        -- di plotoni dell'AI, quindi l'ingegnere potrebbe restare nella ArmyPool
        -- anche mentre fa la guardia; (b) Location/Radius del manager (creato "a
        -- mano" via AddFactoryToClosestManager, non per la via normale del
        -- motore) sono sbagliati/troppo piccoli e la conta perde di vista
        -- ingegneri comunque vicini. Confronto diretto per distinguerle.
        local mgr = aiBrain.BuilderManagers[locationType]
        local diagInfo = ''
        if mgr and mgr.EngineerManager then
            local coordsOk, coords = pcall(function() return mgr.EngineerManager:GetLocationCoords() end)
            local radius = mgr.EngineerManager.Radius
            if coordsOk and coords then
                local realCountSameRadius = table.getn(aiBrain:GetUnitsAroundPoint(unitCategory, coords, radius or 0, 'Ally') or {})
                local realCountWide = table.getn(aiBrain:GetUnitsAroundPoint(unitCategory, coords, 60, 'Ally') or {})
                diagInfo = ' -- diag: coords=(' .. tostring(coords[1]) .. ',' .. tostring(coords[3]) .. ') radius=' .. tostring(radius)
                    .. ' realCount(stessoRaggio)=' .. tostring(realCountSameRadius) .. ' realCount(60)=' .. tostring(realCountWide)
            end
        end
        LOG('[OWPlus-DBG] PoolLessAtLocation(' .. tostring(locationType) .. ', cap=' .. tostring(unitCount) .. ') = ' .. tostring(result) .. ' -- builder "' .. tostring(label) .. '"' .. diagInfo)
    end
    return result
end

-- Fix sess.91 (richiesta esplicita utente in game): nessuna condizione oggi
-- verifica quanti ingegneri esistono DAVVERO prima di autorizzare upgrade
-- fabbrica/difese o produzione unita' -- l'unico argine era l'ordine di
-- Priority nella coda FactoryBuilder (ingegneri 18700+ > produzione 18670+),
-- che non copre l'upgrade (coda PlatoonFormBuilder separata, mai arbitrata
-- insieme).
--
-- Fix Fase H (sess.93): sostituisce il conteggio fisico via scan geometrico
-- (AIUtils.GetOwnUnitsAroundPoint su mgr.EngineerManager.Radius) con la mappa
-- ownership (kind=Engineer, OWPlusOutpostOwnership.lua, Fase G) — nessuno
-- scan, nessun raggio, nessun rischio di "prestito" da un avamposto vicino
-- (stesso bug gia' risolto per la sorveglianza unificata). Nessun filtro
-- categoria extra qui: il bucket 'engineer' e' gia' garantito privo di
-- COMMAND/SUBCOMMANDER/STATIONASSISTPOD dai due punti di claim (fondatore in
-- platoon.lua, prodotti da fabbrica in FactoryBuilderManager.lua).
function OWPlusDebugEngineersAtLeast(aiBrain, locationType, minCount, label)
    local count = 0
    for _, _ in OWPlusOutpostOwnership.OWPlusGetOwnedUnits(aiBrain, locationType, OWPlusOutpostOwnership.OWPlusOwnershipKindEngineer) do
        count = count + 1
    end
    local result = count >= minCount
    if OWPlusDebugThrottle(aiBrain, 'EngineersAtLeast_' .. tostring(locationType) .. '_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] EngineersAtLeast(' .. tostring(locationType) .. ', min=' .. tostring(minCount) .. ') = ' .. tostring(result) .. ' (reali=' .. tostring(count) .. ') -- builder "' .. tostring(label) .. '"')
    end
    return result
end

-- Fase H (sess.93): sostituisce OWPlusDebugPoolLessAtLocation (ArmyPool
-- nativo) come gate di tetto produzione per 'OWPlus Outpost Engineer
-- Builders.lua' — nome nuovo, non riuso quella funzione (wrapper generico di
-- UCBCMod.PoolLessAtLocation, fonte dati diversa, riusarla col nome vecchio
-- sarebbe fuorviante). Motivo della migrazione: PoolLessAtLocation/ArmyPool
-- ha gia' mostrato disallineamenti col reale in questo progetto (sess.78:
-- 13+ ingegneri T3 costruiti col cap=5 mai scattato). Conteggio via mappa
-- ownership (kind=Engineer, gia' garantita priva di COMMAND/SUBCOMMANDER/
-- STATIONASSISTPOD dal claim) filtrato per tier in lettura -- il cap e'
-- per-tier, non totale (T1/T2/T3 controllati separatamente).
function OWPlusDebugEngineersLessAtLocation(aiBrain, locationType, unitCount, tierCategory, label)
    local count = 0
    for u, _ in OWPlusOutpostOwnership.OWPlusGetOwnedUnits(aiBrain, locationType, OWPlusOutpostOwnership.OWPlusOwnershipKindEngineer) do
        if EntityCategoryContains(tierCategory, u) then
            count = count + 1
        end
    end
    local result = count < unitCount
    if OWPlusDebugThrottle(aiBrain, 'EngineersLess_' .. tostring(locationType) .. '_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] EngineersLessAtLocation(' .. tostring(locationType) .. ', cap=' .. tostring(unitCount) .. ') = ' .. tostring(result) .. ' (reali=' .. tostring(count) .. ') -- builder "' .. tostring(label) .. '"')
    end
    return result
end

function OWPlusDebugLocationFactoriesBuildingLess(aiBrain, locationType, unitCount, unitCategory, label)
    local result = UCBCMod.LocationFactoriesBuildingLess(aiBrain, locationType, unitCount, unitCategory)
    if OWPlusDebugThrottle(aiBrain, 'FacBuildingLess_' .. tostring(locationType) .. '_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] LocationFactoriesBuildingLess(' .. tostring(locationType) .. ', cap=' .. tostring(unitCount) .. ') = ' .. tostring(result) .. ' -- builder "' .. tostring(label) .. '"')
    end
    return result
end

function OWPlusDebugEconStorageRatio(aiBrain, mRatio, eRatio, label)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    local result = EBCMod.GreaterThanEconStorageRatio(aiBrain, mRatio, eRatio)
    if OWPlusDebugThrottle(aiBrain, 'EconRatio_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] GreaterThanEconStorageRatio(soglia mass/energy>=' .. tostring(mRatio) .. ') = ' .. tostring(result)
            .. ' (mass=' .. tostring(econ.MassStorageRatio) .. ', energy=' .. tostring(econ.EnergyStorageRatio) .. ') -- builder "' .. tostring(label) .. '"')
    end
    return result
end

-- Sess.94: log diagnostico per la progressione di espansione estrattori/Mass Fab
-- (OWPlus Override Base Mass.lua) — l'utente vuole vedere nel dev.log QUANDO
-- (tempo di gioco) e con QUALE ampiezza (estrattori/massfab posseduti) ogni
-- builder della catena si sblocca, per verificare se il fix alle soglie
-- (sess.94, curva economia MAIN troppo ripida) elimina davvero il burst
-- simultaneo o se l'AI riesce comunque a saturarli tutti in pochi minuti.
function OWPlusDebugMassExpansionGate(aiBrain, mRatio, eRatio, label)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    local result = EBCMod.GreaterThanEconStorageRatio(aiBrain, mRatio, eRatio)
    -- Sess.95 (septies): log commentato su richiesta esplicita utente (test da
    -- remoto, serve un dev.log pulito con solo il nuovo log periodico
    -- massa/energia) -- logica di gating INVARIATA, solo l'output silenziato.
    -- if OWPlusDebugThrottle(aiBrain, 'MassExpansion_' .. tostring(label), 8) then
    --     local extractors = aiBrain:GetListOfUnits(categories.STRUCTURE * categories.MASSEXTRACTION, false) or {}
    --     local massFabs = aiBrain:GetListOfUnits(categories.STRUCTURE * categories.MASSFABRICATION, false) or {}
    --     LOG('[OWPlus-DBG] MassExpansionGate(' .. tostring(label) .. ') = ' .. tostring(result)
    --         .. ' (mass=' .. tostring(econ.MassStorageRatio) .. ', energy=' .. tostring(econ.EnergyStorageRatio)
    --         .. ', estrattori=' .. tostring(table.getn(extractors)) .. ', massfab=' .. tostring(table.getn(massFabs))
    --         .. ', t=' .. tostring(GetGameTimeSeconds()) .. 's)')
    -- end
    return result
end

-- Sess.94: wrapper loggato di GreaterThanEconIncome (nativo), stesso pattern di
-- OWPlusDebugEconStorageRatio -- usato da OWPlus Hydrocarbon Push per rendere
-- verificabile nel dev.log quando/perche' la condizione economica nativa riusata
-- passa o blocca la costruzione.
function OWPlusDebugEconIncome(aiBrain, massIncome, energyIncome, label)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    local result = EBCMod.GreaterThanEconIncome(aiBrain, massIncome, energyIncome)
    -- Sess.95 (septies): log commentato su richiesta esplicita utente -- logica invariata
    -- if OWPlusDebugThrottle(aiBrain, 'EconIncome_' .. tostring(label), 8) then
    --     LOG('[OWPlus-DBG] GreaterThanEconIncome(soglia mass/energy>=' .. tostring(massIncome) .. '/' .. tostring(energyIncome) .. ') = ' .. tostring(result)
    --         .. ' (mass=' .. tostring(econ.MassIncome) .. ', energy=' .. tostring(econ.EnergyIncome) .. ') -- builder "' .. tostring(label) .. '"')
    -- end
    return result
end

-- Sess.94: condizione DIAGNOSTICA neutra (LOG + return true, non blocca mai) --
-- verifica se gli upgrade in-place di 'OWPlus Economy Upgrade.lua' avvengono
-- davvero nonostante il warning nativo "Can't find StructureUpgradeTemplate"
-- (atteso per unita' modded senza tabella upgrade nativa -- il motore FAF fa
-- comunque fallback a Blueprint.General.UpgradesTo, ma serve la controprova
-- diretta: il conteggio destinazione deve salire da 0 nel tempo).
function OWPlusDebugUpgradeProgress(aiBrain, sourceCategory, destCategory, label)
    -- Sess.95 (octies): riattivato su richiesta esplicita utente -- serve per
    -- osservare il potenziamento estrattori nel test SOLO x1 risorse. NOTA:
    -- funzione condivisa anche coi magazzini (Mass/Energy Storage Upgrade T2/T3,
    -- Hydrocarbon Count) -- riappaiono anche quei log come effetto collaterale
    -- inevitabile (stessa funzione, label diversa).
    if OWPlusDebugThrottle(aiBrain, 'UpgradeProgress_' .. tostring(label), 15) then
        local src = aiBrain:GetListOfUnits(sourceCategory, false) or {}
        local dst = aiBrain:GetListOfUnits(destCategory, false) or {}
        LOG('[OWPlus-DBG] UpgradeProgress(' .. tostring(label) .. ') sorgente=' .. tostring(table.getn(src))
            .. ' destinazione=' .. tostring(table.getn(dst)) .. ' (t=' .. tostring(GetGameTimeSeconds()) .. 's)')
    end
    return true
end

-- Sess.94: gate consolidato per 'OWPlus Economy Upgrade.lua' -- sostituisce la
-- coppia (soglia storage fissa + tetto parallelo fisso 2) con un tetto
-- PROPORZIONALE al numero di candidati (20%, minimo 1), usato sia come limite
-- di parallelismo sia come soglia minima per un fallback "force": se lo
-- storage ratio richiesto non e' raggiunto ma ci sono abbastanza candidati
-- pronti E il trend economico non e' negativo, procede comunque -- altrimenti
-- il gate restava quasi sempre bloccato (soglia storage vera solo 5/94 volte
-- osservate in una partita reale di 21 minuti, zero upgrade completati).
-- Sess.95: parametro 'maxConcurrent' opzionale (retrocompatibile — le chiamate
-- esistenti non lo passano, nil = comportamento invariato). Richiesto dall'utente
-- per i magazzini di energia: il tetto proporzionale 20% scala con la quantita'
-- totale, ma il costo economico di un upgrade magazzino energia e' alto in
-- ASSOLUTO (non relativo), quindi con molte strutture il 20% resta comunque
-- "troppi assieme". Un tetto assoluto basso forza "pochi alla volta" a
-- prescindere dalla scala, mentre il tetto proporzionale resta il default per
-- tutti gli altri chiamanti (estrattori, magazzini massa).
function OWPlusDebugUpgradeGate(aiBrain, sourceCategory, mRatio, eRatio, label, maxConcurrent)
    local sourceUnits = aiBrain:GetListOfUnits(sourceCategory, false) or {}
    local total = table.getn(sourceUnits)
    local cap = math.max(1, math.floor(total * 0.20))
    if maxConcurrent then
        cap = math.min(cap, maxConcurrent)
    end
    local inUpgrade = 0
    for _, u in sourceUnits do
        if u and not u.Dead and u:IsUnitState('Upgrading') then
            inUpgrade = inUpgrade + 1
        end
    end
    local result = false
    local reason = 'tetto raggiunto'
    if inUpgrade < cap then
        local storageOk = EBCMod.GreaterThanEconStorageRatio(aiBrain, mRatio, eRatio)
        if storageOk then
            result = true
            reason = 'storage ok'
        elseif total >= cap and EBCMod.GreaterThanEconTrend(aiBrain, 0.0, 0.0) then
            result = true
            reason = 'force (trend ok)'
        else
            reason = 'storage basso, force bloccato'
        end
    end
    -- Sess.95 (octies): riattivato su richiesta esplicita utente -- serve per
    -- osservare il potenziamento estrattori nel test SOLO x1 risorse. NOTA:
    -- funzione condivisa anche con Mass Storage Upgrade T2/T3 -- riappaiono
    -- anche quei log come effetto collaterale inevitabile.
    if OWPlusDebugThrottle(aiBrain, 'UpgradeGate_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] UpgradeGate(' .. tostring(label) .. ') = ' .. tostring(result)
            .. ' (' .. reason .. ', totale=' .. tostring(total) .. ', inUpgrade=' .. tostring(inUpgrade)
            .. ', cap=' .. tostring(cap) .. ')')
    end
    return result
end

-- Sess.95 (quinquies): diagnostica NEUTRA (LOG+true, non blocca mai) per capire
-- perche' il builder 'OWPlus Extractor Upgrade T4' completa un upgrade
-- rarissimamente (osservato: 1 su ~100 candidati in 26 minuti, nonostante il
-- gate economico fosse quasi sempre vero) -- ipotesi principale: il meccanismo
-- nativo T1->T2->T3 (ExtractorPause, invariato) mette periodicamente in pausa
-- gli estrattori T3 per bilanciare l'energia, e questo potrebbe escluderli
-- dalla selezione del plotone 'Plan=UnitUpgradeAI' (non verificabile leggendo
-- codice: quella selezione e' nativa/compilata, non Lua). L'utente non ha
-- notato pause "a occhio" osservando la partita, ma con 90+ unita' che
-- potrebbero alternare stato molto rapidamente un controllo visivo puo' non
-- coglierlo -- questo log da' il dato oggettivo (quanti risultano IN PAUSA nel
-- preciso istante in cui viene valutato) invece di affidarsi all'osservazione.
function OWPlusDebugExtractorPauseState(aiBrain, category, label)
    -- Sess.95 (septies): log commentato su richiesta esplicita utente -- ipotesi
    -- pausa energetica gia' smentita dai dati (regola 36 memoria), condizione
    -- resta NEUTRA (return true).
    -- if OWPlusDebugThrottle(aiBrain, 'ExtractorPauseState_' .. tostring(label), 10) then
    --     local units = aiBrain:GetListOfUnits(category, false) or {}
    --     local total = table.getn(units)
    --     local paused = 0
    --     local upgrading = 0
    --     for _, u in units do
    --         if u and not u.Dead then
    --             if u:IsPaused() then
    --                 paused = paused + 1
    --             end
    --             if u:IsUnitState('Upgrading') then
    --                 upgrading = upgrading + 1
    --             end
    --         end
    --     end
    --     LOG('[OWPlus-DBG] ExtractorPauseState(' .. tostring(label) .. ') totale=' .. tostring(total)
    --         .. ', in pausa=' .. tostring(paused) .. ', in upgrade=' .. tostring(upgrading))
    -- end
    -- Sess.97: riuso temporaneo di questo slot diagnostico (gia' agganciato al
    -- builder Extractor Upgrade T4) per verificare DIRETTAMENTE se le unita'
    -- TECH3 hanno un PlatoonHandle attivo (= "possedute" da qualche altro
    -- plotone, es. il merger nativo) invece di continuare a ipotizzare dal solo
    -- comportamento indiretto -- il fix sul PlatoonTemplate nativo non ha
    -- prodotto alcun tentativo di upgrade nemmeno con totale=37+ e gate vero
    -- quasi sempre, serve la prova diretta.
    if OWPlusDebugThrottle(aiBrain, 'ExtractorPlatoonHandle_' .. tostring(label), 10) then
        local units = aiBrain:GetListOfUnits(category, false) or {}
        local total = table.getn(units)
        local claimed = 0
        local freeSample = nil
        for _, u in units do
            if u and not u.Dead then
                if u.PlatoonHandle then
                    claimed = claimed + 1
                elseif not freeSample then
                    freeSample = u.UnitId
                end
            end
        end
        LOG('[OWPlus-DBG] ExtractorPlatoonHandle(' .. tostring(label) .. ') totale=' .. tostring(total)
            .. ', con PlatoonHandle=' .. tostring(claimed) .. ', libere=' .. tostring(total - claimed)
            .. ', esempio libero=' .. tostring(freeSample))
    end
    return true
end

-- Sess.95 (quinquies): richiesta esplicita utente dopo un terzo test in game --
-- l'upgrade tier dei magazzini di ENERGIA usava una soglia a RATIO (storage
-- energia >=80% del MASSIMO stoccabile ATTUALE) tramite OWPlusDebugUpgradeGate.
-- Il problema: la ratio e' relativa alla capacita' attuale, quindi puo' essere
-- "80% piena" anche quando la capacita' stessa e' ancora piccola -- potenziare
-- un magazzino quasi vuoto in termini assoluti (poca energia stoccata davvero)
-- non serve a molto. Sostituita con un valore ASSOLUTO (aiBrain:GetEconomyStored
-- ('ENERGY'), non un ratio).
-- Sess.95 (sexies): dal test successivo, il valore assoluto DA SOLO (40000) si
-- e' rivelato irrisorio con l'economia scalata del test (storage arrivato a
-- 2-2.8 MILIONI) -- il gate era quasi sempre vero da subito, non filtrava quasi
-- nulla. Richiesta esplicita utente: ENTRAMBI i vincoli insieme (AND), non uno
-- o l'altro -- assoluto (energia stoccata davvero utile in valore) E ratio
-- (percentuale piena, come richiesto originariamente) devono essere veri.
function OWPlusEnergyStorageAbsoluteGate(aiBrain, sourceCategory, minStoredEnergy, eRatio, label)
    local sourceUnits = aiBrain:GetListOfUnits(sourceCategory, false) or {}
    local total = table.getn(sourceUnits)
    local cap = math.max(1, math.floor(total * 0.20))
    local inUpgrade = 0
    for _, u in sourceUnits do
        if u and not u.Dead and u:IsUnitState('Upgrading') then
            inUpgrade = inUpgrade + 1
        end
    end
    local stored = aiBrain:GetEconomyStored('ENERGY')
    local ratioOk = EBCMod.GreaterThanEconStorageRatio(aiBrain, 0.0, eRatio)
    local result = false
    local reason = 'tetto raggiunto'
    if inUpgrade < cap then
        if stored >= minStoredEnergy and ratioOk then
            result = true
            reason = 'assoluto+ratio ok'
        elseif total >= cap and EBCMod.GreaterThanEconTrend(aiBrain, 0.0, 0.0) then
            result = true
            reason = 'force (trend ok)'
        else
            reason = 'assoluto o ratio insufficiente, force bloccato'
        end
    end
    -- Sess.96: riattivato su richiesta esplicita utente per il test dedicato
    -- al nuovo gate uniformato massa/energia -- logica di gating (result/reason
    -- sopra) INVARIATA, solo l'output riattivato.
    if OWPlusDebugThrottle(aiBrain, 'EnergyAbsGate_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] EnergyStorageAbsoluteGate(' .. tostring(label) .. ') = ' .. tostring(result)
            .. ' (' .. reason .. ', stored=' .. tostring(stored) .. '/' .. tostring(minStoredEnergy)
            .. ', ratioOk=' .. tostring(ratioOk) .. ' (>=' .. tostring(eRatio) .. ')'
            .. ', totale=' .. tostring(total) .. ', inUpgrade=' .. tostring(inUpgrade) .. ', cap=' .. tostring(cap) .. ')')
    end
    return result
end

-- Sess.96: richiesta esplicita utente -- uniformare il potenziamento tier dei
-- magazzini di MASSA alla stessa meccanica gia' in uso per l'energia
-- (OWPlusEnergyStorageAbsoluteGate sopra): valore ASSOLUTO stoccato E ratio
-- insieme (AND), non piu' solo ratio (il vecchio OWPlusDebugUpgradeGate,
-- 0.70/0.30). Stessa struttura (tetto di parallelismo 20%/min 1, force-
-- fallback su trend economico non negativo), differisce solo nella risorsa
-- osservata (MASS invece di ENERGY). Soglie di partenza (500 assoluto, 0.80
-- ratio) da affinare in base ai prossimi test, come da indicazione utente.
function OWPlusMassStorageAbsoluteGate(aiBrain, sourceCategory, minStoredMass, mRatio, label)
    local sourceUnits = aiBrain:GetListOfUnits(sourceCategory, false) or {}
    local total = table.getn(sourceUnits)
    local cap = math.max(1, math.floor(total * 0.20))
    local inUpgrade = 0
    for _, u in sourceUnits do
        if u and not u.Dead and u:IsUnitState('Upgrading') then
            inUpgrade = inUpgrade + 1
        end
    end
    local stored = aiBrain:GetEconomyStored('MASS')
    local ratioOk = EBCMod.GreaterThanEconStorageRatio(aiBrain, mRatio, 0.0)
    local result = false
    local reason = 'tetto raggiunto'
    if inUpgrade < cap then
        if stored >= minStoredMass and ratioOk then
            result = true
            reason = 'assoluto+ratio ok'
        elseif total >= cap and EBCMod.GreaterThanEconTrend(aiBrain, 0.0, 0.0) then
            result = true
            reason = 'force (trend ok)'
        else
            reason = 'assoluto o ratio insufficiente, force bloccato'
        end
    end
    -- Sess.96: riattivato su richiesta esplicita utente per il test dedicato
    -- al nuovo gate.
    if OWPlusDebugThrottle(aiBrain, 'MassAbsGate_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] MassStorageAbsoluteGate(' .. tostring(label) .. ') = ' .. tostring(result)
            .. ' (' .. reason .. ', stored=' .. tostring(stored) .. '/' .. tostring(minStoredMass)
            .. ', ratioOk=' .. tostring(ratioOk) .. ' (>=' .. tostring(mRatio) .. ')'
            .. ', totale=' .. tostring(total) .. ', inUpgrade=' .. tostring(inUpgrade) .. ', cap=' .. tostring(cap) .. ')')
    end
    return result
end

-- Sess.95 (ter): la Fase 2 (sess.95, sopra rimossa) legava il potenziamento
-- estrattori alla copertura magazzini con una soglia di popolazione (80%
-- magazzini rispetto agli estrattori T2+/T3) -- richiesta esplicita utente
-- dopo un secondo test in game: con estrattori sparsi per la mappa, molti non
-- hanno nemmeno lo spazio fisico per un magazzino adiacente, quindi quella
-- soglia non era MAI raggiungibile per davvero (confermato: 82 estrattori T2,
-- fase ferma per l'intera partita anche dopo aver sbloccato il collo di
-- bottiglia della costruzione). Redesign completo: il trigger di tier per gli
-- estrattori torna ad essere basato SOLO sulla popolazione degli estrattori
-- stessi (nessuna dipendenza dai magazzini) -- vedi OWPlusPopulationShareAtLeast
-- sotto. I magazzini diventano un processo indipendente (OWPlusMassStorageEligible
-- sotto) e il requisito "circondato da magazzini" per il singolo salto T2->T3
-- e' gestito come preferenza SOFT nella selezione del candidato (hook/lua/
-- platoon.lua, OWPlusExtractorUpgrade), non piu' come gate di fase globale.

-- Verifica generica "l'80% (o la soglia data) del pool rilevante e' gia' al
-- tier superiore?" -- usata per tutte e 3 le transizioni di tier estrattori
-- (T1->T2 decide se tentare anche T2->T3; T2->T3 decide se sbloccare il
-- builder T3->T4). Sostituisce 'UUtils.HaveUnitRatio' nativo per gli usi di
-- questo progetto: quella funzione calcola T1/T2<=ratio, che NON equivale a
-- "T2 e' l'80% del totale" nonostante il commento originale lo suggerisca
-- (con ratio=0.80 il vero punto di scatto e' T2>=55.6% del totale, non 80%) --
-- qui il calcolo e' la percentuale letterale richiesta dall'utente.
function OWPlusPopulationShareAtLeast(aiBrain, ratio, higherCategory, combinedCategory, label)
    local higher = table.getn(aiBrain:GetListOfUnits(higherCategory, false) or {})
    local total = table.getn(aiBrain:GetListOfUnits(combinedCategory, false) or {})
    local result = total > 0 and (higher / total) >= ratio
    -- Sess.95 (octies): riattivato su richiesta esplicita utente -- serve per
    -- osservare il potenziamento estrattori nel test SOLO x1 risorse. NOTA:
    -- funzione condivisa anche con Mass Storage Upgrade T2/T3 -- riappaiono
    -- anche quei log come effetto collaterale inevitabile.
    if OWPlusDebugThrottle(aiBrain, 'PopShare_' .. tostring(label), 10) then
        LOG('[OWPlus-DBG] PopulationShareAtLeast(' .. tostring(label) .. ') = ' .. tostring(result)
            .. ' (superiore=' .. tostring(higher) .. '/' .. tostring(total) .. ', richiesta>=' .. tostring(ratio) .. ')')
    end
    return result
end

-- Gate leggero e indipendente per i magazzini di massa (costruzione E
-- potenziamento tier) -- richiesta esplicita utente: i magazzini non devono
-- piu' aspettare l'80% degli estrattori, solo un pavimento minimo che confermi
-- che la Fase 1 (T1->T2) sia effettivamente iniziata (non un singolo T2
-- isolato per caso).
function OWPlusMassStorageEligible(aiBrain, label)
    local t2plus = table.getn(aiBrain:GetListOfUnits(categories.STRUCTURE * categories.MASSEXTRACTION * (categories.TECH2 + categories.TECH3), false) or {})
    local result = t2plus >= 3
    -- Sess.95 (septies): log commentato su richiesta esplicita utente -- logica invariata
    -- if OWPlusDebugThrottle(aiBrain, 'MassStorageEligible_' .. tostring(label), 10) then
    --     LOG('[OWPlus-DBG] MassStorageEligible(' .. tostring(label) .. ') = ' .. tostring(result) .. ' (estrattoriT2+=' .. tostring(t2plus) .. ')')
    -- end
    return result
end

-- Sess.95 (bis): richiesta esplicita utente dopo un secondo test in game -- il
-- tetto fisso 1 (nativo HaveLessThanUnitsInCategoryBeingBuilt, gia' esistente
-- prima di questa sessione, condiviso da 'OWPlus Mass Storage T1/T2 Eng')
-- rendeva la costruzione magazzini massa a THREAD SINGOLO per l'intera armata,
-- a prescindere da quanti estrattori esistono -- un collo di bottiglia reale
-- a se stante (confermato in game: 82 estrattori T2, solo 11-16 magazzini
-- dopo un test completo), indipendente dal gate di fase legato ai magazzini
-- (rimosso nel redesign 'ter' successivo, vedi OWPlusPopulationShareAtLeast/
-- OWPlusMassStorageEligible sopra) -- questo fix resta valido a prescindere.
-- Tetto PROPORZIONALE (20% degli estrattori T2+/T3, minimo 1) al posto del
-- fisso 1 -- stesso pattern gia' in uso altrove in questo progetto
-- (OWPlusDebugUpgradeGate) invece di un altro numero fisso che si
-- romperebbe di nuovo a scale diverse.
function OWPlusMassStorageBuildThrottle(aiBrain, label)
    local extractorCat = categories.STRUCTURE * categories.MASSEXTRACTION * (categories.TECH2 + categories.TECH3)
    local extractors = table.getn(aiBrain:GetListOfUnits(extractorCat, false) or {})
    local cap = math.max(1, math.floor(extractors * 0.20))
    local storageCat = categories.STRUCTURE * categories.MASSSTORAGE
    local building = aiBrain:NumCurrentlyBuilding(storageCat, storageCat + categories.CONSTRUCTION)
    local result = building < cap
    -- Sess.95 (septies): log commentato su richiesta esplicita utente -- logica invariata
    -- if OWPlusDebugThrottle(aiBrain, 'MassStorageBuildThrottle_' .. tostring(label), 10) then
    --     LOG('[OWPlus-DBG] MassStorageBuildThrottle(' .. tostring(label) .. ') = ' .. tostring(result)
    --         .. ' (inCostruzione=' .. tostring(building) .. ', cap=' .. tostring(cap) .. ', estrattoriT2+=' .. tostring(extractors) .. ')')
    -- end
    return result
end

-- Fase B: esiste davvero, ADESSO, una fabbrica del tier/dominio richiesto nel
-- FactoryList di questo LocationType, che NON sia gia' in upgrade?
--
-- Fix sess.76 (bug reale trovato in game: spam "upgrade fabbrica avviato"
-- ripetuto decine di volte sulla stessa fabbrica): questa condizione era
-- NEUTRA (ritornava sempre true, mai un vero blocco) — nessun'altra condizione
-- del builder verifica se la fabbrica e' gia' in upgrade. Durante la
-- transizione T1->T2 l'unita' resta categorizzata T1 finche' l'upgrade non
-- completa (comportamento nativo vanilla, IssueUpgrade non e' istantaneo),
-- quindi LocationFactoriesBuildingLess (che conta le fabbriche GIA' T2/T3)
-- restava soddisfatta per tutta la durata dell'upgrade — nulla impediva a
-- GetHighestBuilder di riformare un altro plotone 'PlatoonFormBuilder' sulla
-- STESSA fabbrica gia' in corso di upgrade. Ora la condizione e' un vero
-- filtro: conta solo le fabbriche che soddisfano tier/dominio E non sono
-- IsUnitState('Upgrading') — se zero, restituisce false e blocca il builder.
function OWPlusDebugFactoryUpgradeCandidateExists(aiBrain, locationType, techLevel, domainCategory, label)
    local mgr = aiBrain.BuilderManagers[locationType]
    local count = 0
    if mgr and mgr.FactoryManager and mgr.FactoryManager.FactoryList then
        local techCat = categories.TECH1
        if techLevel == 2 then
            techCat = categories.TECH2
        elseif techLevel == 3 then
            techCat = categories.TECH3
        end
        for _, factory in mgr.FactoryManager.FactoryList do
            if not factory.Dead and EntityCategoryContains(techCat * domainCategory, factory)
                and not factory:IsUnitState('Upgrading') and not factory.OWPlusUpgradeClaimed
                and not factory:IsUnitState('Building') then
                count = count + 1
            end
        end
    end
    if OWPlusDebugThrottle(aiBrain, 'UpgradeCandidate_' .. tostring(locationType) .. '_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] Candidati upgrade "' .. tostring(label) .. '" a ' .. tostring(locationType) .. ': ' .. tostring(count) .. ' fabbriche T' .. tostring(techLevel) .. ' libere (non gia\' in upgrade, non gia\' reclamate, non gia\' costruendo)')
    end
    return count > 0
end

-- Fix sess.77 (bug reale trovato in game: spam "upgrade fabbrica avviato"
-- RIPETUTO decine di volte anche con InstanceCount=1 sul builder). Causa
-- diversa da quella ipotizzata in sess.76: non e' un eccesso di plotoni
-- SIMULTANEI (InstanceCount lo impedisce gia' correttamente), e' un
-- ri-trigger SEQUENZIALE fra un ciclo di valutazione e l'altro. UnitUpgradeAI
-- (vanilla, platoon.lua) attende che l'unita' vecchia diventi .Dead (la
-- sostituzione reale dell'entita' durante l'upgrade, non istantanea) — ma
-- IsUnitState('Upgrading') non si sincronizza abbastanza in fretta lato
-- script, lasciando una finestra in cui la fabbrica sembra ancora "libera".
-- In quella finestra il manager riforma un plotone sulla stessa fabbrica
-- (gia' presa dal primo plotone reale) con squad vuota, che si autodistrugge
-- all'istante (UnitUpgradeAI: "if not upgradeIssued then PlatoonDisband()")
-- liberando subito lo slot InstanceCount — il ciclo si ripete finche' il
-- flag nativo non si aggiorna. Fix: claim SINCRONO nostro (stesso pattern
-- OWPlusOutpostBusy validato in sess.76 per gli ingegneri), impostato
-- nell'istante stesso in cui questa condizione (ULTIMA della catena) passa —
-- nessuna finestra di ritardo possibile, e' la stessa istruzione Lua che
-- legge e scrive il flag. Auto-pulizia dopo un tetto di sicurezza (90s,
-- tempo ampiamente sufficiente per T1/T2 anche a cheat multiplier alto) nel
-- caso l'upgrade venga annullato e la stessa entita' T1 resti viva.
--
-- Fix sess.77 (bis, vedi OWPlusFactoryNotUpgrading piu' sotto per la diagnosi
-- completa): questo claim da solo non bastava — funzionava correttamente
-- (ri-tentativi a intervalli di ~90s esatti, il tetto di sicurezza), ma
-- l'upgrade veniva ISSUATO con successo (nessun WARN da UnitUpgradeAI) senza
-- mai completare, tornando idle T1 prima della naturale conclusione, a causa
-- del builder ingegnere che rubava la stessa fabbrica per accodare un nuovo
-- ingegnere. Aggiunta qui la guardia simmetrica 'not factory:IsUnitState
-- ('Building')', cosi' il claim non ruba a sua volta una fabbrica che sta
-- gia' costruendo un'unita' in coda.
function OWPlusClaimFactoryUpgrade(aiBrain, locationType, techLevel, domainCategory, label)
    local mgr = aiBrain.BuilderManagers[locationType]
    if not (mgr and mgr.FactoryManager and mgr.FactoryManager.FactoryList) then
        return false
    end
    local techCat = categories.TECH1
    if techLevel == 2 then
        techCat = categories.TECH2
    elseif techLevel == 3 then
        techCat = categories.TECH3
    end
    -- Sess.100 parte 9 (piano fabbriche, decisione utente "un upgrade alla volta, le altre
    -- producono"): con 2 terra + 1 aria per avamposto, i 4 builder di upgrade (terra/aria x T1/T2)
    -- rivendicavano ognuno una fabbrica DIVERSA nello stesso ciclo -> 3/3 fabbriche occupate insieme
    -- (osservato nel dev.log: 4941 righe "3/3", 1966 "2/2") e produzione ferma. Un solo upgrade per
    -- location: se una qualunque fabbrica e' gia' in upgrade o rivendicata, nessun nuovo claim.
    for _, factory in mgr.FactoryManager.FactoryList do
        if not factory.Dead and (factory:IsUnitState('Upgrading') or factory.OWPlusUpgradeClaimed) then
            if OWPlusDebugThrottle(aiBrain, 'ClaimOneAtATime_' .. tostring(locationType), 30) then
                LOG('[OWPlus-FACTORY] OWPlusClaimFactoryUpgrade(' .. tostring(locationType) .. '): claim "' .. tostring(label)
                    .. '" rifiutato, un\'altra fabbrica e\' gia\' in upgrade/rivendicata (un upgrade alla volta)')
            end
            return false
        end
    end
    for _, factory in mgr.FactoryManager.FactoryList do
        if not factory.Dead and EntityCategoryContains(techCat * domainCategory, factory)
            and not factory:IsUnitState('Upgrading') and not factory.OWPlusUpgradeClaimed
            and not factory:IsUnitState('Building') then
            factory.OWPlusUpgradeClaimed = true
            LOG('[OWPlus] Outpost (' .. tostring(locationType) .. '): OK, upgrade fabbrica avviato — builder "' .. tostring(label) .. '"')
            -- Fix sess.77 (sexies): il claim (questa condizione) e' logicamente SEPARATO dal
            -- passo vanilla reale che forma il plotone (CanFormPlatoon/FormRadius, dentro
            -- PlatoonFormManager.ManagerLoopBody, opaco al nostro hook) — puo' "riuscire" qui
            -- (condizioni verdi) anche se il plotone non si forma mai davvero (fallimento
            -- transitorio non identificato), lasciando IsUnitState('Upgrading') a false per
            -- sempre. Confermato in game (diagnostica dedicata, ora rimossa): PlatoonHandle
            -- nil sia nei casi riusciti che in quelli falliti — non e' un plotone residuo.
            -- PROBLEMA introdotto dal fix precedente (claim con timeout cieco a 90s): quando
            -- CanFormPlatoon fallisce, il nostro STESSO claim blocca il normale riprova nativo
            -- di PlatoonFormManager (ogni 5s) per 90 interi secondi, trasformando un fallimento
            -- transitorio in un blocco quasi permanente. Fix: rilascio ATTIVO a 15s (non piu'
            -- un'attesa cieca) — se l'upgrade non e' realmente partito entro quella finestra
            -- (ampiamente sufficiente a coprire il ritardo di sincronizzazione di
            -- IsUnitState('Upgrading') che aveva causato lo spam originale), si libera subito
            -- il claim cosi' il prossimo ciclo nativo (5s dopo) puo' ritentare quasi
            -- immediatamente invece che dopo un minuto e mezzo.
            ForkThread(function()
                WaitSeconds(15)
                if not factory.Dead then
                    if factory:IsUnitState('Upgrading') then
                        LOG('[OWPlus] Outpost (' .. tostring(locationType) .. '): OK, upgrade "' .. tostring(label) .. '" confermato avviato (Upgrading=true a +15s)')
                    else
                        LOG('[OWPlus-WARN] Outpost (' .. tostring(locationType) .. '): upgrade "' .. tostring(label)
                            .. '" MAI partito (Upgrading=false a +15s, probabile CanFormPlatoon fallito) — claim rilasciato, ritento subito')
                    end
                    factory.OWPlusUpgradeClaimed = nil
                end
            end)
            return true
        end
    end
    return false
end

-- Fix sess.77 (bis): anche col claim sincrono sopra, l'upgrade fabbrica
-- veniva ISSUATO con successo (nessun WARN da UnitUpgradeAI vanilla) ma non
-- completava mai — la fabbrica tornava idle T1 a intervalli di ~90s (esatto
-- timeout di sicurezza del claim) e veniva ri-reclamata da capo, all'infinito.
-- Causa: OWPlus Outpost Engineer Builders.lua non escludeva le fabbriche gia'
-- in upgrade/reclamate dalle proprie condizioni — quindi, mentre la fabbrica
-- stava auto-potenziandosi, il builder ingegnere tentava comunque di mettere
-- in coda un altro ingegnere sulla STESSA fabbrica. In FA una fabbrica non
-- puo' costruire un'unita' E upgradare contemporaneamente: un nuovo ordine di
-- build (che tipicamente pulisce la coda corrente) cancella l'upgrade in
-- corso, spiegando perche' fosse "accettato" ma mai completato. Guardia
-- riusabile per bloccare qualunque builder-ingegnere quando la fabbrica del
-- LocationType e' occupata da un upgrade (nostro claim O flag nativo).
--
-- Sess.100 parte 9 (piano fabbriche): con PIU' fabbriche per avamposto (2 terra + 1 aria) un
-- upgrade in corso non deve fermare la produzione delle altre. La condizione diventa falsa
-- solo se TUTTE le fabbriche vive della location sono in upgrade/reclamate. Con UNA sola
-- fabbrica (o col flag OWPlusMultiFactoryDisabled = true) il comportamento e' identico a prima.
-- Il rischio "un nuovo ordine di build cancella l'upgrade" e' coperto per FABBRICA (non piu' per
-- location) da FactoryBuilderManager.BuilderParamCheck (hook): una fabbrica in upgrade/claimata
-- non riceve mai un builder.
function OWPlusFactoryNotUpgrading(aiBrain, locationType, label)
    local mgr = aiBrain.BuilderManagers[locationType]
    local result = true
    local liveCount, busyCount = 0, 0
    if mgr and mgr.FactoryManager and mgr.FactoryManager.FactoryList then
        for _, factory in mgr.FactoryManager.FactoryList do
            if not factory.Dead then
                liveCount = liveCount + 1
                if factory:IsUnitState('Upgrading') or factory.OWPlusUpgradeClaimed then
                    busyCount = busyCount + 1
                end
            end
        end
    end
    if busyCount > 0 and (OWPlusFactoryTargetsMod.OWPlusMultiFactoryDisabled or busyCount >= liveCount) then
        result = false
    end
    if not result and OWPlusDebugThrottle(aiBrain, 'FactoryNotUpgrading_' .. tostring(locationType) .. '_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] OWPlusFactoryNotUpgrading(' .. tostring(locationType) .. ') = false -- builder "' .. tostring(label) .. '" bloccato, fabbrica in upgrade ('
            .. busyCount .. '/' .. liveCount .. ' fabbriche occupate)')
    elseif result and busyCount > 0
        and OWPlusDebugThrottle(aiBrain, 'FactoryNotUpgradingPartial_' .. tostring(locationType), 30) then
        LOG('[OWPlus-FACTORY] OWPlusFactoryNotUpgrading(' .. tostring(locationType) .. ') = true -- ' .. busyCount .. '/' .. liveCount
            .. ' fabbriche in upgrade, le altre continuano a produrre')
    end
    return result
end

-- Log quando la forward base tenta di espandersi con una nuova fabbrica terra.
function OWPlusLogForwardExpansion(aiBrain, label)
    LOG('[OWPlus] ForwardBase: espansione in corso — builder "' .. tostring(label) .. '" ha superato tutte le condizioni, avvio costruzione')
    return true
end

-- Verifica se uno slot forward base esiste in aiBrain.OWPlusSubBases (registrato da
-- ExpansionFunction quando un marker viene accettato). Usata da 'OWPlus Forward Extra
-- Factory' per sapere se un dato slot (FWD1..FWD4) e' gia' stato assegnato.
function OWPlusForwardSlotExists(aiBrain, slotKey)
    return aiBrain.OWPlusSubBases ~= nil and aiBrain.OWPlusSubBases[slotKey] ~= nil
end

-- Fase 9-F9: quante basi forward sono gia' state accettate (aiBrain.OWPlusForwardBaseMarkers,
-- popolato da ExpansionFunction). Usata per il trigger a due livelli di
-- 'OWPlus Vacant Expansion Area': prima base con soglia bassa, 2a-4a con soglia piu' alta.
-- NOTA (Fase 9-F18): 'OWPlus Vacant Expansion Area' e il sistema a marker/settori sono
-- stati sostituiti dal generatore di avamposti indipendente (OWPlusOutpostGenerator.lua).
-- Questa funzione resta per compatibilita' storica ma non e' piu' referenziata da nessun
-- builder attivo.
function OWPlusForwardCountInRange(aiBrain, minCount, maxCount)
    local count = 0
    if aiBrain.OWPlusForwardBaseMarkers then
        for _ in pairs(aiBrain.OWPlusForwardBaseMarkers) do
            count = count + 1
        end
    end
    return count >= minCount and count < maxCount
end

-- Fase 9-F18: c'e' almeno un avamposto generato (OWPlusOutpostGenerator.lua) non ancora
-- rivendicato da un ingegnere? aiBrain.OWPlusOutpostClaimed traccia gli slot 'OUT#' gia'
-- presi in carico (non ancora quelli completati - una volta costruita la fabbrica lo slot
-- resta comunque "claimed" per sempre, cosi' non viene ripreso in carico una seconda volta).
function OWPlusHasUnclaimedOutpost(aiBrain)
    if not aiBrain.OWPlusSubBases then return false end
    aiBrain.OWPlusOutpostClaimed = aiBrain.OWPlusOutpostClaimed or {}
    for slotKey, _ in aiBrain.OWPlusSubBases do
        if string.sub(slotKey, 1, 3) == 'OUT' and not aiBrain.OWPlusOutpostClaimed[slotKey] then
            return true
        end
    end
    return false
end

-- Fase A (B16): il LocationType passato e' un avamposto riconosciuto? Popolata da
-- platoon.lua quando la prima fabbrica dell'avamposto viene registrata in un
-- BuilderManager reale (9-F19/20).
-- Instrumentazione diagnostica (sess.72): aggiunto LOG throttled (era stato omesso
-- di proposito perche' valutata molto di frequente — l'8s di throttle per-location
-- lo rende ora sicuro) per verificare se questa condizione e' davvero vera per gli
-- avamposti reali nei momenti in cui i builder Fase A/B avrebbero dovuto vincere.
function OWPlusIsOutpostLocation(aiBrain, locationType)
    local result = aiBrain.OWPlusOutpostLocationTypes ~= nil and aiBrain.OWPlusOutpostLocationTypes[locationType] == true
    if OWPlusDebugThrottle(aiBrain, 'IsOutpostLocation_' .. tostring(locationType), 8) then
        LOG('[OWPlus-DBG] OWPlusIsOutpostLocation(' .. tostring(locationType) .. ') = ' .. tostring(result))
    end
    return result
end

-- Fase C (B16), sess.83: analoghe a OWPlusDebugFactoryUpgradeCandidateExists/
-- OWPlusClaimFactoryUpgrade sopra, ma per l'upgrade NATIVO in-place (General.
-- UpgradesTo nel .bp, Plan='UnitUpgradeAI') delle difese modded TotalMayhem
-- con una versione MK2 nota (Mayor/Thug/Coyote/Pen — vedi OWPlusOutpostDefensePool.
-- OWPlusModdedUpgradeChain). A differenza delle fabbriche (tracciate in
-- mgr.FactoryManager.FactoryList), le difese non hanno una lista dedicata nel
-- manager — si scansiona fisicamente attorno alla posizione nota del manager
-- (mgr.Position, campo diretto impostato da AddBuilderManagers/base-ai.lua —
-- NON aiBrain.OWPlusOutpostFactories/OWPlusSubBases, indicizzate per
-- targetLocType e non per la vera chiave LocationType, stesso pitfall di
-- OWPlusOutpostFactoryIsTech sopra). NOTA: aiBrain.BuilderManagers[locationType]
-- e' una tabella semplice {FactoryManager=,PlatoonFormManager=,EngineerManager=,
-- Position=,...}, NON un'istanza di classe — GetLocationCoords() esiste solo sui
-- SOTTO-manager (es. mgr.EngineerManager:GetLocationCoords(), usata da Uveso in
-- aibuildstructures.lua), non sul wrapper stesso; mgr.Position e' piu' diretto e
-- gia' quota-corretta (terrain/surface height applicati da AddBuilderManagers).
-- Stesso doppio gate (non gia' in upgrade, non gia' reclamata dal nostro claim
-- sincrono) e stesso pattern di claim-con-rilascio-attivo-a-15s di
-- OWPlusClaimFactoryUpgrade — riusa la stessa lezione (sess.77) su
-- IsUnitState('Upgrading') che non si sincronizza abbastanza in fretta lato
-- script per fidarsi di un controllo singolo.
-- Fix sess.91 (richiesta esplicita utente in game): OWPlusUpgradeClaimed
-- (sotto) blocca solo doppi claim sulla STESSA famiglia (stesso moddedUnitId)
-- -- non impedisce a Mayor/Thug/Coyote/Pen/Tower Boss di partire tutti
-- insieme appena la soglia storage e' vera, sovraccaricando l'economia
-- dell'avamposto invece di procedere un upgrade alla volta. Nuovo controllo
-- TRASVERSALE a tutte le famiglie: se una qualunque difesa a questo
-- avamposto e' gia' REALMENTE in upgrade, blocca tutti gli altri builder
-- Defense Upgrade finche' non completa.
--
-- Fix regressione sess.91 (bis, trovato in test in game subito dopo il primo
-- deploy): la versione iniziale bloccava anche su 'u.OWPlusUpgradeClaimed'
-- (claim TENTATO, non ancora confermato) -- ma il claim su una famiglia puo'
-- restare bloccato per sempre nel loop 'MAI partito' gia' noto (vedi
-- OWPlusClaimDefenseUpgrade sopra, stesso sintomo su IsUnitState('Upgrading')
-- che non si conferma mai entro 15s -- causa non ancora diagnosticata, gia'
-- sospettata in un hook diagnostico precedente su CanFormPlatoon/FormRadius).
-- Con 'OWPlusUpgradeClaimed' nel controllo, una famiglia bloccata nel loop
-- MAI-partito teneva PERMANENTEMENTE bloccate anche le altre 4 -- prima di
-- questo fix, ogni famiglia falliva/ritentava per conto proprio, senza
-- bloccare le altre. Ora si blocca solo su un upgrade REALMENTE confermato
-- (IsUnitState('Upgrading') == true), mai su un claim ancora da confermare.
--
-- Fix Fase H (sess.93): le 3 funzioni sotto (questa + le 2 seguenti)
-- facevano la STESSA query GetUnitsAroundPoint(STRUCTURE*DEFENSE, pos, 40) —
-- ora migrate alla mappa ownership (kind=Structure, Fase F/sess.88), con
-- filtro EntityCategoryContains(categories.DEFENSE, u) in lettura (il
-- bucket 'structure' contiene anche scudi/artiglieria/SMD/bonus, non solo
-- difese — equivalente al filtro category originale dato che il bucket e'
-- comunque sempre sottoinsieme di STRUCTURE per costruzione). Nessuna delle
-- 3 richiede piu' mgr/mgr.Position.
function OWPlusDebugNoDefenseUpgradeInProgress(aiBrain, locationType, label)
    local result = true
    for u, _ in OWPlusOutpostOwnership.OWPlusGetOwnedUnits(aiBrain, locationType, OWPlusOutpostOwnership.OWPlusOwnershipKindStructure) do
        if EntityCategoryContains(categories.DEFENSE, u) and u:IsUnitState('Upgrading') then
            result = false
            break
        end
    end
    if OWPlusDebugThrottle(aiBrain, 'NoDefUpgradeInProgress_' .. tostring(locationType) .. '_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] NoDefenseUpgradeInProgress(' .. tostring(locationType) .. ') = ' .. tostring(result) .. ' -- builder "' .. tostring(label) .. '"')
    end
    return result
end

function OWPlusDefenseUpgradeCandidateExists(aiBrain, locationType, moddedUnitId, label)
    local count = 0
    for u, _ in OWPlusOutpostOwnership.OWPlusGetOwnedUnits(aiBrain, locationType, OWPlusOutpostOwnership.OWPlusOwnershipKindStructure) do
        if EntityCategoryContains(categories.DEFENSE, u) and string.lower(tostring(u.UnitId)) == moddedUnitId
            and not u:IsUnitState('Upgrading') and not u.OWPlusUpgradeClaimed then
            count = count + 1
        end
    end
    if OWPlusDebugThrottle(aiBrain, 'DefUpgradeCandidate_' .. tostring(locationType) .. '_' .. tostring(label), 8) then
        LOG('[OWPlus-DBG] Candidati upgrade difesa "' .. tostring(label) .. '" a ' .. tostring(locationType) .. ': ' .. tostring(count))
    end
    return count > 0
end

function OWPlusClaimDefenseUpgrade(aiBrain, locationType, moddedUnitId, label)
    for u, _ in OWPlusOutpostOwnership.OWPlusGetOwnedUnits(aiBrain, locationType, OWPlusOutpostOwnership.OWPlusOwnershipKindStructure) do
        if EntityCategoryContains(categories.DEFENSE, u) and string.lower(tostring(u.UnitId)) == moddedUnitId
            and not u:IsUnitState('Upgrading') and not u.OWPlusUpgradeClaimed then
            u.OWPlusUpgradeClaimed = true
            -- Sess.99 (diagnostica temporanea, fix desync): EntityId incluso -- se
            -- piu' unita' candidate identiche esistono nello stesso momento,
            -- verificare in game che sia SEMPRE lo stesso EntityId scelto su ogni
            -- client per lo stesso tick. Da rimuovere/mettere dietro throttle dopo
            -- la conferma.
            LOG('[OWPlus] Outpost (' .. tostring(locationType) .. '): OK, upgrade difesa avviato (' .. moddedUnitId
                .. ', EntityId=' .. tostring(u:GetEntityId()) .. ') — builder "' .. tostring(label) .. '"')
            ForkThread(function()
                WaitSeconds(15)
                if not u.Dead then
                    if u:IsUnitState('Upgrading') then
                        LOG('[OWPlus] Outpost (' .. tostring(locationType) .. '): OK, upgrade difesa (' .. moddedUnitId .. ') confermato avviato (Upgrading=true a +15s)')
                    else
                        LOG('[OWPlus-WARN] Outpost (' .. tostring(locationType) .. '): upgrade difesa (' .. moddedUnitId
                            .. ') MAI partito (Upgrading=false a +15s) — claim rilasciato, ritento subito')
                    end
                    u.OWPlusUpgradeClaimed = nil
                end
            end)
            return true
        end
    end
    return false
end

-- Fase A (B16): la fabbrica di QUESTO LocationType (la stessa chiave reale che il
-- builder system passa qui come placeholder 'LocationType') e' ESATTAMENTE al tier
-- richiesto? NOTA: legge aiBrain.BuilderManagers[locationType].FactoryManager.FactoryList
-- direttamente (fonte di verita' del motore), NON aiBrain.OWPlusOutpostFactories — quella
-- tabella e' indicizzata per targetLocType ('OUT#'), che NON coincide con la vera chiave
-- LocationType assegnata da AddFactoryToClosestManager (vedi commento in platoon.lua,
-- Fase A). Usata per far produrre a ciascun avamposto solo ingegneri del proprio tier
-- attuale (il riassorbimento del tier precedente e' gestito dal watcher in platoon.lua).
function OWPlusOutpostFactoryIsTech(aiBrain, locationType, techLevel)
    local mgr = aiBrain.BuilderManagers[locationType]
    local result = false
    if mgr and mgr.FactoryManager and mgr.FactoryManager.FactoryList then
        local techCat = categories.TECH1
        if techLevel == 2 then
            techCat = categories.TECH2
        elseif techLevel == 3 then
            techCat = categories.TECH3
        end
        for _, factory in mgr.FactoryManager.FactoryList do
            if not factory.Dead and EntityCategoryContains(techCat, factory) then
                result = true
                break
            end
        end
    end
    -- Instrumentazione diagnostica (sess.72): LOG throttled per verificare se il
    -- tier rilevato coincide con quello atteso nei momenti chiave del test.
    if OWPlusDebugThrottle(aiBrain, 'FactoryIsTech_' .. tostring(locationType) .. '_T' .. tostring(techLevel), 8) then
        LOG('[OWPlus-DBG] OWPlusOutpostFactoryIsTech(' .. tostring(locationType) .. ', T' .. tostring(techLevel) .. ') = ' .. tostring(result))
    end
    return result
end

-- Sess.98: diagnostica NEUTRA (LOG+true, non blocca mai) per il secondo problema
-- segnalato dall'utente in game (test 2h07m, 2026-08-05): l'AI costruisce il primo
-- idrocarburo poi si concentra sui generatori T1 standard per diversi minuti prima
-- di costruirne altri, nonostante 'OWPlus Hydrocarbon Push' abbia priorita' FISSA
-- 17950 (piu' alta del nativo 'U1 Power <90%', 17900). Verificato leggendo Base
-- Energy.lua: 'U1 Power <90%' non ha ALCUN DelayEqualBuildPlattons (ne' lo scrive
-- ne' lo controlla, costruisce senza vincoli di marker/cooldown), mentre il nostro
-- Hydrocarbon Push (copiato fedelmente dal nativo 'U1 Power Hydrocarbon', stessi
-- parametri inclusa distance=90 per CanBuildOnHydro) resta soggetto sia al
-- cooldown condiviso CheckBuildPlattonDelay('Energy') sia alla disponibilita' di
-- un marker Hydrocarbon libero entro 90 unita' (MarkerBuildConditions.lua,
-- CanBuildOnHydro). Ipotesi: quando CanBuildOnHydro fallisce (marker piu' vicini
-- gia' costruiti, nessun altro entro 90), il generatore T1 standard (senza questo
-- vincolo) prende sistematicamente il sopravvento finche' la base non si espande
-- abbastanza da portare un nuovo marker in raggio. Questo log riporta lo stato
-- REALE di entrambi i gate ad ogni valutazione, per confermare o escludere.
function OWPlusDebugHydrocarbonDiag(aiBrain, locationType, label)
    if OWPlusDebugThrottle(aiBrain, 'HydroDiag_' .. tostring(label), 10) then
        local t1pgens = table.getn(aiBrain:GetListOfUnits(categories.STRUCTURE * categories.TECH1 * categories.ENERGYPRODUCTION - categories.HYDROCARBON, false) or {})
        local hydro = table.getn(aiBrain:GetListOfUnits(categories.STRUCTURE * categories.HYDROCARBON, false) or {})
        local delayOk = UCBCMod.CheckBuildPlattonDelay(aiBrain, 'Energy')
        -- Sess.98: 90->9999, coerente con il valore reale usato dal gate (sopra).
        local markerOk = MABCMod.CanBuildOnHydro(aiBrain, locationType, 9999, -1000, 100, 1, 'AntiSurface', 1)
        LOG('[OWPlus-DBG] HydrocarbonDiag(' .. tostring(label) .. ') t=' .. tostring(GetGameTimeSeconds())
            .. 's, T1pgens=' .. tostring(t1pgens) .. ', hydro=' .. tostring(hydro)
            .. ', CheckBuildPlattonDelay(Energy)=' .. tostring(delayOk)
            .. ', CanBuildOnHydro(' .. tostring(locationType) .. ')=' .. tostring(markerOk))
    end
    return true
end

-- Sess.98: diagnostica NEUTRA (LOG+true, non blocca mai) per il nuovo builder
-- 'OWPlus Energy Generator Upgrade T4' (EnergyTierExpansion-child) -- T3 e T4
-- condividono le stesse Categories (stesso schema Jaggeds, 'TECH3' non
-- 'TECH4', non esiste una vera categoria distinta), quindi il consueto
-- OWPlusDebugUpgradeProgress (basato su categorie sorgente/destinazione) non
-- puo' distinguerli. Qui la distinzione avviene per ID UNITA' ESATTO (i 4 ID
-- T4 sono noti e fissi, definiti in EnergyTierExpansion-child).
local OWPLUS_T4_ENERGY_GEN_IDS = { ueb1401 = true, uab1401 = true, urb1401 = true, xsb1401 = true }

function OWPlusDebugEnergyGeneratorT4Progress(aiBrain, sourceCategory, label)
    if OWPlusDebugThrottle(aiBrain, 'EnergyGenT4Progress_' .. tostring(label), 15) then
        local units = aiBrain:GetListOfUnits(sourceCategory, false) or {}
        local t3count = 0
        local t4count = 0
        for _, u in units do
            if u and not u.Dead then
                if OWPLUS_T4_ENERGY_GEN_IDS[string.lower(tostring(u.UnitId))] then
                    t4count = t4count + 1
                else
                    t3count = t3count + 1
                end
            end
        end
        LOG('[OWPlus-DBG] EnergyGeneratorT4Progress(' .. tostring(label) .. ') T3=' .. tostring(t3count)
            .. ', T4=' .. tostring(t4count) .. ' (t=' .. tostring(GetGameTimeSeconds()) .. 's)')
    end
    return true
end
