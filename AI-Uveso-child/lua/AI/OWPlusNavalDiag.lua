-- OWPlusNavalDiag.lua
--
-- Sess.102 (richiesta utente 2026-10-16): DIAGNOSTICA TEMPORANEA del navale di Overwhelm+, per
-- capire nei test e nelle partite come vanno le basi navali e i plotoni. Solo LOG: non cambia
-- nulla nella simulazione (nessun ordine, nessuno stato letto da altri sistemi).
-- Ogni OWPLUS_NAVAL_DIAG_INTERVAL secondi, per ogni IA Overwhelm+, tag [OWPlus-NAVAL-DIAG]:
--   BASE    per MAIN (se ha cantieri) e ogni base 'Naval Area': cantieri per tier, ingegneri,
--           difese (antinave / antiaeree / contro superficie / scudi / sonar), navi presenti
--   CANTIERI distanza minima tra due cantieri (verifica della distanza di 32)
--   PROD    navi vive per tier e famiglia, in attesa nell'ArmyPool, costruite in totale,
--           quante NON vengono dal catalogo (dovrebbero essere 0 a parte gli sperimentali)
--   PLOTONE nuovo plotone navale (builder, composizione), poi a ogni giro dimensione,
--           posizione, spostamento dall'ultimo giro e distanza dal nemico; fine plotone.
-- Togliere: OWPLUS_NAVAL_DIAG_ENABLED = false (o eliminare il thread in overwhelmplusai.lua).

local categories = categories
local OWPlusNavalCatalogMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusNavalCatalog.lua')

OWPLUS_NAVAL_DIAG_ENABLED = true
local OWPLUS_NAVAL_DIAG_INTERVAL = 60

local SHIP = categories.MOBILE * categories.NAVAL
local CATALOG_IDS = {}
for _, c in ipairs(OWPlusNavalCatalogMod.OWPLUS_NAVAL_CATALOG) do
    CATALOG_IDS[c[3]] = true
end

local function Tier(u)
    if EntityCategoryContains(categories.EXPERIMENTAL, u) then return 4 end
    if EntityCategoryContains(categories.TECH3, u) then return 3 end
    if EntityCategoryContains(categories.TECH2, u) then return 2 end
    return 1
end

local function Family(u)
    if EntityCategoryContains(categories.EXPERIMENTAL, u) then return 'sperimentale' end
    if EntityCategoryContains(OWPlusNavalCatalogMod.OWPlusNavalSubCategory, u) then return 'sub' end
    if EntityCategoryContains(OWPlusNavalCatalogMod.OWPlusNavalSurfaceCategory, u) then return 'superficie' end
    return 'altro'
end

local function OwnUnitsAround(aiBrain, cat, pos, radius)
    local n = 0
    for _, u in ipairs(aiBrain:GetUnitsAroundPoint(cat, pos, radius, 'Ally') or {}) do
        if not u.Dead and u:GetAIBrain() == aiBrain then
            n = n + 1
        end
    end
    return n
end

local function EnemyStart(aiBrain)
    local enemy = aiBrain:GetCurrentEnemy()
    if enemy then
        local x, z = enemy:GetArmyStartPos()
        if x then return x, z end
    end
    return nil
end

local function Fmt(x)
    return string.format('%.0f', x)
end

local function ReportBases(aiBrain, nick)
    local names = {}
    for name, mgr in aiBrain.BuilderManagers do
        if type(name) == 'string' and (name == 'MAIN' or mgr.BaseType == 'Naval Area') then
            table.insert(names, name)
        end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local mgr = aiBrain.BuilderManagers[name]
        local fm = mgr.FactoryManager
        local pos = fm and fm.Location or mgr.Position
        local radius = (fm and fm.Radius) or 60
        local yards = { 0, 0, 0 }
        for _, f in ipairs((fm and fm.FactoryList) or {}) do
            if not f.Dead and EntityCategoryContains(OWPlusNavalCatalogMod.OWPlusShipyardCategory, f) then
                local t = Tier(f)
                if t > 3 then t = 3 end
                yards[t] = yards[t] + 1
            end
        end
        local totalYards = yards[1] + yards[2] + yards[3]
        if pos and (name ~= 'MAIN' or totalYards > 0) then
            local engineers = mgr.EngineerManager and mgr.EngineerManager:GetNumCategoryUnits('Engineers', categories.ALLUNITS) or 0
            local def = categories.STRUCTURE * categories.DEFENSE
            LOG('[OWPlus-NAVAL-DIAG] [' .. nick .. '] BASE ' .. name .. ' (' .. tostring(mgr.BaseType) .. ') a (' .. Fmt(pos[1]) .. ',' .. Fmt(pos[3])
                .. ') raggio ' .. Fmt(radius) .. ' | cantieri T1/T2/T3 ' .. yards[1] .. '/' .. yards[2] .. '/' .. yards[3]
                .. ' | ingegneri ' .. engineers
                .. ' | difese antinave ' .. OwnUnitsAround(aiBrain, def * categories.ANTINAVY, pos, radius)
                .. ' antiaeree ' .. OwnUnitsAround(aiBrain, def * categories.ANTIAIR, pos, radius)
                .. ' superficie ' .. OwnUnitsAround(aiBrain, def * (categories.DIRECTFIRE + categories.INDIRECTFIRE), pos, radius)
                .. ' scudi ' .. OwnUnitsAround(aiBrain, categories.STRUCTURE * categories.SHIELD, pos, radius)
                .. ' sonar ' .. OwnUnitsAround(aiBrain, categories.STRUCTURE * categories.SONAR, pos, radius)
                .. ' | navi superficie ' .. OwnUnitsAround(aiBrain, OWPlusNavalCatalogMod.OWPlusNavalSurfaceCategory, pos, radius)
                .. ' sub ' .. OwnUnitsAround(aiBrain, OWPlusNavalCatalogMod.OWPlusNavalSubCategory, pos, radius))
        end
    end
    LOG('[OWPlus-NAVAL-DIAG] [' .. nick .. '] basi navali attive (GetManagerCount) ' .. aiBrain:GetManagerCount('Naval Area'))
end

local function ReportShipyardSpacing(aiBrain, nick)
    local pts = {}
    for _, u in ipairs(aiBrain:GetListOfUnits(OWPlusNavalCatalogMod.OWPlusShipyardCategory, false) or {}) do
        if not u.Dead then
            local p = u:GetPosition()
            table.insert(pts, { p[1], p[3] })
        end
    end
    local n = table.getn(pts)
    if n < 2 then
        LOG('[OWPlus-NAVAL-DIAG] [' .. nick .. '] CANTIERI ' .. n .. ' in totale')
        return
    end
    local best
    for i = 1, n - 1 do
        for j = i + 1, n do
            local d = VDist2(pts[i][1], pts[i][2], pts[j][1], pts[j][2])
            if not best or d < best then best = d end
        end
    end
    LOG('[OWPlus-NAVAL-DIAG] [' .. nick .. '] CANTIERI ' .. n .. ' in totale, distanza minima tra due cantieri ' .. Fmt(best)
        .. ' (obiettivo >= ' .. OWPlusNavalCatalogMod.OWPLUS_SHIPYARD_MIN_SPACING .. ')')
end

local function ReportProduction(aiBrain, nick)
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local alive = { 0, 0, 0, 0 }
    local fam = { superficie = 0, sub = 0, sperimentale = 0, altro = 0 }
    local waiting = 0
    aiBrain.OWPlusNavalBuilt = aiBrain.OWPlusNavalBuilt or { 0, 0, 0, 0 }
    aiBrain.OWPlusNavalBuiltNonCatalog = aiBrain.OWPlusNavalBuiltNonCatalog or 0
    aiBrain.OWPlusNavalBuiltById = aiBrain.OWPlusNavalBuiltById or {}
    local newIds = {}
    for _, u in ipairs(aiBrain:GetListOfUnits(SHIP, false) or {}) do
        if not u.Dead and not u:IsBeingBuilt() then
            local t = Tier(u)
            alive[t] = alive[t] + 1
            local f = Family(u)
            fam[f] = fam[f] + 1
            if u.PlatoonHandle == pool then
                waiting = waiting + 1
            end
            if not u.OWPlusNavalDiagCounted then
                u.OWPlusNavalDiagCounted = true
                aiBrain.OWPlusNavalBuilt[t] = aiBrain.OWPlusNavalBuilt[t] + 1
                local id = u.UnitId
                if not CATALOG_IDS[id] then
                    aiBrain.OWPlusNavalBuiltNonCatalog = aiBrain.OWPlusNavalBuiltNonCatalog + 1
                    table.insert(newIds, id .. '(fuori catalogo)')
                end
                aiBrain.OWPlusNavalBuiltById[id] = (aiBrain.OWPlusNavalBuiltById[id] or 0) + 1
            end
        end
    end
    local built = aiBrain.OWPlusNavalBuilt
    -- le 8 navi piu' costruite (ordinate per numero e poi per id, ordine stabile)
    local top = {}
    for id, n in aiBrain.OWPlusNavalBuiltById do
        table.insert(top, { id, n })
    end
    table.sort(top, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
    local topText = ''
    for i = 1, math.min(8, table.getn(top)) do
        topText = topText .. ' ' .. top[i][1] .. 'x' .. top[i][2]
    end
    LOG('[OWPlus-NAVAL-DIAG] [' .. nick .. '] PROD navi vive T1/T2/T3/T4 ' .. alive[1] .. '/' .. alive[2] .. '/' .. alive[3] .. '/' .. alive[4]
        .. ' (superficie ' .. fam.superficie .. ', sub ' .. fam.sub .. ', sperimentali ' .. fam.sperimentale .. ', altro ' .. fam.altro .. ')'
        .. ' | in attesa di plotone ' .. waiting
        .. ' | costruite in totale T1/T2/T3/T4 ' .. built[1] .. '/' .. built[2] .. '/' .. built[3] .. '/' .. built[4]
        .. ' | fuori catalogo ' .. aiBrain.OWPlusNavalBuiltNonCatalog
        .. ' | piu\' costruite:' .. topText)
    if table.getn(newIds) > 0 then
        LOG('[OWPlus-NAVAL-DIAG] [' .. nick .. '] PROD nuove navi fuori catalogo:' .. table.concat(newIds, ' '))
    end
end

local function PlatoonComposition(units)
    local t = { 0, 0, 0, 0 }
    local sub, surf = 0, 0
    for _, u in ipairs(units) do
        if not u.Dead then
            local tier = Tier(u)
            t[tier] = t[tier] + 1
            if Family(u) == 'sub' then sub = sub + 1 else surf = surf + 1 end
        end
    end
    return t[1] + t[2] + t[3] + t[4], 'T1/T2/T3/T4 ' .. t[1] .. '/' .. t[2] .. '/' .. t[3] .. '/' .. t[4] .. ' superficie ' .. surf .. ' sub ' .. sub
end

local function ReportPlatoons(aiBrain, nick)
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local ex, ez = EnemyStart(aiBrain)
    local now = GetGameTimeSeconds()
    aiBrain.OWPlusNavalDiagPlatoons = aiBrain.OWPlusNavalDiagPlatoons or {}
    -- nuovi plotoni con almeno una nave
    for _, p in ipairs(aiBrain:GetPlatoonsList() or {}) do
        if p ~= pool and not p.OWPlusNavalDiagId then
            local units = p:GetPlatoonUnits() or {}
            local hasShip = false
            for _, u in ipairs(units) do
                if not u.Dead and EntityCategoryContains(SHIP, u) then
                    hasShip = true
                    break
                end
            end
            if hasShip then
                aiBrain.OWPlusNavalDiagSerial = (aiBrain.OWPlusNavalDiagSerial or 0) + 1
                p.OWPlusNavalDiagId = aiBrain.OWPlusNavalDiagSerial
                local size, comp = PlatoonComposition(units)
                local builder = p.BuilderName or (p.PlatoonData and p.PlatoonData.OldBuilderName) or '?'
                local pos = p:GetPlatoonPosition()
                table.insert(aiBrain.OWPlusNavalDiagPlatoons, { id = p.OWPlusNavalDiagId, platoon = p, builder = builder, start = size, born = now, last = pos })
                LOG('[OWPlus-NAVAL-DIAG] [' .. nick .. '] PLOTONE #' .. p.OWPlusNavalDiagId .. ' NUOVO builder "' .. tostring(builder)
                    .. '" piano ' .. tostring(p.PlanName) .. ' unita\' ' .. size .. ' (' .. comp .. ')'
                    .. (pos and (' a (' .. Fmt(pos[1]) .. ',' .. Fmt(pos[3]) .. ')') or ''))
            end
        end
    end
    -- stato dei plotoni seguiti
    local kept = {}
    for _, e in ipairs(aiBrain.OWPlusNavalDiagPlatoons) do
        local p = e.platoon
        if not aiBrain:PlatoonExists(p) then
            LOG('[OWPlus-NAVAL-DIAG] [' .. nick .. '] PLOTONE #' .. e.id .. ' FINITO (sciolto o distrutto) builder "' .. tostring(e.builder)
                .. '" dopo ' .. Fmt(now - e.born) .. ' s, partito con ' .. e.start .. ' unita\'')
        else
            local size, comp = PlatoonComposition(p:GetPlatoonUnits() or {})
            local pos = p:GetPlatoonPosition()
            local text = '[OWPlus-NAVAL-DIAG] [' .. nick .. '] PLOTONE #' .. e.id .. ' "' .. tostring(e.builder) .. '" unita\' ' .. size .. '/' .. e.start
                .. ' (' .. comp .. ') eta\' ' .. Fmt(now - e.born) .. ' s'
            if pos then
                text = text .. ' a (' .. Fmt(pos[1]) .. ',' .. Fmt(pos[3]) .. ')'
                if e.last then
                    text = text .. ' spostato ' .. Fmt(VDist2(pos[1], pos[3], e.last[1], e.last[3]))
                end
                if ex then
                    text = text .. ' dal nemico ' .. Fmt(VDist2(pos[1], pos[3], ex, ez))
                end
                e.last = pos
            end
            LOG(text)
            table.insert(kept, e)
        end
    end
    aiBrain.OWPlusNavalDiagPlatoons = kept
end

function OWPlusNavalDiagReport(aiBrain)
    local nick = tostring(aiBrain.Nickname)
    LOG('[OWPlus-NAVAL-DIAG] [' .. nick .. '] ===== rapporto navale t=' .. Fmt(GetGameTimeSeconds()) .. ' s, acqua sulla mappa '
        .. Fmt(aiBrain:GetMapWaterRatio() * 100) .. '%, catalogo attivo=' .. tostring(OWPlusNavalCatalogMod.OWPlusNavalCatalogEnabled()))
    ReportBases(aiBrain, nick)
    ReportShipyardSpacing(aiBrain, nick)
    ReportProduction(aiBrain, nick)
    ReportPlatoons(aiBrain, nick)
end

function OWPlusNavalDiagThread(aiBrain)
    WaitSeconds(30)
    LOG('[OWPlus-NAVAL-DIAG] [' .. tostring(aiBrain.Nickname) .. '] OWPlusNavalDiagThread: OK, avviato (ogni ' .. OWPLUS_NAVAL_DIAG_INTERVAL .. ' s)')
    while aiBrain and not aiBrain:IsDefeated() do
        local ok, err = pcall(OWPlusNavalDiagReport, aiBrain)
        if not ok then
            WARN('[OWPlus-NAVAL-DIAG] [' .. tostring(aiBrain.Nickname) .. '] errore nel rapporto: ' .. tostring(err))
        end
        WaitSeconds(OWPLUS_NAVAL_DIAG_INTERVAL)
    end
end
