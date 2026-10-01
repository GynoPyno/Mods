-- Uveso Forward Base OverwhelmPlus.lua
-- Template per la base avanzata direzionale (OWPlusForwardBase).
-- Viene selezionato da ExpansionFunction quando un marker 'Expansion Area' o
-- 'Large Expansion Area' si trova in direzione del nemico e a distanza
-- ragionevole da MAIN.
-- Contiene solo fabbriche terra (per unita' da combattimento) + difese.
-- Gli ingegneri vengono inviati da MAIN, non nascono qui.
--
-- Fase 9-F5 (2026-07-03): markerType allargato da solo 'Expansion Area' (2 sulla
-- mappa scmp_009) anche a 'Large Expansion Area' (8 sulla mappa) — prima questi
-- ultimi finivano tutti gestiti dal template stock UvesoExpansionAreaLarge (nessun
-- filtro direzionale, produzione non coordinata con la nostra strategia). Aggiunto
-- anche un cap MAX_FORWARD_BASES per evitare dispersione eccessiva di risorse.
--
-- Fase 9-F11 (2026-07-04): sostituito il cono singolo "verso il nemico" con 4
-- settori angolari fissi relativi alla direzione del nemico (FRONTE/DESTRA/
-- SINISTRA/RETROVIA), ciascuno legato a uno slot fisso (FWD1-4). Motivazione
-- utente: un solo cono produce basi allineate e prevedibili; i 4 settori
-- sparpagliano gli avamposti intorno a MAIN dando controllo mappa reale, pur
-- mantenendo FWD1 (il primo, quello che scatta piu' veloce via Tier1) rivolto
-- verso il nemico per valore tattico immediato. Aggiunto anche il reroll: se
-- uno slot fallisce ripetutamente per terreno non valido (vedi hook/lua/
-- platoon.lua), lo slot si libera e un marker diverso nello stesso settore
-- puo' prendere il suo posto — il marker fallito resta rifiutato per sempre.
--
-- SUPERATO (Fase 9-F18, 2026-07-05): il sistema a marker/settori sopra descritto
-- e' stato sostituito da OWPlusOutpostGenerator.lua, che genera avamposti lungo
-- 8 direzioni fisse senza dipendere da marker di scena (niente piu' vincolo dei
-- 2 estrattori vicini, niente piu' rischio di finire su spawn vuoti di altri
-- giocatori — bug scoperto in sess.64). Questo file resta intatto per
-- reversibilita' ma la sua ExpansionFunction non e' piu' raggiungibile in pratica:
-- nessun builder attivo cerca piu' marker 'Expansion Area'/'Large Expansion Area'.

BaseBuilderTemplate {
    BaseTemplateName = 'OWPlusForwardBase',
    Builders = {
        -----------------------------------------------------------------------------
        -- Ingegneri: vengono da MAIN. Assistono le costruzioni e tornano a MAIN.
        -- NON includere 'U123 Engineer Builders': gli ingegneri non nascono qui.
        -----------------------------------------------------------------------------
        'UC123 Assistees',
        'U123 Engineer Transfer To MainBase',

        -----------------------------------------------------------------------------
        -- Fabbriche: costruite da MAIN via OWPlus Forward Extra Factory (Fase 9-F7),
        -- che riusa il Plan OWPlusDispersedBuildAI gia' collaudato per i nodi dispersi.
        -- 'OWPlus Forward Land Factory' (EngineerBuilder generico Uveso) rimosso:
        -- non trovava mai un ingegnere disponibile in loco (EngineerCount=0 qui),
        -- causava spam infinito di "espansione in corso" senza mai costruire nulla.
        -- U123 Factory Upgrader Rush aggiorna T1->T2->T3.
        -----------------------------------------------------------------------------
        'U123 Factory Upgrader Rush',

        -----------------------------------------------------------------------------
        -- Produzione unita' terra: solo combattimento.
        -- OWPlus Land T2T3 bypassa i builder Uveso default e garantisce T2/T3.
        -----------------------------------------------------------------------------
        'U123 Land Builders Panic',
        'U123 Land Builders ADAPTIVE',
        'OWPlus Land T2T3',

        -----------------------------------------------------------------------------
        -- Former: le unita' attaccano appena formate, senza gate NoRush.
        -----------------------------------------------------------------------------
        'OWPlus Land Formers Aggressive',

        -----------------------------------------------------------------------------
        -- Difese locali: scudi, AA, point defense.
        -----------------------------------------------------------------------------
        'U23 Shields Builder',
        'U23 Shields Upgrader',
        'U234 Repair Shields Former',
        'U123 Defense Anti Air Builders',
        'U123 Defense Anti Ground Builders',

        -----------------------------------------------------------------------------
        -- Scout.
        -----------------------------------------------------------------------------
        'U1 Land Scout Builders',
        'U1 Air Scout Builders',
        'U1 Land Scout Formers',
        'U13 Air Scout Formers',
    },
    NonCheatBuilders = {},

    BaseSettings = {
        FactoryCount = {
            Land = 2,
            Air  = 0,
            Sea  = 0,
            Gate = 0,
        },
        EngineerCount = {
            Tech1 = 0,
            Tech2 = 0,
            Tech3 = 0,
            SCU   = 0,
        },
        MassToFactoryValues = {
            T1Value  = 6,
            T2Value  = 15,
            T3Value  = 22.5,
        },
    },

    -- ExpansionFunction: chiamata per ogni marker 'Expansion Area' / 'Large Expansion Area' sulla mappa.
    -- Restituisce 2000 (> 1000 di UvesoExpansionArea) solo per marker che sono:
    --   1. A distanza ragionevole da MAIN (60-220 unita')
    --   2. In un settore (FRONTE/DESTRA/SINISTRA/RETROVIA, 90 gradi ciascuno)
    --      relativo alla direzione del nemico, il cui slot FWD1-4 e' ancora libero
    --   3. Su terreno che supera il check di validita' (Fase 9-F8)
    -- Per tutti gli altri marker restituisce -1 (UvesoExpansionArea li gestisce).
    ExpansionFunction = function(aiBrain, location, markerType)
        -- Fase 9-F19: disattivata. Da quando gli avamposti (OUT#) vengono
        -- registrati in un BuilderManager reale via AddFactoryToClosestManager,
        -- questa ExpansionFunction e' di nuovo raggiungibile (quella funzione
        -- crea marker sintetici e rivaluta ExpansionFunction su tutti i template)
        -- — rischiava di vincere al posto dei template stock di Uveso, che hanno
        -- gia' una produzione ingegneri funzionante che questo template FORWARD
        -- non ha mai avuto. Meglio lasciar vincere sempre lo stock.
        -- 'do ... end': in Lua 'return' deve chiudere il blocco; un return nudo
        -- seguito dal vecchio codice rendeva il file intero non caricabile.
        do return -1 end

        -- Fase 9-F12: nome army nei log, per distinguere piu' AI OverwhelmPlus i
        -- cui log si intrecciano nello stesso file quando girano in parallelo.
        local ownerName = (ArmyBrains[aiBrain:GetArmyIndex()] and ArmyBrains[aiBrain:GetArmyIndex()].Nickname) or tostring(aiBrain:GetArmyIndex())

        if not aiBrain.Uveso then
            LOG('[OWPlus] ForwardBase ExpansionFunction (' .. ownerName .. '): aiBrain.Uveso assente, skip (markerType=' .. tostring(markerType) .. ')')
            return -1
        end
        if markerType ~= 'Expansion Area' and markerType ~= 'Large Expansion Area' then
            LOG('[OWPlus] ForwardBase ExpansionFunction (' .. ownerName .. '): markerType "' .. tostring(markerType) .. '" non gestito da noi, skip')
            return -1
        end
        LOG('[OWPlus] ForwardBase ExpansionFunction (' .. ownerName .. '): valutazione marker tipo=' .. tostring(markerType) .. ' avviata')

        local myX, myZ = aiBrain:GetArmyStartPos()
        local markerX = location.x or location[1]
        local markerZ = location.z or location[3]
        if not markerX or not markerZ then
            LOG('[OWPlus] ForwardBase ExpansionFunction (' .. ownerName .. '): location senza coordinate, skip')
            return -1
        end

        -- Un marker gia' valutato in precedenza: se accettato (true) mantiene il
        -- template vincente; se rifiutato per fallimento costruzione (vedi reroll
        -- in hook/lua/platoon.lua) non viene mai piu' riconsiderato.
        local markerKey = math.floor(markerX) .. '_' .. math.floor(markerZ)
        aiBrain.OWPlusForwardBaseMarkers = aiBrain.OWPlusForwardBaseMarkers or {}

        local markerState = aiBrain.OWPlusForwardBaseMarkers[markerKey]
        if markerState == 'REJECTED' then
            return -1
        end
        if markerState then
            return 2000
        end

        -- Nemico corrente: usa aiBrain:GetCurrentEnemy() (stesso meccanismo di
        -- CanPathToCurrentEnemy in MiscBuildConditions.lua di Uveso) invece di un
        -- ciclo manuale su ArmyBrains+IsEnemy — piu' robusto e gia' testato/attivo
        -- in questa stessa run (CanPathToCurrentEnemy ha trovato il nemico correttamente
        -- per entrambe le AI in un test FFA dove il ciclo manuale falliva).
        local currentEnemy = aiBrain:GetCurrentEnemy()
        if not currentEnemy then
            LOG('[OWPlus] ForwardBase ExpansionFunction (' .. ownerName .. '): GetCurrentEnemy() nil, skip')
            return -1
        end
        local enemyX, enemyZ = currentEnemy:GetArmyStartPos()
        if not enemyX or not enemyZ then
            LOG('[OWPlus] ForwardBase ExpansionFunction (' .. ownerName .. '): nemico senza start pos, skip')
            return -1
        end

        -- Vettore verso il marker
        local mx = markerX - myX
        local mz = markerZ - myZ
        local markerDist = math.sqrt(mx*mx + mz*mz)
        if markerDist < 1 then return -1 end

        -- Rifiuta marker troppo vicini a MAIN o troppo lontani. Range differenziato
        -- per tipo (Fase 9-F13): i marker 'Large Expansion Area' sono pensati da
        -- Uveso per stare tra basi alleate su mappe team grandi (visto in test su
        -- Setons/scmp_009: tutti gli 8 marker Large Expansion Area erano a 300-945
        -- unita', ben oltre il vecchio limite 220 unico) — range massimo piu' ampio
        -- solo per quel tipo. 'Expansion Area' resta 60-220 (gia' testato, funziona).
        local maxDist = (markerType == 'Large Expansion Area') and 500 or 220
        if markerDist < 60 or markerDist > maxDist then
            LOG('[OWPlus] ForwardBase ExpansionFunction (' .. ownerName .. '): marker (' .. math.floor(markerX) .. ',' .. math.floor(markerZ)
                .. ') fuori range distanza (dist=' .. math.floor(markerDist) .. ', richiesto 60-' .. maxDist .. '), scartato')
            return -1
        end

        -- Fase 9-F11: settore angolare relativo alla direzione del nemico, invece
        -- del vecchio cono singolo. atan2 in gradi, poi differenza normalizzata
        -- in [-180, 180] tra angolo-marker e angolo-nemico.
        local enemyAngleDeg = math.deg(math.atan2(enemyZ - myZ, enemyX - myX))
        local markerAngleDeg = math.deg(math.atan2(mz, mx))
        local diffDeg = markerAngleDeg - enemyAngleDeg
        while diffDeg > 180 do diffDeg = diffDeg - 360 end
        while diffDeg < -180 do diffDeg = diffDeg + 360 end

        local sector, slotKey
        if math.abs(diffDeg) <= 45 then
            sector, slotKey = 'FRONTE', 'FWD1'
        elseif diffDeg > 45 and diffDeg <= 135 then
            sector, slotKey = 'DESTRA', 'FWD2'
        elseif diffDeg < -45 and diffDeg >= -135 then
            sector, slotKey = 'SINISTRA', 'FWD3'
        else
            sector, slotKey = 'RETROVIA', 'FWD4'
        end

        -- Lo slot di questo settore e' gia' occupato da un'altra base (in
        -- costruzione o completata)? Lascia che un altro template/marker gestisca
        -- questo punto invece di competere per lo stesso settore.
        aiBrain.OWPlusSubBases = aiBrain.OWPlusSubBases or {}
        if aiBrain.OWPlusSubBases[slotKey] then
            return -1
        end

        -- Fase 9-F8: verifica validita' del terreno PRIMA di accettare definitivamente
        -- il marker — altrimenti uno slot su MAX_FORWARD_BASES resterebbe sprecato per
        -- sempre su una posizione mai costruibile (visto in gioco: marker accettato ma
        -- 'terreno non valido' ripetuto ogni 30s per tutta la partita). Se surfaceHeight
        -- e terrainHeight divergono di oltre 0.5, il punto e' probabilmente acqua o
        -- terreno troppo irregolare — scarta e lascia che un altro marker venga provato.
        local terrainH = GetTerrainHeight(markerX, markerZ)
        local surfaceH = GetSurfaceHeight(markerX, markerZ)
        if math.abs(surfaceH - terrainH) > 0.5 then
            LOG('[OWPlus] ForwardBase (' .. ownerName .. '): marker (' .. math.floor(markerX) .. ',' .. math.floor(markerZ)
                .. ') scartato, terreno non valido (terrainH=' .. string.format('%.1f', terrainH)
                .. ' surfaceH=' .. string.format('%.1f', surfaceH) .. ')')
            return -1
        end

        -- Marker accettato: registra per sempre (il reroll in caso di fallimento
        -- costruzione lo marchera' 'REJECTED' da hook/lua/platoon.lua)
        aiBrain.OWPlusForwardBaseMarkers[markerKey] = true

        -- Fase 9-F7: registra la posizione anche in OWPlusSubBases (stessa tabella
        -- gia' usata da OWPlusDispersedBuildAI per i nodi NE/SE/SW/NW) cosi'
        -- 'OWPlus Forward Extra Factory' (builder a MAIN) puo' inviare un ingegnere
        -- qui riusando il Plan gia' collaudato, invece del builder locale generico
        -- che non trovava mai un ingegnere disponibile (EngineerCount=0 alla forward base).
        aiBrain.OWPlusSubBases[slotKey] = { markerX, surfaceH, markerZ }

        LOG('[OWPlus] ForwardBase (' .. ownerName .. '): marker ACCETTATO tipo=' .. tostring(markerType)
            .. ' (' .. math.floor(markerX) .. ',' .. math.floor(markerZ)
            .. ') settore=' .. sector .. ' (diff=' .. string.format('%.0f', diffDeg) .. ' deg)'
            .. ' dist=' .. math.floor(markerDist)
            .. ' -> slot ' .. slotKey)

        -- 2000 > 1000 (UvesoExpansionArea) -> questo template vince il marker
        return 2000
    end,
}
