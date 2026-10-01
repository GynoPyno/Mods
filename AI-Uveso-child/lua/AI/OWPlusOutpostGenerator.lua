-- OWPlusOutpostGenerator.lua
-- Fase 9-F18: sistema avamposti indipendente da marker di scena. Sostituisce il
-- sistema a settori/marker precedente (9-F11/12/13, 'OWPlus Vacant Expansion Area',
-- ExpansionFunction in Uveso Forward Base OverwhelmPlus.lua).
--
-- Motivazione (sess.64): il vecchio sistema dipendeva dai marker 'Expansion Area'
-- (richiedono 2+ estrattori entro 30u, vedi Conoscenze_AI_30) e 'Large Expansion
-- Area' (raggiunti tramite AIFindStartLocationNeedsEngineer, che pero' mischia
-- insieme marker reali E slot ARMY_X vuoti di altri giocatori — bug scoperto in
-- sess.64: avamposti costruiti su spawn altrui). Il nuovo sistema non cerca piu'
-- marker: genera i punti da solo lungo 8 direzioni fisse dal centro di MAIN,
-- validati a terreno e a distanza da OGNI start di giocatore (non solo il nostro).
--
-- Thread forkato da aiBrain (non da un platoon/unita') in overwhelmplusai.lua —
-- sopravvive per tutta la partita, stesso pattern di PriorityManagerThread/
-- LocationRangeManagerThread di Uveso (aiarchetype-managerloader.lua).

-- Fix sess.76 (richiesta esplicita utente): ricetta semplificata al massimo —
-- una sola fabbrica di terra, niente piu' varianti/conteggi casuali. Motivo:
-- ridurre al minimo il tempo (e quindi la finestra di rischio) tra sbarco
-- dell'ingegnere e "avamposto online" (prima fabbrica adottata in un
-- BuilderManager reale, protezioni dedicate agganciate) — piu' breve la
-- ricetta, prima l'avamposto e' al sicuro. Se in futuro si vorra' reintrodurre
-- varieta', farlo DOPO che l'avamposto e' gia' online (stessa logica gia'
-- usata per le difese, rimandate a una fase 2 in platoon.lua).
local OWPlusOutpostRecipes = {
    { 'T1LandFactory' },
}

-- Fase C (B16): le difese non sono piu' una lista fissa nel builder — ogni
-- avamposto riceve una selezione casuale (3-7 point-defense + 4-9 AA, pool
-- vanilla+TotalMayhem) generata qui insieme alla ricetta fabbriche, e salvata in
-- aiBrain.OWPlusOutpostDefenseRecipes[slotKey]. Vedi OWPlusOutpostDefensePool.lua.

local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')
local AITargetManager = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua')
local OWPlusOutpostDefensePool = import('/mods/AI-Uveso-child/lua/AI/OWPlusOutpostDefensePool.lua')

local function OWPlusTerrainValid(x, z)
    local terrainH = GetTerrainHeight(x, z)
    local surfaceH = GetSurfaceHeight(x, z)
    return math.abs(surfaceH - terrainH) <= 0.5
end

-- Vero se (x,z) e' dentro l'area giocabile della mappa (stessa funzione usata
-- da Uveso stesso in aibuildstructures.lua per i limiti di ricerca).
local function OWPlusInPlayableArea(x, z, playableArea)
    return x >= playableArea[1] and x <= playableArea[3] and z >= playableArea[2] and z <= playableArea[4]
end

-- Vero se (x,z) e' abbastanza lontano da OGNI start di giocatore (non solo il
-- nostro) — evita di ripetere il bug ARMY_X scoperto nel vecchio sistema.
--
-- Fix sess.87 (richiesta esplicita utente, confermato in test OWTEST): su una
-- mappa con piu' slot armata di quanti giocatori reali configurati (es.
-- total_open_war.v0007 con /owtest che assegna solo ARMY_1/ARMY_8), gli slot
-- non assegnati restano "fantasma" — IsDefeated() (= ArmyIsOutOfGame()) non
-- diventa mai true perche' nulla li marca esplicitamente chiusi durante il
-- lancio da riga di comando (stesso meccanismo gia' noto: "il lancio CLI non
-- popola i dati della lobby", qui si manifesta sul flag out-of-game invece
-- che sulle opzioni AI). Risultato osservato: la scansione a Nord si bloccava
-- in modo permanente e silenzioso oltre una certa distanza, sempre alla
-- stessa posizione (uno slot fantasma mai in play). Fix: oltre a non essere
-- sconfitta, l'armata deve avere DAVVERO avuto un Comandante — uno slot mai
-- assegnato non ne genera mai uno, un giocatore vero (umano o IA) si' sempre.
local function OWPlusFarFromEveryStart(x, z, minDist)
    for _, brain in ArmyBrains do
        if brain and not brain:IsDefeated() then
            local hasCommander = brain:GetListOfUnits(categories.COMMAND, false)
            if hasCommander and table.getn(hasCommander) > 0 then
                local sx, sz = brain:GetArmyStartPos()
                if sx and VDist2(x, z, sx, sz) < minDist then
                    return false
                end
            end
        end
    end
    return true
end

-- Fase 9-F21: una direzione per thread, forkata in parallelo, invece di un
-- unico thread che scandiva le 8 direzioni in sequenza. Prima (9-F18/20) ogni
-- direzione richiedeva ~7 minuti (41 check * 10s) prima di passare alla
-- successiva — confermato in test: a 15 minuti di gioco l'espansione aveva
-- coperto solo 2-3 direzioni su 8. Ora tutte e 8 avanzano insieme, allo stesso
-- ritmo, fin da inizio partita.
local function OWPlusOutpostDirectionThread(aiBrain, angleDeg, startX, startZ, ownerName)
    local rad = math.rad(angleDeg)
    local dirX, dirZ = math.cos(rad), math.sin(rad)
    local perpX, perpZ = -dirZ, dirX
    local playableArea = AITargetManager.GetPlayableArea()

    -- Fase 9-F21: passo aumentato da 10 a 20 — a passo 10 gli avamposti
    -- risultavano troppo ravvicinati (osservato in test: strisce dense di
    -- 23 fabbriche di terra + 14 di aria lungo una singola direzione).
    local STEP = 20
    local MAX_DIST = 500

    -- Fase 9-F31: distanza minima differenziata. Le 4 direzioni diagonali
    -- (45/135/225/315) condividono lo stesso raggio di ricerca dei nodi
    -- dispersi di MAIN (BASE_NE/SE/SW/NW, che provano 20-90 in overwhelmplusai.lua)
    -- — restano a 90 per evitare sovrapposizioni. Le 4 direzioni cardinali
    -- (0/90/180/270) non hanno nulla di MAIN nelle vicinanze, quindi possono
    -- partire da 50, avvicinando i primi avamposti senza rischio di collisione.
    local isDiagonal = (angleDeg == 45 or angleDeg == 135 or angleDeg == 225 or angleDeg == 315)
    local MIN_DIST = isDiagonal and 90 or 50

    while true do
        local dist = MIN_DIST
        local offMap = false
        while dist <= MAX_DIST and not offMap do
            local checkKey = angleDeg .. '_' .. dist
            if not aiBrain.OWPlusOutpostChecked[checkKey] then
                local jitterDist = dist + Random(-5, 5)
                local jitterLateral = Random(-15, 15)
                local x = startX + dirX * jitterDist + perpX * jitterLateral
                local z = startZ + dirZ * jitterDist + perpZ * jitterLateral

                if not OWPlusInPlayableArea(x, z, playableArea) then
                    -- Fuori mappa: piu' lontano si andrebbe in questa direzione,
                    -- piu' si resterebbe fuori mappa. Fermiamo questa direzione
                    -- invece di continuare a controllare punti inutili — resta
                    -- innocua a livello di prestazioni (nessun ciclo attivo).
                    offMap = true
                    LOG('[OWPlus] Outpost (' .. ownerName .. '): direzione ' .. angleDeg
                        .. 'deg fuori mappa a dist=' .. dist .. ', fermata')
                elseif OWPlusTerrainValid(x, z) and OWPlusFarFromEveryStart(x, z, 80) then
                    aiBrain.OWPlusOutpostChecked[checkKey] = true
                    aiBrain.OWPlusOutpostCount = (aiBrain.OWPlusOutpostCount or 0) + 1
                    local slotKey = 'OUT' .. aiBrain.OWPlusOutpostCount
                    local surfaceH = GetSurfaceHeight(x, z)
                    aiBrain.OWPlusSubBases[slotKey] = { x, surfaceH, z }
                    local recipe = OWPlusOutpostRecipes[Random(1, table.getn(OWPlusOutpostRecipes))]
                    -- Sess.100 parte 9 (piano fabbriche): 2 terra + 1 aria nella ricetta iniziale
                    -- (OWPlusFactoryTargets.lua). Con OWPlusMultiFactoryDisabled = true resta la
                    -- ricetta storica a 1 fabbrica di terra scelta sopra (Random gia' consumato).
                    if not OWPlusFactoryTargetsMod.OWPlusMultiFactoryDisabled then
                        recipe = OWPlusFactoryTargetsMod.OWPlusOutpostFactoryRecipe()
                        LOG('[OWPlus-FACTORY] Outpost ' .. slotKey .. ': ricetta iniziale = ' .. table.concat(recipe, ', '))
                    end
                    aiBrain.OWPlusOutpostRecipes[slotKey] = recipe
                    -- Fase C (B16): selezione difese iniziali (3-7 terra + 4-9 AA,
                    -- pool vanilla+TotalMayhem) generata una volta per avamposto,
                    -- alla stessa maniera della ricetta fabbriche.
                    local defenses = OWPlusOutpostDefensePool.OWPlusPickInitialOutpostDefenses(aiBrain)
                    aiBrain.OWPlusOutpostDefenseRecipes[slotKey] = defenses
                    LOG('[OWPlus] Outpost (' .. ownerName .. '): registrato ' .. slotKey
                        .. ' a (' .. math.floor(x) .. ',' .. math.floor(z) .. ') direzione=' .. angleDeg
                        .. 'deg dist=' .. dist .. ', ricetta=' .. table.getn(recipe) .. ' fabbriche, difese='
                        .. table.getn(defenses.ground) .. ' terra + ' .. table.getn(defenses.aa) .. ' AA')
                    -- NON marchiamo checkKey come "definitivo" se il terreno fallisce: un
                    -- punto fallito oggi (es. detriti/prop temporanei) puo' essere riprovato
                    -- al prossimo giro, usando un nuovo scarto casuale.
                end
            end
            if not offMap then
                dist = dist + STEP
                WaitSeconds(10)
            end
        end
        -- Range esaurito o direzione fuori mappa: pausa lunga, poi riprova solo
        -- i punti ancora non validati (terreno) — i punti fuori mappa vengono
        -- ricontrollati ma falliscono subito senza lavoro pesante.
        WaitSeconds(300)
    end
end

-- Fase 9-F18/9-F21: entry point forkato da aiBrain in overwhelmplusai.lua. Crea
-- un thread indipendente per ciascuna delle 8 direzioni fisse (rosa dei venti)
-- dal centro di MAIN — vedi OWPlusOutpostDirectionThread sopra per i dettagli
-- di scansione, jitter e limite mappa. Nessun tetto sul numero di avamposti per
-- direzione — solo terreno valido e non troppo vicino a uno start altrui.
function OWPlusOutpostScanThread(aiBrain)
    local ownerName = (ArmyBrains[aiBrain:GetArmyIndex()] and ArmyBrains[aiBrain:GetArmyIndex()].Nickname) or tostring(aiBrain:GetArmyIndex())
    local startX, startZ = aiBrain:GetArmyStartPos()
    -- Fix sess.88 (richiesta esplicita utente): ripristinate tutte e 8 le direzioni
    -- (rosa dei venti) — l'isolamento diagnostico di sess.77 (solo Nord/270deg,
    -- per isolare "avamposti multipli in competizione" durante l'indagine del
    -- blocco post salto-di-tier, problema chiuso da tempo in sess.85) resta solo
    -- come nota storica qui sotto.
    local angles = { 0, 45, 90, 135, 180, 225, 270, 315 }

    aiBrain.OWPlusSubBases = aiBrain.OWPlusSubBases or {}
    aiBrain.OWPlusOutpostRecipes = aiBrain.OWPlusOutpostRecipes or {}
    aiBrain.OWPlusOutpostDefenseRecipes = aiBrain.OWPlusOutpostDefenseRecipes or {}
    aiBrain.OWPlusOutpostChecked = aiBrain.OWPlusOutpostChecked or {}
    aiBrain.OWPlusOutpostCount = aiBrain.OWPlusOutpostCount or 0

    for _, angleDeg in angles do
        aiBrain:ForkThread(OWPlusOutpostDirectionThread, angleDeg, startX, startZ, ownerName)
    end
end
