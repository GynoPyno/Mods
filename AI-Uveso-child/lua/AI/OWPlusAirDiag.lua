-- OWPlusAirDiag.lua
--
-- Sess.104 (Consegna A del piano aria/navi, richiesta utente 2026-11-21): DIAGNOSTICA dell'aria di
-- Overwhelm+, per MISURARE prima di cambiare i plotoni aerei. Solo LOG: non cambia nulla nella
-- simulazione (nessun ordine, nessuno stato letto da altri sistemi). Ogni OWPLUS_AIR_DIAG_INTERVAL
-- secondi, per ogni IA Overwhelm+, tag [OWPlus-AIR-DIAG]:
--   PROD     aerei vivi per tier e ruolo, in attesa nell'ArmyPool, costruiti in totale, quanti
--            aerei d'attacco NON vengono dal catalogo, le 8 unita' piu' costruite
--   NEMICO   per ogni armata avversaria: forza aerea nel conteggio del thread di superiorita'
--            (stessa funzione, OWPlusAirStrengthOf) contro TUTTI i suoi aerei, unita' di terra e
--            contraerea; serve a capire se "nemici=0" per 54 minuti era vero o un errore di conteggio
--   PLOTONE  nuovo plotone aereo d'attacco (builder, composizione, distanza dal nemico), fine del
--            plotone (vita, dimensione massima, distanza dal nemico alla fine) e riepilogo di quelli
--            vivi: misura "si forma, va avanti, fine" e quanto crescono davvero
-- Togliere: OWPLUS_AIR_DIAG_ENABLED = false (o eliminare il thread in overwhelmplusai.lua).

local categories = categories
local OWPlusAirCatalogMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusAirCatalog.lua')

OWPLUS_AIR_DIAG_ENABLED = true
local OWPLUS_AIR_DIAG_INTERVAL = 30     -- secondi tra due giri (plotoni a ogni giro)
local OWPLUS_AIR_DIAG_PROD_EVERY = 2    -- PROD e NEMICO ogni 2 giri (60 s)

local AIR = categories.MOBILE * categories.AIR
local CATALOG_IDS = {}
for _, c in ipairs(OWPlusAirCatalogMod.OWPLUS_AIR_CATALOG) do
    CATALOG_IDS[c[4]] = true
end

local function Fmt(x)
    return string.format('%.0f', x)
end

local function Tier(u)
    if EntityCategoryContains(categories.EXPERIMENTAL, u) then return 4 end
    if EntityCategoryContains(categories.TECH3, u) then return 3 end
    if EntityCategoryContains(categories.TECH2, u) then return 2 end
    return 1
end

-- Ruolo di un aereo, nell'ordine: sperimentale, caccia/suolo (stesse categorie del catalogo e dei
-- plotoni), poi le famiglie escluse dal catalogo
local ROLES = { 'caccia', 'suolo', 'sperimentale', 'scout', 'trasporto', 'silurante', 'altro' }
local function Role(u)
    if EntityCategoryContains(categories.EXPERIMENTAL, u) then return 'sperimentale' end
    if EntityCategoryContains(OWPlusAirCatalogMod.OWPlusAirFighterCategory, u) then return 'caccia' end
    if EntityCategoryContains(OWPlusAirCatalogMod.OWPlusAirGroundCategory, u) then return 'suolo' end
    if EntityCategoryContains(categories.SCOUT, u) then return 'scout' end
    if EntityCategoryContains(categories.TRANSPORTFOCUS, u) then return 'trasporto' end
    if EntityCategoryContains(categories.ANTINAVY, u) then return 'silurante' end
    return 'altro'
end

local function RoleCounts()
    local t = {}
    for _, r in ipairs(ROLES) do
        t[r] = 0
    end
    return t
end

local function RoleText(t)
    local s = ''
    for _, r in ipairs(ROLES) do
        if t[r] > 0 then
            s = s .. ' ' .. r .. ' ' .. t[r]
        end
    end
    if s == '' then s = ' nessuno' end
    return s
end

local function EnemyStart(aiBrain)
    local enemy = aiBrain:GetCurrentEnemy()
    if enemy then
        local x, z = enemy:GetArmyStartPos()
        if x then return x, z end
    end
    return nil
end

local function DistToEnemy(aiBrain, pos)
    local ex, ez = EnemyStart(aiBrain)
    if ex and pos and pos[1] then
        return Fmt(VDist2(pos[1], pos[3], ex, ez))
    end
    return '?'
end

-- ---------------------------------------------------------------------------
-- PROD
-- ---------------------------------------------------------------------------
local function ReportProduction(aiBrain, nick)
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local alive = { 0, 0, 0, 0 }
    local roles = RoleCounts()
    local waiting = 0
    aiBrain.OWPlusAirBuilt = aiBrain.OWPlusAirBuilt or { 0, 0, 0, 0 }
    aiBrain.OWPlusAirBuiltNonCatalog = aiBrain.OWPlusAirBuiltNonCatalog or 0
    aiBrain.OWPlusAirBuiltById = aiBrain.OWPlusAirBuiltById or {}
    local newIds = {}
    for _, u in ipairs(aiBrain:GetListOfUnits(AIR, false) or {}) do
        if not u.Dead and not u:IsBeingBuilt() then
            local t = Tier(u)
            local r = Role(u)
            alive[t] = alive[t] + 1
            roles[r] = roles[r] + 1
            if (r == 'caccia' or r == 'suolo') and u.PlatoonHandle == pool then
                waiting = waiting + 1
            end
            if not u.OWPlusAirDiagCounted then
                u.OWPlusAirDiagCounted = true
                aiBrain.OWPlusAirBuilt[t] = aiBrain.OWPlusAirBuilt[t] + 1
                local id = u.UnitId
                if (r == 'caccia' or r == 'suolo') and not CATALOG_IDS[id] then
                    aiBrain.OWPlusAirBuiltNonCatalog = aiBrain.OWPlusAirBuiltNonCatalog + 1
                    table.insert(newIds, id .. '(fuori catalogo)')
                end
                aiBrain.OWPlusAirBuiltById[id] = (aiBrain.OWPlusAirBuiltById[id] or 0) + 1
            end
        end
    end
    local built = aiBrain.OWPlusAirBuilt
    local top = {}
    for id, n in aiBrain.OWPlusAirBuiltById do
        table.insert(top, { id, n })
    end
    table.sort(top, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
    local topText = ''
    for i = 1, math.min(8, table.getn(top)) do
        topText = topText .. ' ' .. top[i][1] .. 'x' .. top[i][2]
    end
    LOG('[OWPlus-AIR-DIAG] [' .. nick .. '] PROD aerei vivi T1/T2/T3/T4 ' .. alive[1] .. '/' .. alive[2] .. '/' .. alive[3] .. '/' .. alive[4]
        .. ' (' .. RoleText(roles) .. ' )'
        .. ' | in attesa di plotone ' .. waiting
        .. ' | costruiti in totale T1/T2/T3/T4 ' .. built[1] .. '/' .. built[2] .. '/' .. built[3] .. '/' .. built[4]
        .. ' | fuori catalogo ' .. aiBrain.OWPlusAirBuiltNonCatalog
        .. ' | piu\' costruiti:' .. topText)
    if table.getn(newIds) > 0 then
        LOG('[OWPlus-AIR-DIAG] [' .. nick .. '] PROD nuovi aerei d\'attacco fuori catalogo:' .. table.concat(newIds, ' '))
    end
end

-- ---------------------------------------------------------------------------
-- NEMICO
-- ---------------------------------------------------------------------------
local function ReportEnemies(aiBrain, nick)
    local myIndex = aiBrain:GetArmyIndex()
    local n = 0
    for _, brain in ipairs(ArmyBrains) do
        local idx = brain:GetArmyIndex()
        if idx ~= myIndex then
            n = n + 1
            local civ = 'n/d'
            if ArmyIsCivilian then
                civ = tostring(ArmyIsCivilian(idx))
            end
            local strCount, strMass = OWPlusAirCatalogMod.OWPlusAirStrengthOf(brain)
            local totalAir, scouts, transports = 0, 0, 0
            local byId = {}
            for _, u in ipairs(brain:GetListOfUnits(AIR, false) or {}) do
                if not u.Dead and u:GetFractionComplete() >= 1 then
                    totalAir = totalAir + 1
                    if EntityCategoryContains(categories.SCOUT, u) then scouts = scouts + 1 end
                    if EntityCategoryContains(categories.TRANSPORTFOCUS, u) then transports = transports + 1 end
                    -- "ID/ruolo": il ruolo e' quello del catalogo; 'altro' = fuori dal conteggio d'attacco
                    local key = tostring(u.UnitId) .. '/' .. Role(u)
                    byId[key] = (byId[key] or 0) + 1
                end
            end
            local top = {}
            for key, cnt in byId do
                table.insert(top, { key, cnt })
            end
            table.sort(top, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
            local topText = ''
            for i = 1, math.min(6, table.getn(top)) do
                topText = topText .. ' ' .. top[i][1] .. 'x' .. top[i][2]
            end
            local land = table.getn(brain:GetListOfUnits(categories.MOBILE * categories.LAND, false) or {})
            local aaMobile = table.getn(brain:GetListOfUnits(categories.MOBILE * categories.ANTIAIR, false) or {})
            local aaStruct = table.getn(brain:GetListOfUnits(categories.STRUCTURE * categories.ANTIAIR, false) or {})
            LOG('[OWPlus-AIR-DIAG] [' .. nick .. '] NEMICO ' .. tostring(brain.Nickname) .. ' (armata ' .. idx .. ')'
                .. ' ostile=' .. tostring(IsEnemy(myIndex, idx)) .. ' sconfitta=' .. tostring(brain:IsDefeated()) .. ' civile=' .. civ
                .. ' | aerei nel conteggio del thread ' .. strCount .. ' (' .. Fmt(strMass) .. ' massa)'
                .. ' | aerei totali ' .. totalAir .. ' (scout ' .. scouts .. ', trasporti ' .. transports .. ')'
                .. ' | tipi piu\' numerosi (ID/ruolo):' .. topText
                .. ' | unita\' di terra ' .. land .. ' | antiaeree mobili ' .. aaMobile .. ' fisse ' .. aaStruct)
        end
    end
    if n == 0 then
        LOG('[OWPlus-AIR-DIAG] [' .. nick .. '] NEMICO nessuna altra armata in ArmyBrains')
    end
end

-- ---------------------------------------------------------------------------
-- PLOTONE
-- ---------------------------------------------------------------------------
local function PlatoonStats(units)
    local roles = RoleCounts()
    local t = { 0, 0, 0, 0 }
    local live = 0
    for _, u in ipairs(units) do
        if not u.Dead then
            live = live + 1
            roles[Role(u)] = roles[Role(u)] + 1
            local tier = Tier(u)
            t[tier] = t[tier] + 1
        end
    end
    return live, roles, t
end

local function ReportPlatoons(aiBrain, nick)
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local now = GetGameTimeSeconds()
    aiBrain.OWPlusAirDiagPlatoons = aiBrain.OWPlusAirDiagPlatoons or {}
    -- nuovi plotoni con almeno un aereo d'attacco o sperimentale (gli esploratori da 1 non contano)
    for _, p in ipairs(aiBrain:GetPlatoonsList() or {}) do
        if p ~= pool and not p.OWPlusAirDiagId then
            local units = p:GetPlatoonUnits() or {}
            local live, roles, tiers = PlatoonStats(units)
            if roles.caccia + roles.suolo + roles.sperimentale > 0 then
                aiBrain.OWPlusAirDiagSerial = (aiBrain.OWPlusAirDiagSerial or 0) + 1
                p.OWPlusAirDiagId = aiBrain.OWPlusAirDiagSerial
                local pos = p:GetPlatoonPosition()
                local builder = p.BuilderName or (p.PlatoonData and p.PlatoonData.OldBuilderName) or '?'
                table.insert(aiBrain.OWPlusAirDiagPlatoons, { plat = p, id = p.OWPlusAirDiagId, builder = builder, born = now, maxSize = live })
                LOG('[OWPlus-AIR-DIAG] [' .. nick .. '] PLOTONE #' .. p.OWPlusAirDiagId .. ' NUOVO builder "' .. tostring(builder)
                    .. '" piano ' .. tostring(p.PlanName) .. ' unita\' ' .. live .. ' (T1/T2/T3/T4 ' .. tiers[1] .. '/' .. tiers[2] .. '/' .. tiers[3] .. '/' .. tiers[4]
                    .. ';' .. RoleText(roles) .. ' )' .. ' a (' .. (pos and Fmt(pos[1]) or '?') .. ',' .. (pos and Fmt(pos[3]) or '?')
                    .. ') distanza dal nemico ' .. DistToEnemy(aiBrain, pos))
            end
        end
    end
    -- plotoni seguiti: aggiorna la dimensione massima, riporta la fine
    local kept = {}
    local alive = {}
    for _, e in ipairs(aiBrain.OWPlusAirDiagPlatoons) do
        local p = e.plat
        local live = 0
        if aiBrain:PlatoonExists(p) then
            live = PlatoonStats(p:GetPlatoonUnits() or {})
        end
        if live > 0 then
            if live > e.maxSize then e.maxSize = live end
            e.lastSize = live
            local pos = p:GetPlatoonPosition()
            e.lastPos = pos and { pos[1], pos[2], pos[3] } or e.lastPos
            table.insert(kept, e)
            table.insert(alive, '#' .. e.id .. ':' .. live)
        else
            LOG('[OWPlus-AIR-DIAG] [' .. nick .. '] PLOTONE #' .. e.id .. ' FINITO (sciolto o distrutto) builder "' .. tostring(e.builder)
                .. '" vissuto ' .. Fmt(now - e.born) .. ' s, dimensione massima ' .. e.maxSize .. ', ultima ' .. tostring(e.lastSize or e.maxSize)
                .. ', distanza dal nemico all\'ultima posizione ' .. DistToEnemy(aiBrain, e.lastPos))
        end
    end
    aiBrain.OWPlusAirDiagPlatoons = kept
    LOG('[OWPlus-AIR-DIAG] [' .. nick .. '] PLOTONI vivi ' .. table.getn(kept) .. ': ' .. table.concat(alive, ' '))
end

-- ---------------------------------------------------------------------------
-- PERCHE' UN PLOTONE AEREO NON TROVA UN BERSAGLIO (Consegna A, passo 1)
-- ---------------------------------------------------------------------------
-- Chiamata da HeroFightPlatoon (hook/lua/platoon.lua, override del child) PRIMA del piano nativo, solo
-- per i plotoni con PlatoonData.OWPlusAirAttack (i 5 batch di 'OWPlus Air Attack Batching.lua'). Rifa' la
-- stessa ricerca nativa (AIFindNearestCategoryTargetInRange, stesso punto di partenza di HeroFightPlatoon)
-- e, se non trova nulla, ripete la scansione contando perche' ogni candidato e' stato scartato, con gli
-- stessi criteri della funzione nativa (AI-Uveso/hook/lua/AI/aiutilities.lua): visto/radar, attaccabile,
-- minaccia della cella contro forza del plotone * AttackEnemyStrength / 100. Un log per plotone, tag
-- [OWPlus-AIRWAVE]. Non cambia nessun comportamento: il piano nativo parte subito dopo, identico.
local function PlatoonStrengthPoints(platoon)
    local s = 0
    for _, unit in platoon:GetPlatoonUnits() do
        if not unit.Dead then
            local h = unit.Blueprint and unit.Blueprint.CategoriesHash
            if h then
                if h.TECH1 then s = s + 1
                elseif h.TECH2 then s = s + 3
                elseif h.TECH3 then s = s + 13
                elseif h.EXPERIMENTAL then s = s + 80
                elseif h.COMMAND then s = s + 20 end
            end
        end
    end
    return s
end

function OWPlusAirWhyNoTarget(platoon)
    if not OWPLUS_AIR_DIAG_ENABLED then
        return
    end
    local aiBrain = platoon:GetBrain()
    local nick = tostring(aiBrain.Nickname)
    local data = platoon.PlatoonData or {}
    local tag = '[OWPlus-AIRWAVE] [' .. nick .. '] "' .. tostring(platoon.BuilderName) .. '" t=' .. Fmt(GetGameTimeSeconds())
    local AITargetManager = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua')
    local AIUtils = import('/lua/ai/aiutilities.lua')
    local AIAttackUtils = import('/lua/ai/aiattackutilities.lua')
    AIAttackUtils.GetMostRestrictiveLayer(platoon)
    local layer = platoon.MovementLayer
    local armyIndex = aiBrain:GetArmyIndex()
    local maxRadius = data.SearchRadius or 100
    local attackPct = data.AttackEnemyStrength or 100
    local moveTo = {}
    for _, c in ipairs(data.MoveToCategories or {}) do
        table.insert(moveTo, c)
    end
    local searchCat = data.TargetSearchCategory
    local pos = platoon:GetPlatoonPosition()
    if not pos or not pos[1] or not searchCat then
        LOG(tag .. ' AIRWAVE: dati insufficienti (posizione o categoria di ricerca mancanti)')
        return
    end
    -- stesso punto di partenza di HeroFightPlatoon quando GetTargetsFromBase e' falso
    local from, src = pos, 'posizione del plotone'
    local ht = aiBrain.highestEnemyThreat and aiBrain.highestEnemyThreat[layer] and aiBrain.highestEnemyThreat[layer][1]
    local eco = aiBrain.highestEnemyEcoValue and aiBrain.highestEnemyEcoValue['All'] and aiBrain.highestEnemyEcoValue['All'][1]
    if ht then
        from = AITargetManager.GetHeatMapGridPositionFromIndex(armyIndex, ht.gridPos[1], ht.gridPos[2])
        src = 'cella di massima minaccia ' .. layer
    elseif eco then
        from = AITargetManager.GetHeatMapGridPositionFromIndex(armyIndex, eco.gridPos[1], eco.gridPos[2])
        src = 'cella di massimo valore nemico'
    end
    local strength = PlatoonStrengthPoints(platoon)
    local allowed = strength / 100 * attackPct
    local head = ' ' .. table.getn(platoon:GetPlatoonUnits()) .. ' unita\' forza ' .. strength .. ' (ammessa minaccia ' .. string.format('%.1f', allowed)
        .. ' = ' .. attackPct .. '%), ricerca da ' .. src .. ' raggio ' .. Fmt(maxRadius) .. ': '
    local uwp, unp, _, reason = AIUtils.AIFindNearestCategoryTargetInRange(aiBrain, platoon, 'Attack', from, maxRadius, moveTo, searchCat, false)
    local found = uwp or unp
    if found and not found.Dead then
        local tp = found:GetPosition()
        LOG(tag .. head .. 'OK, bersaglio nativo ' .. tostring(found.UnitId) .. ' a ' .. Fmt(VDist2(pos[1], pos[3], tp[1], tp[3]))
            .. ' dal plotone, ' .. (uwp and 'con percorso' or 'senza percorso'))
        return
    end
    -- nessun bersaglio: ripeto la scansione contando i motivi di scarto
    local heatMap = AITargetManager.GetHeatMapForArmy(armyIndex)
    local counts = { totali = 0, categoria = 0, nonVisti = 0, nonAttaccabili = 0, troppoDifesi = 0, idonei = 0 }
    local minThreat, maxThreat
    local seen = {}
    for _, t in ipairs(aiBrain:GetUnitsAroundPoint(searchCat, from, maxRadius, 'Enemy') or {}) do
        if not t.Dead and not seen[t.EntityId] then
            seen[t.EntityId] = true
            counts.totali = counts.totali + 1
            local inCat = false
            for _, c in ipairs(moveTo) do
                if EntityCategoryContains(c, t) then inCat = true break end
            end
            if not inCat then
                counts.categoria = counts.categoria + 1
            elseif not platoon:CanAttackTarget('Attack', t) then
                counts.nonAttaccabili = counts.nonAttaccabili + 1
            else
                local blip = t:GetBlip(armyIndex)
                local visible = blip and (blip:IsOnRadar(armyIndex) or blip:IsSeenEver(armyIndex))
                    and not blip:BeenDestroyed() and not blip:IsKnownFake(armyIndex) and not blip:IsMaybeDead(armyIndex)
                if not visible then
                    counts.nonVisti = counts.nonVisti + 1
                else
                    local tp = t:GetPosition()
                    local x, z = AITargetManager.GetHeatMapGridIndexFromPosition(tp)
                    local threat = (heatMap[x] and heatMap[x][z] and heatMap[x][z].threatRing and heatMap[x][z].threatRing[layer]) or 0
                    if not minThreat or threat < minThreat then minThreat = threat end
                    if not maxThreat or threat > maxThreat then maxThreat = threat end
                    if allowed < threat then
                        counts.troppoDifesi = counts.troppoDifesi + 1
                    else
                        counts.idonei = counts.idonei + 1
                    end
                end
            end
        end
    end
    LOG(tag .. head .. 'NESSUN bersaglio nativo (' .. tostring(reason) .. '). Candidati: ' .. counts.totali .. ' nel raggio, fuori dalle categorie del builder '
        .. counts.categoria .. ', non attaccabili ' .. counts.nonAttaccabili .. ', non visti/radar ' .. counts.nonVisti
        .. ', troppo difesi ' .. counts.troppoDifesi .. ' (minaccia della cella da ' .. tostring(minThreat and string.format('%.1f', minThreat) or '-')
        .. ' a ' .. tostring(maxThreat and string.format('%.1f', maxThreat) or '-') .. '), idonei ' .. counts.idonei)
end

-- ---------------------------------------------------------------------------
function OWPlusAirDiagReport(aiBrain)
    local nick = tostring(aiBrain.Nickname)
    aiBrain.OWPlusAirDiagRound = (aiBrain.OWPlusAirDiagRound or 0) + 1
    LOG('[OWPlus-AIR-DIAG] [' .. nick .. '] ===== rapporto aereo t=' .. Fmt(GetGameTimeSeconds()) .. ' s, quota caccia '
        .. string.format('%.0f', (aiBrain.OWPlusAirFighterShare or 0) * 100) .. '%')
    if math.mod(aiBrain.OWPlusAirDiagRound, OWPLUS_AIR_DIAG_PROD_EVERY) == 1 then
        ReportProduction(aiBrain, nick)
        ReportEnemies(aiBrain, nick)
    end
    ReportPlatoons(aiBrain, nick)
end

function OWPlusAirDiagThread(aiBrain)
    WaitSeconds(30)
    LOG('[OWPlus-AIR-DIAG] [' .. tostring(aiBrain.Nickname) .. '] OWPlusAirDiagThread: OK, avviato (ogni ' .. OWPLUS_AIR_DIAG_INTERVAL .. ' s)')
    while aiBrain and not aiBrain:IsDefeated() do
        local ok, err = pcall(OWPlusAirDiagReport, aiBrain)
        if not ok then
            WARN('[OWPlus-AIR-DIAG] [' .. tostring(aiBrain.Nickname) .. '] errore nel rapporto: ' .. tostring(err))
        end
        WaitSeconds(OWPLUS_AIR_DIAG_INTERVAL)
    end
end
