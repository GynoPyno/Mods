-- AI-Uveso-child: hook platoon.lua
-- OWPlusDispersedBuildAI: PlatoonAI custom per costruire nelle sub-location BASE_NE/SE/SW/NW.
--
-- PROBLEMA: EngineerBuildAI (branch else) passa reference=true (booleano) ad AIExecuteBuildStructure.
-- Uveso's AIExecuteBuildStructure usa closeToBuilder → posizione dell'ingegnere (= MAIN).
-- Construction.LocationType nel builder non viene mai letto in questo path.
--
-- SOLUZIONE: questo PlatoonAI legge cons.LocationType, trova le coordinate in
-- aiBrain.OWPlusSubBases[locType] (tabella custom, immune a DeadBaseMonitor),
-- e passa targetPos come 'reference' (tabella) ad AIExecuteBuildStructure.
-- Uveso controlla per primo "reference and type(reference) == 'table'" → usa targetPos come centro.
--
-- NOTA: NON si usa aiBrain.BuilderManagers per le sub-location perché DeadBaseMonitor
-- rimuove ogni manager non-MAIN senza ingegneri/fabbriche dopo 5 secondi dalla creazione.

-- Sess.98 (bis): case corretto -- era '/lua/AI/aibuildstructures.lua' (A/I
-- maiuscole), ma OGNI hook su questo file (sia AI-Uveso sia il nostro,
-- aggiunto in questa stessa sessione) e' registrato con path minuscolo
-- '/lua/ai/aibuildstructures.lua'. La funzione nativa import() (system/
-- import.lua) tenta prima il path ESATTO, poi fa fallback al minuscolo --
-- un mismatch di case qui rischia di risolvere a una copia del modulo
-- diversa da quella con gli hook applicati, a seconda dell'ordine di
-- caricamento. Sospettato (non confermato al 100%) come causa della
-- rottura del sistema OWPlusDispersedBuildAI (basette diagonali BASE_NE/
-- SE/SW/NW, "zero strutture costruite" sistematico) -- fix a rischio
-- minimo comunque corretto per coerenza col resto del progetto.
local AIBuildStructures = import('/lua/ai/aibuildstructures.lua')
-- Fase 9-F30: modulo nostro (non un file hookato del motore/di un'altra mod),
-- quindi nessun rischio di load-order come per aiarchetype-managerloader.lua —
-- sicuro da importare qui a livello di file.
local OWPlusTransportUtils = import('/mods/AI-Uveso-child/lua/AI/OWPlusTransportUtils.lua')
-- Fase C (B16): stesso motivo di OWPlusTransportUtils sopra — modulo nostro, puro
-- (nessuna dipendenza esterna a livello di file), sicuro da importare qui.
local OWPlusOutpostDefensePool = import('/mods/AI-Uveso-child/lua/AI/OWPlusOutpostDefensePool.lua')
-- Fase F (B16), sess.88: mappa di appartenenza esplicita unita'->avamposto
-- (sostituisce l'inferenza per prossimita' nel conteggio difese/scudi/
-- artiglieria) — stesso motivo di OWPlusOutpostDefensePool sopra, modulo
-- nostro puro, sicuro da importare qui.
local OWPlusOutpostOwnership = import('/mods/AI-Uveso-child/lua/AI/OWPlusOutpostOwnership.lua')
-- Sess.100 parte 9 (piano fabbriche): flag OWPlusMultiFactoryDisabled e obiettivi per base
-- (modulo nostro puro, sicuro da importare a livello di file come i due sopra).
local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')

-- Sess.100 parte 9 (piano fabbriche): con 3 fabbriche per avamposto e avamposti a 13-31 unita'
-- l'uno dall'altro, le scansioni "fabbriche entro 20 dall'avamposto" contano anche quelle dei
-- VICINI. Questo filtro assegna ogni fabbrica alla base piu' vicina (stessa regola del
-- censimento, OWPlusFactoryTargets.lua) e la accetta solo se e' questo avamposto. Col flag
-- OWPlusMultiFactoryDisabled = true restituisce sempre true (comportamento storico).
local function OWPlusFactoryBelongsToOutpost(aiBrain, factory, outpostKey)
    if OWPlusFactoryTargetsMod.OWPlusMultiFactoryDisabled then
        return true
    end
    local nearestKey = OWPlusFactoryTargetsMod.OWPlusFactoryNearestBaseKey(aiBrain, factory)
    return nearestKey == nil or nearestKey == outpostKey
end

-- Numero di fabbriche vive di QUESTO avamposto (scansione a raggio 20 filtrata per appartenenza).
local function OWPlusCountOutpostFactories(aiBrain, outpostKey, outpostPos)
    local count = 0
    for _, f in aiBrain:GetUnitsAroundPoint(categories.STRUCTURE * categories.FACTORY, outpostPos, 20, 'Ally') or {} do
        if not f.Dead and OWPlusFactoryBelongsToOutpost(aiBrain, f, outpostKey) then
            count = count + 1
        end
    end
    return count
end
-- Sess.94: import a livello di file sicuro -- il platoon.lua NATIVO di AI-Uveso
-- (caricato PRIMA di questo file nel load order) importa gia' 'uvesoutilities.lua'
-- allo stesso modo, a livello di file, senza cautele di lazy-loading (a
-- differenza di 'AddFactoryToClosestManager' sopra, che ha dipendenze circolari
-- col bootstrap AI in corso) -- quando questo file viene processato la cache e'
-- gia' pronta. '/lua/upgradetemplates.lua' e' un file MOTORE (path generico,
-- nessun prefisso mod), sempre disponibile.
local UUtils = import('/mods/AI-Uveso/lua/AI/uvesoutilities.lua')
local UpgradeTemplatesMod = import('/lua/upgradetemplates.lua')
-- Fase C (B16), sess.81: tetto ai retry di un singolo task difesa. Un task che
-- fallisce ripetutamente (difesa modded senza posto valido, ingegnere sempre
-- inadatto) veniva rimesso in coda all'infinito (1378 requeue osservati in game
-- con l'opzione A). Oltre questa soglia il task viene scartato invece di
-- intasare la coda per sempre.
local OWPLUS_MAX_DEFENSE_RETRIES = 8
-- Fase D-difese (sess.86): interruttore rapido per isolare la nuova feature
-- "difese scalate per tier" (lotto aggiuntivo + slot bonus al tier-up, vedi
-- OWPlusPickTierDefenses in OWPlusOutpostDefensePool.lua) durante il test in
-- game — se qualcosa si rompe, mettere a false qui isola immediatamente se il
-- problema e' questa feature o qualcos'altro, senza dover fare revert di codice.
local OWPLUS_TIER_DEFENSES_ENABLED = true
-- Fase C (B16), sess.82: helper condiviso per il gate 2 (posizione) del build
-- diretto di un ID blueprint literale modded — Conoscenze_AI_40 §40.1. Usato sia
-- dal ramo 'build' (task nuovi) sia dal ramo 'reclaim' (upgrade MK1->MK2 di una
-- difesa esistente, sess.82): stesso identico anello di offset, evitava di
-- triplicare la stessa logica in tre punti diversi del file. Ritorna la
-- worldPos {x,y,z} trovata valida, o nil se nessun offset e' risultato
-- costruibile entro maxTries tentativi. Non verifica CanBuild (capacita'
-- ingegnere) — quello resta un gate separato a carico del chiamante, perche' e'
-- indipendente dalla posizione.
local function OWPlusFindModdedBuildSpot(aiBrain, bpId, centerPos, radiusMin, radiusMax, maxTries)
    local tries = 0
    while tries < maxTries do
        local a = math.rad(Random(0, 359))
        local d = Random(radiusMin, radiusMax)
        local cx = centerPos[1] + math.cos(a) * d
        local cz = centerPos[3] + math.sin(a) * d
        if aiBrain:CanBuildStructureAt(bpId, { cx, 0, cz }) then
            return { cx, centerPos[2], cz }
        end
        tries = tries + 1
    end
    return nil
end
-- Fix Fase F-ter (sess.89, B20): la cattura a raggio stretto (5 unita') introdotta
-- in Fase F-bis fallisce il 20-64% delle volte a seconda della categoria (peggio
-- per le difese T1 — verificato su log reale, vedi AI_Mod_Spec.md B20). Causa
-- probabile: quando l'ingegnere piazza piu' strutture piccole ravvicinate in
-- rapida successione (T1, tetto piu' alto = piu' unita' nello stesso anello), il
-- motore puo' scostare leggermente il piazzamento reale dalla posizione comandata
-- per evitare la collisione con una struttura appena piazzata li' accanto —
-- oltre il raggio 5 originale ma sempre ben sotto la distanza minima reale tra
-- due avamposti consecutivi (13-31 unita', vedi Fase F). Fix: raggio allargato a
-- 10 (meta' del margine minimo misurato, non l'intero — resta un margine di
-- sicurezza contro un vicino), scelta della struttura PIU' VICINA alla posizione
-- comandata invece della prima trovata (l'ordine di GetUnitsAroundPoint non e'
-- garantito per distanza), esclusione di strutture gia' di proprieta' di un
-- ALTRO avamposto (tag OWPlusOwnerOutpost, difesa aggiuntiva contro un falso
-- positivo di raggio), e un secondo tentativo dopo una breve attesa se il primo
-- scan non trova nulla (copre un'eventuale finestra di propagazione dello spatial
-- query subito dopo la conferma 'costruzione finita').
local function OWPlusCaptureBuiltStructure(aiBrain, outpostKey, targetPos)
    local RADIUS = 10
    for attempt = 1, 2 do
        -- Fase H (sess.93): unico scan geometrico rimasto in tutto il sistema
        -- avamposto, ora dietro un helper condiviso (OWPlusOutpostOwnership.lua)
        -- — nessun'altra copia di GetUnitsAroundPoint nel resto del sistema
        -- avamposto, tutte migrate alla mappa ownership.
        local candidates = OWPlusOutpostOwnership.OWPlusScanUnitsAroundPoint(aiBrain, categories.STRUCTURE, targetPos, RADIUS)
        local best, bestDist = nil, nil
        for _, u in candidates do
            if not u.Dead and (not u.OWPlusOwnerOutpost or u.OWPlusOwnerOutpost == outpostKey) then
                local upos = u:GetPosition()
                local d = VDist2(targetPos[1], targetPos[3], upos[1], upos[3])
                if not bestDist or d < bestDist then
                    best, bestDist = u, d
                end
            end
        end
        if best then
            LOG('[OWPlus-DIAG] Outpost (' .. outpostKey .. '): cattura struttura OK al tentativo '
                .. attempt .. ', dist=' .. math.floor(bestDist or -1) .. ', unitId=' .. tostring(best.UnitId))
            return best
        end
        if attempt == 1 then
            LOG('[OWPlus-DIAG] Outpost (' .. outpostKey .. '): cattura struttura fallita al tentativo 1 (raggio '
                .. RADIUS .. '), ritento tra 2s')
            WaitSeconds(2)
        end
    end
    LOG('[OWPlus-DIAG] Outpost (' .. outpostKey .. '): cattura struttura fallita dopo 2 tentativi (raggio ' .. RADIUS .. ')')
    return nil
end

-- Fase D3 (B24), sess.90: problema segnalato dall'utente in test — le unita'
-- da combattimento appena prodotte da un avamposto (Fase D1) venivano
-- immediatamente mandate all'attacco DA SOLE da un Former nativo di MAIN.
-- Causa verificata nel motore: PoolGreaterAtLocation/PoolLessAtLocation
-- (UnitCountBuildConditions.lua) sono basate sulla POSIZIONE FISICA (raggio
-- attorno al manager), non sulla proprieta' dell'unita' — il raggio di MAIN
-- (sempre >=90, vedi Conoscenze_AI_45 sez.45.1) puo' includere avamposti
-- vicini, quindi il Former nativo di MAIN "vede" e ruba le nostre unita' dal
-- pool condiviso ArmyPool.
--
-- Fix: reclamo IMMEDIATO — appena un'unita' da combattimento compare vicino
-- alla fabbrica dell'avamposto, viene spostata (aiBrain:AssignUnitsToPlatoon,
-- API nativa gia' usata da Uveso per lo stesso scopo, es. aibuildstructures.lua)
-- in un plotone "di attesa" dedicato all'avamposto — questo la toglie da
-- ArmyPool, quindi nessun Former esterno (incluso quello di MAIN) puo' piu'
-- vederla. Quando il plotone di attesa raggiunge la soglia dinamica (stessa
-- famiglia di formula logaritmica di B16 Fase G/B20, calcolata dal tempo di
-- fondazione del singolo avamposto), le unita' vengono spostate in un vero
-- plotone d'attacco con Plan=HeroFightPlatoon (stesso Plan usato da quasi
-- tutti i template d'attacco Uveso) e inviate.
local function OWPlusOutpostAttackThreshold(elapsedSeconds)
    if not elapsedSeconds or elapsedSeconds < 0 then
        elapsedSeconds = 0
    end
    return 10 + math.floor(2 * math.log(1 + elapsedSeconds / 300))
end

local function OWPlusOutpostAttackWatcher(aiBrain, outpostKey)
    ForkThread(function()
        local OWPlusLogConditionsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua')
        while aiBrain.Status ~= 'Defeat' do
            WaitSeconds(2)
            local mgr = aiBrain.BuilderManagers[outpostKey]
            local pos = mgr and mgr.Position
            if pos and OWPlusLogConditionsMod.OWPlusOutpostAttackEnabled(aiBrain) then
                -- Reclamo immediato: qualunque unita' da combattimento non ancora
                -- taggata, vicino alla fabbrica, va nel pool protetto.
                local nearby = aiBrain:GetUnitsAroundPoint(
                    categories.MOBILE * categories.LAND * (categories.DIRECTFIRE + categories.INDIRECTFIRE)
                        - categories.SHIELD - categories.STEALTHFIELD - categories.EXPERIMENTAL
                        - categories.ENGINEER - categories.SCOUT - categories.COMMAND - categories.SUBCOMMANDER,
                    pos, 20, 'Ally') or {}
                for _, u in nearby do
                    if not u.Dead and not u.OWPlusOwnerOutpost then
                        u.OWPlusOwnerOutpost = outpostKey
                        aiBrain.OWPlusOutpostAttackPool = aiBrain.OWPlusOutpostAttackPool or {}
                        if not aiBrain.OWPlusOutpostAttackPool[outpostKey] then
                            aiBrain.OWPlusOutpostAttackPool[outpostKey] = aiBrain:MakePlatoon('', '')
                        end
                        aiBrain:AssignUnitsToPlatoon(aiBrain.OWPlusOutpostAttackPool[outpostKey], { u }, 'Unassigned', 'None')
                        LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, unita\' (' .. tostring(u.UnitId)
                            .. ') reclamata nel pool protetto, sottratta a Former esterni (Fase D3)')
                    end
                end

                -- Soglia di lancio: conta le unita' vive nel pool protetto,
                -- confronta con la soglia dinamica, forma ed invia se raggiunta.
                local holdPlat = aiBrain.OWPlusOutpostAttackPool and aiBrain.OWPlusOutpostAttackPool[outpostKey]
                if holdPlat then
                    local heldUnits = {}
                    for _, u in holdPlat:GetPlatoonUnits() do
                        if not u.Dead then
                            table.insert(heldUnits, u)
                        end
                    end
                    local founded = aiBrain.OWPlusOutpostFoundedAt and aiBrain.OWPlusOutpostFoundedAt[outpostKey]
                    local elapsed = founded and (GetGameTimeSeconds() - founded) or 0
                    local threshold = OWPlusOutpostAttackThreshold(elapsed)
                    if table.getn(heldUnits) >= threshold then
                        local attackPlat = aiBrain:MakePlatoon('', '')
                        -- Sess.100 parte 12 (fix bug): il plotone nasce a mano, non da un Builder,
                        -- quindi PlatoonData restava VUOTO -> HeroFightPlatoon senza MoveToCategories
                        -- (nessun bersaglio cercabile, plotone fermo) e SearchRadius di default 100.
                        -- Stessi dati dei plotoni batch terra di MAIN (OWPlus Formers.lua,
                        -- OWPlusLandBatchData). Sess.100 parte 14 (decisione utente): anche la marcia in
                        -- formazione con rilascio/riformazione (OWPlusFormationMarch) -- le "strisce" del test
                        -- multiplayer 2026-10-03 erano questi plotoni (212 lanci da 10-17 unita' sciolte).
                        local _, _, OWPlusEnemyZone = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua').GetDangerZoneRadii()
                        attackPlat.PlatoonData = {
                            OWPlusFormationMarch = true,
                            SearchRadius = OWPlusEnemyZone,
                            DirectMoveEnemyBase = true,
                            GetTargetsFromBase = false,
                            AggressiveMove = true,
                            AttackEnemyStrength = 1000000,
                            TargetSearchCategory = categories.ALLUNITS - categories.AIR,
                            MoveToCategories = {
                                categories.STRUCTURE * categories.MASSEXTRACTION,
                                categories.STRUCTURE * categories.ENERGYPRODUCTION,
                                categories.FACTORY,
                                categories.STRUCTURE * categories.DEFENSE,
                                categories.ALLUNITS - categories.AIR,
                            },
                        }
                        attackPlat.BuilderName = 'OWPlus Outpost Attack ' .. outpostKey
                        aiBrain:AssignUnitsToPlatoon(attackPlat, heldUnits, 'Attack', 'GrowthFormation')
                        attackPlat:StopAI()
                        attackPlat:ForkAIThread(attackPlat.HeroFightPlatoon)
                        aiBrain.OWPlusOutpostAttackPool[outpostKey] = nil
                        LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, plotone d\'attacco lanciato ('
                            .. table.getn(heldUnits) .. ' unita\', soglia=' .. threshold .. ', Fase D3, MoveToCategories impostate, marcia in formazione, SearchRadius='
                            .. tostring(OWPlusEnemyZone) .. ')')
                    end
                end
            end
        end
    end)
end
-- Fase 9-F21: AddFactoryToClosestManager (usata piu' sotto, dentro il ForkThread
-- di riaggancio) e' una "globale" ma vive nell'ambiente isolato del modulo
-- aiarchetype-managerloader.lua — in questo motore ogni file import()ato ha il
-- proprio _G separato (setfenv), quindi va acceduta tramite la tabella
-- restituita da import(), non come nome nudo. Confermato bug reale in game log:
-- "access to nonexistent global variable AddFactoryToClosestManager" da
-- platoon.lua, ogni volta che 9-F19/20 tentava di chiamarla.
--
-- Fase 9-F23: l'import di questo modulo NON va fatto qui a livello di file (si
-- eseguirebbe troppo presto, mentre platoon.lua stesso si sta ancora caricando,
-- prima che il resto del bootstrap AI abbia definito le globali da cui questo
-- modulo dipende) — confermato crash reale: "access to nonexistent global
-- variable ExecutePlan" proprio dentro aiarchetype-managerloader.lua, innescato
-- da questo import a caricamento modulo. L'import va fatto in modo "lazy",
-- dentro la funzione/ForkThread che lo usa davvero: a quel punto nel match il
-- bootstrap AI normale (PriorityManagerThread ecc., forkati da questo stesso
-- file a inizio partita) ha gia' caricato ed eseguito il modulo, quindi
-- l'import() qui sotto trova la cache gia' pronta (stesso path base motore
-- usato dal resto del gioco, non il path del file di hook della mod) invece di
-- ricaricarlo da zero.

-- Sess.94: copia fedele di 'ExtractorUpgrade' (AI-Uveso, lua/AI/uvesoutilities.lua
-- righe 102-183), unica modifica alla soglia del fallback "force senza economia
-- sufficiente" (era fissa "4", causa del batch di upgrade T1->T2->T3 osservato
-- dall'utente in game: con 90+ estrattori quella soglia era sempre soddisfatta,
-- il sistema non aspettava mai davvero l'economia). Non si puo' fare un hook
-- minimale sulla funzione originale: 'platoon.lua' nativo la importa con path
-- assoluto esplicito della mod ('/mods/AI-Uveso/lua/AI/uvesoutilities.lua'),
-- che bypassa il meccanismo di override-by-path (funziona solo per path
-- generici motore, non per self-reference esplicito di un'altra mod al
-- proprio codice) -- verificato con un test dedicato (log di conferma
-- caricamento mai comparso). Serve quindi ridefinire l'intero metodo di
-- classe 'ExtractorUpgradeAI' piu' sotto, che chiama QUESTA funzione al posto
-- di 'UUtils.ExtractorUpgrade'.
local function OWPlusExtractorUpgrade(self, aiBrain, MassExtractorUnitList, ratio, techLevel, UnitUpgradeTemplates, StructureUpgradeTemplates)
    -- Sess.99: import mancante -- il ramo TECH3->TECH4 (sotto) usa
    -- OWPlusLogConditionsMod ma questa funzione non lo importava mai (a
    -- differenza di TUTTE le altre funzioni del file che ne fanno uso, ognuna
    -- con il proprio 'local ... = import(...)'). Root cause del bug "0 T4 su
    -- 188 estrattori": al primo trigger utile il motore lanciava "access to
    -- nonexistent global variable" alla riga del tetto fisso TECH3 piu' sotto,
    -- e quell'errore terminava per sempre l'intero coroutine ExtractorUpgradeAI
    -- (confermato: nessuna riga OWPlusExtractorUpgrade/ExtractorUpgradeAI nel
    -- log dopo il crash, per il resto della partita).
    local OWPlusLogConditionsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua')
    -- Do we have the eco to upgrade ?
    -- Sess.94: nome nudo non visibile qui (isolamento _G per modulo, stesso
    -- motivo di UpgradeTemplates sopra) -- accesso tramite UUtils importato.
    local MassRatioCheckPositive = UUtils.GlobalMassUpgradeCostVsGlobalMassIncomeRatio(self, aiBrain, ratio, techLevel, '<' )
    -- search for the neares building to the base for upgrade.
    local BasePosition = aiBrain.BuilderManagers['MAIN'].Position
    local factionIndex = aiBrain:GetFactionIndex()
    local UpgradingBuilding = 0
    local DistanceToBase = nil
    local LowestDistanceToBase = nil
    local upgradeID = nil
    local upgradeBuilding = nil
    local UnitPos = nil
    local FactionToIndex  = { UEF = 1, AEON = 2, CYBRAN = 3, SERAPHIM = 4, NOMADS = 5, ARM = 6, CORE = 7}
    local UnitBeingUpgradeFactionIndex = nil

    -- Sess.95 (ter): conteggio UpgradingBuilding SEMPRE sulla lista COMPLETA
    -- (non sul sottoinsieme filtrato per magazzini sotto) -- serve al tetto di
    -- parallelismo piu' in basso e deve riflettere TUTTE le unita' di questo
    -- techLevel in upgrade, anche quelle fuori dal pool ristretto.
    for k, v in MassExtractorUnitList do
        if v and not v.Dead and not v:BeenDestroyed() and EntityCategoryContains(ParseEntityCategory(techLevel), v) and v:IsUnitState('Upgrading') then
            UpgradingBuilding = UpgradingBuilding + 1
        end
    end

    -- Sess.95 (ter): requisito SOFT "almeno 2 magazzini adiacenti" prima di
    -- promuovere un estrattore da TECH2 a TECH3 (richiesta esplicita utente,
    -- solo per questo salto) -- con estrattori sparsi per la mappa un requisito
    -- rigido bloccherebbe per sempre quelli isolati, quindi si applica solo
    -- come PREFERENZA: se almeno un candidato TECH2 ha >=2 magazzini entro 20
    -- unita', la selezione (piu' vicino alla base, sotto) avviene SOLO tra
    -- quelli; altrimenti (nessun candidato qualificato) si ricade sulla lista
    -- completa, esattamente come prima -- nessuno stallo permanente.
    local candidatePool = MassExtractorUnitList
    if techLevel == 'TECH2' then
        local withStorage = {}
        for k, v in MassExtractorUnitList do
            if v and not v.Dead and not v:BeenDestroyed() and EntityCategoryContains(ParseEntityCategory(techLevel), v) then
                local nearbyStorage = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE * categories.MASSSTORAGE, v:GetPosition(), 20, 'Ally') or {}
                if table.getn(nearbyStorage) >= 2 then
                    table.insert(withStorage, v)
                end
            end
        end
        if table.getn(withStorage) > 0 then
            candidatePool = withStorage
            -- Sess.95 (octies): riattivato su richiesta esplicita utente
            LOG('[OWPlus-DBG] OWPlusExtractorUpgrade(TECH2->TECH3): ' .. tostring(table.getn(withStorage)) .. ' candidati con >=2 magazzini adiacenti, selezione ristretta a questi')
        end
    end

    for k, v in candidatePool do
        local TempID
        -- Check if we don't want to upgrade this unit (Upgrading gia' contato sopra)
        if not v
            or v.Dead
            or v:BeenDestroyed()
            or v:IsPaused()
            or not EntityCategoryContains(ParseEntityCategory(techLevel), v)
            or v:GetFractionComplete() < 1
            or v:IsUnitState('Upgrading')
        then
            -- Skip this loop and continue with the next array
            continue
        end
        -- Check for the nearest distance from mainbase
        UnitPos = v:GetPosition()
        DistanceToBase= VDist2(BasePosition[1] or 0, BasePosition[3] or 0, UnitPos[1] or 0, UnitPos[3] or 0)
        if not LowestDistanceToBase or DistanceToBase < LowestDistanceToBase then
            -- Sess.98 (richiesta esplicita utente, indagine dedicata estrattori T4):
            -- v.Blueprint.FactionCategory sostituisce string.upper(v.Blueprint.
            -- General.FactionName) -- stesso campo usato dal nativo UnitUpgradeAI,
            -- gia' pre-calcolato dal motore al caricamento blueprint
            -- (system/Blueprints.lua: bp.FactionCategory = string.upper(bp.General.
            -- FactionName or 'Unknown')) con fallback sicuro se il campo manca.
            -- Ipotesi migliore trovata per la mancata risoluzione dell'upgrade
            -- estrattori T3->T4 (nessun successo mai osservato su ueb1302
            -- nonostante migliaia di tentativi in un test manuale) -- da validare.
            UnitBeingUpgradeFactionIndex = FactionToIndex[v.Blueprint.FactionCategory] or factionIndex
            -- see if we can find a upgrade
            if EntityCategoryContains(categories.MOBILE, v) then
                TempID = aiBrain:FindUpgradeBP(v:GetUnitId(), UnitUpgradeTemplates[UnitBeingUpgradeFactionIndex])
                if not TempID then
                    AIWarn('['..string.gsub(debug.getinfo(1).source, ".*\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *OWPlusExtractorUpgrade ERROR: Can\'t find UnitUpgradeTemplate for mobile unit: ' .. repr(v:GetUnitId()) )
                end
            else
                TempID = aiBrain:FindUpgradeBP(v:GetUnitId(), StructureUpgradeTemplates[UnitBeingUpgradeFactionIndex])
                if not TempID then
                    AIWarn('['..string.gsub(debug.getinfo(1).source, ".*\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *OWPlusExtractorUpgrade ERROR: Can\'t find StructureUpgradeTemplate for structure: ' .. repr(v:GetUnitId()) )
                end
            end
            -- Check if we can build the upgrade
            if TempID and EntityCategoryContains(categories.STRUCTURE, v) and not v:CanBuild(TempID) then
                AIWarn('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *OWPlusExtractorUpgrade ERROR: Can\'t upgrade structure with StructureUpgradeTemplate: ' .. repr(v:GetUnitId()) )
            elseif TempID then
                upgradeID = TempID
                upgradeBuilding = v
                LowestDistanceToBase = DistanceToBase
            end
        end
    end
    -- Sess.95 (ter): tetto di PARALLELISMO -- proporzionale (20%, minimo 4),
    -- richiesta esplicita utente ("non tutti in blocco, ma quattro alla
    -- volta"). Sostituisce il vecchio 'UpgradingBuilding > 0' che serializzava
    -- a un solo upgrade alla volta per l'intera armata -- causa reale dello
    -- stallo osservato: con l'energy storage quasi mai al 95%, il ramo
    -- economico sotto era quasi sempre attivo, e quel gate bloccava la
    -- funzione non appena UNA SOLA unita' era gia' in upgrade. Applicato QUI
    -- (prima del blocco economico, non piu' dentro), cosi' il tetto vale
    -- SEMPRE, anche nel raro caso di economia sana che prima lo bypassava.
    -- Sess.98 (bis): tetto FISSO 5 per il salto T3->T4 (richiesta esplicita
    -- utente), separato dal tetto proporzionale sopra -- con centinaia di
    -- estrattori (es. 337) il 20% supera facilmente le decine in parallelo,
    -- qui vogliamo un numero piccolo e indipendente dalla scala della mappa.
    local maxParallel
    if techLevel == 'TECH3' then
        maxParallel = 5
        if OWPlusLogConditionsMod.OWPlusDebugThrottle(aiBrain, 'ExtractorT3T4MaxParallel', 15) then
            LOG('[OWPlus-DBG] OWPlusExtractorUpgrade(TECH3->TECH4): OK, tetto fisso applicato (inUpgrade=' .. tostring(UpgradingBuilding) .. '/' .. tostring(maxParallel) .. ')')
        end
    else
        maxParallel = math.max(4, math.floor(table.getn(MassExtractorUnitList) * 0.20))
    end
    if UpgradingBuilding >= maxParallel then
        return false
    end
    -- If we have not the Eco then return false. Exept we have none extractor upgrading or 100% mass storrage
    if not MassRatioCheckPositive and aiBrain:GetEconomyStoredRatio('MASS') < 0.80 or aiBrain:GetEconomyStoredRatio('ENERGY') < 0.95 then
        -- Sess.94: soglia fissa "4" -> 20% del totale candidati (minimo 4).
        -- Con molti estrattori il force scatta piu' raramente, invece di
        -- essere sempre soddisfatto (causa del batch percepito in game).
        local forceThreshold = math.max(4, math.floor(table.getn(MassExtractorUnitList) * 0.20))
        if table.getn(MassExtractorUnitList) < forceThreshold then
            return false
        end
        -- Even if we don't have the Eco for it; If we have more then forceThreshold Extractors, then upgrade at least one of them.
        -- Sess.95 (octies): riattivato su richiesta esplicita utente
        LOG('[OWPlus-DBG] OWPlusExtractorUpgrade(' .. tostring(techLevel) .. '): force senza eco sufficiente (candidati=' .. tostring(table.getn(MassExtractorUnitList)) .. ', soglia=' .. tostring(forceThreshold) .. ')')
    end
    -- Have we found a unit that can upgrade ?
    if upgradeID and upgradeBuilding then
        if self.Brain[ScenarioInfo.Options.AIPLatoonNameDebug] or ScenarioInfo.Options.AIPLatoonNameDebug == 'all' then
            upgradeBuilding:SetCustomName('Upgrading BaseDist: '..(LowestDistanceToBase or 'Unknown ???'))
        end
        IssueUpgrade({upgradeBuilding}, upgradeID)
        coroutine.yield(10)
        return true
    end
    return false
end

-- Sess.98 (bis): helper per il generatore energia T3->T4, chiamato dal nuovo
-- metodo 'OWPlusEnergyGeneratorUpgradeAI' sotto -- copia semplificata di
-- 'OWPlusExtractorUpgrade' sopra (stesso schema: candidato piu' vicino a MAIN,
-- FactionCategory, FindUpgradeBP+CanBuild, IssueUpgrade diretto, MAI
-- CanFormPlatoon). Non riusa OWPlusExtractorUpgrade direttamente: quella ha
-- logica specifica massa (MassRatioCheckPositive, pausa estrattori, requisito
-- magazzini adiacenti T2->T3) non pertinente qui -- il gate economico proprio
-- del generatore energia (OWPlusEnergyStorageAbsoluteGate, gia' negoziato con
-- l'utente in sess.98) resta la fonte di verita' unica, richiamato qui invece
-- di duplicarne la logica.
-- Sess.98 (bis): whitelist ID T4 -- il T4 ha ANCORA 'TECH3' tra le sue
-- Categories (nessun TECH4 nativo, stesso schema Jaggeds), quindi
-- 'EnergyGeneratorUnitList' (categories.STRUCTURE*ENERGYPRODUCTION*TECH3)
-- include ANCHE i T4 gia' completati. Senza questo filtro venivano scansionati
-- ad ogni ciclo, generando un warning 'Can't find StructureUpgradeTemplate'
-- inutile (osservato 2781 volte in un test da 35 minuti) -- innocuo per la
-- logica (il warning non porta mai a un IssueUpgrade, verificato nei log: mai
-- un successo con source='ueb1401'), ma rumore puro da eliminare.
local OWPLUS_T4_ENERGY_GEN_IDS_PLATOON = { ueb1401 = true, uab1401 = true, urb1401 = true, xsb1401 = true }

local function OWPlusEnergyGeneratorUpgrade(self, aiBrain, EnergyGeneratorUnitList, StructureUpgradeTemplates)
    local OWPlusLogConditionsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua')
    local UpgradingBuilding = 0
    for k, v in EnergyGeneratorUnitList do
        if v and not v.Dead and not v:BeenDestroyed() and v:IsUnitState('Upgrading') then
            UpgradingBuilding = UpgradingBuilding + 1
        end
    end
    if not OWPlusLogConditionsMod.OWPlusEnergyStorageAbsoluteGate(aiBrain, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3, 40000, 0.80, 'Energy Generator Upgrade T4') then
        return false
    end
    local BasePosition = aiBrain.BuilderManagers['MAIN'].Position
    local factionIndex = aiBrain:GetFactionIndex()
    local FactionToIndex = { UEF = 1, AEON = 2, CYBRAN = 3, SERAPHIM = 4, NOMADS = 5, ARM = 6, CORE = 7 }
    local DistanceToBase, LowestDistanceToBase, upgradeID, upgradeBuilding, UnitPos
    for k, v in EnergyGeneratorUnitList do
        if not v or v.Dead or v:BeenDestroyed() or v:IsPaused() or v:GetFractionComplete() < 1 or v:IsUnitState('Upgrading')
            or OWPLUS_T4_ENERGY_GEN_IDS_PLATOON[string.lower(tostring(v:GetUnitId()))]
        then
            continue
        end
        UnitPos = v:GetPosition()
        DistanceToBase = VDist2(BasePosition[1] or 0, BasePosition[3] or 0, UnitPos[1] or 0, UnitPos[3] or 0)
        if not LowestDistanceToBase or DistanceToBase < LowestDistanceToBase then
            local UnitBeingUpgradeFactionIndex = FactionToIndex[v.Blueprint.FactionCategory] or factionIndex
            local TempID = aiBrain:FindUpgradeBP(v:GetUnitId(), StructureUpgradeTemplates[UnitBeingUpgradeFactionIndex])
            if not TempID then
                AIWarn('[OWPlusEnergyGeneratorUpgrade] ERROR: Can\'t find StructureUpgradeTemplate for structure: ' .. repr(v:GetUnitId()))
            elseif not v:CanBuild(TempID) then
                AIWarn('[OWPlusEnergyGeneratorUpgrade] ERROR: Can\'t upgrade structure with StructureUpgradeTemplate: ' .. repr(v:GetUnitId()))
            else
                upgradeID = TempID
                upgradeBuilding = v
                LowestDistanceToBase = DistanceToBase
            end
        end
    end
    if upgradeID and upgradeBuilding then
        -- Sess.98 (ter): aggiunto EntityId (identificatore univoco dell'ISTANZA,
        -- diverso da GetUnitId che e' il tipo di blueprint) e posizione --
        -- richiesta esplicita utente dopo aver osservato in game un
        -- ri-potenziamento sullo stesso edificio nonostante il log AI risultasse
        -- pulito (nessun doppio tentativo sullo stesso UnitId). Se lo stesso
        -- EntityId compare due volte in questo log, e' la PROVA diretta che e'
        -- la stessa istanza fisica issuata due volte -- se invece EntityId e
        -- posizione sono sempre diversi, il fenomeno osservato non viene dal
        -- nostro IssueUpgrade e va cercato altrove (probabile residuo visivo
        -- lato client dello stesso bug di refresh gia' confermato: nome/UI
        -- rimasti T3 nonostante produzione 8000 = T4 reale).
        local upos = upgradeBuilding:GetPosition()
        LOG('[OWPlus-DBG] OWPlusEnergyGeneratorUpgrade: OK, upgrade issuato su "' .. tostring(upgradeBuilding:GetUnitId())
            .. '" -> "' .. tostring(upgradeID) .. '" (EntityId=' .. tostring(upgradeBuilding:GetEntityId())
            .. ', pos=' .. tostring(math.floor(upos[1])) .. ',' .. tostring(math.floor(upos[3])) .. ')')
        IssueUpgrade({upgradeBuilding}, upgradeID)
        -- Sess.99: rete di sicurezza esplicita -- confermato nel dev.log che il T4
        -- fallisce a caricare il proprio mesh_build (asset mai creato per gli id
        -- custom), lo script nativo OnStartBeingBuilt crasha su di esso, e lo
        -- stesso errore si propaga a OnStopBuild sul VECCHIO edificio T3 --
        -- impedendo la sua distruzione nativa di fine-upgrade (osservato in game
        -- dall'utente coi trucchi di teletrasporto: due entita' fisiche sovrapposte,
        -- il vecchio T3 con mesh che continua a produrre la sua quota). Il pattern
        -- nativo (UnitUpgradeAI sopra, righe 576-585) aspetta 'v.Dead' come segnale
        -- di completamento upgrade -- qui replichiamo lo stesso segnale con un
        -- timeout, e se scade verifichiamo che il T4 sia davvero presente e
        -- completo prima di forzare la distruzione esplicita del vecchio edificio
        -- (idempotente: se il motore lo ha gia' distrutto da solo, upgradeBuilding.
        -- Dead e' gia' true e il thread esce subito senza fare nulla).
        local upgradeTargetPos = upos
        ForkThread(function()
            local waited = 0
            while not upgradeBuilding.Dead and waited < 90 do
                WaitSeconds(3)
                waited = waited + 3
            end
            if not upgradeBuilding.Dead then
                local nearby = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE * categories.ENERGYPRODUCTION, upgradeTargetPos, 5, 'Ally') or {}
                local t4Found = false
                for _, u in nearby do
                    if u and not u.Dead and not u:BeenDestroyed()
                        and OWPLUS_T4_ENERGY_GEN_IDS_PLATOON[string.lower(tostring(u:GetUnitId()))]
                        and u:GetFractionComplete() >= 1 then
                        t4Found = true
                        break
                    end
                end
                if t4Found then
                    LOG('[OWPlus-DBG] OWPlusEnergyGeneratorUpgrade: WARN, vecchio edificio T3 ancora vivo dopo '
                        .. tostring(waited) .. 's dall\'upgrade (bug mesh_build T4) e T4 completo confermato nelle vicinanze -- distruzione esplicita forzata')
                    upgradeBuilding:Destroy()
                else
                    LOG('[OWPlus-DBG] OWPlusEnergyGeneratorUpgrade: WARN, T3 ancora vivo dopo timeout ma nessun T4 completo trovato nelle vicinanze -- distruzione NON forzata (upgrade probabilmente ancora in corso)')
                end
            end
        end)
        coroutine.yield(10)
        return true
    end
    return false
end

-- Sess.100 parte 12 (decisione utente): "tana libera tutti". La marcia in formazione tiene
-- il plotone compatto ma alla velocita' dell'unita' piu' lenta: le unita' veloci perdono il
-- loro vantaggio. Vicino al nemico il plotone viene "rilasciato": da quel momento
-- SetPlatoonFormationOverride forza sempre NoFormation (ognuno alla propria velocita'),
-- anche sulle AttackFormation che Uveso chiede vicino al bersaglio. Effetto dal prossimo
-- ordine di movimento nativo (waypoint successivo / ordini di combattimento): non si
-- rilanciano ordini a mano per non disturbare i controlli "bloccato" del movimento Uveso.
--
-- Sess.100 parte 13 (test multiplayer: "strisce" di unita', rilascio troppo precoce;
-- decisioni utente): il rilascio scattava con UN nemico qualsiasi (anche un estrattore)
-- entro gittata MASSIMA del plotone + 40, cioe' 130-150 con un'artiglieria a bordo, e non
-- tornava mai indietro. Ora:
--   * contano solo nemici ARMATI (mobili o difese fisse con DIRECTFIRE/INDIRECTFIRE; no
--     aerei, muri, esploratori, strutture economiche/radar);
--   * servono almeno OWPLUS_RELEASE_MIN_ARMED_ENEMIES nemici armati, oppure 1 minaccia
--     pesante (difesa fissa, sperimentale, comandante/sottocomandante);
--   * raggio = gittata MINIMA del plotone (per unita' la sua arma principale di superficie,
--     poi il minimo tra le unita', come MaxPlatoonWeaponRange di Uveso) + OWPLUS_RELEASE_MARGIN,
--     ricalcolato a ogni controllo (merge, perdite);
--   * RIFORMAZIONE: dopo OWPLUS_REFORM_CALM_SECONDS senza nemici armati nel raggio il
--     plotone torna in AttackFormation dal prossimo spostamento (niente strisce nei
--     trasferimenti tra un bersaglio e l'altro), e puo' essere rilasciato di nuovo.
local OWPLUS_RELEASE_MARGIN = 30
local OWPLUS_RELEASE_CHECK_SECONDS = 1
local OWPLUS_RELEASE_MIN_ARMED_ENEMIES = 3
local OWPLUS_REFORM_CALM_SECONDS = 15
local OWPLUS_RELEASE_ARMED_CATEGORY = (categories.MOBILE + categories.STRUCTURE * categories.DEFENSE)
    * (categories.DIRECTFIRE + categories.INDIRECTFIRE) - categories.AIR - categories.WALL - categories.SCOUT
local OWPLUS_RELEASE_HEAVY_CATEGORY = OWPLUS_RELEASE_ARMED_CATEGORY
    * (categories.STRUCTURE + categories.EXPERIMENTAL + categories.COMMAND + categories.SUBCOMMANDER)
-- armi che non definiscono la gittata d'ingaggio a terra
local OWPLUS_RELEASE_IGNORED_WEAPON_CATEGORIES = { ['Anti Air'] = true, ['Death'] = true, ['Defense'] = true, ['Teleport'] = true }

local function OWPlusPlatoonReleaseRange(platoon)
    local minRange
    for _, unit in platoon:GetPlatoonUnits() do
        if not unit.Dead then
            local unitRange = 0
            for _, weapon in unit:GetBlueprint().Weapon or {} do
                if (weapon.Damage or 0) >= 1 and (weapon.MaxRadius or 0) >= 1
                    and not OWPLUS_RELEASE_IGNORED_WEAPON_CATEGORIES[weapon.WeaponCategory or ''] then
                    if weapon.MaxRadius > unitRange then
                        unitRange = weapon.MaxRadius
                    end
                end
            end
            if unitRange > 0 and (not minRange or unitRange < minRange) then
                minRange = unitRange
            end
        end
    end
    return minRange or 30
end

local function OWPlusFormationLabel(platoon)
    return '#' .. tostring(platoon.OWPlusSerial or '?') .. ' "' .. tostring(platoon.BuilderName) .. '"'
end

local function OWPlusFormationReleaseWatcher(platoon)
    local aiBrain = platoon:GetBrain()
    local calm = 0
    LOG('[OWPlus-FORMATION] OK: watcher rilascio/riformazione avviato per ' .. OWPlusFormationLabel(platoon)
        .. ' (raggio iniziale=' .. string.format('%.0f', OWPlusPlatoonReleaseRange(platoon) + OWPLUS_RELEASE_MARGIN) .. ')')
    while aiBrain:PlatoonExists(platoon) do
        WaitSeconds(OWPLUS_RELEASE_CHECK_SECONDS)
        if not aiBrain:PlatoonExists(platoon) then
            return
        end
        local pos = platoon:GetPlatoonPosition()
        if pos then
            local radius = OWPlusPlatoonReleaseRange(platoon) + OWPLUS_RELEASE_MARGIN
            local armed = aiBrain:GetNumUnitsAroundPoint(OWPLUS_RELEASE_ARMED_CATEGORY, pos, radius, 'Enemy')
            if not platoon.OWPlusFormationReleased then
                local heavy = 0
                if armed > 0 then
                    heavy = aiBrain:GetNumUnitsAroundPoint(OWPLUS_RELEASE_HEAVY_CATEGORY, pos, radius, 'Enemy')
                end
                if armed >= OWPLUS_RELEASE_MIN_ARMED_ENEMIES or heavy > 0 then
                    platoon.OWPlusFormationReleased = true
                    calm = 0
                    CopyOfOldPlatoonClassOWPlusChild.SetPlatoonFormationOverride(platoon, 'NoFormation')
                    LOG('[OWPlus-FORMATION] OK: plotone ' .. OWPlusFormationLabel(platoon) .. ' ('
                        .. tostring(table.getn(platoon:GetPlatoonUnits())) .. ' unita\') RILASCIATO (tana libera tutti): '
                        .. tostring(armed) .. ' nemici armati (pesanti=' .. tostring(heavy) .. ') entro ' .. string.format('%.0f', radius)
                        .. ' (t=' .. string.format('%.0f', GetGameTimeSeconds()) .. ')')
                end
            else
                if armed > 0 then
                    calm = 0
                else
                    calm = calm + OWPLUS_RELEASE_CHECK_SECONDS
                end
                if calm >= OWPLUS_REFORM_CALM_SECONDS then
                    platoon.OWPlusFormationReleased = false
                    calm = 0
                    CopyOfOldPlatoonClassOWPlusChild.SetPlatoonFormationOverride(platoon, 'AttackFormation')
                    LOG('[OWPlus-FORMATION] OK: plotone ' .. OWPlusFormationLabel(platoon) .. ' ('
                        .. tostring(table.getn(platoon:GetPlatoonUnits())) .. ' unita\') RIFORMATO: nessun nemico armato entro '
                        .. string.format('%.0f', radius) .. ' da ' .. OWPLUS_REFORM_CALM_SECONDS .. 's (t=' .. string.format('%.0f', GetGameTimeSeconds()) .. ')')
                end
            end
        end
    end
end

-- DIAGNOSTICA TEMPORANEA (sess.100 parte 13, da togliere a indagine chiusa): nel test
-- multiplayer i plotoni batch si formavano con 48-50 unita' ma partivano in marcia con
-- 6-13 NELLO STESSO SECONDO. Esclusi: watcher avamposti, droni/pod, la diagnostica di
-- formazione. Qui: numero progressivo per plotone (deterministico, per brain), unita'
-- all'avvio del piano e ogni variazione nei primi OWPLUS_DIAG_TRACE_SECONDS secondi.
-- Il merge Uveso e' tracciato in hook/lua/AI/aiutilities.lua.
local OWPLUS_DIAG_TRACE_SECONDS = 15

local function OWPlusPlatoonSizeTrace(platoon)
    local aiBrain = platoon:GetBrain()
    local last = table.getn(platoon:GetPlatoonUnits())
    for second = 1, OWPLUS_DIAG_TRACE_SECONDS do
        WaitSeconds(1)
        if not aiBrain:PlatoonExists(platoon) then
            LOG('[OWPlus-DIAG-PLATOON] ' .. OWPlusFormationLabel(platoon) .. ' SCIOLTO dopo ' .. second .. 's (ultime unita\'=' .. last .. ')')
            return
        end
        local now = table.getn(platoon:GetPlatoonUnits())
        if now ~= last then
            LOG('[OWPlus-DIAG-PLATOON] ' .. OWPlusFormationLabel(platoon) .. ' unita\' ' .. last .. ' -> ' .. now .. ' dopo ' .. second .. 's')
            last = now
        end
    end
end

CopyOfOldPlatoonClassOWPlusChild = Platoon
Platoon = Class(CopyOfOldPlatoonClassOWPlusChild) {

    -- Sess.100 parte 12 (opzione A approvata dall'utente): marcia in formazione.
    -- Le 4 funzioni di marcia native Uveso (MoveToLocationInclTransport, MovePath,
    -- MoveDirect, MoveWithTransportNoPath in AI-Uveso/hook/lua/platoon.lua) chiamano
    -- SetPlatoonFormationOverride('NoFormation') all'inizio: ogni unita' corre alla
    -- propria velocita' massima e il plotone misto si allunga "a striscia"; la
    -- AttackFormation torna solo a <80 dalla fine del percorso. Per i plotoni con
    -- PlatoonData.OWPlusFormationMarch (solo i batch terra di MAIN, OWPlus Formers.lua)
    -- sostituiamo NoFormation con AttackFormation: in formazione il gruppo si muove
    -- alla velocita' dell'unita' piu' lenta. Metodo del motore (moho.platoon_methods,
    -- non definito in Lua): l'originale si raggiunge dalla classe genitore.
    -- DIAGNOSTICA TEMPORANEA (vedi OWPlusPlatoonSizeTrace sopra la classe): solo per i
    -- plotoni con marcia in formazione; nessun cambiamento di comportamento.
    HeroFightPlatoon = function(self, self2)
        if self.PlatoonData and self.PlatoonData.OWPlusFormationMarch and not self.OWPlusSerial then
            local aiBrain = self:GetBrain()
            aiBrain.OWPlusPlatoonSerial = (aiBrain.OWPlusPlatoonSerial or 0) + 1
            self.OWPlusSerial = aiBrain.OWPlusPlatoonSerial
            local units, droppable = 0, 0
            for _, u in self:GetPlatoonUnits() do
                if not u.Dead then
                    units = units + 1
                    local hash = u.Blueprint and u.Blueprint.CategoriesHash
                    if hash and (hash.INSIGNIFICANTUNIT or hash.POD or hash.DRONE or hash.OPERATION) then
                        droppable = droppable + 1
                    end
                end
            end
            LOG('[OWPlus-DIAG-PLATOON] [' .. tostring(aiBrain.Nickname) .. '] ' .. OWPlusFormationLabel(self) .. ' avvio piano: unita\'=' .. units
                .. ' (scartabili da Uveso=' .. droppable .. ') t=' .. string.format('%.0f', GetGameTimeSeconds()))
            self:ForkThread(OWPlusPlatoonSizeTrace)
        end
        return CopyOfOldPlatoonClassOWPlusChild.HeroFightPlatoon(self, self2)
    end,

    -- Rilascio "tana libera tutti" e riformazione: vedi OWPlusFormationReleaseWatcher sopra la classe.
    SetPlatoonFormationOverride = function(self, formation)
        if self.PlatoonData and self.PlatoonData.OWPlusFormationMarch
            and self.MovementLayer ~= 'Air' and self.MovementLayer ~= 'Water' then
            if self.OWPlusFormationReleased then
                formation = 'NoFormation'
            elseif formation == 'NoFormation' then
                if not self.OWPlusFormationMarchLogged then
                    self.OWPlusFormationMarchLogged = true
                    LOG('[OWPlus-FORMATION] OK: plotone ' .. OWPlusFormationLabel(self) .. ' ('
                        .. tostring(table.getn(self:GetPlatoonUnits())) .. ' unita\') marcia in AttackFormation invece di NoFormation (t='
                        .. string.format('%.0f', GetGameTimeSeconds()) .. ')')
                end
                if not self.OWPlusReleaseWatcherStarted then
                    self.OWPlusReleaseWatcherStarted = true
                    self:ForkThread(OWPlusFormationReleaseWatcher)
                end
                formation = 'AttackFormation'
            end
        end
        return CopyOfOldPlatoonClassOWPlusChild.SetPlatoonFormationOverride(self, formation)
    end,

    -- Sess.98 (richiesta esplicita utente, indagine dedicata): subclass di
    -- 'UnitUpgradeAI' NATIVO (motore, /lua/platoon.lua) -- copia fedele,
    -- unica differenza un rilascio esplicito dello slot InstanceCount prima
    -- del controllo 'aiBrain:PlatoonExists(self)'.
    --
    -- BUG NATIVO TROVATO: 'RemoveHandle' (che libera lo slot InstanceCount
    -- del Builder, vedi Builder.lua StoreHandle/RemoveHandle) viene chiamato
    -- SOLO da dentro 'PlatoonDisband()'. Ma il codice nativo, dopo il loop
    -- d'attesa fine-upgrade, fa `if not aiBrain:PlatoonExists(self) then
    -- return end` PRIMA di chiamare PlatoonDisband() -- se la mini-platoon
    -- "carrier" (1 sola unita', quella che sta per essere sostituita
    -- dall'upgrade) risulta gia' non-esistente per aiBrain a quel punto
    -- (l'unita' sorgente viene distrutta+ricreata dall'upgrade, stessa
    -- meccanica di regola 20b/memoria progetto), il ramo salta interamente
    -- PlatoonDisband() -- e quindi RemoveHandle() non viene MAI chiamato,
    -- lo slot InstanceCount resta 'ActivePlatoon' per il resto della
    -- partita. Confermato in game (sess.98, generatore energia T4,
    -- InstanceCount=1): primo upgrade riuscito, poi CheckInstanceCount()
    -- risultato permanentemente false per ~13 minuti successivi nonostante
    -- gate sempre vero e candidati disponibili (hook diagnostico dedicato su
    -- PlatoonFormManager.lua). Il fix e' un rilascio esplicito e
    -- IDEMPOTENTE (PlatoonDisband, se poi eseguito comunque, ritrova
    -- BuilderHandle=nil e non fa nulla di male chiamando RemoveHandle su un
    -- builder gia' liberato -- RemoveHandle si limita a riscrivere lo stesso
    -- stato 'Available').
    --
    -- Impatto: essendo un subclass della classe Platoon GLOBALE (stesso
    -- pattern di ExtractorUpgradeAI sotto), il fix si applica a QUALUNQUE
    -- builder che usi Plan='UnitUpgradeAI' in tutto il gioco (inclusi quelli
    -- gia' esistenti con InstanceCount basso, es. Energy/Mass Storage
    -- Upgrade T2/T3) -- corretto per scope, non e' un bug specifico del
    -- nuovo builder generatori, e' strutturale al meccanismo nativo stesso.
    UnitUpgradeAI = function(self)
        local aiBrain = self:GetBrain()
        local platoonUnits = self:GetPlatoonUnits()
        local factionIndex = aiBrain:GetFactionIndex()
        local FactionToIndex  = { UEF = 1, AEON = 2, CYBRAN = 3, SERAPHIM = 4, NOMADS = 5}
        local UnitBeingUpgradeFactionIndex = nil
        local upgradeIssued = false
        self:Stop()
        for k, v in platoonUnits do
            local upgradeID
            UnitBeingUpgradeFactionIndex = FactionToIndex[v.Blueprint.FactionCategory] or factionIndex
            if self.PlatoonData.OverideUpgradeBlueprint then
                local tempUpgradeID = self.PlatoonData.OverideUpgradeBlueprint[UnitBeingUpgradeFactionIndex]
                if not tempUpgradeID then
                    -- OverideUpgradeBlueprint vuoto per questa fazione: nessun log (comportamento nativo, silenzioso)
                elseif type(tempUpgradeID) ~= 'string' then
                    WARN('[OWPlus-child UnitUpgradeAI] OverideUpgradeBlueprint ' .. tostring(v.UnitId) .. ' failed. (Override unit not present.)')
                elseif v:CanBuild(tempUpgradeID) then
                    upgradeID = tempUpgradeID
                else
                    WARN('[OWPlus-child UnitUpgradeAI] OverideUpgradeBlueprint ' .. tostring(v.UnitId) .. ':CanBuild( ' .. tempUpgradeID .. ' ) failed. (Override tree not available, upgrading to default instead.)')
                end
            end
            if not upgradeID and EntityCategoryContains(categories.MOBILE, v) then
                upgradeID = aiBrain:FindUpgradeBP(v.UnitId, UpgradeTemplatesMod.UnitUpgradeTemplates[UnitBeingUpgradeFactionIndex])
                if not upgradeID then
                    WARN('[OWPlus-child UnitUpgradeAI] Can\'t find UnitUpgradeTemplate for mobile unit: ' .. tostring(v.UnitId))
                end
            elseif not upgradeID then
                upgradeID = aiBrain:FindUpgradeBP(v.UnitId, UpgradeTemplatesMod.StructureUpgradeTemplates[UnitBeingUpgradeFactionIndex])
                if not upgradeID then
                    WARN('[OWPlus-child UnitUpgradeAI] Can\'t find StructureUpgradeTemplate for structure: ' .. tostring(v.UnitId) .. '  faction: ' .. tostring(v.Blueprint.FactionCategory))
                end
            end
            if upgradeID and EntityCategoryContains(categories.STRUCTURE, v) and not v:CanBuild(upgradeID) then
                WARN('[OWPlus-child UnitUpgradeAI] ' .. tostring(v.UnitId) .. ':CanBuild( ' .. upgradeID .. ' ) failed!')
                continue
            end
            if upgradeID then
                upgradeIssued = true
                IssueUpgrade({v}, upgradeID)
            end
        end
        if not upgradeIssued then
            self:PlatoonDisband()
            return
        end
        local upgrading = true
        while aiBrain:PlatoonExists(self) and upgrading do
            WaitSeconds(3)
            upgrading = false
            for k, v in platoonUnits do
                if v and not v.Dead then
                    upgrading = true
                end
            end
        end
        -- FIX (vedi commento sopra): rilascio esplicito PRIMA del controllo
        -- PlatoonExists, che nel nativo puo' saltare interamente
        -- PlatoonDisband()/RemoveHandle() lasciando lo slot occupato per sempre.
        if self.BuilderHandle then
            LOG('[OWPlus-DBG] UnitUpgradeAI: OK, rilascio esplicito InstanceCount slot (fix leak nativo) per builder "' .. tostring(self.BuilderName) .. '"')
            self.BuilderHandle:RemoveHandle(self)
            self.BuilderHandle = nil
        end
        if not aiBrain:PlatoonExists(self) then
            return
        end
        WaitTicks(1)
        self:PlatoonDisband()
    end,

    -- Sess.98 (bis): metodo AIPlan custom per il generatore energia T3->T4,
    -- assegnato via BuilderData.AIPlan al plotone persistente formato da
    -- 'AddToEnergyGeneratorUpgradePlatoon' (Plan='PlatoonMerger'). Loop
    -- semplificato rispetto a 'ExtractorUpgradeAI' sotto (nessuna pausa
    -- estrattori, nessun ratio massa -- non pertinenti qui): rilegge la lista
    -- LIVE dei generatori T3 ad ogni ciclo (non self:GetPlatoonUnits(), che
    -- include anche generatori gia' aggiornati a T4 rimasti storicamente nel
    -- plotone merger) e delega il gate/selezione a 'OWPlusEnergyGeneratorUpgrade'.
    OWPlusEnergyGeneratorUpgradeAI = function(self)
        local aiBrain = self:GetBrain()
        LOG('[OWPlus-DBG] OWPlusEnergyGeneratorUpgradeAI: OK, thread avviato (bypass CanFormPlatoon via PlatoonMerger, stesso pattern estrattori)')
        while aiBrain:PlatoonExists(self) do
            while not aiBrain:IsOpponentAIRunning() do
                coroutine.yield(10)
            end
            local EnergyGeneratorUnitList = aiBrain:GetListOfUnits(categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3, false, false)
            OWPlusEnergyGeneratorUpgrade(self, aiBrain, EnergyGeneratorUnitList, UpgradeTemplatesMod.StructureUpgradeTemplates)
            coroutine.yield(10)
            for k, v in self:GetPlatoonUnits() do
                if not v or v.Dead or v:BeenDestroyed() then
                    coroutine.yield(1)
                    self:PlatoonDisbandNoAssign()
                    return
                end
            end
        end
    end,

    -- Sess.94: subclass di 'ExtractorUpgradeAI' (AI-Uveso, hook/lua/platoon.lua
    -- righe 1073-1156) -- copia fedele del loop coroutine nativo, unica
    -- differenza le chiamate a 'UUtils.ExtractorUpgrade' sostituite con
    -- 'OWPlusExtractorUpgrade' (sopra, soglia force proporzionale invece che
    -- fissa). 'UUtils.ExtractorPause'/'UUtils.HaveUnitRatio' restano invariate
    -- (non toccate, nessun motivo di modificarle).
    ExtractorUpgradeAI = function(self)
        local aiBrain = self:GetBrain()
        -- Sess.95: import una tantum (thread di lunga durata, un solo import per
        -- plotone invece che uno per tick) -- stesso path gia' usato altrove nel
        -- file per lo stesso modulo.
        local OWPlusLogConditionsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua')
        -- Sess.95 (octies): riattivato su richiesta esplicita utente
        LOG('[OWPlus-DBG] ExtractorUpgradeAI (override sess.95 ter): OK, thread avviato, trigger a percentuale + parallelismo proporzionale attivi')
        -- Sess.95 (septies): richiesta esplicita utente (test da remoto, non puo'
        -- osservare visivamente) -- nuovo log periodico indipendente, ogni 15s,
        -- massa/energia stoccata ATTUALE + capacita' MASSIMA (non un ratio o un
        -- conteggio unita' come tutti gli altri log commentati sopra, un valore
        -- assoluto diretto leggibile a colpo d'occhio). Guardia one-time su
        -- aiBrain (questo metodo puo' essere invocato piu' volte se il plotone
        -- nativo viene riformato) -- stesso pattern flag-su-aiBrain gia' in uso
        -- altrove nel progetto per azioni "una volta sola per partita".
        if not aiBrain.OWPlusEconStorageLoggerStarted then
            aiBrain.OWPlusEconStorageLoggerStarted = true
            ForkThread(function()
                while not aiBrain:IsDefeated() do
                    local massStored = aiBrain:GetEconomyStored('MASS')
                    local energyStored = aiBrain:GetEconomyStored('ENERGY')
                    local massRatio = aiBrain:GetEconomyStoredRatio('MASS')
                    local energyRatio = aiBrain:GetEconomyStoredRatio('ENERGY')
                    local massMax = massRatio > 0 and (massStored / massRatio) or massStored
                    local energyMax = energyRatio > 0 and (energyStored / energyRatio) or energyStored
                    LOG('[OWPlus-ECON] ' .. tostring(aiBrain.Name) .. ' -- Magazzino massa: ' .. tostring(massStored)
                        .. ' / max ' .. tostring(massMax) .. ' -- Magazzino energia: ' .. tostring(energyStored)
                        .. ' / max ' .. tostring(energyMax) .. ' (t=' .. tostring(GetGameTimeSeconds()) .. 's)')
                    WaitSeconds(15)
                end
            end)
        end
        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        local ratio = 0.0
        local RatioTable = {0.0, 0.10, 0.10, 0.15, 0.20, 0.25, 0.30, 0.40, 0.50, 1.0}
        if personality == 'uvesorush' then
            RatioTable = {0.00, 0.05, 0.10, 0.15, 0.20, 0.30, 0.40, 0.50, 0.50, 0.75}
        end
        local platoonUnits
        local MassExtractorUnitList
        -- Sess.98: helper per il ramo T1->T2/T2->T3 (invariato, gia' esistente sopra
        -- come corpo if/else inline) -- estratto in funzione per essere richiamabile
        -- anche come fallback dal nuovo ramo T2->T3->T4 sotto, senza duplicare il
        -- blocco. Chiusura su 'self'/'aiBrain'/'MassExtractorUnitList'/'ratio' (tutte
        -- gia' 'local' nello scope esterno, riassegnate ma mai ridichiarate dentro il
        -- while: sicuro leggerle da qui, stessa cella di memoria ad ogni ciclo).
        local function OWPlusTryExtractorUpgradeT1T2()
            if OWPlusLogConditionsMod.OWPlusPopulationShareAtLeast(aiBrain, 0.80,
                categories.MASSEXTRACTION * categories.TECH2,
                categories.MASSEXTRACTION * (categories.TECH1 + categories.TECH2),
                'Extractor T1->T2 trigger') then
                if not OWPlusExtractorUpgrade(self, aiBrain, MassExtractorUnitList, ratio, 'TECH2', UpgradeTemplatesMod.UnitUpgradeTemplates, UpgradeTemplatesMod.StructureUpgradeTemplates) then
                    OWPlusExtractorUpgrade(self, aiBrain, MassExtractorUnitList, ratio, 'TECH1', UpgradeTemplatesMod.UnitUpgradeTemplates, UpgradeTemplatesMod.StructureUpgradeTemplates)
                end
            else
                OWPlusExtractorUpgrade(self, aiBrain, MassExtractorUnitList, ratio, 'TECH1', UpgradeTemplatesMod.UnitUpgradeTemplates, UpgradeTemplatesMod.StructureUpgradeTemplates)
            end
        end
        while aiBrain:PlatoonExists(self) do
            while not aiBrain:IsOpponentAIRunning() do
                coroutine.yield(10)
            end
            if aiBrain.PriorityManager.HasParagon then
                ratio = RatioTable[10]
            elseif aiBrain:GetEconomyIncome('MASS') * 10 > 1000 then
                ratio = RatioTable[10]
            elseif aiBrain:GetEconomyIncome('MASS') * 10 > 600 then
                ratio = RatioTable[9]
            elseif GetGameTimeSeconds() > 1800 then
                ratio = RatioTable[8]
            elseif GetGameTimeSeconds() > 1500 then
                ratio = RatioTable[7]
            elseif GetGameTimeSeconds() > 1200 then
                ratio = RatioTable[6]
            elseif GetGameTimeSeconds() > 900 then
                ratio = RatioTable[5]
            elseif GetGameTimeSeconds() > 600 then
                ratio = RatioTable[4]
            elseif GetGameTimeSeconds() > 360 then
                ratio = RatioTable[3]
            elseif GetGameTimeSeconds() > 180 then
                ratio = RatioTable[2]
            elseif GetGameTimeSeconds() <= 180 then
                ratio = RatioTable[1]
            end
            platoonUnits = self:GetPlatoonUnits()
            MassExtractorUnitList = aiBrain:GetListOfUnits(categories.MASSEXTRACTION * (categories.TECH1 + categories.TECH2 + categories.TECH3), false, false)
            -- Check if we can pause/unpause TECH3 Extractors (for more energy)
            if not UUtils.ExtractorPause( self, aiBrain, MassExtractorUnitList, ratio, 'TECH3') then
                -- Check if we can pause/unpause TECH2 Extractors
                if not UUtils.ExtractorPause( self, aiBrain, MassExtractorUnitList, ratio, 'TECH2') then
                    -- Check if we can pause/unpause TECH1 Extractors
                    if not UUtils.ExtractorPause( self, aiBrain, MassExtractorUnitList, ratio, 'TECH1') then
                        -- We have nothing to pause or unpause, lets upgrade more extractors
                        -- Sess.95 (ter): redesign completo, richiesta esplicita utente dopo un
                        -- secondo test in game -- il gate di fase legato ai magazzini (sess.95)
                        -- e' stato rimosso: con estrattori sparsi per la mappa l'80% di copertura
                        -- magazzini non era mai raggiungibile per davvero. Il trigger torna ad
                        -- essere basato SOLO sulla popolazione estrattori (nessuna dipendenza dai
                        -- magazzini) -- OWPlusPopulationShareAtLeast calcola la percentuale
                        -- LETTERALE richiesta (80% del pool T1+T2 e' gia' T2), a differenza di
                        -- 'UUtils.HaveUnitRatio' nativo che calcola T1/T2<=ratio (con ratio=0.80
                        -- il vero punto di scatto e' ~55.6% del totale, non 80% come suggerisce il
                        -- commento originale -- discrepanza scoperta in questa sessione). Il
                        -- requisito magazzini per il salto T2->T3 e' ora dentro
                        -- OWPlusExtractorUpgrade stesso (soft, per singolo candidato).
                        -- Sess.98 (richiesta esplicita utente): NUOVO ramo TECH3->TECH4
                        -- (mod Jaggeds, ueb1302->ueb1402 & co.) -- prima causa reale
                        -- trovata leggendo il motore: questa funzione (ExtractorUpgradeAI,
                        -- override di quella nativa) e il suo helper OWPlusExtractorUpgrade
                        -- operano su MassExtractorUnitList, una lista GLOBALE
                        -- (aiBrain:GetListOfUnits, riga sopra) e issuano l'upgrade
                        -- direttamente via IssueUpgrade() -- MAI passando da
                        -- CanFormPlatoon/FormPlatoon (motore nativo/compilato). Il builder
                        -- separato 'OWPlus Extractor Upgrade T4' (Plan='UnitUpgradeAI',
                        -- rimosso in questa stessa sessione) falliva SEMPRE
                        -- CanFormPlatoon=false (confermato via hook diagnostico su
                        -- PlatoonFormManager, radius=10000, 16 minuti di test reale, zero
                        -- eccezioni) proprio perche' tentava di formare un plotone nuovo
                        -- per ogni candidato invece di riusare questo meccanismo esistente,
                        -- gia' comprovato funzionante per T1->T2 e T2->T3 sullo stesso tipo
                        -- di unita'. Stesso pattern di trigger (population share 80%) del
                        -- ramo T1->T2 sotto, per coerenza.
                        -- Sess.99: 0.15->0.40 (richiesta esplicita utente) -- deadlock
                        -- economico osservato in game: gli estrattori T4 consumano
                        -- cosi' tanta energia che gli ingegneri non riescono piu' ad
                        -- avanzare a T3, l'AI resta bloccata a costruire solo generatori
                        -- T2. Soglia piu' alta ritarda il trigger T3->T4, dando piu'
                        -- margine all'economia energetica prima che il salto scatti.
                        if OWPlusLogConditionsMod.OWPlusPopulationShareAtLeast(aiBrain, 0.40,
                            categories.MASSEXTRACTION * categories.TECH3,
                            categories.MASSEXTRACTION * (categories.TECH2 + categories.TECH3),
                            'Extractor T2->T3 trigger') then
                            -- Try to upgrade a TECH3 extractor to TECH4 first.
                            if OWPlusLogConditionsMod.OWPlusDebugThrottle(aiBrain, 'ExtractorT3T4Attempt', 15) then
                                LOG('[OWPlus-DBG] ExtractorUpgradeAI: OK, ramo TECH3->TECH4 attivo (trigger population 80% superato), tento upgrade su un candidato T3')
                            end
                            if not OWPlusExtractorUpgrade(self, aiBrain, MassExtractorUnitList, ratio, 'TECH3', UpgradeTemplatesMod.UnitUpgradeTemplates, UpgradeTemplatesMod.StructureUpgradeTemplates) then
                                -- Nessun TECH3 idoneo in questo ciclo: prova T1->T2/T2->T3 come prima.
                                OWPlusTryExtractorUpgradeT1T2()
                            end
                        else
                            -- Meno dell'80% degli estrattori T2+T3 e' gia' T3: comportamento invariato.
                            OWPlusTryExtractorUpgradeT1T2()
                        end
                    end
                end
            end
            -- Check the Eco every x Ticks
            coroutine.yield(10)
            -- find dead units inside the platoon and disband if we find one
            for k,v in self:GetPlatoonUnits() do
                if not v or v.Dead or v:BeenDestroyed() then
                    coroutine.yield(1)
                    self:PlatoonDisbandNoAssign()
                    return
                end
            end
        end
        -- No return here. We will never reach this position. After disbanding this platoon, the forked 'ExtractorUpgradeAI' thread will be terminated from outside.
    end,


    OWPlusDispersedBuildAI = function(self)
        local aiBrain = self:GetBrain()
        local cons = self.PlatoonData and self.PlatoonData.Construction
        if not cons or not cons.BuildStructures then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end

        -- Trova le coordinate della sub-location target (es. 'BASE_NE')
        local targetLocType = cons.LocationType
        local targetPos
        local buildList = cons.BuildStructures
        local buildRefs

        -- Fase 9-F18: 'OWPlusOutpostPool' e' un sentinel — non e' una location
        -- fissa, ma dice "scegli dinamicamente un avamposto (OUT#) generato da
        -- OWPlusOutpostGenerator.lua non ancora rivendicato". La ricetta di quello
        -- slot (fabbriche scelte a caso) viene anteposta alle difese gia' in
        -- cons.BuildStructures.
        if targetLocType == 'OWPlusOutpostPool' then
            aiBrain.OWPlusOutpostClaimed = aiBrain.OWPlusOutpostClaimed or {}
            local chosenKey
            if aiBrain.OWPlusSubBases then
                for slotKey, _ in aiBrain.OWPlusSubBases do
                    if string.sub(slotKey, 1, 3) == 'OUT' and not aiBrain.OWPlusOutpostClaimed[slotKey] then
                        chosenKey = slotKey
                        break
                    end
                end
            end
            if not chosenKey then
                WaitTicks(1)
                self:PlatoonDisband()
                return
            end
            aiBrain.OWPlusOutpostClaimed[chosenKey] = true
            targetLocType = chosenKey
            targetPos = aiBrain.OWPlusSubBases[chosenKey]
            local recipe = aiBrain.OWPlusOutpostRecipes and aiBrain.OWPlusOutpostRecipes[chosenKey] or {}
            buildList = {}
            buildRefs = {}
            for _, t in recipe do
                table.insert(buildList, t)
                table.insert(buildRefs, targetPos)
            end
            -- Fix sess.76 (richiesta utente): le difese NON vengono piu' aggiunte
            -- alla ricetta iniziale. Osservato in game: con fabbriche+difese nello
            -- stesso buildList, l'ingegnere restava esposto al meccanismo nativo
            -- di riassegnazione (EngineerManager:TaskFinished, vedi hook dedicato)
            -- per tutta la durata della lista lunga (12-18 strutture) — piu' tempo
            -- passa prima che la prima fabbrica sia adottata in un BuilderManager
            -- reale, piu' a lungo l'ingegnere resta vulnerabile. Ora il buildList
            -- contiene SOLO le fabbriche: l'avamposto va "online" (fabbrica
            -- adottata, builder dedicati agganciati) il piu' velocemente
            -- possibile. Le difese vengono costruite DOPO, da un thread dedicato
            -- avviato solo quando l'avamposto e' gia' online (vedi piu' sotto,
            -- vicino al log "agganciati builder dedicati") — la ricetta difese
            -- resta comunque disponibile in aiBrain.OWPlusOutpostDefenseRecipes,
            -- semplicemente non consumata qui.
            LOG('[OWPlus] Outpost: rivendicato ' .. chosenKey .. ', ' .. table.getn(buildList) .. ' fabbriche da costruire (difese rimandate a dopo)')
        elseif targetLocType then
            -- Legge da OWPlusSubBases (tabella custom sul brain, immune a DeadBaseMonitor).
            -- BuilderManagers NON viene usato: i manager vuoti vengono rimossi dopo 5s.
            targetPos = aiBrain.OWPlusSubBases and aiBrain.OWPlusSubBases[targetLocType]
        end

        if not targetPos then
            LOG('[OWPlus-WARN] OWPlusDispersedBuildAI: sub-base ' .. tostring(targetLocType) .. ' non trovata in OWPlusSubBases')
            self:EngineerBuildAI()
            return
        end

        if not buildRefs then
            buildRefs = {}
            for _ in buildList do table.insert(buildRefs, targetPos) end
        end

        -- Trova l'ingegnere
        local eng
        for _, v in self:GetPlatoonUnits() do
            if not v.Dead and EntityCategoryContains(categories.ENGINEER, v) then
                IssueClearCommands({v})
                if not eng then
                    eng = v
                else
                    IssueGuard({v}, eng)
                end
            end
        end

        if not eng or eng.Dead then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end

        -- Fase 9-F34: guardia difensiva contro il doppio-assegnamento dello
        -- stesso ingegnere a due rivendicazioni avamposto in parallelo (bug
        -- osservato in sess.67: un ingegnere che stava gia' costruendo un
        -- avamposto ad est e' stato caricato da un trasporto e portato a
        -- costruirne un altro a nord-ovest). 'OWPlus Outpost Factory Claim' ha
        -- InstanceCount=6, quindi fino a 6 rivendicazioni possono partire in
        -- parallelo — se il framework di selezione ingegneri (fuori dal nostro
        -- controllo) assegna per errore/race lo stesso ingegnere a due platoon
        -- OWPlusDispersedBuildAI, questo flag lo rileva e la SECONDA
        -- rivendicazione si ritira subito senza toccare l'ingegnere, lasciando
        -- la prima (gia' in corso) indisturbata. Il flag viene ripulito a ogni
        -- uscita della funzione (abbandono, fallimento terreno, completamento).
        if eng.OWPlusOutpostBusy then
            LOG('[OWPlus-WARN] OWPlusDispersedBuildAI: ingegnere gia\' impegnato su un altro avamposto, abbandono rivendicazione di ' .. tostring(targetLocType))
            self:PlatoonDisband()
            return
        end
        eng.OWPlusOutpostBusy = true

        -- Fase 9-F30: per gli avamposti OUT# (non per i nodi BASE_ di MAIN, gia'
        -- vicini e raramente in timeout), spostiamo l'ingegnere con la nostra
        -- logistica trasporto scritta a mano (OWPlusTransportUtils.lua) invece
        -- di affidarci a AIAttackUtils.SendPlatoonWithTransportsNoCheck.
        -- Motivazione: sess.66, quella funzione di motore rifiutava sempre di
        -- usare un trasporto — CONFERMATO con un log diagnostico che trasporti
        -- completamente liberi esistevano vicino a MAIN nel momento esatto del
        -- tentativo (nessuno stato attivo), eppure la funzione restituiva
        -- comunque "nessun trasporto disponibile", senza errori/crash e senza
        -- un motivo verificabile dal codice sorgente (compilato nel motore).
        -- Prima di questo (9-F24-27) avevamo gia' scoperto e corretto due bug
        -- nostri nella chiamata (target=nil, GetMostRestrictiveLayer mancante)
        -- che spiegavano i primi fallimenti — ma anche dopo quei fix, con
        -- trasporti confermati liberi, la funzione continuava a rifiutarsi.
        if targetLocType and string.sub(targetLocType, 1, 3) == 'OUT' then
            local mainPos = aiBrain.BuilderManagers and aiBrain.BuilderManagers['MAIN'] and aiBrain.BuilderManagers['MAIN'].Position
            local usedTransport = false
            if mainPos then
                LOG('[OWPlus] Outpost: tentativo trasporto (logistica propria) verso ' .. targetLocType)
                usedTransport = OWPlusTransportUtils.OWPlusTransportUnit(aiBrain, eng, mainPos, targetPos)
            end
            if not aiBrain:PlatoonExists(self) or eng.Dead then
                eng.OWPlusOutpostBusy = nil
                return
            end
            if usedTransport then
                LOG('[OWPlus] Outpost: trasporto usato per raggiungere ' .. targetLocType)
            else
                -- Fase 9-F33: espansione avamposti SOLO via trasporto, su richiesta
                -- esplicita dell'utente (sess.67, confermata efficace in sess.68 —
                -- fallback a piedi cancellato). Se non c'e' un trasporto libero ORA,
                -- abbandoniamo questo tentativo (verra' ritentato dal builder) invece
                -- di camminare — cosi' l'AI e' spinta a costruire piu' trasporti
                -- invece di aggirarli a piedi.
                --
                -- Fase 9-F35: throttle 10s prima di disbandare. Senza, il builder
                -- ('OWPlus Outpost Factory Claim', priorita' alta, valutato quasi
                -- ogni tick) rirendicava e riabbandonava lo stesso slot in loop
                -- istantaneo — confermato in sess.68: 527 abbandoni per 1 solo
                -- trasporto trovato libero in una partita di 4 minuti.
                LOG('[OWPlus] Outpost: nessun trasporto disponibile, tentativo abbandonato (solo-trasporto, 9-F33) per ' .. targetLocType)
                WaitSeconds(10)
                eng.OWPlusOutpostBusy = nil
                -- Rilascia lo slot (se e' un OUT# con claim registrato) cosi'
                -- 'OWPlus Outpost Factory Claim' puo' ritentarlo quando un
                -- trasporto sara' di nuovo libero, invece di perderlo per sempre.
                if targetLocType and aiBrain.OWPlusOutpostClaimed then
                    aiBrain.OWPlusOutpostClaimed[targetLocType] = nil
                end
                self:PlatoonDisband()
                return
            end
        end

        -- Fase sess.85 (registrazione anticipata — sostituisce il recupero
        -- reattivo piu' sotto, ora commentato). L'ingegnere e' appena stato
        -- scaricato all'avamposto. Invece di lasciarlo costruire "libero" e poi
        -- tentare di strappare la fabbrica risultante a MAIN (che lascia
        -- trigger nativi fantasma legati a MAIN per sempre — confermato in
        -- game, vedi Conoscenze_AI_37 §37.2: SetupFactoryCallbacks registra 4
        -- trigger via ScenarioTriggers.lua SOLO se BuilderManagerData e' nil,
        -- e non rimuove mai i vecchi se l'unita' viene poi ri-registrata
        -- altrove), registriamo QUI l'ingegnere al manager dedicato PRIMA che
        -- costruisca qualunque cosa. Il motore nativo (EngineerManager.lua,
        -- UnitConstructionFinished, riga ~807-809) assegna automaticamente e
        -- correttamente la fabbrica al manager dell'ingegnere che l'ha
        -- costruita — lo stesso identico meccanismo che gia' fa funzionare
        -- senza problemi le espansioni di MAIN.
        if targetLocType and string.sub(targetLocType, 1, 3) == 'OUT'
            and not (aiBrain.OWPlusOutpostFactories and aiBrain.OWPlusOutpostFactories[targetLocType]) then
            local outpostKey = targetLocType
            local outpostPos = targetPos
            if not aiBrain.BuilderManagers[outpostKey] then
                if not Scenario.MasterChain._MASTERCHAIN_.Markers[outpostKey] then
                    Scenario.MasterChain._MASTERCHAIN_.Markers[outpostKey] = {
                        color = 'fff4a460',
                        hint = true,
                        orientation = { 0, 0, 0 },
                        prop = "/env/common/props/markers/M_Expansion_prop.bp",
                        type = 'Expansion Area',
                        position = outpostPos,
                    }
                end
                aiBrain:AddBuilderManagers(outpostPos, 100, outpostKey, true)
                LOG('[OWPlus] Outpost: ' .. outpostKey .. ' — manager dedicato creato PRIMA della costruzione (registrazione anticipata)')
            end
            aiBrain.BuilderManagers[outpostKey].EngineerManager:AddUnit(eng, true)
            LOG('[OWPlus] Outpost: ' .. outpostKey .. ' — ingegnere (' .. tostring(eng.UnitId)
                .. ') registrato al manager dedicato PRIMA di costruire (registrazione anticipata)')

            -- Fase G (sess.93): ownership esplicita (OWPlusOutpostOwnership.lua,
            -- gia' in uso per le strutture dalla Fase F/sess.88) estesa
            -- all'ingegnere fondatore — l'unico ingegnere di un avamposto che non
            -- passa mai da FactoryFinishBuilding (nessuna fabbrica esiste ancora
            -- in questo istante). Sostituisce lo scan geometrico usato finora
            -- dalla sorveglianza unificata (vedi piu' sotto), che contava anche
            -- ingegneri di avamposti vicini entro raggio 30.
            OWPlusOutpostOwnership.OWPlusClaimForOutpost(aiBrain, outpostKey, eng,
                OWPlusOutpostOwnership.OWPlusOwnershipKindEngineer)

            aiBrain.OWPlusOutpostLocationTypes = aiBrain.OWPlusOutpostLocationTypes or {}
            aiBrain.OWPlusOutpostLocationTypes[outpostKey] = true
            aiBrain.OWPlusOutpostRealLocType = aiBrain.OWPlusOutpostRealLocType or {}
            aiBrain.OWPlusOutpostRealLocType[outpostKey] = outpostKey
            LOG('[OWPlus] Outpost: ' .. outpostKey .. ' registrato in OWPlusOutpostLocationTypes (registrazione anticipata)')

            -- Fase D1 (B24): assegna il tipo di produzione (mono bot/carri/artiglieria)
            -- una sola volta, alla prima registrazione reale dell'avamposto.
            -- Fix (sess.90, regressione trovata dall'utente): le funzioni di
            -- OWPlusLogConditions.lua non sono globali cross-file, vanno prese
            -- tramite import() + accesso con il punto (stesso pattern gia' usato
            -- qui sotto per AddGlobalBuilderGroup).
            local OWPlusLogConditionsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua')
            OWPlusLogConditionsMod.OWPlusAssignOutpostType(aiBrain, outpostKey)

            -- Fase D3 (B24): timestamp di fondazione (stabile, mai resettato,
            -- a differenza di OWPlusOutpostTierTimer) + avvio watcher di
            -- reclamo/lancio plotoni d'attacco, una sola volta per avamposto.
            aiBrain.OWPlusOutpostFoundedAt = aiBrain.OWPlusOutpostFoundedAt or {}
            if not aiBrain.OWPlusOutpostFoundedAt[outpostKey] then
                aiBrain.OWPlusOutpostFoundedAt[outpostKey] = GetGameTimeSeconds()
                OWPlusOutpostAttackWatcher(aiBrain, outpostKey)
            end

            -- Fase D-difese, crescita logaritmica (sess.86): timer del tier attivo
            -- (T1) parte alla fondazione — il watcher periodico dedicato (vedi
            -- "sorveglianza crescita difese" piu' sotto) lo legge per calcolare il
            -- tetto corrente. Resettato di nuovo ad ogni salita di tier (vedi punto
            -- di rilevamento tier-up piu' sotto in questo file).
            if OWPLUS_TIER_DEFENSES_ENABLED then
                aiBrain.OWPlusOutpostTierTimer = aiBrain.OWPlusOutpostTierTimer or {}
                aiBrain.OWPlusOutpostTierTimer[outpostKey] = GetGameTimeSeconds()
            end

            local OWPlusAddBuilderTable = import('/lua/ai/AIAddBuilderTable.lua')
            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, outpostKey, 'OWPlus Outpost Engineer Builders')
            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, outpostKey, 'OWPlus Outpost Factory Upgrade')
            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, outpostKey, 'OWPlus Outpost Defense Upgrade')
            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, outpostKey, 'OWPlus Outpost Production')
            -- Sess.100 parte 9 (piano fabbriche): produzione AEREA per la fabbrica aerea della ricetta
            -- (disattivata dal flag via PriorityFunction dei suoi builder, vedi OWPlus Outpost Air Production.lua).
            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, outpostKey, 'OWPlus Outpost Air Production')
            LOG('[OWPlus-FACTORY] Outpost: ' .. outpostKey .. ' — agganciato gruppo produzione aria (registrazione anticipata)')
            -- Sess.97: richiesta esplicita utente -- i magazzini massa (a differenza
            -- di quelli energia, gia' coperti da Uveso nativo su ExpansionArea)
            -- non avevano mai un builder registrato per gli avamposti, quindi
            -- AdjacencyCheck (raggio 60 dal punto BASE del manager, mai da MAIN
            -- se l'estrattore e' vicino a un avamposto) non poteva mai risultare
            -- vera per un estrattore lontano da MAIN.
            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, outpostKey, 'OWPlus Outpost Mass Storage Adjacency')
            LOG('[OWPlus] Outpost: ' .. outpostKey .. ' — agganciati builder dedicati (Engineer/FactoryUpgrade/DefenseUpgrade/Production/MassStorageAdjacency) al manager (registrazione anticipata)')

            local defenseRecipe = aiBrain.OWPlusOutpostDefenseRecipes and aiBrain.OWPlusOutpostDefenseRecipes[outpostKey]
            if defenseRecipe then
                aiBrain.OWPlusOutpostPendingDefenses = aiBrain.OWPlusOutpostPendingDefenses or {}
                local queue = {}
                aiBrain.OWPlusOutpostPendingDefenses[outpostKey] = queue
                for _, t in defenseRecipe.ground do
                    table.insert(queue, { action = 'build', unitType = t, tier = 1 })
                end
                for _, t in defenseRecipe.aa do
                    table.insert(queue, { action = 'build', unitType = t, tier = 1 })
                end
                LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, ' .. table.getn(queue)
                    .. ' difese T1 iniziali aggiunte in coda (registrazione anticipata)')
            end

            -- Cattura il riferimento alla fabbrica una volta costruita, solo per
            -- il nostro tracking interno (OWPlusOutpostFactories) — la
            -- registrazione al manager e' gia' garantita dal motore nativo via
            -- EngineerManager:AddUnit qui sopra, non serve piu' alcuna
            -- correzione/furto da MAIN qui.
            --
            -- Fix (bug reale osservato in game, stesso test): la versione
            -- originale aspettava eng:IsUnitState('Building') prima di
            -- scandire — ma questo ForkThread parte in parallelo al flusso
            -- principale, PRIMA che l'ordine di costruzione sia effettivamente
            -- partito. Se lo stato 'Building' risultava falso al primissimo
            -- controllo, il ciclo non entrava mai e la scansione avveniva
            -- subito, quando la fabbrica non esisteva ancora — confermato:
            -- 'catturata per tracking' non e' MAI comparsa nel log di un test
            -- intero. Poiche' un'altra sorveglianza (poco sotto, riassorbimento
            -- tier ingegneri) aspetta fino a 60s che questa tabella si popoli e
            -- ABORTISCE per sempre se non succede, il bug lasciava gli
            -- ingegneri di tier superato mai riassorbiti (sintomo osservato:
            -- avamposti con meno di 5 ingegneri T3). Fix: polling fisico
            -- ripetuto (stesso pattern gia' usato dal watcher 9-F22 qui sotto),
            -- niente affidamento sullo stato istantaneo dell'ingegnere.
            ForkThread(function()
                local waited = 0
                local found = false
                while waited < 300 and not found do
                    local nearby = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE * categories.FACTORY, outpostPos, 15, 'Ally')
                    for _, u in nearby or {} do
                        if not u.Dead then
                            aiBrain.OWPlusOutpostFactories = aiBrain.OWPlusOutpostFactories or {}
                            aiBrain.OWPlusOutpostFactories[outpostKey] = u
                            LOG('[OWPlus] Outpost (' .. outpostKey .. '): fabbrica (' .. tostring(u.UnitId)
                                .. ') catturata per tracking — manager gia\' assegnato dal motore nativo ("'
                                .. tostring(u.BuilderManagerData and u.BuilderManagerData.FactoryBuildManager
                                    and u.BuilderManagerData.FactoryBuildManager.LocationType or 'SCONOSCIUTO') .. '")')
                            found = true
                            break
                        end
                    end
                    if not found then
                        WaitSeconds(5)
                        waited = waited + 5
                    end
                end
                if not found then
                    LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): tracking fabbrica non riuscito entro 300s, nessuna fabbrica trovata vicino a targetPos')
                end
            end)
        end

        local factionLookup = { UEF = 1, AEON = 2, CYBRAN = 3, SERAPHIM = 4, NOMADS = 5 }
        local factionIndex = cons.FactionIndex or factionLookup[eng.factionCategory] or 1
        local buildingTmplFile = import(cons.BuildingTemplateFile or '/lua/BuildingTemplates.lua')
        local baseTmplFile = import(cons.BaseTemplateFile or '/lua/BaseTemplates.lua')
        local buildingTmpl = buildingTmplFile[(cons.BuildingTemplate or 'BuildingTemplates')][factionIndex]
        local baseTmpl = baseTmplFile[(cons.BaseTemplate or 'BaseTemplates')][factionIndex]
        local baseTmplAtTarget = AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, targetPos)

        self.SetupEngineerCallbacks(eng)

        -- Costruisce vicino a targetPos (o a buildRefs[i] per le difese, 9-F21).
        -- closeToBuilder=nil, reference=tabella → AIExecuteBuildStructure di Uveso
        -- entra nel branch "reference and type(reference)=='table'" → relativeTo = reference.
        for i, buildType in buildList do
            if aiBrain:PlatoonExists(self) and not eng.Dead then
                -- Diagnostica (sess.75): sospetto che l'ingegnere venga "rubato" da un
                -- builder generico di Uveso ('U1 Engineer Reclaim'/'UC123 Assistees',
                -- punto critico noto — non conoscono il nostro flag OWPlusOutpostBusy,
                -- campo custom che il codice vanilla non ha motivo di rispettare) prima
                -- di finire tutta la ricetta, lasciando avamposti con solo 2-3 fabbriche
                -- + le prime 1-2 difese costruite, poi silenzio (osservato in game,
                -- sess.75). Se il PlatoonHandle non e' piu' questo plotone, qualcun
                -- altro lo ha gia' preso in carico.
                if eng.PlatoonHandle ~= self then
                    LOG('[OWPlus-DBG] OWPlusDispersedBuildAI: ingegnere (' .. tostring(eng.UnitId) .. ') NON e\' piu\' in questo plotone prima di costruire item '
                        .. i .. '/' .. table.getn(buildList) .. ' (' .. tostring(buildType) .. ') a ' .. tostring(targetLocType)
                        .. ' — PlatoonHandle attuale: ' .. tostring(eng.PlatoonHandle and (eng.PlatoonHandle.BuilderName or eng.PlatoonHandle.PlanName or 'sconosciuto') or 'nil'))
                end
                AIBuildStructures.AIExecuteBuildStructure(
                    aiBrain, eng, buildType,
                    nil,             -- closeToBuilder nil → non usa posizione eng
                    false,           -- relative false
                    buildingTmpl,
                    baseTmplAtTarget,
                    buildRefs[i],    -- reference tabella → Uveso usa come centro di ricerca
                    nil
                )
            end
        end

        -- Fase 9-F14 (RIMOSSA, sess.76): esisteva un controllo separato qui,
        -- prima del loop finale, che provava a indovinare se il posizionamento
        -- fosse fallito guardando Moving/Building per un tempo limitato (fino a
        -- 180s) — un'euristica Lua parallela e ridondante rispetto al loop
        -- finale qui sotto, che fa la STESSA cosa in modo piu' robusto (grazia
        -- piu' lunga, diagnostica anti-furto). La doppia euristica ha causato un
        -- bug reale: quando questo controllo concludeva (erroneamente) "terreno
        -- non valido" mentre l'ingegnere in realta' AVEVA gia' un ordine nativo
        -- valido in coda (la chiamata AIExecuteBuildStructure qui sopra aveva
        -- gia' trovato posto ed emesso l'ordine — PlatoonDisband() non lo
        -- cancella), l'ingegnere continuava a costruire per conto suo (HP reali
        -- in salita, confermato dall'utente: 3600/4000 su una struttura da
        -- 4000) mentre il nostro codice lo considerava gia' "libero" — varco da
        -- cui una rivendicazione successiva lo riprendeva, sembrando un furto.
        -- Ora c'e' UNA sola fonte di verita' (il loop finale sotto): si fida
        -- SOLO dello stato nativo reale, senza provare a indovinare prima. Se
        -- il posizionamento e' davvero impossibile, l'ingegnere restera'
        -- inattivo e il loop lo rilevera' comunque (dopo idleGraceSeconds),
        -- solo piu' lentamente (fino al tetto di sicurezza) — vedi 'everBuilt'
        -- piu' sotto per il meccanismo "3 fallimenti poi scarta lo slot",
        -- spostato qui per scattare solo su un fallimento vero (zero strutture
        -- mai costruite), non su un sospetto prematuro.
        --
        -- Fase 9-F32: RIMOSSA self.ProcessBuildCommand(eng, false) (era qui dalla
        -- 9-F31). Causa di root del bug "ingegnere ripreso mentre costruisce
        -- ancora", confermata leggendo /lua/platoon.lua vanilla:
        -- ProcessBuildCommand fa IssueClearCommands({eng}) e ri-emette SOLO il
        -- primo item di eng.EngineerBuildQueue, scartando gli ordini nativi per
        -- gli item 2..N gia' emessi dal ciclo AIExecuteBuildStructure qui sopra
        -- (che li mette in coda nativa direttamente via aiBrain:BuildStructure,
        -- non serve alcuna chiamata di supporto). Il completamento del primo
        -- item dovrebbe far scattare EngineerBuildDone (via SetupEngineerCallbacks)
        -- per processare l'item successivo, ma EngineerBuildDone controlla
        -- `unit.PlatoonHandle.PlanName == 'EngineerBuildAI'` — il nostro plotone
        -- ha PlanName = 'OWPlusDispersedBuildAI', quindi il callback esce subito
        -- e la catena si interrompe dopo il primo item. L'ingegnere risultava
        -- "davvero" libero a livello nativo (nessun comando in coda) pur avendo
        -- ancora 1-4 strutture pianificate nel nostro codice — altri builder
        -- (reclaim/economia) lo raccoglievano, e siccome era l'unico membro di
        -- questo plotone la riassegnazione lo disbandava, uccidendo anche
        -- questo stesso thread a meta' esecuzione (spiega perche' il LOG di
        -- chiusura sotto non compariva mai in sess.67, nemmeno per il primo
        -- avamposto avviato con 12+ minuti disponibili prima della fine del test).
        --
        -- Fix: nessuna chiamata a ProcessBuildCommand. Attendiamo lo stato
        -- nativo dell'ingegnere (che riflette davvero cosa sta facendo) invece
        -- della sua coda Lua-side, che nel nostro path non viene mai svuotata
        -- correttamente — stesso pattern di WatchForNotBuilding in platoon.lua
        -- vanilla. Resta "occupato" finche' sta costruendo o si sposta tra una
        -- struttura e l'altra, con lo stesso tetto di sicurezza di prima.
        local queueWaited = 0
        local queueMaxWait = 600
        -- Diagnostica (sess.75): questo loop controlla solo IsUnitState('Building'/
        -- 'Moving') — se l'ingegnere viene rubato da un altro builder che lo mette
        -- SUBITO al lavoro su qualcos'altro (es. reclaim), risulterebbe comunque
        -- "Building"/"Moving" e il loop continuerebbe fino al tetto di sicurezza
        -- (600s) pensando che stia ancora completando la NOSTRA ricetta — quando
        -- in realta' l'ha abbandonata da tempo. wasStolen evita di floodare il
        -- log, segnala solo il momento in cui il furto viene rilevato.
        local wasStolen = false
        -- Fix sess.76 (bug reale trovato, non il furto sospettato in sess.75):
        -- uscire dal loop al PRIMO istante non-Building/non-Moving dichiarava
        -- "completato" anche per una pausa normale tra una struttura e l'altra
        -- (camminata verso il punto successivo, breve attesa risorse) — a quel
        -- punto OWPlusOutpostBusy veniva rilasciato SUBITO, esponendo
        -- l'ingegnere al meccanismo nativo di riassegnazione (EngineerManager
        -- hook) proprio nel mezzo della ricetta. Ora serve un periodo di
        -- inattivita' CONTINUA (idleGraceSeconds) prima di dichiarare davvero
        -- concluso — una pausa breve non fa piu' uscire dal loop.
        local idleStreak = 0
        local idleGraceSeconds = 20
        local loggedIdleStart = false
        -- Fase 9-F14 (spostata qui, sess.76): traccia se ALMENO una struttura e'
        -- davvero entrata in costruzione durante questo tentativo — usato dopo
        -- il loop per il meccanismo "3 fallimenti poi scarta lo slot" (ex 9-F11/
        -- 9-F13/9-F18), ora agganciato a un fallimento vero (zero progresso)
        -- invece che al sospetto prematuro del vecchio controllo separato.
        local everBuilt = false
        while not eng.Dead and queueWaited < queueMaxWait do
            if eng:IsUnitState('Building') or eng:IsUnitState('Moving') then
                if eng:IsUnitState('Building') then
                    everBuilt = true
                end
                if loggedIdleStart then
                    loggedIdleStart = false
                    LOG('[OWPlus-DBG] OWPlusDispersedBuildAI: ingegnere (' .. tostring(eng.UnitId)
                        .. ') ripreso a costruire/muoversi dopo pausa di ' .. idleStreak .. 's a ' .. tostring(targetLocType))
                end
                idleStreak = 0
            else
                idleStreak = idleStreak + 5
                if not loggedIdleStart then
                    loggedIdleStart = true
                    LOG('[OWPlus-DBG] OWPlusDispersedBuildAI: ingegnere (' .. tostring(eng.UnitId)
                        .. ') inattivo (ne Building ne Moving) a ' .. tostring(targetLocType) .. ', grazia ' .. idleGraceSeconds .. 's prima di dichiarare concluso')
                end
                if idleStreak >= idleGraceSeconds then
                    break
                end
            end
            if eng.PlatoonHandle ~= self and not wasStolen then
                wasStolen = true
                LOG('[OWPlus-DBG] OWPlusDispersedBuildAI: ingegnere (' .. tostring(eng.UnitId) .. ') rubato da un altro plotone durante l\'attesa finale a '
                    .. tostring(targetLocType) .. ' dopo ' .. queueWaited .. 's — PlatoonHandle attuale: '
                    .. tostring(eng.PlatoonHandle and (eng.PlatoonHandle.BuilderName or eng.PlatoonHandle.PlanName or 'sconosciuto') or 'nil'))
            end
            WaitSeconds(5)
            queueWaited = queueWaited + 5
        end
        LOG('[OWPlus] OWPlusDispersedBuildAI: OK, costruzione avamposto completata (o ingegnere morto/tetto raggiunto) a ' .. tostring(targetLocType))
        -- Fase 9-F34: costruzione conclusa (o ingegnere morto/tetto raggiunto) —
        -- rilascia il flag cosi' l'ingegnere (se sopravvissuto) torna disponibile
        -- per una futura rivendicazione avamposto legittima.
        --
        -- Fix sess.76 (bug reale osservato in game: struttura in coda su
        -- posizione irraggiungibile, es. cima di una montagna raggiungibile
        -- solo in volo): l'uscita dal loop per grazia-inattivita' (idleGraceSeconds)
        -- NON significa che tutte le strutture del buildList siano state
        -- davvero completate — puo' scattare anche con una struttura ancora
        -- bloccata in coda nativa (mai raggiungibile a piedi). Senza
        -- IssueClearCommands, quell'ordine STALE restava nella coda nativa
        -- dell'ingegnere: appena veniva rimesso al lavoro da un altro sistema
        -- (es. il watcher "compito locale di default" qui sotto, che lo trova
        -- libero e gli assegna assist fabbrica), l'ingegnere oscillava
        -- all'infinito tra il nuovo ordine e la ripresa dell'ordine irraggiungibile
        -- rimasto in coda — osservato dal vivo in game (sess.76). Ripulire la
        -- coda qui garantisce che chiunque riprenda l'ingegnere parta da zero.
        if not eng.Dead then
            IssueClearCommands({eng})
            eng.OWPlusOutpostBusy = nil
        end

        -- Fase 9-F11/13/18 (spostato da 9-F14, sess.76): "3 fallimenti poi
        -- scarta lo slot" — ora scatta SOLO se questo tentativo non ha mai
        -- costruito nulla (everBuilt=false), non piu' su un sospetto prematuro.
        -- Stesso meccanismo di prima: dopo 3 fallimenti veri consecutivi sullo
        -- stesso slot, lo liberiamo (o rifiutiamo per sempre il marker, per gli
        -- slot FWD che ne hanno uno) invece di ritentarlo all'infinito.
        if not everBuilt and targetLocType and (string.sub(targetLocType, 1, 3) == 'FWD' or string.sub(targetLocType, 1, 5) == 'BASE_' or string.sub(targetLocType, 1, 3) == 'OUT') then
            local ownerName = (ArmyBrains[aiBrain:GetArmyIndex()] and ArmyBrains[aiBrain:GetArmyIndex()].Nickname) or tostring(aiBrain:GetArmyIndex())
            aiBrain.OWPlusForwardFailCount = aiBrain.OWPlusForwardFailCount or {}
            aiBrain.OWPlusForwardFailCount[targetLocType] = (aiBrain.OWPlusForwardFailCount[targetLocType] or 0) + 1
            LOG('[OWPlus] OWPlusDispersedBuildAI (' .. ownerName .. '): ' .. targetLocType .. ' fallimento vero (zero strutture costruite) #'
                .. aiBrain.OWPlusForwardFailCount[targetLocType] .. '/3')
            if aiBrain.OWPlusForwardFailCount[targetLocType] >= 3 then
                if string.sub(targetLocType, 1, 3) == 'FWD' then
                    local markerKey = math.floor(targetPos[1]) .. '_' .. math.floor(targetPos[3])
                    aiBrain.OWPlusForwardBaseMarkers = aiBrain.OWPlusForwardBaseMarkers or {}
                    aiBrain.OWPlusForwardBaseMarkers[markerKey] = 'REJECTED'
                    LOG('[OWPlus] OWPlusDispersedBuildAI (' .. ownerName .. '): ' .. targetLocType .. ' liberato dopo 3 fallimenti, marker ('
                        .. markerKey .. ') rifiutato per sempre')
                else
                    LOG('[OWPlus] OWPlusDispersedBuildAI (' .. ownerName .. '): ' .. targetLocType .. ' disabilitato dopo 3 fallimenti (nessun fallback disponibile)')
                end
                aiBrain.OWPlusSubBases[targetLocType] = nil
                aiBrain.OWPlusForwardFailCount[targetLocType] = nil
            end
        elseif everBuilt and targetLocType and aiBrain.OWPlusForwardFailCount then
            -- Reset del contatore: un tentativo che ha davvero costruito qualcosa
            -- azzera i fallimenti precedenti, non serve piu' scartare lo slot.
            aiBrain.OWPlusForwardFailCount[targetLocType] = nil
        end

        -- Fase 9-F17 (diagnostica): a quale BuilderManager finisce per appartenere
        -- la fabbrica costruita qui? Se e' 'MAIN', significa che segue le regole
        -- di produzione di MAIN (solo ingegneri, 9-F4) invece della lista Builders
        -- del template Uveso Forward Base OverwhelmPlus.lua (mai attaccata per FWD*
        -- per lo stesso motivo per cui fabbrica/difese richiedevano un workaround).
        if targetLocType and (string.sub(targetLocType, 1, 3) == 'FWD' or string.sub(targetLocType, 1, 5) == 'BASE_') then
            ForkThread(function()
                WaitSeconds(60)
                local nearby = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE * categories.FACTORY * categories.LAND, targetPos, 15, 'Ally')
                for _, u in nearby or {} do
                    if not u.Dead and u.BuilderManagerData and u.BuilderManagerData.FactoryBuildManager then
                        LOG('[OWPlus] Diagnostica manager: fabbrica ' .. tostring(u.UnitId) .. ' a ' .. tostring(targetLocType)
                            .. ' appartiene al manager "' .. tostring(u.BuilderManagerData.FactoryBuildManager.LocationType) .. '"')
                    elseif not u.Dead then
                        LOG('[OWPlus] Diagnostica manager: fabbrica ' .. tostring(u.UnitId) .. ' a ' .. tostring(targetLocType)
                            .. ' SENZA BuilderManagerData (orfana)')
                    end
                end
            end)
        end

        -- Fase 9-F19 (corretta in 9-F20): per gli avamposti OUT#, cattura il
        -- riferimento alla PRIMA fabbrica costruita e la ri-registra in un
        -- BuilderManager dedicato tramite AddFactoryToClosestManager. Scoperta
        -- (9-F20): la fabbrica NON resta orfana — viene assegnata automaticamente
        -- al manager di MAIN (confermato dal diagnostico 9-F17 sui nodi BASE_,
        -- che trova sempre 'appartiene al manager "MAIN"'). Il check originale
        -- 'not u.BuilderManagerData' quindi non scattava mai: bisogna PRIMA
        -- staccare esplicitamente la fabbrica dal manager attuale (rimuoverla dal
        -- FactoryList di MAIN), stesso pattern che Uveso stesso usa per le
        -- fabbriche navali mal assegnate in LocationRangeManagerThread
        -- (aiarchetype-managerloader.lua), POI chiamare AddFactoryToClosestManager
        -- perche' la trovi realmente senza manager.
        --
        -- NOTA sess.85: il ForkThread reattivo qui sotto (ricerca fabbrica ->
        -- distacco da MAIN -> ri-registrazione) e' COMMENTATO (non cancellato,
        -- su richiesta esplicita dell'utente) perche' sostituito dalla
        -- registrazione anticipata subito sopra (ingegnere assegnato a
        -- EngineerManager PRIMA di costruire). local outpostKey/outpostPos
        -- restano attivi perche' servono ai watcher SEGUENTI in questo stesso
        -- blocco if (Fase 9-F22, sorveglianza build/tier/difese), che non sono
        -- toccati da questo cambio. Se la registrazione anticipata si rivela
        -- insufficiente in qualche caso limite, il blocco commentato resta
        -- come riferimento per un ripristino — altrimenti va cancellato in una
        -- sessione futura una volta confermato il funzionamento in game.
        --
        -- Fix (bug reale osservato in game, stesso test del fix tracking qui
        -- sopra): la guardia originale ('not OWPlusOutpostFactories[...]') e'
        -- diventata inaffidabile ORA che il tracking funziona ed e' veloce —
        -- si popola in pochi secondi (riga 'catturata per tracking'), MOLTO
        -- prima che l'ingegnere finisca l'intera coda di costruzione e il
        -- flusso principale arrivi fin qui. Risultato confermato in game: la
        -- condizione arriva gia' falsa, le 4 sorveglianze essenziali qui sotto
        -- (ricostruzione, mutex build-order, riassorbimento tier, coda difese/
        -- guardia) non partono MAI — zero difese costruite in un test intero.
        -- Serve una guardia "ho gia' avviato le sorveglianze per questo
        -- avamposto" INDIPENDENTE dal tracking, impostata in modo sincrono e
        -- deterministico proprio qui (nessuna corsa possibile: e' lo stesso
        -- identico punto, valutata una sola volta per avamposto).
        aiBrain.OWPlusOutpostWatchersStarted = aiBrain.OWPlusOutpostWatchersStarted or {}
        if targetLocType and string.sub(targetLocType, 1, 3) == 'OUT'
            and not aiBrain.OWPlusOutpostWatchersStarted[targetLocType] then
            aiBrain.OWPlusOutpostWatchersStarted[targetLocType] = true
            local outpostKey = targetLocType
            local outpostPos = targetPos
            --[[ ForkThread(function()
                local waitedBuild = 0
                while eng and not eng.Dead and eng:IsUnitState('Building') and waitedBuild < 300 do
                    WaitSeconds(5)
                    waitedBuild = waitedBuild + 5
                end
                WaitSeconds(2)
                local nearby = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE * categories.FACTORY, targetPos, 15, 'Ally')
                for _, u in nearby or {} do
                    if not u.Dead then
                        aiBrain.OWPlusOutpostFactories = aiBrain.OWPlusOutpostFactories or {}
                        aiBrain.OWPlusOutpostFactories[targetLocType] = u
                        if u.BuilderManagerData and u.BuilderManagerData.FactoryBuildManager then
                            local oldLocType = u.BuilderManagerData.FactoryBuildManager.LocationType
                            for k, v in u.BuilderManagerData.FactoryBuildManager.FactoryList do
                                if v == u then
                                    u.BuilderManagerData.FactoryBuildManager.FactoryList[k] = nil
                                end
                            end
                            -- Fix sess.77 (quater, applicato per coerenza/sicurezza anche qui):
                            -- rimuovere dalla FactoryList del vecchio manager non basta —
                            -- SetupFactoryCallbacks (vanilla) registra i trigger di completamento
                            -- costruzione SOLO se BuilderManagerData e' nil in quel momento. Senza
                            -- azzerarlo, quei trigger potrebbero restare legati al vecchio manager.
                            u.BuilderManagerData = nil
                            LOG('[OWPlus] Outpost: fabbrica (' .. tostring(u.UnitId) .. ') a ' .. targetLocType
                                .. ' staccata dal manager "' .. tostring(oldLocType) .. '"')
                        end
                        -- Fix sess.83 (richiesta esplicita utente, bug osservato in game):
                        -- AddFactoryToClosestManager (vanilla) cerca il MARKER DI MAPPA piu'
                        -- vicino tra 'Blank Marker'/'Expansion Area'/'Large Expansion Area' —
                        -- il nostro MAIN e' un 'Blank Marker'. Se l'avamposto e' abbastanza
                        -- vicino a MAIN da rientrare nel raggio ATTUALE del SUO manager
                        -- (FactoryManager.Radius, che cresce nel tempo — "spirale
                        -- addensamento"), la fabbrica viene agganciata DIRETTAMENTE al
                        -- manager di MAIN invece che a uno dedicato, ereditando l'intera
                        -- lista Builders di MAIN (inclusa produzione unita' generica) — root
                        -- cause confermata di "l'avamposto costruisce unita' come decide
                        -- MAIN, non i nostri builder dedicati" e "ingegneri oltre il tetto di
                        -- 5" (i builder ingegnere di MAIN, con tetti diversi, si aggiungono
                        -- ai nostri). Creiamo il manager NOI, sulla posizione nota
                        -- dell'avamposto (outpostPos) e con targetLocType come chiave
                        -- (es. 'OUT3') — stesso pattern ATOMICO che AddFactoryToClosestManager
                        -- usa internamente quando decide di crearne uno nuovo (creare un
                        -- marker sintetico in Scenario.MasterChain, poi AddBuilderManagers +
                        -- FactoryManager:AddFactory, nessun WaitSeconds in mezzo — la stessa
                        -- garanzia anti-DeadBaseMonitor che aveva motivato la scelta
                        -- originale di questa funzione in 9-F19), ma con chiave/posizione
                        -- NOSTRE invece che dedotte da un marker esistente — l'avamposto non
                        -- puo' piu' finire dentro MAIN, indipendentemente dalla distanza.
                        -- AddBuilderManagers legge Scenario.MasterChain._MASTERCHAIN_.Markers
                        -- [baseName].type incondizionatamente: senza un marker preesistente
                        -- crasherebbe (indicizzazione su nil).
                        if not aiBrain.BuilderManagers[targetLocType] then
                            if not Scenario.MasterChain._MASTERCHAIN_.Markers[targetLocType] then
                                Scenario.MasterChain._MASTERCHAIN_.Markers[targetLocType] = {
                                    color = 'fff4a460',
                                    hint = true,
                                    orientation = { 0, 0, 0 },
                                    prop = "/env/common/props/markers/M_Expansion_prop.bp",
                                    type = 'Expansion Area',
                                    position = outpostPos,
                                }
                            end
                            aiBrain:AddBuilderManagers(outpostPos, 100, targetLocType, true)
                        end
                        aiBrain.BuilderManagers[targetLocType].FactoryManager:AddFactory(u)
                        u.lost = nil
                        LOG('[OWPlus] Outpost: prima fabbrica (' .. tostring(u.UnitId) .. ') a ' .. targetLocType
                            .. ' registrata nel manager dedicato "' .. targetLocType .. '" (bypassato AddFactoryToClosestManager)')

                        -- targetLocType E' ora la chiave reale (deterministico, non serve piu'
                        -- scandire tutti i manager per scoprirlo).
                        local realLocType = targetLocType

                        if realLocType then
                            aiBrain.OWPlusOutpostLocationTypes = aiBrain.OWPlusOutpostLocationTypes or {}
                            aiBrain.OWPlusOutpostLocationTypes[realLocType] = true
                            -- Fix orfano fabbrica (sess.72): serve la chiave reale anche fuori da
                            -- questo ForkThread (dal watcher di recupero orfani piu' sotto), che
                            -- e' un ForkThread SIBLING separato e non vede 'realLocType' (locale a
                            -- questo blocco). Salvata per-outpost cosi' resta leggibile ovunque.
                            aiBrain.OWPlusOutpostRealLocType = aiBrain.OWPlusOutpostRealLocType or {}
                            aiBrain.OWPlusOutpostRealLocType[targetLocType] = realLocType
                            LOG('[OWPlus] Outpost: ' .. targetLocType .. ' registrato in OWPlusOutpostLocationTypes con chiave reale "' .. realLocType .. '"')

                            -- Fase D1 (B24): assegna il tipo di produzione (mono
                            -- bot/carri/artiglieria) una sola volta. Fix (sess.90):
                            -- vedi nota nel blocco "registrazione anticipata" sopra.
                            local OWPlusLogConditionsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua')
                            OWPlusLogConditionsMod.OWPlusAssignOutpostType(aiBrain, realLocType)

                            -- Fase D3 (B24): vedi nota nel blocco "registrazione anticipata" sopra.
                            aiBrain.OWPlusOutpostFoundedAt = aiBrain.OWPlusOutpostFoundedAt or {}
                            if not aiBrain.OWPlusOutpostFoundedAt[realLocType] then
                                aiBrain.OWPlusOutpostFoundedAt[realLocType] = GetGameTimeSeconds()
                                OWPlusOutpostAttackWatcher(aiBrain, realLocType)
                            end

                            -- Fase A/B/C fix (sess.71, aggiornato sess.83): dalla sess.83 il
                            -- manager dell'avamposto viene creato da NOI (vedi sopra) senza
                            -- alcun template stock — parte con zero BuilderGroup. Agganciamo
                            -- qui SOLO quelli dedicati OWPlus (mai un intero template
                            -- 'overwhelmplus'/stock, per non esporre gli avamposti anche ai
                            -- builder generici di produzione unita').
                            local OWPlusAddBuilderTable = import('/lua/ai/AIAddBuilderTable.lua')
                            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, realLocType, 'OWPlus Outpost Engineer Builders')
                            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, realLocType, 'OWPlus Outpost Factory Upgrade')
                            -- Fase C, sess.83: upgrade nativo in-place MK1->MK2 delle difese
                            -- modded (vedi OWPlus Outpost Defense Upgrade.lua).
                            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, realLocType, 'OWPlus Outpost Defense Upgrade')
                            -- Fase D1 (B24): produzione unita' da combattimento mono-categoria.
                            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, realLocType, 'OWPlus Outpost Production')
                            -- Sess.100 parte 9: produzione aerea (vedi sopra, registrazione anticipata).
                            OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, realLocType, 'OWPlus Outpost Air Production')
                            LOG('[OWPlus-FACTORY] Outpost: ' .. tostring(realLocType) .. ' — agganciato gruppo produzione aria (manager reale)')
                            LOG('[OWPlus] Outpost: ' .. targetLocType .. ' — agganciati builder dedicati (Engineer/FactoryUpgrade/DefenseUpgrade/Production) al manager "' .. realLocType .. '"')

                            -- Fix sess.78: Fase difese unificata. Non costruisce piu' nulla qui
                            -- direttamente — si limita a travasare la ricetta T1 iniziale (gia'
                            -- generata da OWPlusOutpostGenerator.lua, invariata) nella coda
                            -- condivisa aiBrain.OWPlusOutpostPendingDefenses[outpostKey], che il
                            -- watcher periodico unico (vedi "sorveglianza unificata difese/guardia"
                            -- piu' sotto) consuma pezzo per pezzo. Sostituisce il vecchio ciclo
                            -- dedicato — root cause del "costruisce 1-3 difese poi si ferma": un
                            -- ciclo separato competeva con Fase A per gli stessi ingegneri liberi.
                            do
                                local defenseRecipe = aiBrain.OWPlusOutpostDefenseRecipes and aiBrain.OWPlusOutpostDefenseRecipes[outpostKey]
                                if defenseRecipe then
                                    aiBrain.OWPlusOutpostPendingDefenses = aiBrain.OWPlusOutpostPendingDefenses or {}
                                    local queue = {}
                                    aiBrain.OWPlusOutpostPendingDefenses[outpostKey] = queue
                                    for _, t in defenseRecipe.ground do
                                        table.insert(queue, { action = 'build', unitType = t, tier = 1 })
                                    end
                                    for _, t in defenseRecipe.aa do
                                        table.insert(queue, { action = 'build', unitType = t, tier = 1 })
                                    end
                                    LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, ' .. table.getn(queue)
                                        .. ' difese T1 iniziali aggiunte in coda')
                                end
                            end

                            -- Fix (sess.73): confermato via hook diagnostico (AssignBuildOrder,
                            -- FactoryBuilderManager.lua / ManagerLoopBody, PlatoonFormManager.lua)
                            -- che: 1) la fabbrica chiede "cosa costruisco?" SOLO alla nascita e al
                            -- completamento dell'ordine corrente (FactoryFinishBuilding), mai piu'
                            -- nel frattempo — i nostri 2 BuilderGroup vengono agganciati DOPO questa
                            -- primissima richiesta (gia' soddisfatta, quasi certamente da un builder
                            -- stock del template UvesoExpansionArea), quindi restano invisibili
                            -- finche' quell'ordine non finisce (mai successo entro la durata dei
                            -- test); 2) le NOSTRE condizioni custom (OWPlusLogConditions.lua) non
                            -- sono valutate dal vivo dal motore ma lette da una cache aggiornata da
                            -- un thread condiviso di tutto il brain (ConditionsMonitor,
                            -- BrainConditionsMonitor.lua) con fino a ~7s di ritardo dalla prima
                            -- registrazione. Attendiamo quindi 8s (oltre il ritardo massimo della
                            -- cache) prima di forzare una nuova valutazione su entrambi i sistemi,
                            -- invece di aspettare un trigger naturale che potrebbe non arrivare mai.
                            local forceLocType = realLocType
                            local forceOutpostKey = targetLocType
                            ForkThread(function()
                                WaitSeconds(8)
                                local mgr = aiBrain.BuilderManagers[forceLocType]
                                if not mgr then return end

                                -- Fase A: guardia IsIdleState() — AssignBuildOrder non controlla se
                                -- la fabbrica e' gia' impegnata, forzarla su una occupata rischierebbe
                                -- di accodare un secondo ordine sopra quello in corso.
                                if mgr.FactoryManager and mgr.FactoryManager.FactoryList then
                                    for _, fac in mgr.FactoryManager.FactoryList do
                                        if not fac.Dead and fac.BuilderManagerData and fac.BuilderManagerData.BuilderType and fac:IsIdleState() then
                                            mgr.FactoryManager:AssignBuildOrder(fac, fac.BuilderManagerData.BuilderType)
                                            LOG('[OWPlus] Outpost: ' .. forceOutpostKey .. ' — forzata nuova valutazione builder su fabbrica ('
                                                .. tostring(fac.UnitId) .. ', bType=' .. tostring(fac.BuilderManagerData.BuilderType) .. ')')
                                        end
                                    end
                                end

                                -- Fase B: nessun equivalente di AssignBuildOrder — la decisione vive
                                -- dentro ManagerLoopBody, normalmente richiamato dal loop periodico
                                -- del manager. La invochiamo direttamente sui SOLI builder upgrade
                                -- appena agganciati (handle gia' disponibili in BuilderHandles).
                                local upgradeHandles = mgr.BuilderHandles and mgr.BuilderHandles['OWPlus Outpost Factory Upgrade']
                                if mgr.PlatoonFormManager and upgradeHandles then
                                    for _, builderHandle in upgradeHandles do
                                        mgr.PlatoonFormManager:ManagerLoopBody(builderHandle, 'Any')
                                    end
                                    LOG('[OWPlus] Outpost: ' .. forceOutpostKey .. ' — forzata valutazione immediata builder upgrade fabbrica')
                                end
                            end)
                        else
                            -- Irraggiungibile dalla sess.83 (realLocType = targetLocType,
                            -- sempre impostato) — lasciato come rete di sicurezza silenziosa
                            -- nel caso AddBuilderManagers fallisse in modo imprevisto.
                            LOG('[OWPlus-WARN] Outpost: ' .. targetLocType .. ' — creazione manager dedicato fallita in modo imprevisto, OWPlusOutpostLocationTypes NON popolato')
                        end
                        break
                    end
                end
            end) ]] -- fine ForkThread reattivo commentato (sess.85, Fase 9-F19/20)

            -- Fase 9-F22: sorveglianza distruzione/ricostruzione. Se TUTTE le
            -- fabbriche di questo avamposto muoiono, dopo un periodo di sicurezza
            -- (per non rimandare un ingegnere in mezzo a un combattimento ancora
            -- in corso) e solo quando l'area torna libera da nemici, libera lo
            -- slot cosi' 'OWPlus Outpost Factory Claim' puo' rimandare un
            -- ingegnere a ricostruirlo — stessa posizione (OWPlusSubBases) e
            -- stessa ricetta (OWPlusOutpostRecipes), mai toccate qui.
            ForkThread(function()
                WaitSeconds(90)
                local initialCount = OWPlusCountOutpostFactories(aiBrain, outpostKey, outpostPos)
                if initialCount == 0 then
                    LOG('[OWPlus] Outpost watcher (' .. outpostKey .. '): nessuna fabbrica trovata dopo 90s, sorveglianza annullata')
                    return
                end
                LOG('[OWPlus] Outpost watcher (' .. outpostKey .. '): OK, sorveglianza avviata su ' .. initialCount .. ' fabbriche')

                -- Fix falso-morto da upgrade (sess.74): la versione precedente teneva un
                -- riferimento fisso alle unita' catturate qui sopra e controllava solo
                -- '.Dead' su QUELLE istanze specifiche. Confermato in dev.log (sess.73/74):
                -- un upgrade riuscito di una fabbrica sostituisce l'entita' (la vecchia
                -- muore, ne nasce una nuova alla stessa posizione — comportamento normale
                -- del motore per l'upgrade di una struttura, gia' noto da Conoscenze_AI_34
                -- §34.1 e dal fix orfano di sess.72) — per un avamposto con UNA sola
                -- fabbrica, questo faceva scattare "tutte le fabbriche distrutte" su un
                -- avamposto perfettamente sano appena salito di tier, buttando via un
                -- successo e forzando una ricostruzione completa (osservato: OUT17,
                -- ricostruzione poi fallita per terreno non valido). Fix: ad ogni ciclo
                -- ri-scansiona fisicamente l'area invece di fidarsi di riferimenti vecchi
                -- — cosi' una fabbrica sostituita da upgrade viene vista correttamente
                -- come "ancora presente", non come "morta".
                while true do
                    WaitSeconds(30)
                    local liveCount = OWPlusCountOutpostFactories(aiBrain, outpostKey, outpostPos)
                    if liveCount == 0 then
                        break
                    end
                end
                LOG('[OWPlus] Outpost watcher (' .. outpostKey .. '): OK, tutte le fabbriche distrutte, attesa di sicurezza (60s) prima di valutare ricostruzione')

                WaitSeconds(60)
                while aiBrain:GetNumUnitsAroundPoint(categories.ALLUNITS - categories.SCOUT, outpostPos, 40, 'Enemy') > 0 do
                    WaitSeconds(30)
                end

                aiBrain.OWPlusOutpostClaimed[outpostKey] = nil
                aiBrain.OWPlusOutpostFactories[outpostKey] = nil
                -- Fix sess.85: reset anche del nuovo flag guardia (vedi sopra) —
                -- senza, alla ricostruzione le 4 sorveglianze di questo stesso
                -- blocco (incluso questo watcher stesso) non ripartirebbero mai,
                -- dato che il flag resterebbe 'true' dalla prima fondazione.
                if aiBrain.OWPlusOutpostWatchersStarted then
                    aiBrain.OWPlusOutpostWatchersStarted[outpostKey] = nil
                end
                LOG('[OWPlus] Outpost watcher (' .. outpostKey .. '): OK, area libera da nemici, slot rilasciato per ricostruzione')
            end)

            -- Fix sess.78: sorveglianza continua ordine di build. Confermato in game
            -- (dev.log) che il mutex nativo factory.DelayThread puo' bloccarsi non solo
            -- al riaggancio dopo un tier-up (gia' coperto dal reset esplicito nei rami
            -- di recupero sopra) ma anche durante il normale funzionamento — es. subito
            -- dopo che FactoryFinishBuilding (vanilla) richiede il prossimo ordine e
            -- AssignBuildOrder fallisce quel tick (CanBuildPlatoon negativo): il retry
            -- nativo a 2s puo' collidere col mutex e la fabbrica resta ferma per il
            -- resto della partita senza nessun sintomo visibile (osservato: nessuna
            -- riga AssignBuildOrder/DelayBuildOrder per gli ultimi ~6 minuti di un test
            -- da 10). Watcher persistente per l'intera vita dell'avamposto: ogni 10s, se
            -- la fabbrica corrente e' viva e non sta ne' costruendo ne' potenziando,
            -- forza un reset del mutex e un nuovo tentativo — innocuo se non c'e'
            -- davvero nulla da costruire (GetHighestBuilder torna 'nessun builder',
            -- gia' visibile dall'hook diagnostico esistente in FactoryBuilderManager.lua).
            --
            -- Fix sess.78 (ter, causa reale del watcher mai intervenuto): diagnostica
            -- dedicata in game ha rivelato che questo ForkThread e' un SIBLING creato in
            -- modo sincrono insieme a 9-F22/Fase A/orfani, MOLTO prima che il ForkThread
            -- asincrono di Fase 9-F19 arrivi a popolare
            -- aiBrain.OWPlusOutpostRealLocType[outpostKey] (deve prima aspettare che
            -- l'ingegnere finisca di costruire la fabbrica) — confermato dall'ordine reale
            -- nel log: 'avviata sorveglianza' compariva PRIMA di 'registrato in
            -- OWPlusOutpostLocationTypes con chiave reale'. Il while sotto veniva quindi
            -- valutato falso al primissimo controllo (Lua valuta la condizione PRIMA del
            -- corpo, incluso il WaitSeconds interno) — il ciclo non entrava mai, il thread
            -- terminava subito in silenzio, per l'intera partita. Stessa identica causa
            -- del watcher "ingegnere libero" di Fase A poco sotto (stesso fix applicato
            -- li'). Attesa attiva (non timeout cieco) finche' la registrazione non e'
            -- completa, prima di entrare nel ciclo di sorveglianza vero e proprio.
            ForkThread(function()
                local waitReg = 0
                while not (aiBrain.OWPlusOutpostRealLocType and aiBrain.OWPlusOutpostRealLocType[outpostKey]) and waitReg < 300 do
                    WaitSeconds(5)
                    waitReg = waitReg + 5
                end
                LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, avviata sorveglianza continua ordine di build fabbrica')
                while aiBrain.OWPlusOutpostRealLocType and aiBrain.OWPlusOutpostRealLocType[outpostKey] do
                    WaitSeconds(10)
                    local curFactory = aiBrain.OWPlusOutpostFactories and aiBrain.OWPlusOutpostFactories[outpostKey]
                    local curRealLocType = aiBrain.OWPlusOutpostRealLocType[outpostKey]
                    local curMgr = curRealLocType and aiBrain.BuilderManagers[curRealLocType]
                    if OWPlusFactoryTargetsMod.OWPlusMultiFactoryDisabled then
                        if curFactory and not curFactory.Dead and curMgr and curMgr.FactoryManager
                            and not curFactory:IsUnitState('Building') and not curFactory:IsUnitState('Upgrading') then
                            curFactory.DelayThread = nil
                            local bType = 'Land'
                            if EntityCategoryContains(categories.AIR, curFactory) then
                                bType = 'Air'
                            elseif EntityCategoryContains(categories.NAVAL, curFactory) then
                                bType = 'Sea'
                            end
                            curMgr.FactoryManager:AssignBuildOrder(curFactory, bType)
                        end
                    elseif curMgr and curMgr.FactoryManager and curMgr.FactoryManager.FactoryList then
                        -- Sess.100 parte 9 (piano fabbriche): l'avamposto ha 2 terra + 1 aria. Il mutex
                        -- factory.DelayThread (regola 20k) puo' bloccare OGNI fabbrica, non solo quella
                        -- tracciata: si controllano tutte le fabbriche del manager. Le fabbriche in
                        -- upgrade/claimate/che costruiscono restano escluse (stesse guardie di prima).
                        local kicked = 0
                        for _, f in curMgr.FactoryManager.FactoryList do
                            if f and not f.Dead and not f.OWPlusUpgradeClaimed
                                and not f:IsUnitState('Building') and not f:IsUnitState('Upgrading') then
                                f.DelayThread = nil
                                local bType = 'Land'
                                if EntityCategoryContains(categories.AIR, f) then
                                    bType = 'Air'
                                elseif EntityCategoryContains(categories.NAVAL, f) then
                                    bType = 'Sea'
                                end
                                curMgr.FactoryManager:AssignBuildOrder(f, bType)
                                kicked = kicked + 1
                            end
                        end
                        aiBrain.OWPlusOutpostKickLogTime = aiBrain.OWPlusOutpostKickLogTime or {}
                        local nowKick = GetGameTimeSeconds()
                        if kicked > 0 and (not aiBrain.OWPlusOutpostKickLogTime[outpostKey]
                            or nowKick - aiBrain.OWPlusOutpostKickLogTime[outpostKey] >= 60) then
                            aiBrain.OWPlusOutpostKickLogTime[outpostKey] = nowKick
                            LOG('[OWPlus-FACTORY] Outpost (' .. outpostKey .. '): sorveglianza build order, ' .. kicked .. ' fabbriche libere ri-sollecitate')
                        end
                    end
                end
            end)

            -- Sorveglianza tier fabbrica avamposto. Rileva ogni salita di tier
            -- (T1->T2->T3) e aggiorna aiBrain.OWPlusOutpostFactories con l'entita'
            -- viva corrente (l'upgrade distrugge e ricrea l'unita', Conoscenze_AI_35
            -- §35.1). Nota (sess.78): il riassorbimento esplicito degli ingegneri di
            -- tier superato NON vive piu' qui — se ne occupa il watcher unificato
            -- difese/guardia (piu' sotto in questo file), che ritrova comunque
            -- qualunque ingegnere idle ad ogni ciclo, indipendentemente dal tier.
            -- Qui restano solo il rilevamento tier-up e il popolamento della coda
            -- difese da riscattare (vedi sotto).
            ForkThread(function()
                -- Fix race condition (sess.73): questo ForkThread e' SIBLING del thread
                -- di registrazione (quello che popola aiBrain.OWPlusOutpostFactories,
                -- piu' sopra in questo file) — nessuna garanzia che sia gia' finito
                -- quando questo parte. Controllare 'OWPlusOutpostFactories[outpostKey]'
                -- all'istante zero lo trovava quasi sempre nil, facendo terminare la
                -- sorveglianza all'istante (confermato in dev.log sess.73: "avviata" e
                -- "terminata (fabbrica assente/morta)" sempre a distanza zero, per OGNI
                -- avamposto di ogni test finora — il riassorbimento non ha mai
                -- funzionato). Fix: attendere fino a 60s che la tabella venga popolata
                -- prima di dichiarare la sorveglianza avviata o abbandonarla.
                local waitedForFactory = 0
                while not (aiBrain.OWPlusOutpostFactories and aiBrain.OWPlusOutpostFactories[outpostKey])
                    and waitedForFactory < 60 do
                    WaitSeconds(2)
                    waitedForFactory = waitedForFactory + 2
                end
                if not (aiBrain.OWPlusOutpostFactories and aiBrain.OWPlusOutpostFactories[outpostKey]) then
                    LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): sorveglianza riassorbimento tier non avviata, fabbrica mai registrata entro 60s')
                    return
                end

                LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, avviata sorveglianza riassorbimento tier ingegneri')
                local lastTier = 1
                while true do
                    WaitSeconds(20)
                    -- Fix falso-morto da upgrade (sess.74): la versione precedente teneva
                    -- fisso il riferimento a aiBrain.OWPlusOutpostFactories[outpostKey] e
                    -- si fermava al primo .Dead — ma un upgrade riuscito sostituisce
                    -- l'entita' (stesso motivo del fix 9-F22 poco sopra), quindi il
                    -- riassorbimento si fermava dopo il PRIMO salto di tier, lasciando
                    -- indietro ingegneri costruiti su tier successivi (osservato: un
                    -- ingegnere T2 "rimasto in coda" dopo l'upgrade a T3). Fix: ad ogni
                    -- ciclo ri-cerca fisicamente la fabbrica viva di tier piu' alto vicino
                    -- alla posizione nota, invece di fidarsi della vecchia istanza —
                    -- cosi' il riassorbimento segue correttamente T1->T2->T3 anche
                    -- attraverso piu' sostituzioni di entita'.
                    local nearbyFactories = aiBrain:GetUnitsAroundPoint(
                        categories.STRUCTURE * categories.FACTORY, outpostPos, 20, 'Ally') or {}
                    local factory
                    local curTier = 0
                    for _, f in nearbyFactories do
                        if not f.Dead and OWPlusFactoryBelongsToOutpost(aiBrain, f, outpostKey) then
                            local fTier = 1
                            if EntityCategoryContains(categories.TECH3, f) then
                                fTier = 3
                            elseif EntityCategoryContains(categories.TECH2, f) then
                                fTier = 2
                            end
                            if fTier > curTier then
                                curTier = fTier
                                factory = f
                            end
                        end
                    end
                    if not factory then break end
                    aiBrain.OWPlusOutpostFactories[outpostKey] = factory

                    if curTier > lastTier then
                        LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, fabbrica salita a tier ' .. curTier
                            .. ', riassorbimento ingegneri tier ' .. lastTier)

                        -- Fase D-difese, crescita logaritmica (sess.86): il timer va resettato
                        -- QUI, subito al rilevamento, non dopo l'attesa di svuotamento coda piu'
                        -- sotto (sess.79, fino a 180s) — quell'attesa serve solo all'ordine del
                        -- reclaim (un meccanismo diverso), ma la sorveglianza crescita difese
                        -- (piu' sotto in questo file) rilegge il tier ATTIVO direttamente dalla
                        -- fabbrica fisica, non da questo blocco — se il reset restava dopo
                        -- l'attesa, per tutta la sua durata (fino a 3 minuti, bug reale osservato
                        -- in game) il tier veniva gia' letto come nuovo ma il timer restava
                        -- ancora quello del tier precedente, calcolando un tetto scorretto.
                        if OWPLUS_TIER_DEFENSES_ENABLED then
                            aiBrain.OWPlusOutpostTierTimer = aiBrain.OWPlusOutpostTierTimer or {}
                            aiBrain.OWPlusOutpostTierTimer[outpostKey] = GetGameTimeSeconds()
                            LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, timer crescita difese resettato per tier ' .. curTier)
                        end

                        -- Diagnostica sess.77 (quater): dump non-throttled dello stato reale di
                        -- FactoryManager.FactoryList nell'istante esatto del salto di tier, per
                        -- capire se la lista resta "sporca" (vecchia entita' morta ancora presente,
                        -- nuova entita' T-superiore mai aggiunta) — sospettato responsabile del
                        -- "buco nero": la valutazione builder Engineer/FactoryUpgrade per questa
                        -- location si ferma per sempre subito dopo ogni salto di tier osservato.
                        do
                            local diagRealLocType = aiBrain.OWPlusOutpostRealLocType and aiBrain.OWPlusOutpostRealLocType[outpostKey]
                            local diagMgr = diagRealLocType and aiBrain.BuilderManagers[diagRealLocType]
                            if diagMgr and diagMgr.FactoryManager and diagMgr.FactoryManager.FactoryList then
                                local diagCount = 0
                                local diagParts = {}
                                for _, diagF in diagMgr.FactoryManager.FactoryList do
                                    diagCount = diagCount + 1
                                    table.insert(diagParts, tostring(diagF.UnitId) .. '(Dead=' .. tostring(diagF.Dead)
                                        .. ',T3=' .. tostring(EntityCategoryContains(categories.TECH3, diagF))
                                        .. ',T2=' .. tostring(EntityCategoryContains(categories.TECH2, diagF)) .. ')')
                                end
                                LOG('[OWPlus-DIAG] Tier-up (' .. outpostKey .. ', manager="' .. tostring(diagRealLocType)
                                    .. '"): FactoryList contiene ' .. diagCount .. ' voci: ' .. table.concat(diagParts, ' | '))
                            else
                                LOG('[OWPlus-DIAG] Tier-up (' .. outpostKey .. '): manager/FactoryManager/FactoryList non trovato (realLocType="'
                                    .. tostring(diagRealLocType) .. '")')
                            end
                            -- Heartbeat 15s x 8 (120s totali): lo snapshot singolo sopra cattura
                            -- solo l'istante esatto — se il "buco nero" si manifesta qualche
                            -- secondo dopo (es. durante le ForkThread di riassorbimento/Fase C
                            -- che partono subito sotto), questo heartbeat lo mostra comunque.
                            ForkThread(function()
                                local diagTicks = 0
                                while diagTicks < 8 do
                                    WaitSeconds(15)
                                    diagTicks = diagTicks + 1
                                    local hbMgr = diagRealLocType and aiBrain.BuilderManagers[diagRealLocType]
                                    if hbMgr and hbMgr.FactoryManager and hbMgr.FactoryManager.FactoryList then
                                        local hbCount = 0
                                        local hbParts = {}
                                        for _, hbF in hbMgr.FactoryManager.FactoryList do
                                            hbCount = hbCount + 1
                                            -- Fix sess.77 (quinquies): estesa con IsUnitState('Upgrading'/'Building')
                                            -- e OWPlusUpgradeClaimed sulle entita' vive, per capire se gli Engineer
                                            -- builder restano bloccati per sempre da 'Upgrading' incollato a true su
                                            -- una fabbrica gia' al tier massimo (T3, nessun upgrade successivo
                                            -- possibile), o se il blocco ha un'altra causa.
                                            local hbExtra = ''
                                            if not hbF.Dead then
                                                hbExtra = ',Upgrading=' .. tostring(hbF:IsUnitState('Upgrading'))
                                                    .. ',Building=' .. tostring(hbF:IsUnitState('Building'))
                                                    .. ',Claimed=' .. tostring(hbF.OWPlusUpgradeClaimed)
                                            end
                                            table.insert(hbParts, tostring(hbF.UnitId) .. '(Dead=' .. tostring(hbF.Dead) .. hbExtra .. ')')
                                        end
                                        -- Fix sess.77 (quinquies): timestamp REALE dell'ultima valutazione
                                        -- della condizione, letto direttamente da OWPlusDebugLastLog (scritto
                                        -- ad OGNI chiamata della funzione, indipendentemente dal throttle sul
                                        -- LOG) — piu' affidabile di cercare righe di log throttled per capire
                                        -- SE e QUANDO il ciclo di valutazione builder per questa location si
                                        -- e' davvero fermato, invece di dedurlo dall'assenza di righe.
                                        local hbLastEval = aiBrain.OWPlusDebugLastLog
                                            and aiBrain.OWPlusDebugLastLog['IsOutpostLocation_' .. tostring(diagRealLocType)]
                                        local hbNow = GetGameTimeSeconds()
                                        local hbAgo = hbLastEval and (hbNow - hbLastEval) or nil
                                        LOG('[OWPlus-DIAG] Heartbeat +' .. (diagTicks * 15) .. 's (' .. outpostKey .. '): FactoryList = '
                                            .. hbCount .. ' voci: ' .. table.concat(hbParts, ' | ')
                                            .. ' -- ultima valutazione OWPlusIsOutpostLocation: ' .. tostring(hbAgo) .. 's fa')
                                    else
                                        LOG('[OWPlus-DIAG] Heartbeat +' .. (diagTicks * 15) .. 's (' .. outpostKey .. '): manager sparito!')
                                    end
                                end
                            end)
                        end
                        -- Fase D-difese, crescita logaritmica (sess.86): il blocco reclaim
                        -- generico sotto (sess.78/79/83 — aggiorna 1:1 OGNI vecchia difesa
                        -- generica del tier superato al tier nuovo, senza alcun tetto) e'
                        -- COMMENTATO su richiesta esplicita dell'utente — confermato in game
                        -- che "eredita" un numero di difese T3 ben oltre il tetto basso
                        -- iniziale del nuovo sistema di crescita (es. AA 7-12 contro tetto 2-5
                        -- appena saliti a tier 3), perche' i due meccanismi lavoravano in
                        -- parallelo con logiche indipendenti. Ora e' SOLO il tetto logaritmico
                        -- (watcher "sorveglianza crescita difese" piu' sotto) a decidere quante
                        -- difese di un tier esistono — le vecchie difese del tier precedente
                        -- restano ferme al loro tier per sempre (nessun aggiornamento
                        -- automatico), coerente col resto del design "additivo, mai distruttivo
                        -- ne' furtivo". Non cancellato, commentato come riferimento.
                        --[[
                        local oldTierCat = categories.TECH1
                        if lastTier == 2 then
                            oldTierCat = categories.TECH2
                        end
                        -- Fix sess.79 (bug di timing confermato in game): il tier-up a T3
                        -- scattava PRIMA che l'ondata di upgrade T1->T2 avesse finito di
                        -- trasformare fisicamente le difese — lo scan sotto (che cerca
                        -- strutture GIA' del tier vecchio) trovava zero candidati perche'
                        -- le difese erano ancora T1 (task 'reclaim' non ancora consumati
                        -- dal watcher), quindi nessun task T2->T3 veniva mai accodato.
                        -- Fix: attendere che la coda di questo avamposto sia vuota (ondata
                        -- precedente completata) prima di accodare la prossima — con un
                        -- tetto di sicurezza (180s) per non restare bloccati per sempre se
                        -- un task specifico continua a fallire.
                        local drainWaited = 0
                        while aiBrain.OWPlusOutpostPendingDefenses and aiBrain.OWPlusOutpostPendingDefenses[outpostKey]
                            and table.getn(aiBrain.OWPlusOutpostPendingDefenses[outpostKey]) > 0 and drainWaited < 180 do
                            WaitSeconds(5)
                            drainWaited = drainWaited + 5
                        end
                        if drainWaited > 0 then
                            LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, atteso ' .. drainWaited
                                .. 's svuotamento coda prima di accodare upgrade tier ' .. curTier)
                        end
                        -- Fix sess.78: riassorbimento ingegneri tier vecchio + Fase C reclaim
                        -- unificati nella stessa coda condivisa della Fase difese (vedi sopra).
                        -- Non serve piu' riassegnare esplicitamente gli ingegneri di tier
                        -- superato — il watcher periodico unico li ritrova comunque appena
                        -- diventano idle (nessuna lista dedicata). Qui ci limitiamo ad
                        -- accodare un task 'reclaim' per ogni difesa fisicamente trovata
                        -- ancora al tier vecchio: il retry-su-fallimento e la protezione
                        -- OWPlusOutpostBusy restano identici, gestiti dentro il watcher.
                        local oldDefenses = aiBrain:GetUnitsAroundPoint(
                            categories.STRUCTURE * categories.DEFENSE * oldTierCat - categories.SHIELD, outpostPos, 40, 'Ally') or {}
                        if table.getn(oldDefenses) > 0 then
                            aiBrain.OWPlusOutpostPendingDefenses = aiBrain.OWPlusOutpostPendingDefenses or {}
                            aiBrain.OWPlusOutpostPendingDefenses[outpostKey] = aiBrain.OWPlusOutpostPendingDefenses[outpostKey] or {}
                            local queue = aiBrain.OWPlusOutpostPendingDefenses[outpostKey]
                            local queuedCount = 0
                            local skippedModded = 0
                            for _, oldDef in oldDefenses do
                                if not oldDef.Dead then
                                    -- Fix sess.83: le difese modded con una versione MK2 nota
                                    -- (OWPlusModdedUpgradeFor) sono ora gestite dal builder
                                    -- nativo 'OWPlus Outpost Defense Upgrade' (upgrade in-place
                                    -- continuo, non un one-shot legato a questo scan) — escluse
                                    -- qui per non farle upgradare DUE volte in parallelo da due
                                    -- meccanismi diversi (nativo in-place vs reclaim custom).
                                    if OWPlusOutpostDefensePool.OWPlusModdedUpgradeFor(oldDef.UnitId) then
                                        skippedModded = skippedModded + 1
                                    else
                                        table.insert(queue, {
                                            action = 'reclaim',
                                            targetUnit = oldDef,
                                            newTier = curTier,
                                            isAA = EntityCategoryContains(categories.ANTIAIR, oldDef),
                                        })
                                        queuedCount = queuedCount + 1
                                    end
                                end
                            end
                            LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, ' .. queuedCount
                                .. ' difese tier ' .. lastTier .. ' aggiunte in coda per upgrade a tier ' .. curTier
                                .. ' (' .. skippedModded .. ' modded escluse, gestite dal builder nativo)')
                        end
                        ]]

                        lastTier = curTier
                    end
                end
                LOG('[OWPlus] Outpost (' .. outpostKey .. '): sorveglianza riassorbimento tier terminata (fabbrica assente/morta)')
            end)

            -- Fase D-difese, crescita logaritmica (sess.86): sorveglianza crescita
            -- difese. Ogni 60s rilegge il tier ATTIVO dalla fabbrica fisica (non un
            -- contatore locale — coerente col resto del file), calcola il tetto
            -- corrente (terra/AA/bonus, OWPlusGetTierDefenseTargets) dal timer di
            -- quel tier, conta fisicamente quante difese di quel tier/bonus esistono
            -- gia' vicino all'avamposto, e accoda solo la differenza mancante.
            -- Gestisce SOLO il tier attivo + il suo bonus — i tier gia' superati non
            -- vengono piu' rivalutati ne' riforniti (design confermato esplicitamente
            -- dall'utente: a fabbrica/ingegneri tier 3 niente nuove T1, solo T3
            -- principale + qualche T2 moddato bonus). Watcher persistente per
            -- l'intera vita dell'avamposto, stesso guard-loop degli altri watcher di
            -- questo blocco (OWPlusOutpostRealLocType[outpostKey]).
            if OWPLUS_TIER_DEFENSES_ENABLED then
                ForkThread(function()
                    while aiBrain.OWPlusOutpostRealLocType and aiBrain.OWPlusOutpostRealLocType[outpostKey] do
                        WaitSeconds(60)
                        local curFactory = aiBrain.OWPlusOutpostFactories and aiBrain.OWPlusOutpostFactories[outpostKey]
                        if curFactory and not curFactory.Dead then
                            local activeTier = 1
                            if EntityCategoryContains(categories.TECH3, curFactory) then
                                activeTier = 3
                            elseif EntityCategoryContains(categories.TECH2, curFactory) then
                                activeTier = 2
                            end
                            local tierStart = aiBrain.OWPlusOutpostTierTimer and aiBrain.OWPlusOutpostTierTimer[outpostKey]
                            if tierStart then
                                local elapsed = GetGameTimeSeconds() - tierStart
                                local groundTarget, aaTarget, bonusTarget, shieldTarget, artilleryTarget, tacticalMDTarget =
                                    OWPlusOutpostDefensePool.OWPlusGetTierDefenseTargets(activeTier, elapsed)

                                -- Fix Fase F (sess.88, richiesta esplicita utente): sostituisce lo
                                -- scan a raggio (GetUnitsAroundPoint) con l'iterazione sulla mappa
                                -- di appartenenza esplicita (OWPlusOutpostOwnership.lua). Motivo:
                                -- confermato su un test reale che avamposti consecutivi (passo 20
                                -- del generatore) cadono quasi sempre entro il raggio 40 usato dal
                                -- vecchio scan — ogni difesa veniva contata anche dall'avamposto
                                -- vicino, gonfiando entrambi i conteggi. La mappa contiene SOLO le
                                -- unita' che QUESTO avamposto ha costruito (tag scritto al momento
                                -- della costruzione, vedi i due punti 'build' piu' sotto in questo
                                -- file), quindi zero rischio di conteggio incrociato per
                                -- costruzione, non serve piu' nessuna esclusione di categoria
                                -- (ARTILLERY/ANTIMISSILE) a valle.
                                local tierCat = categories.TECH1
                                if activeTier == 3 then
                                    tierCat = categories.TECH3
                                elseif activeTier == 2 then
                                    tierCat = categories.TECH2
                                end
                                local bonusIds = OWPlusOutpostDefensePool.OWPlusGetBonusIdList(aiBrain, activeTier)
                                local groundCount, aaCount, bonusCount, shieldCount, artilleryCount, tacticalMDCount = 0, 0, 0, 0, 0, 0
                                for d, _ in OWPlusOutpostOwnership.OWPlusGetOwnedUnits(aiBrain, outpostKey) do
                                    local dId = string.lower(tostring(d.UnitId))
                                    local isBonus = false
                                    for _, bId in bonusIds do
                                        if dId == bId then isBonus = true end
                                    end
                                    if isBonus then
                                        bonusCount = bonusCount + 1
                                    elseif EntityCategoryContains(categories.ANTIMISSILE, d) then
                                        -- Fix Fase G (sess.88): ANTIMISSILE da solo NON basta a
                                        -- distinguere tattico da strategico — condividono la stessa
                                        -- categoria, si distinguono SOLO dal tier (confermato sui
                                        -- builder nativi Soriarn: 'ANTIMISSILE * TECH2' per il
                                        -- tattico, 'ANTIMISSILE * TECH3' per lo strategico).
                                        -- TECH2 = Missile Difesa Tattica, fa parte di un tetto a
                                        -- crescita come scudi/artiglieria. TECH3 = SMD, tiro unico
                                        -- (vedi piu' sotto), resta ignorata qui di proposito.
                                        -- Controllata PRIMA di SHIELD perche' almeno un candidato SMD
                                        -- (smp0080, Antares UEF) porta anche SHIELD insieme.
                                        if EntityCategoryContains(categories.TECH2, d) then
                                            tacticalMDCount = tacticalMDCount + 1
                                        end
                                    elseif EntityCategoryContains(categories.SHIELD, d) then
                                        if EntityCategoryContains(tierCat, d) then
                                            shieldCount = shieldCount + 1
                                        end
                                    elseif EntityCategoryContains(categories.ARTILLERY, d) then
                                        if EntityCategoryContains(tierCat, d) then
                                            artilleryCount = artilleryCount + 1
                                        end
                                    elseif EntityCategoryContains(tierCat, d) then
                                        if EntityCategoryContains(categories.ANTIAIR, d) then
                                            aaCount = aaCount + 1
                                        else
                                            groundCount = groundCount + 1
                                        end
                                    end
                                end

                                LOG('[OWPlus-DIAG] Outpost (' .. outpostKey .. '): sorveglianza crescita difese tier '
                                    .. activeTier .. ', elapsed=' .. math.floor(elapsed) .. 's — terra ' .. groundCount
                                    .. '/' .. groundTarget .. ', AA ' .. aaCount .. '/' .. aaTarget .. ', bonus '
                                    .. bonusCount .. '/' .. bonusTarget .. ', scudi ' .. shieldCount .. '/' .. shieldTarget
                                    .. ', artiglieria ' .. artilleryCount .. '/' .. artilleryTarget .. ', missile difesa tattica '
                                    .. tacticalMDCount .. '/' .. tacticalMDTarget)

                                aiBrain.OWPlusOutpostPendingDefenses = aiBrain.OWPlusOutpostPendingDefenses or {}
                                aiBrain.OWPlusOutpostPendingDefenses[outpostKey] = aiBrain.OWPlusOutpostPendingDefenses[outpostKey] or {}
                                local queue = aiBrain.OWPlusOutpostPendingDefenses[outpostKey]

                                local groundNeeded = math.max(0, groundTarget - groundCount)
                                local aaNeeded = math.max(0, aaTarget - aaCount)
                                if groundNeeded > 0 or aaNeeded > 0 then
                                    local missingGround, missingAA = OWPlusOutpostDefensePool.OWPlusPickTierMainline(
                                        aiBrain, activeTier, groundNeeded, aaNeeded)
                                    for _, t in missingGround do
                                        table.insert(queue, { action = 'build', unitType = t, tier = activeTier })
                                    end
                                    for _, t in missingAA do
                                        table.insert(queue, { action = 'build', unitType = t, tier = activeTier })
                                    end
                                end
                                local bonusNeeded = math.max(0, bonusTarget - bonusCount)
                                if bonusNeeded > 0 then
                                    local missingBonus = OWPlusOutpostDefensePool.OWPlusPickBonusDefenses(
                                        aiBrain, activeTier, bonusNeeded)
                                    for _, t in missingBonus do
                                        table.insert(queue, { action = 'build', unitType = t, tier = activeTier - 1 })
                                    end
                                end

                                -- Fase E (sess.88): scudi/artiglieria mancanti — stesso principio di
                                -- terra/AA sopra, ma con zone='inner' (il consumer piu' sotto in
                                -- questo file li piazza nell'anello protetto 3-10 invece
                                -- dell'anello perimetrale 10-18 di terra/AA) e un 'label' leggibile
                                -- per distinguerli nel log di successo/fallimento a valle (l'utente
                                -- verifica da remoto solo via log, non puo' guardare lo schermo).
                                local shieldNeeded = math.max(0, shieldTarget - shieldCount)
                                local artilleryNeeded = math.max(0, artilleryTarget - artilleryCount)
                                if shieldNeeded > 0 or artilleryNeeded > 0 then
                                    local missingShield, missingArtillery = OWPlusOutpostDefensePool.OWPlusPickTierShieldArtillery(
                                        aiBrain, activeTier, shieldNeeded, artilleryNeeded)
                                    for _, t in missingShield do
                                        table.insert(queue, { action = 'build', unitType = t, tier = activeTier, zone = 'inner', label = 'scudo' })
                                    end
                                    for _, t in missingArtillery do
                                        table.insert(queue, { action = 'build', unitType = t, tier = activeTier, zone = 'inner', label = 'artiglieria' })
                                    end
                                end

                                -- Fase G (sess.88): Missile Difesa Tattica mancante — stesso
                                -- principio di scudi/artiglieria sopra (crescita nel tempo, anello
                                -- interno, label per il log).
                                local tacticalMDNeeded = math.max(0, tacticalMDTarget - tacticalMDCount)
                                if tacticalMDNeeded > 0 then
                                    local missingTacticalMD = OWPlusOutpostDefensePool.OWPlusPickTacticalMissileDefense(
                                        aiBrain, activeTier, tacticalMDNeeded)
                                    for _, t in missingTacticalMD do
                                        table.insert(queue, { action = 'build', unitType = t, tier = activeTier, zone = 'inner', label = 'missile difesa tattica' })
                                    end
                                end

                                -- Fase E (sess.88): SMD — tiro unico quando l'avamposto raggiunge
                                -- tier 3, mai ripetuto (flag dedicato OWPlusOutpostSMDRolled, per
                                -- avamposto — coerente con la decisione esplicita dell'utente "il
                                -- numero resta quello per il resto della partita"). Stessa coda/
                                -- consumer di tutto il resto, zone='inner' come scudi/artiglieria.
                                aiBrain.OWPlusOutpostSMDRolled = aiBrain.OWPlusOutpostSMDRolled or {}
                                if activeTier >= 3 and not aiBrain.OWPlusOutpostSMDRolled[outpostKey] then
                                    aiBrain.OWPlusOutpostSMDRolled[outpostKey] = true
                                    local smdCount = OWPlusOutpostDefensePool.OWPlusRollSMDCount()
                                    if smdCount > 0 then
                                        local missingSMD = OWPlusOutpostDefensePool.OWPlusPickSMD(aiBrain, smdCount)
                                        for _, t in missingSMD do
                                            table.insert(queue, { action = 'build', unitType = t, tier = activeTier, zone = 'inner', label = 'SMD' })
                                        end
                                    end
                                    LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, tiro SMD eseguito (una tantum, tier '
                                        .. activeTier .. ') -> ' .. smdCount .. ' antimissili strategici aggiunti in coda')
                                end

                                -- Fase H (sess.88): lanciamissili strategico offensivo — stesso
                                -- principio dell'SMD sopra (tiro unico a tier 3, flag dedicato
                                -- separato, mai ripetuto), zone='inner' come tutte le categorie
                                -- speciali.
                                aiBrain.OWPlusOutpostStrategicMissileRolled = aiBrain.OWPlusOutpostStrategicMissileRolled or {}
                                if activeTier >= 3 and not aiBrain.OWPlusOutpostStrategicMissileRolled[outpostKey] then
                                    aiBrain.OWPlusOutpostStrategicMissileRolled[outpostKey] = true
                                    local strategicMissileCount = OWPlusOutpostDefensePool.OWPlusRollStrategicMissileCount()
                                    if strategicMissileCount > 0 then
                                        local missingStrategicMissile = OWPlusOutpostDefensePool.OWPlusPickStrategicMissile(aiBrain, strategicMissileCount)
                                        for _, t in missingStrategicMissile do
                                            table.insert(queue, { action = 'build', unitType = t, tier = activeTier, zone = 'inner', label = 'lanciamissili strategico' })
                                        end
                                    end
                                    LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, tiro lanciamissili strategico eseguito (una tantum, tier '
                                        .. activeTier .. ') -> ' .. strategicMissileCount .. ' lanciamissili aggiunti in coda')
                                end

                                if groundNeeded > 0 or aaNeeded > 0 or bonusNeeded > 0 or shieldNeeded > 0 or artilleryNeeded > 0 or tacticalMDNeeded > 0 then
                                    LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, crescita difese tier ' .. activeTier
                                        .. ' — aggiunte in coda ' .. groundNeeded .. ' terra, ' .. aaNeeded .. ' AA, '
                                        .. bonusNeeded .. ' bonus tier ' .. (activeTier - 1) .. ', ' .. shieldNeeded
                                        .. ' scudi, ' .. artilleryNeeded .. ' artiglieria, ' .. tacticalMDNeeded
                                        .. ' missile difesa tattica')
                                end
                            end
                        end
                    end
                end)
            end

            -- Fix orfano fabbrica avamposto (sess.72): confermato in dev.log (100%
            -- riproducibile su ogni avamposto osservato) che la fabbrica di un
            -- avamposto puo' sparire dal FactoryList del suo BuilderManager (es. dopo
            -- un upgrade — il motore distrugge l'unita' vecchia e ne crea una nuova
            -- alla stessa posizione, comportamento normale per l'upgrade di una
            -- struttura) senza che nulla ri-registri la nuova entita': l'avamposto
            -- resta con fabbrica fisicamente presente ma invisibile a
            -- OWPlusOutpostFactoryIsTech per il resto della partita — "costruito ma
            -- fermo". Stesso pattern di recupero che Uveso usa per le fabbriche navali
            -- disperse (LocationRangeManagerThread, aiarchetype-managerloader.lua:
            -- "no factory manager?" -> AddFactoryToClosestManager), qui applicato
            -- puntualmente alla posizione nota dell'avamposto invece che a scansione
            -- globale su tutte le unita' dell'esercito.
            ForkThread(function()
                WaitSeconds(30)
                local emptyStreak = 0
                while aiBrain.OWPlusOutpostRealLocType and aiBrain.OWPlusOutpostRealLocType[outpostKey] do
                    local realLocType = aiBrain.OWPlusOutpostRealLocType[outpostKey]
                    local mgr = aiBrain.BuilderManagers[realLocType]
                    if not mgr or not mgr.FactoryManager then
                        -- Fix sess.77: non e' solo la ENTRY nel FactoryList a poter sparire —
                        -- puo' sparire il MANAGER stesso. DeadBaseMonitor (base-ai.lua, vedi
                        -- Conoscenze_AI regola 19) distrugge ogni BuilderManager non-MAIN privo
                        -- di ingegneri/fabbriche ogni 5s: durante un upgrade fabbrica esiste una
                        -- finestra reale (vecchia entita' gia' .Dead, nuova non ancora
                        -- ri-registrata) in cui puo' scattare. Diagnostica dedicata (sess.77,
                        -- dump FactoryList al salto di tier + heartbeat 15s) ha confermato: il
                        -- manager risultava sparito esattamente al tier-up e mai piu' tornato —
                        -- root cause reale del "buco nero" post tier-up inseguito per tutta la
                        -- sessione. Fix: invece di arrendersi (vecchio comportamento: break),
                        -- ri-registrare da zero la fabbrica fisicamente ancora viva alla
                        -- posizione nota, stesso identico percorso della PRIMA adozione (Fase
                        -- 9-F19/20 piu' sopra in questo file).
                        local rescueCandidates = aiBrain:GetUnitsAroundPoint(
                            categories.STRUCTURE * categories.FACTORY, outpostPos, 20, 'Ally') or {}
                        local rescueFactory
                        for _, cand in rescueCandidates do
                            -- Fix sess.84 (bug reale confermato in game): il vecchio codice
                            -- prendeva il primo candidato non-morto senza verificarne la
                            -- provenienza — per un avamposto vicino a MAIN (es. 90 unita') questo
                            -- ha strappato a MAIN una vera Support Factory T3 (ZEB9601, capace di
                            -- costruire unita' mobili T3 in autonomia via il proprio
                            -- BuildableCategory) semplicemente perche' si trovava nel raggio di
                            -- 20 unita'. Due esclusioni mirate: (a) categories.SUPPORTFACTORY —
                            -- la nostra ricetta avamposto non produce MAI questa categoria
                            -- direttamente, una struttura cosi' trovata qui e' sempre una
                            -- compagna di UN'ALTRA fabbrica (quasi certamente di MAIN), mai la
                            -- nostra; (b) candidato gia' assegnato al manager 'MAIN' — MAIN non
                            -- va mai considerato "orfano" nel senso in cui lo sono i nostri
                            -- avamposti, quindi una sua struttura non va mai rivendicata qui.
                            local candIsSupportFactory = EntityCategoryContains(categories.SUPPORTFACTORY, cand)
                            local candBelongsToMain = cand.BuilderManagerData and cand.BuilderManagerData.FactoryBuildManager
                                and cand.BuilderManagerData.FactoryBuildManager.LocationType == 'MAIN'
                            if not cand.Dead and not candIsSupportFactory and not candBelongsToMain
                                and OWPlusFactoryBelongsToOutpost(aiBrain, cand, outpostKey) then
                                rescueFactory = cand
                                break
                            end
                        end
                        if rescueFactory then
                            -- Come nella prima adozione (Fase 9-F19/20): la fabbrica potrebbe
                            -- essere gia' stata auto-assegnata al manager di MAIN dal motore
                            -- (comportamento nativo quando nessun manager dedicato la reclama) —
                            -- va staccata esplicitamente prima di AddFactoryToClosestManager,
                            -- altrimenti il guard 'if not v.BuilderManagerData' di vanilla la
                            -- ignora e resta assegnata a MAIN.
                            if rescueFactory.BuilderManagerData and rescueFactory.BuilderManagerData.FactoryBuildManager then
                                local rescueOldLocType = rescueFactory.BuilderManagerData.FactoryBuildManager.LocationType
                                for k, v in rescueFactory.BuilderManagerData.FactoryBuildManager.FactoryList do
                                    if v == rescueFactory then
                                        rescueFactory.BuilderManagerData.FactoryBuildManager.FactoryList[k] = nil
                                    end
                                end
                                -- Fix sess.77 (quater): rimuovere la fabbrica dalla FactoryList del
                                -- vecchio manager NON basta — SetupFactoryCallbacks (vanilla,
                                -- FactoryBuilderManager.lua) registra i trigger "fabbrica ha finito
                                -- di costruire, chiedi il prossimo ordine" SOLO se
                                -- unit.BuilderManagerData e' nil in quel momento. Senza azzerarlo
                                -- qui, quei trigger restano legati per sempre al VECCHIO manager
                                -- (i loro closure catturano il vecchio 'self') anche se la fabbrica
                                -- compare correttamente nella FactoryList del manager giusto —
                                -- spiega perche' una prima valutazione poteva riuscire per caso ma
                                -- nessun ordine successivo veniva mai richiesto.
                                rescueFactory.BuilderManagerData = nil
                                LOG('[OWPlus] Outpost (' .. outpostKey .. '): fabbrica di recupero (' .. tostring(rescueFactory.UnitId)
                                    .. ') staccata dal manager "' .. tostring(rescueOldLocType) .. '"')
                            end
                            -- Fix sess.78: diagnostica in game (hook DelayBuildOrder,
                            -- FactoryBuilderManager.lua) ha confermato che rescueFactory.DelayThread
                            -- puo' risultare gia' 'true' in questo istante (residuo del vecchio
                            -- manager o di un'altra catena di retry in corso) — con quel mutex
                            -- bloccato, sia il fork automatico di AddFactory sia la nostra chiamata
                            -- esplicita di AssignBuildOrder poco sotto si annullano in silenzio senza
                            -- pianificare nessun retry, lasciando la fabbrica orfana per sempre.
                            -- Reset esplicito per garantire un punto di partenza pulito.
                            rescueFactory.DelayThread = nil
                            -- Fix sess.83: stesso bypass della PRIMA adozione (vedi sopra in
                            -- questo file) — manager dedicato creato/riusato direttamente su
                            -- outpostKey/outpostPos, mai piu' affidato alla ricerca "marker piu'
                            -- vicino" di AddFactoryToClosestManager (stesso rischio di merge con
                            -- MAIN se l'avamposto e' nel suo raggio attuale). outpostKey resta
                            -- la chiave del manager per l'intera vita dell'avamposto, anche
                            -- attraverso un recupero come questo.
                            if not aiBrain.BuilderManagers[outpostKey] then
                                if not Scenario.MasterChain._MASTERCHAIN_.Markers[outpostKey] then
                                    Scenario.MasterChain._MASTERCHAIN_.Markers[outpostKey] = {
                                        color = 'fff4a460',
                                        hint = true,
                                        orientation = { 0, 0, 0 },
                                        prop = "/env/common/props/markers/M_Expansion_prop.bp",
                                        type = 'Expansion Area',
                                        position = outpostPos,
                                    }
                                end
                                aiBrain:AddBuilderManagers(outpostPos, 100, outpostKey, true)
                            end
                            aiBrain.BuilderManagers[outpostKey].FactoryManager:AddFactory(rescueFactory)
                            rescueFactory.lost = nil
                            local newRealLocType = outpostKey
                            if newRealLocType then
                                aiBrain.OWPlusOutpostLocationTypes[newRealLocType] = true
                                aiBrain.OWPlusOutpostRealLocType[outpostKey] = newRealLocType
                                -- Fase D1 (B24): il tipo va assegnato anche in questo percorso di
                                -- recupero — OWPlusAssignOutpostType non riassegna se gia' presente.
                                -- Fix (sess.90): vedi nota nel blocco "registrazione anticipata" sopra.
                                local OWPlusLogConditionsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua')
                                OWPlusLogConditionsMod.OWPlusAssignOutpostType(aiBrain, newRealLocType)

                                -- Fase D3 (B24): vedi nota nel blocco "registrazione anticipata" sopra.
                                aiBrain.OWPlusOutpostFoundedAt = aiBrain.OWPlusOutpostFoundedAt or {}
                                if not aiBrain.OWPlusOutpostFoundedAt[newRealLocType] then
                                    aiBrain.OWPlusOutpostFoundedAt[newRealLocType] = GetGameTimeSeconds()
                                    OWPlusOutpostAttackWatcher(aiBrain, newRealLocType)
                                end
                                local OWPlusAddBuilderTable = import('/lua/ai/AIAddBuilderTable.lua')
                                OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, newRealLocType, 'OWPlus Outpost Engineer Builders')
                                OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, newRealLocType, 'OWPlus Outpost Factory Upgrade')
                                OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, newRealLocType, 'OWPlus Outpost Defense Upgrade')
                                OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, newRealLocType, 'OWPlus Outpost Production')
                                -- Sess.100 parte 9: produzione aerea (vedi sopra, registrazione anticipata).
                                OWPlusAddBuilderTable.AddGlobalBuilderGroup(aiBrain, newRealLocType, 'OWPlus Outpost Air Production')
                                LOG('[OWPlus-FACTORY] Outpost: ' .. tostring(newRealLocType) .. ' — agganciato gruppo produzione aria (recupero manager)')
                                -- Fix sess.77 (septies): stessa rete di sicurezza del ramo
                                -- "fabbrica orfana" poco sotto — chiamata diretta ed esplicita a
                                -- AssignBuildOrder, indipendente da cosa AddFactoryToClosestManager
                                -- abbia deciso internamente.
                                local rescueBType2 = 'Land'
                                if EntityCategoryContains(categories.AIR, rescueFactory) then
                                    rescueBType2 = 'Air'
                                elseif EntityCategoryContains(categories.NAVAL, rescueFactory) then
                                    rescueBType2 = 'Sea'
                                end
                                aiBrain.BuilderManagers[newRealLocType].FactoryManager:AssignBuildOrder(rescueFactory, rescueBType2)
                                -- Fix sess.78 (bis): la rete di sicurezza "usa e getta" a 5s qui
                                -- (rimossa) copriva solo la collisione DelayThread al riaggancio, ma
                                -- confermato in game (dev.log) che la stessa collisione puo' ripetersi
                                -- in QUALUNQUE momento della partita, anche durante il normale
                                -- funzionamento (es. dopo che FactoryFinishBuilding richiede il
                                -- prossimo ordine e AssignBuildOrder fallisce quel tick) — sostituita
                                -- da un watcher persistente per l'intera vita dell'avamposto, vedi
                                -- "sorveglianza continua ordine di build" piu' sotto.
                                aiBrain.OWPlusOutpostFactories = aiBrain.OWPlusOutpostFactories or {}
                                aiBrain.OWPlusOutpostFactories[outpostKey] = rescueFactory
                                LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, manager sparito (DeadBaseMonitor) — ricreato e riagganciato con chiave "' .. newRealLocType .. '"')
                                emptyStreak = 0
                            else
                                -- Irraggiungibile dalla sess.83 (newRealLocType = outpostKey,
                                -- sempre impostato) — lasciato come rete di sicurezza silenziosa.
                                LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): manager sparito, creazione manager di recupero fallita in modo imprevisto')
                                break
                            end
                        else
                            emptyStreak = emptyStreak + 20
                            if emptyStreak >= 300 then
                                LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): manager sparito e nessuna fabbrica viva/recuperabile per 300s consecutivi, sorveglianza terminata')
                                break
                            end
                        end
                    else
                        local aliveCount = 0
                        if mgr.FactoryManager.FactoryList then
                            for _, f in mgr.FactoryManager.FactoryList do
                                if not f.Dead then
                                    aliveCount = aliveCount + 1
                                end
                            end
                        end

                        if aliveCount == 0 then
                            local candidates = aiBrain:GetUnitsAroundPoint(
                                categories.STRUCTURE * categories.FACTORY, outpostPos, 20, 'Ally') or {}
                            local rescued = false
                            for _, cand in candidates do
                                -- Fix sess.84 (bug reale confermato in game): il presupposto del
                                -- commento storico sotto ("qualunque candidato trovato qui e'
                                -- SEMPRE la nostra fabbrica auto-assegnata a MAIN") si e' rivelato
                                -- falso per un avamposto vicino a MAIN (90 unita') — lo scan ha
                                -- strappato a MAIN una vera Support Factory T3 (ZEB9601, capace di
                                -- costruire unita' mobili T3 in autonomia). Stesse due esclusioni
                                -- del ramo "manager sparito" qui sopra: mai una SUPPORTFACTORY (la
                                -- nostra ricetta non ne produce mai direttamente), mai un
                                -- candidato gia' assegnato al manager 'MAIN' (mai da considerare
                                -- "orfano" nel nostro senso).
                                local candIsSupportFactory = EntityCategoryContains(categories.SUPPORTFACTORY, cand)
                                local candBelongsToMain = cand.BuilderManagerData and cand.BuilderManagerData.FactoryBuildManager
                                    and cand.BuilderManagerData.FactoryBuildManager.LocationType == 'MAIN'
                                if not cand.Dead and not candIsSupportFactory and not candBelongsToMain
                                    and OWPlusFactoryBelongsToOutpost(aiBrain, cand, outpostKey) then
                                    -- Fix sess.77 (bis): 'not cand.BuilderManagerData' non scattava
                                    -- mai — confermato in game (diagnostica dedicata): la nuova
                                    -- fabbrica T-superiore NON resta orfana dopo un upgrade, il
                                    -- motore la auto-assegna a un manager esistente (tipicamente
                                    -- MAIN, stesso comportamento gia' noto dalla PRIMA adozione,
                                    -- Fase 9-F19/20 piu' sopra) — quindi ha SEMPRE BuilderManagerData
                                    -- non-nil, solo puntato al manager sbagliato. Va staccata
                                    -- esplicitamente da quel manager (stesso identico pattern della
                                    -- 9-F19/20) prima di AddFactory, non solo aggiunta se libera.
                                    if cand.BuilderManagerData and cand.BuilderManagerData.FactoryBuildManager
                                        and cand.BuilderManagerData.FactoryBuildManager ~= mgr.FactoryManager then
                                        local candOldLocType = cand.BuilderManagerData.FactoryBuildManager.LocationType
                                        for k, v in cand.BuilderManagerData.FactoryBuildManager.FactoryList do
                                            if v == cand then
                                                cand.BuilderManagerData.FactoryBuildManager.FactoryList[k] = nil
                                            end
                                        end
                                        -- Fix sess.77 (quater): rimuovere dalla FactoryList del vecchio
                                        -- manager NON basta — SetupFactoryCallbacks (vanilla,
                                        -- FactoryBuilderManager.lua) registra i trigger "fabbrica ha
                                        -- finito di costruire, chiedi il prossimo ordine" SOLO se
                                        -- unit.BuilderManagerData e' nil in quel momento. Letto il
                                        -- codice vanilla: senza azzerarlo qui, quei trigger restano
                                        -- legati per sempre al VECCHIO manager (closure che cattura il
                                        -- vecchio 'self'), anche se la fabbrica compare correttamente
                                        -- nella FactoryList del manager giusto — root cause reale del
                                        -- "condizioni verdi ma fabbrica ferma dopo il primo ordine".
                                        cand.BuilderManagerData = nil
                                        LOG('[OWPlus] Outpost (' .. outpostKey .. '): fabbrica (' .. tostring(cand.UnitId)
                                            .. ') staccata dal manager "' .. tostring(candOldLocType) .. '"')
                                    end
                                    -- Diagnostica sess.78 (confermata in game): ipotesi (b) e' quella
                                    -- reale — cand.DelayThread risulta gia' 'true' PRIMA ancora che
                                    -- AddFactory venga chiamato (log pre-AddFactory sotto, invariati
                                    -- come sorveglianza), quindi sia il fork automatico di AddFactory
                                    -- sia la nostra chiamata esplicita di AssignBuildOrder poco sotto
                                    -- si annullano in silenzio senza pianificare nessun retry —
                                    -- root cause reale della fabbrica T3 ferma per sempre.
                                    local diagAlreadyInList = false
                                    for _, diagExisting in mgr.FactoryManager.FactoryList do
                                        if diagExisting == cand then diagAlreadyInList = true end
                                    end
                                    LOG('[OWPlus-DIAG] Outpost (' .. outpostKey .. '): pre-AddFactory fabbrica orfana ('
                                        .. tostring(cand.UnitId) .. '): gia_in_FactoryList=' .. tostring(diagAlreadyInList)
                                        .. ', DelayThread=' .. tostring(cand.DelayThread))
                                    -- Fix sess.78: reset esplicito per garantire un punto di partenza
                                    -- pulito ad AddFactory e alla chiamata esplicita poco sotto.
                                    cand.DelayThread = nil
                                    mgr.FactoryManager:AddFactory(cand)
                                    LOG('[OWPlus-DIAG] Outpost (' .. outpostKey .. '): post-AddFactory (' .. tostring(cand.UnitId)
                                        .. '): DelayThread=' .. tostring(cand.DelayThread))
                                    -- Fix sess.77 (septies): confermato in game (hook diagnostico
                                    -- gia' esistente su AssignBuildOrder, sess.73) — dopo un
                                    -- riaggancio "a freddo" la catena nativa che chiede "cosa
                                    -- costruire" (SetupNewFactory -> DelayBuildOrder ->
                                    -- AssignBuildOrder) a volte non parte MAI: zero righe di log
                                    -- dell'hook per l'intera restante durata della partita, non
                                    -- "chiamata ma nessun builder trovato". Sospetto: AddFactory
                                    -- vanilla ha un guard 'FactoryAlreadyExists' che, se la
                                    -- fabbrica risulta gia' presente nella FactoryList per altra
                                    -- via, salta silenziosamente l'intera configurazione (incluso
                                    -- il fork di DelayBuildOrder). Chiamata diretta ed esplicita
                                    -- come rete di sicurezza, indipendente da cosa abbia deciso
                                    -- AddFactory internamente — stesso bType che vanilla stesso
                                    -- avrebbe determinato (i nostri avamposti sono sempre Land).
                                    local rescueBType = 'Land'
                                    if EntityCategoryContains(categories.AIR, cand) then
                                        rescueBType = 'Air'
                                    elseif EntityCategoryContains(categories.NAVAL, cand) then
                                        rescueBType = 'Sea'
                                    end
                                    mgr.FactoryManager:AssignBuildOrder(cand, rescueBType)
                                    LOG('[OWPlus-DIAG] Outpost (' .. outpostKey .. '): post-AssignBuildOrder esplicito ('
                                        .. tostring(cand.UnitId) .. '): DelayThread=' .. tostring(cand.DelayThread))
                                    -- Fix sess.78 (bis): la rete di sicurezza "usa e getta" a 5s qui
                                    -- (rimossa) copriva solo la collisione DelayThread al riaggancio, ma
                                    -- confermato in game (dev.log) che la stessa collisione puo'
                                    -- ripetersi in QUALUNQUE momento della partita, anche durante il
                                    -- normale funzionamento — sostituita da un watcher persistente per
                                    -- l'intera vita dell'avamposto, vedi "sorveglianza continua ordine
                                    -- di build" piu' sotto.
                                    cand.lost = nil
                                    aiBrain.OWPlusOutpostFactories = aiBrain.OWPlusOutpostFactories or {}
                                    aiBrain.OWPlusOutpostFactories[outpostKey] = cand
                                    LOG('[OWPlus] Outpost (' .. outpostKey .. '): fabbrica orfana (' .. tostring(cand.UnitId)
                                        .. ') trovata e riagganciata al manager "' .. realLocType .. '"')
                                    rescued = true
                                    emptyStreak = 0
                                    break
                                end
                            end
                            if not rescued then
                                emptyStreak = emptyStreak + 20
                                if emptyStreak >= 300 then
                                    LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): nessuna fabbrica viva/recuperabile per 300s consecutivi, sorveglianza orfani terminata (probabile distruzione reale, gestita dalla 9-F22)')
                                    break
                                end
                            end
                        else
                            emptyStreak = 0
                        end
                    end

                    WaitSeconds(20)
                end
            end)

            -- Fix sess.78: sorveglianza unificata difese/guardia. Sostituisce questo
            -- watcher (Fase A: assist fabbrica di default) insieme al vecchio ciclo
            -- "Fase difese" (sopra) e al riassorbimento ingegneri/Fase C reclaim
            -- (dentro la sorveglianza tier piu' sotto) — 4 sistemi indipendenti che
            -- competevano per gli stessi ingegneri liberi, causando furti/blocchi
            -- intermittenti (difesa costruita 1-3 volte poi "si pianta": un altro
            -- sistema si portava via l'ingegnere a meta' lista). Ora un solo ciclo:
            -- ogni ingegnere non impegnato in costruzione/spostamento (guardia
            -- inclusa, che non ha "coda" da perdere se interrotta) sceglie dalla coda
            -- condivisa aiBrain.OWPlusOutpostPendingDefenses[outpostKey] il task di
            -- tier piu' alto che sa fare (mai spreca un T3 su un T1 se c'e' anche un
            -- T2/T3 da fare); altrimenti va di guardia alla fabbrica. "Controlla coda
            -- -> rimuovi elemento" senza WaitSeconds in mezzo e' atomico in questo
            -- motore (thread cooperativi, nessuna prelazione a meta' blocco) — nessun
            -- sistema di prenotazione necessario, i doppioni sono tollerati (confermato
            -- dall'utente: costruire/reclamare due volte la stessa cosa non e' un
            -- problema pratico).
            ForkThread(function()
                local waitReg = 0
                while not (aiBrain.OWPlusOutpostRealLocType and aiBrain.OWPlusOutpostRealLocType[outpostKey]) and waitReg < 300 do
                    WaitSeconds(5)
                    waitReg = waitReg + 5
                end
                LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, avviata sorveglianza unificata difese/guardia')
                local factionLookup = { UEF = 1, AEON = 2, CYBRAN = 3, SERAPHIM = 4, NOMADS = 5 }
                while aiBrain.OWPlusOutpostRealLocType and aiBrain.OWPlusOutpostRealLocType[outpostKey] do
                    WaitSeconds(10)
                    local queue = aiBrain.OWPlusOutpostPendingDefenses and aiBrain.OWPlusOutpostPendingDefenses[outpostKey]
                    local curFactory = aiBrain.OWPlusOutpostFactories and aiBrain.OWPlusOutpostFactories[outpostKey]
                    -- Fix Fase G (sess.93): sostituisce lo scan geometrico (raggio 30,
                    -- categories.MOBILE * categories.ENGINEER) con l'ownership esplicita
                    -- kind=Engineer (OWPlusOutpostOwnership.lua) — stesso principio della
                    -- Fase F/sess.88 per le strutture. Il generatore avamposti piazza a
                    -- passi di 20, quindi avamposti consecutivi cadono spesso entro
                    -- raggio 30 l'uno dall'altro: lo scan geometrico contava anche
                    -- ingegneri di un avamposto vicino (o non ancora assegnati), fino a
                    -- 18-21 "liberi" per un solo avamposto osservati in un test da 15
                    -- minuti (tetto di progetto: 5). Resta un array numerico (invariato
                    -- 'for _, e in nearbyEngs do' piu' sotto).
                    local nearbyEngs = {}
                    for unit, _ in OWPlusOutpostOwnership.OWPlusGetOwnedUnits(aiBrain, outpostKey,
                        OWPlusOutpostOwnership.OWPlusOwnershipKindEngineer) do
                        table.insert(nearbyEngs, unit)
                    end
                    -- Sess.99 (diagnostica temporanea, fix desync): verifica in game che
                    -- la sequenza EntityId di nearbyEngs sia IDENTICA su ogni client allo
                    -- stesso beat -- prima del fix (chiavi-unit, ordine non garantito)
                    -- poteva differire tra client; dopo il fix (OWPlusGetOwnedUnits ordina
                    -- per EntityId) deve essere sempre la stessa sequenza ovunque. Da
                    -- rimuovere/mettere dietro throttle dopo la conferma.
                    local nearbyEngsIds = {}
                    for _, eng in nearbyEngs do
                        table.insert(nearbyEngsIds, tostring(eng:GetEntityId()))
                    end
                    LOG('[OWPlus-DIAG] Sorveglianza unificata (' .. outpostKey .. '): nearbyEngs ordine EntityId=[' .. table.concat(nearbyEngsIds, ',') .. ']')
                    -- Diagnostica sess.78 (sexies, temporanea): nessun task viene mai
                    -- preso in carico nonostante la coda venga popolata correttamente
                    -- alla nascita/tier-up (log "aggiunte in coda" confermato) — tutti
                    -- gli ingegneri finiscono sempre in guardia. LOG per capire se la
                    -- coda risulta vuota/nil in questo punto, o se il problema e'
                    -- altrove (tier ingegnere, eligibilita', ecc.).
                    LOG('[OWPlus-DIAG] Sorveglianza unificata (' .. outpostKey .. '): queue='
                        .. tostring(queue ~= nil) .. ', len=' .. tostring(queue and table.getn(queue))
                        .. ', nearbyEngs=' .. table.getn(nearbyEngs))

                    -- Fix sess.92 (richiesta esplicita utente): la costruzione iniziale
                    -- delle difese non aveva alcun controllo economico, a differenza
                    -- dell'upgrade (OWPlusDebugEconStorageRatio, gia' usato da 'OWPlus
                    -- Outpost Defense Upgrade.lua'). Riusiamo la stessa funzione/soglia
                    -- (0.15) qui: se i magazzini sono sotto soglia, azzeriamo la lista
                    -- di ingegneri liberi per questo giro cosi' nessuno pesca un nuovo
                    -- task dalla coda — restano di guardia (stesso comportamento gia'
                    -- esistente quando pickedIdx e' nil), nessuna modifica al
                    -- parallelismo quando l'economia lo permette.
                    local OWPlusLogConditionsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua')
                    if not OWPlusLogConditionsMod.OWPlusDebugEconStorageRatio(aiBrain, 0.15, 0.15, 'Outpost Defense Construction ' .. outpostKey) then
                        nearbyEngs = {}
                    end

                    for _, e in nearbyEngs do
                        -- Fix sess.87: 'Reclaiming' mancava — un ingegnere che sta reclamando
                        -- detriti (es. un relitto enorme sulla posizione di build, che il
                        -- motore fa reclamare prima di costruire) non e' ne' 'Building' ne'
                        -- 'Moving', quindi risultava "libero" a questo scan e veniva
                        -- riassegnato altrove — IssueClearCommands nel ramo scelto cancellava
                        -- il reclaim in corso. Confermato dall'utente in game (ingegnere
                        -- interrotto mentre reclamava un relitto Aeon Czar).
                        if not e.Dead and not e:IsUnitState('Building') and not e:IsUnitState('Moving') and not e:IsUnitState('Reclaiming') then
                            local engTier = 1
                            if EntityCategoryContains(categories.TECH3, e) then
                                engTier = 3
                            elseif EntityCategoryContains(categories.TECH2, e) then
                                engTier = 2
                            end
                            -- Passo A: task di tier piu' alto che questo ingegnere sa fare
                            local pickedIdx, pickedTier
                            if queue then
                                for idx, item in queue do
                                    local itemTier = item.tier or item.newTier
                                    if itemTier <= engTier and (not pickedTier or itemTier > pickedTier) then
                                        pickedIdx = idx
                                        pickedTier = itemTier
                                    end
                                end
                            end
                            if pickedIdx then
                                -- Passo B: rimozione atomica (nessun WaitSeconds prima di qui)
                                local task = queue[pickedIdx]
                                table.remove(queue, pickedIdx)
                                -- Sess.99 (diagnostica temporanea, fix desync): quale ingegnere
                                -- (per EntityId, non UnitId -- serve l'istanza esatta) ha pescato
                                -- quale task -- verificare in game che sia identico su ogni
                                -- client per lo stesso tick.
                                LOG('[OWPlus-DIAG] Sorveglianza unificata (' .. outpostKey .. '): ingegnere EntityId='
                                    .. tostring(e:GetEntityId()) .. ' pesca task tier=' .. tostring(pickedTier))
                                e.OWPlusOutpostGuardTarget = nil
                                e.OWPlusOutpostBusy = true
                                IssueClearCommands({e})
                                -- Fix sess.78 (octies): diagnostica confermata dal log — 'e' arrivava
                                -- nil (UnitId/Dead/PlatoonHandle tutti nil) dentro il ForkThread, mentre
                                -- 'task' (locale dichiarata qui sopra) arrivava sempre corretta. La
                                -- differenza e' che 'e' e' la variabile di controllo del ciclo
                                -- 'for _, e in nearbyEngs do': in questo motore ForkThread non esegue
                                -- in modo sincrono, quindi per quando la closure gira il ciclo esterno
                                -- e' gia' andato avanti (o terminato) e la closure vede il valore
                                -- "svuotato" della variabile di loop, non lo snapshot dell'iterazione
                                -- in cui e' stata creata. Fix: passare 'e'/'task' come argomenti
                                -- espliciti di ForkThread (valutati subito, non tramite closure) — i
                                -- parametri della funzione hanno di proposito lo stesso nome, cosi'
                                -- fanno shadow delle variabili esterne senza dover rinominare nulla
                                -- nel corpo sottostante.
                                ForkThread(function(e, task)
                                    local success = false
                                    if task.action == 'build' then
                                        -- Fix sess.79: raggio ridotto da 20-40 a 10-18, poi a 7-15
                                        -- (sess.79 bis, l'utente lo voleva ancora piu' vicino dopo il
                                        -- test). Confermato dall'utente in game: con distanza fino a 40
                                        -- le difese finivano FUORI dal raggio di rilevamento ingegneri
                                        -- liberi (30, vedi 'nearbyEngs' piu' sopra) — un ingegnere che
                                        -- finiva di costruire li' diventava invisibile al watcher e
                                        -- veniva "perso" (riassorbito altrove). 7-15 resta ben dentro il
                                        -- raggio 30 con ampio margine.
                                        -- Fix Fase E (sess.88, richiesta esplicita utente): anello
                                        -- riportato a 10-18 per terra/AA (era stato stretto a 7-15 in
                                        -- sess.79-bis per preferenza, non per un bug — resta comunque
                                        -- ben dentro il raggio 30 di rilevamento ingegneri liberi, vedi
                                        -- 'nearbyEngs' piu' sopra, stesso margine di sicurezza di
                                        -- allora). scudi/artiglieria/SMD (task.zone=='inner', Fase E)
                                        -- usano invece un anello piu' vicino al centro (3-10),
                                        -- protetto dietro la linea terra/AA per design esplicito.
                                        local defRadiusMin, defRadiusMax = 10, 18
                                        if task.zone == 'inner' then
                                            defRadiusMin, defRadiusMax = 3, 10
                                        end
                                        local defAngle = math.rad(Random(0, 359))
                                        local defDist = Random(defRadiusMin, defRadiusMax)
                                        local defensePos = { outpostPos[1] + math.cos(defAngle) * defDist, outpostPos[2], outpostPos[3] + math.sin(defAngle) * defDist }
                                        -- Fix sess.78 (septies): 'e.factionCategory' non esiste su nessun
                                        -- unit object (verificato: zero riferimenti in vanilla/FAF/AI-Uveso)
                                        -- — risultava sempre nil, quindi defFactionIndex cadeva sempre sul
                                        -- fallback 1 (UEF), corretto per caso solo quando l'avamposto e' UEF.
                                        -- aiBrain:GetFactionIndex() e' l'API corretta (usata anche da Uveso
                                        -- stesso in aibuildstructures.lua) — l'aiBrain rappresenta sempre
                                        -- un'unica fazione per l'intera partita.
                                        local defFactionIndex = aiBrain:GetFactionIndex()
                                        -- Fix sess.81 (opzione B — le difese modded "sparite"):
                                        -- il pool difese mescola TOKEN vanilla ('T1GroundDefense', che
                                        -- DecideWhatToBuild risolve) e ID BLUEPRINT literali modded
                                        -- ('BRNT1EXPD'). L'opzione A (voce auto-mappante nel template +
                                        -- AIExecuteBuildStructure) faceva passare i controlli di Uveso ma
                                        -- FindPlaceToBuild() falliva comunque per gli ID literali (nessun
                                        -- footprint associato nel template) — 689 fallimenti e requeue
                                        -- infinito in game. Per gli ID modded bypassiamo del tutto la catena
                                        -- DecideWhatToBuild/FindPlaceToBuild e costruiamo con la primitiva
                                        -- diretta IssueBuildMobile, esattamente come fa il motore (vedi
                                        -- wreckage_1.lua Rebuild). Per i token vanilla teniamo
                                        -- AIExecuteBuildStructure invariato (funziona: 11 terra + 10 AA).
                                        -- Discriminante: se l'ID (minuscolo) esiste in __blueprints e' un
                                        -- blueprint literale (percorso modded), altrimenti e' un token.
                                        local defLiteralId = string.lower(tostring(task.unitType))
                                        local isModdedLiteral = __blueprints and __blueprints[defLiteralId] ~= nil
                                        if isModdedLiteral then
                                            -- Fix sess.81: le difese T1 modded (Mayor/Thug/Coyote/Pen) sono
                                            -- costruibili SOLO da un ingegnere T1 (verificato in game:
                                            -- T2/T3 davano CanBuild=false sulla base MK1, 81 pick sprecati).
                                            -- Se l'ingegnere assegnato NON e' T1 e la MK1 in mano ha una
                                            -- versione MK2 mappata, sostituiamo l'ID PRIMA del gate CanBuild:
                                            -- un T2/T3 costruisce direttamente la MK2 (che sa fare) invece
                                            -- di fallire sulla MK1 e tornare in coda in attesa di un T1.
                                            if engTier > 1 then
                                                local mk2Id = OWPlusOutpostDefensePool.OWPlusModdedUpgradeFor(defLiteralId)
                                                -- Fix sess.86 (fallimento silenzioso reale, richiesta esplicita
                                                -- utente di renderlo rumoroso): OWPlusModdedUpgradeFor puo' in
                                                -- teoria tornare un valore truthy ma inutilizzabile (es. stringa
                                                -- vuota, gia' visto in game per un default del motore su
                                                -- General.UpgradesTo — causa gia' corretta ALLA FONTE, questa e'
                                                -- una seconda guardia qui al punto di consumo, difesa in
                                                -- profondita'). Se capita di nuovo per qualunque altro motivo,
                                                -- un WARN esplicito rende il problema visibile subito nel log
                                                -- invece di corrompere silenziosamente defLiteralId.
                                                -- Fix sess.87 (bug reale confermato in game: Tower Boss mai
                                                -- costruito): un ingegnere tier>1 non garantisce di poter
                                                -- costruire il bersaglio dell'upgrade — es. BRNT2EPD (Tower
                                                -- Boss, T2) si aggiorna a BRNT2EPDT3 che pero' ha SOLO
                                                -- BUILTBYTIER3ENGINEER nel .bp: un T2 costruisce la base ma
                                                -- non l'upgrade. La vecchia regola binaria "tier>1 -> sostituisci
                                                -- sempre" andava bene per Mayor/Thug/Coyote/Pen (sess.81, MK1
                                                -- solo-T1 -> MK2 T2/T3), non generalizza: verificare che QUESTO
                                                -- ingegnere possa costruire il bersaglio prima di sostituire,
                                                -- altrimenti restare sull'ID originale.
                                                if mk2Id and mk2Id ~= '' and e:CanBuild(mk2Id) then
                                                    LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, ingegnere tier ' .. engTier
                                                        .. ' -> sostituita MK1 (' .. defLiteralId .. ') con MK2 (' .. mk2Id .. ')')
                                                    defLiteralId = mk2Id
                                                elseif mk2Id and mk2Id ~= '' then
                                                    LOG('[OWPlus] Outpost (' .. outpostKey .. '): ingegnere tier ' .. engTier
                                                        .. ' non puo costruire il bersaglio upgrade (' .. mk2Id .. ') di ' .. defLiteralId
                                                        .. ' — sostituzione SALTATA, resto sulla base originale')
                                                elseif mk2Id then
                                                    LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): OWPlusModdedUpgradeFor(' .. defLiteralId
                                                        .. ') ha tornato un valore non valido (' .. tostring(mk2Id)
                                                        .. ') — sostituzione MK2 SALTATA, resto sulla MK1 originale')
                                                end
                                            end
                                            LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, ramo build diretto (opzione B) per '
                                                .. (task.label or 'difesa') .. ' modded ' .. defLiteralId)
                                            -- Gate 1 (capacita' ingegnere): tier/fazione/restrizioni. Se
                                            -- l'ingegnere non puo' costruirla e' inutile cercare posizioni:
                                            -- il task torna in coda per un ingegnere piu' adatto.
                                            if not e:CanBuild(defLiteralId) then
                                                -- Fix Fase E (sess.88): label nel WARN — l'utente verifica solo
                                                -- via log (remoto, non vede lo schermo), serve distinguere un
                                                -- CanBuild=false su artiglieria/scudo/SMD da uno su difesa
                                                -- normale senza dover incrociare unitType a mano col catalogo.
                                                LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): ingegnere (' .. tostring(e.UnitId)
                                                    .. ') non puo costruire ' .. (task.label or 'difesa') .. ' ' .. defLiteralId
                                                    .. ' (CanBuild=false), task rimesso in coda')
                                            else
                                                -- Gate 2 (posizione valida): anello di offset attorno
                                                -- all'avamposto, via helper condiviso OWPlusFindModdedBuildSpot
                                                -- (sess.82, ora usato anche dal ramo 'reclaim' per l'upgrade
                                                -- MK1->MK2). Fix Fase E (sess.88): stesso anello 10-18/3-10
                                                -- (task.zone) del ramo vanilla-token sopra, non piu' un 7-15
                                                -- fisso — vedi commento li' per il perche'.
                                                local modRadiusMin, modRadiusMax = 10, 18
                                                if task.zone == 'inner' then
                                                    modRadiusMin, modRadiusMax = 3, 10
                                                end
                                                local buildWorldPos = OWPlusFindModdedBuildSpot(aiBrain, defLiteralId, outpostPos, modRadiusMin, modRadiusMax, 8)
                                                if not buildWorldPos then
                                                    LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): CanBuildStructureAt ha rifiutato tutte le 8 posizioni per '
                                                        .. defLiteralId .. ', task rimesso in coda')
                                                else
                                                    -- IssueBuildMobile: primitiva diretta "unita' mobile va a
                                                    -- costruire questa struttura in questa posizione mondo",
                                                    -- non passa da FindPlaceToBuild. La y viene snappata al
                                                    -- terreno dal motore.
                                                    IssueClearCommands({e})
                                                    IssueBuildMobile({e}, buildWorldPos, defLiteralId, {})
                                                    local buildWaited = 0
                                                    -- Fix sess.87: 'Reclaiming' aggiunto — vedi nota sullo scan
                                                    -- ingegneri liberi piu' sopra, stesso motivo.
                                                    while not e.Dead and (e:IsUnitState('Building') or e:IsUnitState('Moving') or e:IsUnitState('Reclaiming')) and buildWaited < 180 do
                                                        WaitSeconds(5)
                                                        buildWaited = buildWaited + 5
                                                    end
                                                    if not e.Dead and buildWaited < 180 then
                                                        success = true
                                                        -- Fix Fase F-bis (sess.88): PRIMO tentativo (GetUnitBeingBuilt
                                                        -- catturato dentro il loop sopra) confermato NON funzionante —
                                                        -- verificato su un'intera partita reale (18 minuti, centinaia
                                                        -- di costruzioni): 'registrata=false' SEMPRE, mai una volta
                                                        -- 'true'. La API esiste ed e' usata cosi' nel platoon.lua
                                                        -- vanilla di riferimento, ma li' e' dentro un platoon AI
                                                        -- gia' stabilito (EconUnfinishedBody) — evidentemente non si
                                                        -- popola allo stesso modo per un ordine IssueBuildMobile
                                                        -- diretto come il nostro. Fix Fase F-ter (sess.89): la
                                                        -- scansione a raggio 5 di Fase F-bis fallisce troppo spesso
                                                        -- (vedi OWPlusCaptureBuiltStructure sopra) — sostituita con
                                                        -- l'helper condiviso (raggio 10, piu' vicina, esclude
                                                        -- strutture altrui, un retry).
                                                        local newUnit = OWPlusCaptureBuiltStructure(aiBrain, outpostKey, buildWorldPos)
                                                        if newUnit then
                                                            OWPlusOutpostOwnership.OWPlusClaimForOutpost(aiBrain, outpostKey, newUnit)
                                                        end
                                                        LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, ' .. (task.label or 'difesa')
                                                            .. ' modded costruita (opzione B, ' .. defLiteralId .. ') da ingegnere ('
                                                            .. tostring(e.UnitId) .. '), registrata=' .. tostring(newUnit ~= nil))
                                                    end
                                                end
                                            end
                                        else
                                            -- Ramo TOKEN vanilla: AIExecuteBuildStructure invariato. Nessuna
                                            -- mutazione del template condiviso qui, quindi niente table.copy
                                            -- (l'auto-mapping opzione A serviva solo agli ID modded, ora
                                            -- gestiti dal ramo diretto sopra).
                                            local defBuildingTmpl = import('/lua/BuildingTemplates.lua')['BuildingTemplates'][defFactionIndex]
                                            local defBaseTmpl = import('/lua/BaseTemplates.lua')['BaseTemplates'][defFactionIndex]
                                            local defBaseTmplAtTarget = AIBuildStructures.AIBuildBaseTemplateFromLocation(defBaseTmpl, defensePos)
                                            LOG('[OWPlus-DIAG] Outpost (' .. outpostKey .. '): pre-build (token vanilla) unitType=' .. tostring(task.unitType)
                                                .. ', e=' .. tostring(e.UnitId) .. ' Dead=' .. tostring(e.Dead)
                                                .. ', defFactionIndex=' .. tostring(defFactionIndex))
                                            -- Fix sess.80 (parte 1): catturiamo il VALORE DI RITORNO di
                                            -- AIExecuteBuildStructure, non solo l'esito del pcall — un false
                                            -- significa "nessun ordine emesso" e non va contato come successo.
                                            local buildOk, buildIssued = pcall(function()
                                                return AIBuildStructures.AIExecuteBuildStructure(
                                                    aiBrain, e, task.unitType, nil, false, defBuildingTmpl, defBaseTmplAtTarget, defensePos, nil)
                                            end)
                                            if not buildOk then
                                                LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): AIExecuteBuildStructure (build) CRASH catturato: ' .. tostring(buildIssued))
                                            elseif not buildIssued then
                                                LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): AIExecuteBuildStructure ha ritornato FALSE per '
                                                    .. (task.label or 'difesa') .. ' (' .. tostring(task.unitType)
                                                    .. ') — nessun ordine emesso (unita non risolta o nessun posto valido), task rimesso in coda')
                                            end
                                            local buildWaited = 0
                                            if buildOk and buildIssued then
                                                -- Fix sess.87: 'Reclaiming' aggiunto — stesso motivo dello
                                                -- scan ingegneri liberi piu' sopra (indentazione diversa dal
                                                -- ramo modded, per questo la sostituzione precedente non
                                                -- aveva preso anche questo punto).
                                                while not e.Dead and (e:IsUnitState('Building') or e:IsUnitState('Moving') or e:IsUnitState('Reclaiming')) and buildWaited < 180 do
                                                    WaitSeconds(5)
                                                    buildWaited = buildWaited + 5
                                                end
                                                if not e.Dead and buildWaited < 180 then
                                                    success = true
                                                    -- Fix Fase F-bis (sess.88): stesso fix del ramo modded sopra
                                                    -- — GetUnitBeingBuilt confermato non funzionante su una
                                                    -- partita reale intera, sostituito con scansione a raggio
                                                    -- stretto (5) sulla posizione comandata (defensePos). Fix
                                                    -- Fase F-ter (sess.89): raggio 5 insufficiente, sostituito
                                                    -- con l'helper condiviso OWPlusCaptureBuiltStructure (raggio
                                                    -- 10, piu' vicina, esclude strutture altrui, un retry).
                                                    local newUnit = OWPlusCaptureBuiltStructure(aiBrain, outpostKey, defensePos)
                                                    if newUnit then
                                                        OWPlusOutpostOwnership.OWPlusClaimForOutpost(aiBrain, outpostKey, newUnit)
                                                    end
                                                    LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, ' .. (task.label or 'difesa') .. ' costruita ('
                                                        .. tostring(task.unitType) .. ') da ingegnere (' .. tostring(e.UnitId)
                                                        .. '), registrata=' .. tostring(newUnit ~= nil))
                                                end
                                            end
                                        end
                                    elseif task.action == 'reclaim' then
                                        local oldDef = task.targetUnit
                                        if oldDef.Dead then
                                            -- gia' sparita nel frattempo (es. reclamata da un altro
                                            -- ingegnere in un ciclo precedente) — doppione tollerato,
                                            -- nessun danno, task consumato senza fare nulla.
                                            success = true
                                        else
                                            -- Fix sess.83: le difese modded con upgrade nativo sono
                                            -- escluse a monte da questa coda (vedi filtro al
                                            -- popolamento, scan tier-up piu' sopra) — arrivano qui
                                            -- SOLO difese vanilla generiche, sempre col token
                                            -- (es. 'T2GroundDefense'), mai un ID modded literale.
                                            local newDefType = OWPlusOutpostDefensePool.OWPlusPickUpgradeDefense(aiBrain, task.newTier, task.isAA)
                                            local defFactionIndex = aiBrain:GetFactionIndex()
                                            local defBuildingTmpl = import('/lua/BuildingTemplates.lua')['BuildingTemplates'][defFactionIndex]
                                            local defBaseTmpl = import('/lua/BaseTemplates.lua')['BaseTemplates'][defFactionIndex]

                                            -- Fix sess.79: prova PRIMA a costruire il tier superiore in un
                                            -- punto libero vicino (stesso raggio 7-15 delle difese
                                            -- iniziali), lasciando la vecchia difesa in piedi come bonus.
                                            -- Reclama SOLO come fallback esplicito, quando non si trova un
                                            -- posto libero — mai come primo tentativo. Motivo (confermato
                                            -- dall'utente in game): con difese sparse c'era gia' spazio
                                            -- libero, reclamare prima era solo tempo sprecato.
                                            local freeAngle = math.rad(Random(0, 359))
                                            local freeDist = Random(7, 15)
                                            local freePos = { outpostPos[1] + math.cos(freeAngle) * freeDist, outpostPos[2], outpostPos[3] + math.sin(freeAngle) * freeDist }
                                            local freeBaseTmplAtTarget = AIBuildStructures.AIBuildBaseTemplateFromLocation(defBaseTmpl, freePos)
                                            local freeOk, freeFoundSpot = pcall(function()
                                                return AIBuildStructures.AIExecuteBuildStructure(
                                                    aiBrain, e, newDefType, nil, false, defBuildingTmpl, freeBaseTmplAtTarget, freePos, nil)
                                            end)
                                            if not freeOk then
                                                LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): AIExecuteBuildStructure (upgrade, punto libero) CRASH catturato: ' .. tostring(freeFoundSpot))
                                            end
                                            if freeOk and freeFoundSpot then
                                                -- Posto trovato, ordine emesso: aspetta come il ramo 'build'
                                                -- normale. Vecchia difesa lasciata in piedi.
                                                local freeBuildWaited = 0
                                                -- Fix sess.87: 'Reclaiming' aggiunto — stesso motivo dello
                                                -- scan ingegneri liberi piu' sopra.
                                                while not e.Dead and (e:IsUnitState('Building') or e:IsUnitState('Moving') or e:IsUnitState('Reclaiming')) and freeBuildWaited < 180 do
                                                    WaitSeconds(5)
                                                    freeBuildWaited = freeBuildWaited + 5
                                                end
                                                if not e.Dead and freeBuildWaited < 180 then
                                                    success = true
                                                    LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, difesa tier ' .. task.newTier .. ' ('
                                                        .. tostring(newDefType) .. ') costruita in punto libero, vecchia difesa lasciata in piedi')
                                                end
                                                -- Se non e' true (timeout o morto), 'success' resta false: il
                                                -- task torna in coda e si ritenta piu' avanti, SENZA forzare
                                                -- un reclaim sopra un ordine di build magari ancora in corso.
                                            else
                                                -- Nessun posto libero trovato (o crash): fallback, reclama
                                                -- la vecchia difesa (posizione garantita valida, gia'
                                                -- occupata prima) e ricostruisce li'.
                                                local defPosOk, defPos = pcall(function() return oldDef:GetPosition() end)
                                                if defPosOk and defPos then
                                                    IssueReclaim({e}, oldDef)
                                                    local reclaimWaited = 0
                                                    while not oldDef.Dead and reclaimWaited < 120 do
                                                        WaitSeconds(3)
                                                        reclaimWaited = reclaimWaited + 3
                                                    end
                                                    if oldDef.Dead and not e.Dead then
                                                        local rebuildBaseTmplAtTarget = AIBuildStructures.AIBuildBaseTemplateFromLocation(defBaseTmpl, defPos)
                                                        local rebuildOk, rebuildErr = pcall(function()
                                                            AIBuildStructures.AIExecuteBuildStructure(
                                                                aiBrain, e, newDefType, nil, false, defBuildingTmpl, rebuildBaseTmplAtTarget, defPos, nil)
                                                        end)
                                                        if rebuildOk then
                                                            LOG('[OWPlus] Outpost (' .. outpostKey .. '): OK, difesa reclamata e ricostruita a tier '
                                                                .. task.newTier .. ' (' .. tostring(newDefType) .. ')')
                                                        else
                                                            LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): AIExecuteBuildStructure (reclaim-rebuild) CRASH catturato: ' .. tostring(rebuildErr))
                                                        end
                                                        -- Stesso comportamento pre-esistente (non introdotto ora):
                                                        -- success=true una volta reclamata la vecchia struttura,
                                                        -- indipendentemente dall'esito del rebuild — la vecchia
                                                        -- difesa e' comunque persa, ritentare da capo non aiuta.
                                                        success = true
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    if not success then
                                        -- Fix sess.81 (tetto retry): contatore per-task. Con l'opzione A
                                        -- un task modded impossibile veniva rimesso in coda all'infinito
                                        -- (1378 requeue). Ora dopo OWPLUS_MAX_DEFENSE_RETRIES tentativi il
                                        -- task viene scartato, cosi' la coda non resta intasata per sempre
                                        -- da un task che non potra' mai completarsi.
                                        local liveQueue = aiBrain.OWPlusOutpostPendingDefenses and aiBrain.OWPlusOutpostPendingDefenses[outpostKey]
                                        task.OWPlusRetries = (task.OWPlusRetries or 0) + 1
                                        if liveQueue and task.OWPlusRetries <= OWPLUS_MAX_DEFENSE_RETRIES then
                                            table.insert(liveQueue, task)
                                            LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): task difesa (' .. tostring(task.action)
                                                .. ', ' .. tostring(task.unitType) .. ') non completato (tentativo '
                                                .. task.OWPlusRetries .. '/' .. OWPLUS_MAX_DEFENSE_RETRIES .. '), rimesso in coda')
                                        else
                                            LOG('[OWPlus-WARN] Outpost (' .. outpostKey .. '): task difesa (' .. tostring(task.action)
                                                .. ', ' .. tostring(task.unitType) .. ') SCARTATO dopo ' .. tostring(task.OWPlusRetries)
                                                .. ' tentativi (tetto retry raggiunto)')
                                        end
                                    end
                                    -- Fix sess.78: NON ripulire OWPlusOutpostBusy qui. Il nostro
                                    -- watcher non usa questo flag per decidere chi rivalutare (solo
                                    -- IsUnitState('Building'/'Moving')), ma altri sistemi si' — es.
                                    -- 'OWPlus Outpost Factory' (sceglie ingegneri per fondare un
                                    -- NUOVO avamposto, via OWPlusHasFreeEngineerAtLocation) esclude
                                    -- esplicitamente chi ha questo flag attivo. Ripulirlo qui aprirebbe
                                    -- una finestra (fino a 10s, prossimo ciclo del watcher) in cui
                                    -- l'ingegnere torna "rubabile" — la stessa vulnerabilita' gia'
                                    -- osservata e chiusa oggi con la guardia fabbrica. Resta true per
                                    -- sempre una volta impostato la prima volta (stesso principio gia'
                                    -- in uso per la guardia, poco sotto).
                                end, e, task)
                            elseif curFactory and not curFactory.Dead and e.OWPlusOutpostGuardTarget ~= curFactory then
                                -- Fix sess.76: IssueClearCommands prima di IssueGuard — senza,
                                -- un ordine STALE rimasto in coda nativa poteva riemergere dopo
                                -- l'assist, causando un oscillare infinito.
                                IssueClearCommands({e})
                                IssueGuard({e}, curFactory)
                                -- Traccia il bersaglio (non un booleano) per accorgersi se la
                                -- fabbrica cambia identita' (upgrade struttura, Conoscenze_AI_35
                                -- §35.1: distrugge la vecchia entita' e ne crea una nuova) — un
                                -- semplice flag "sto gia' guardando" resterebbe vero per sempre
                                -- anche puntando a un'entita' morta, bloccando il riaggancio.
                                e.OWPlusOutpostGuardTarget = curFactory
                                e.OWPlusOutpostBusy = true
                                LOG('[OWPlus] Outpost (' .. outpostKey .. '): ingegnere libero (' .. tostring(e.UnitId)
                                    .. ') messo ad assist della fabbrica per default (nessun compito locale trovato)')
                            end
                        end
                    end
                end
            end)
        end
    end,

    -- Fix sess.76 (root cause reale del "tutto fermo dopo N strutture",
    -- confermata leggendo /lua/platoon.lua vanilla): EngineerBuildDone/
    -- EngineerCaptureDone/EngineerReclaimDone/EngineerFailedToBuild vanilla
    -- hanno tutte lo stesso bug di precedenza Lua:
    --   if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
    -- che Lua interpreta come (not unit.PlatoonHandle.PlanName) == 'EngineerBuildAI'
    -- — sempre falso quando PlanName e' una stringa non vuota (quindi il
    -- "return" non scatta MAI, per NESSUN piano, incluso il nostro
    -- 'OWPlusDispersedBuildAI'). Risultato: appena l'ingegnere completa
    -- l'ULTIMA struttura nativa in coda (eng.EngineerBuildQueue, popolata da
    -- AIExecuteBuildStructure), il trigger vanilla EngineerBuildDone chiama
    -- comunque ProcessBuildCommand — che, trovando la coda vuota dopo aver
    -- rimosso l'item appena completato, chiama eng.PlatoonHandle:PlatoonDisband()
    -- SUL NOSTRO PLOTONE. PlatoonDisband cancella gli ordini nativi
    -- dell'ingegnere e soprattutto distrugge self.AIThread — uccidendo la
    -- coroutine di OWPlusDispersedBuildAI a meta' esecuzione (tipicamente
    -- dentro il loop di attesa finale), SENZA alcun errore Lua: il nostro
    -- codice semplicemente smette di girare, OWPlusOutpostBusy resta true per
    -- sempre, e l'avamposto adottato/i builder dedicati non partono mai —
    -- esattamente il pattern "costruisce N strutture poi tutto fermo"
    -- osservato per l'intera sessione, non solo con la ricetta a 1 fabbrica.
    -- Confermato in dev.log: 'EngineerManager:TaskFinished' scattava proprio
    -- nell'istante in cui l'utente vedeva la fabbrica finire (TaskFinished e'
    -- chiamato anche da dentro PlatoonDisband stesso).
    --
    -- Fix: override dei 4 callback per il nostro piano, con la precedenza
    -- corretta ("not (X == Y)" invece di "not X == Y") — se il piano e' il
    -- nostro, non facciamo nulla (la ricetta e il loop di attesa dedicato
    -- gestiscono gia' tutto da soli); altrimenti richiamiamo la versione
    -- originale invariata.
    EngineerBuildDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if unit.PlatoonHandle.PlanName == 'OWPlusDispersedBuildAI' then
            return
        end
        CopyOfOldPlatoonClassOWPlusChild.EngineerBuildDone(unit, params)
    end,
    EngineerCaptureDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if unit.PlatoonHandle.PlanName == 'OWPlusDispersedBuildAI' then
            return
        end
        CopyOfOldPlatoonClassOWPlusChild.EngineerCaptureDone(unit, params)
    end,
    EngineerReclaimDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if unit.PlatoonHandle.PlanName == 'OWPlusDispersedBuildAI' then
            return
        end
        CopyOfOldPlatoonClassOWPlusChild.EngineerReclaimDone(unit, params)
    end,
    EngineerFailedToBuild = function(unit, params)
        if not unit.PlatoonHandle then return end
        if unit.PlatoonHandle.PlanName == 'OWPlusDispersedBuildAI' then
            return
        end
        CopyOfOldPlatoonClassOWPlusChild.EngineerFailedToBuild(unit, params)
    end,

    -- Fase 9-F28 (fix B12): PlatoonMerger (stock Uveso) chiama Platoon:GetPlan()
    -- su ogni elemento di aiBrain:GetPlatoonsList() senza controllare se quel
    -- metodo esiste davvero. Confermato in sess.66 (dev.log ricorrente):
    --   attempt to call method 'GetPlan' (a nil value)
    -- Se il crash avviene qui, la funzione si interrompe PRIMA di creare/
    -- riusare il plotone unificato — le unita' del plotone chiamante restano
    -- quindi in un plotone "orfano" mai fuso ne' disbandato, mai assegnate a
    -- un plotone d'attacco attivo. Sospettato (insieme a UnitsLessInPlatoon,
    -- vedi hook/lua/editor/unitcountbuildconditions.lua) come causa
    -- dell'esercito pieno di unita' che non lancia mai un attacco su vasta
    -- scala. Fix: stessa guardia difensiva "Platoon and Platoon.GetPlan and"
    -- prima di chiamare :GetPlan() — nessun'altra logica modificata rispetto
    -- all'originale.
    PlatoonMerger = function(self)
        local aiBrain = self:GetBrain()
        local PlatoonPlan = self.PlatoonData.AIPlan
        if not PlatoonPlan then
            return
        end
        local platoonUnits = self:GetPlatoonUnits()
        local AlreadyMergedPlatoon
        local PlatoonList = aiBrain:GetPlatoonsList()
        for _, Platoon in PlatoonList do
            if Platoon and Platoon.GetPlan and Platoon:GetPlan() == PlatoonPlan then
                AlreadyMergedPlatoon = Platoon
                break
            end
        end
        if not AlreadyMergedPlatoon then
            AlreadyMergedPlatoon = aiBrain:MakePlatoon( PlatoonPlan..'Platoon', PlatoonPlan )
            AlreadyMergedPlatoon.PlanName = PlatoonPlan
            AlreadyMergedPlatoon.BuilderName = PlatoonPlan..'Platoon'
        end
        aiBrain:AssignUnitsToPlatoon( AlreadyMergedPlatoon, platoonUnits, 'support', 'none' )
        AlreadyMergedPlatoon.PlatoonData.SearchRadius = self.PlatoonData.SearchRadius
        AlreadyMergedPlatoon.PlatoonData.GetTargetsFromBase = self.PlatoonData.GetTargetsFromBase
        AlreadyMergedPlatoon.PlatoonData.IgnorePathing = self.PlatoonData.IgnorePathing
        AlreadyMergedPlatoon.PlatoonData.DirectMoveEnemyBase = self.PlatoonData.DirectMoveEnemyBase
        AlreadyMergedPlatoon.PlatoonData.RequireTransport = self.PlatoonData.RequireTransport
        AlreadyMergedPlatoon.PlatoonData.AggressiveMove = self.PlatoonData.AggressiveMove
        AlreadyMergedPlatoon.PlatoonData.AttackEnemyStrength = self.PlatoonData.AttackEnemyStrength
        AlreadyMergedPlatoon.PlatoonData.TargetSearchCategory = self.PlatoonData.TargetSearchCategory
        AlreadyMergedPlatoon.PlatoonData.MoveToCategories = self.PlatoonData.MoveToCategories
        AlreadyMergedPlatoon.PlatoonData.WeaponTargetCategories = self.PlatoonData.WeaponTargetCategories
        AlreadyMergedPlatoon.PlatoonData.TargetHug = self.PlatoonData.TargetHug
        self:PlatoonDisbandNoAssign()
    end,
}
