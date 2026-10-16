-- OWPlusNavalCatalog.lua
--
-- Sess.102 (decisioni utente 2026-10-15/16, approccio A): navale di Overwhelm+.
--  * Basi navali: le fonda il nostro gruppo 'OWPlus Naval Expansion' (copia dei builder nativi
--    "Vacant NavalArea") con il tetto OWPLUS_NAVAL_BASES_MAX; il template della base e'
--    OWPlusExpansionNaval (AIBaseTemplates). Il template nativo di Uveso resta per le altre IA.
--  * Cantieri: per Overwhelm+ il punto di costruzione lo sceglie OWPlusFindShipyardSpot (anelli
--    attorno alla base, almeno OWPLUS_SHIPYARD_MIN_SPACING tra i centri dei cantieri, compresi
--    quelli appena prenotati, e acqua tutto intorno). Chiamata da hook/lua/AI/aibuildstructures.lua.
--  * Produzione: catalogo di 62 navi (vanilla + moddate), un template per unita'
--    (OWPlus PlatoonTemplates Naval Catalog.lua), fasce per tier con probabilita' uguale dentro
--    il tier (decisione utente: niente adattamento per ora), T1 solo finche' non c'e' un
--    cantiere T2/T3. Esclusi: sperimentali (fase dedicata), sottomarini nucleari strategici,
--    Nomadi, portaerei (backlog: dovranno costruire aerei e usarli).
--  * Plotoni: due famiglie per fisica (superficie / sottomarini), a lotti, formati per base.
--
-- Rollback: OWPlusNavalCatalogDisabled = true (OWPlusFactoryTargets.lua).
-- Determinismo (regola 38t): solo array con ipairs, nessun pairs() su chiavi-oggetto.

local categories = categories
local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')
local OWPlusAirCatalogMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusAirCatalog.lua')

OWPLUS_NAVAL_BASES_MAX = 2
OWPLUS_SHIPYARD_MIN_SPACING = 32
local OWPLUS_SHIPYARD_SEARCH_MAX_RADIUS = 80
local OWPLUS_SHIPYARD_RING_STEP = 8
local OWPLUS_SHIPYARD_WATER_RING = 14
local OWPLUS_SHIPYARD_RESERVATION_SECONDS = 90
local OWPLUS_SHIPYARD_MAP_MARGIN = 12

-- Plotoni: stesse categorie dei template (OWPlus PlatoonTemplates Naval Catalog.lua).
-- Superficie: tutto cio' che non va sott'acqua, navi di supporto comprese (Bulwark, Mermaid).
-- Sottomarini: le unita' SUBMERSIBLE, compresi i cacciatorpedinieri che si immergono (Uashavoh).
OWPlusNavalSurfaceCategory = categories.MOBILE * categories.NAVAL - categories.SUBMERSIBLE
    - categories.EXPERIMENTAL - categories.CARRIER - categories.MOBILESONAR
-- Sess.102 (correzione utente): i sottomarini nucleari STRATEGICI si escludono per ID, non con
-- categories.NUKE, che ha anche il Seawolf di BlackOps (sottomarino d'attacco T3 UEF con missile
-- nucleare TATTICO, NukeWeapon = false).
OWPlusNavalSubCategory = categories.MOBILE * categories.NAVAL * categories.SUBMERSIBLE
    - categories.EXPERIMENTAL - categories.CARRIER
    - categories.uas0304 - categories.ues0304 - categories.urs0304

-- Cantieri veri: l'entita' '<id>ef' delle portaerei e' STRUCTURE FACTORY NAVAL (Conoscenze_acquisite_51 §51.1)
OWPlusShipyardCategory = categories.STRUCTURE * categories.FACTORY * categories.NAVAL - categories.EXTERNALFACTORYUNIT

-- { tier, fazione (chiave FactionSquads), id } — generato dal censimento dei blueprint (sess.101)
OWPLUS_NAVAL_CATALOG = {
    { 1, 'Aeon',     'brost1battleship' },      -- Undine Class (TotalMayhem)
    { 1, 'Aeon',     'brost1destr' },           -- Chronos Class (TotalMayhem)
    { 1, 'Aeon',     'uas0102' },               -- Shard (vanilla)
    { 1, 'Aeon',     'uas0103' },               -- Beacon Class (vanilla)
    { 1, 'Aeon',     'uas0203' },               -- Sylph (vanilla)
    { 1, 'Cybran',   'brmst1battlecruiser' },   -- Coelacanth Class (TotalMayhem)
    { 1, 'Cybran',   'brmst1destr' },           -- Charcaradon Class (TotalMayhem)
    { 1, 'Cybran',   'urs0103' },               -- Trident Class (vanilla)
    { 1, 'Cybran',   'urs0203' },               -- Sliver (vanilla)
    { 1, 'Seraphim', 'xss0103' },               -- Hau-esel (vanilla)
    { 1, 'Seraphim', 'xss0203' },               -- Sou-istle (vanilla)
    { 1, 'UEF',      'brnst1artillery' },       -- Polestar Class (TotalMayhem)
    { 1, 'UEF',      'brnst1battleship' },      -- Meridian Class (TotalMayhem)
    { 1, 'UEF',      'ues0103' },               -- Thunderhead Class (vanilla)
    { 1, 'UEF',      'ues0203' },               -- Tigershark (vanilla)
    { 2, 'Aeon',     'uas0201' },               -- Exodus Class (vanilla)
    { 2, 'Aeon',     'uas0202' },               -- Infinity Class (vanilla)
    { 2, 'Aeon',     'xas0204' },               -- Vesper (vanilla)
    { 2, 'Cybran',   'anc_urs202' },            -- Defender Class (Antares Unit Pack)
    { 2, 'Cybran',   'urs0201' },               -- Salem Class (vanilla)
    { 2, 'Cybran',   'urs0202' },               -- Siren Class (vanilla)
    { 2, 'Cybran',   'xrs0204' },               -- Barracuda (vanilla)
    { 2, 'Cybran',   'xrs0205' },               -- CI:18 Mermaid (vanilla)
    { 2, 'Seraphim', 'bss0206' },               -- Zthuzene (BlackOpsFAF-Unleashed)
    { 2, 'Seraphim', 'xss0201' },               -- Uashavoh (vanilla)
    { 2, 'Seraphim', 'xss0202' },               -- Ithalua (vanilla)
    { 2, 'UEF',      'kes0201' },               -- Beirut Class (#Marlos mods compilation)
    { 2, 'UEF',      'ues0201' },               -- Valiant Class (vanilla)
    { 2, 'UEF',      'ues0202' },               -- Governor Class (vanilla)
    { 2, 'UEF',      'xes0102' },               -- Cooper (vanilla)
    { 2, 'UEF',      'xes0205' },               -- Bulwark (vanilla)
    { 3, 'Aeon',     'brost3bship' },           -- Lupen Class (TotalMayhem)
    { 3, 'Aeon',     'eas0302' },               -- Messiah Class (BlackOpsFAF-EXUnits)
    { 3, 'Aeon',     'kas0301' },               -- IOWA Class (#Marlos mods compilation)
    { 3, 'Aeon',     'kas0302' },               -- Infiltrator Class (#Marlos mods compilation)
    { 3, 'Aeon',     'uas0302' },               -- Omen Class (vanilla)
    { 3, 'Aeon',     'was0332' },               -- Shadow of Intent (Antares Unit Pack / BattlePack)
    { 3, 'Aeon',     'xas0306' },               -- Torrent Class (vanilla)
    { 3, 'Cybran',   'brs0304' },               -- Reaper Class (BlackOpsFAF-Unleashed)
    { 3, 'Cybran',   'brs0305' },               -- Leviathan (BlackOpsFAF-Unleashed)
    { 3, 'Cybran',   'ers0302' },               -- Aries Class (BlackOpsFAF-EXUnits)
    { 3, 'Cybran',   'krs0301' },               -- Universe Class (#Marlos mods compilation)
    { 3, 'Cybran',   'krs0302' },               -- Sadam Class (#Marlos mods compilation)
    { 3, 'Cybran',   'krs0401' },               -- Lockdown Class (#Marlos mods compilation)
    { 3, 'Cybran',   'urs0302' },               -- Galaxy Class (vanilla)
    { 3, 'Cybran',   'urs_prg' },               -- Deviater Class (Antares Unit Pack)
    { 3, 'Cybran',   'wrs0303' },               -- Executioner Class (BattlePack)
    { 3, 'Seraphim', 'bss0306' },               -- Ithaluthe-Esel (BlackOpsFAF-Unleashed)
    { 3, 'Seraphim', 'kss0301' },               -- Uan shal voh (#Marlos mods compilation)
    { 3, 'Seraphim', 'kss0401' },               -- Ithalia (#Marlos mods compilation)
    { 3, 'Seraphim', 'wss0301' },               -- Echigo (Antares Unit Pack / BattlePack)
    { 3, 'Seraphim', 'wss0401' },               -- Eechibumas (BattlePack)
    { 3, 'Seraphim', 'xss0302' },               -- Hauthuum (vanilla)
    { 3, 'Seraphim', 'xss0304' },               -- Yathsou (vanilla)
    { 3, 'UEF',      'ees0301' },               -- Seawolf, sottomarino d'attacco (BlackOpsFAF-EXUnits)
    { 3, 'UEF',      'ees0302' },               -- Knox Class (BlackOpsFAF-EXUnits)
    { 3, 'UEF',      'kes0301' },               -- Everest Class (#Marlos mods compilation)
    { 3, 'UEF',      'kes0302' },               -- Iwojima Class (#Marlos mods compilation)
    { 3, 'UEF',      'kes0401' },               -- Guada Class (#Marlos mods compilation)
    { 3, 'UEF',      'ues0302' },               -- Summit Class (vanilla)
    { 3, 'UEF',      'wes0303' },               -- Posideon Class (BattlePack)
    { 3, 'UEF',      'xes0307' },               -- Neptune Class (vanilla)
}

function OWPlusNavalTemplateName(c)
    return 'OWPlus Naval T' .. c[1] .. ' ' .. c[2] .. ' ' .. c[3]
end

function OWPlusNavalCatalogEnabled()
    return not OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled
end

function OWPlusIsPlusBrain(aiBrain)
    return OWPlusAirCatalogMod.OWPlusIsPlusBrain(aiBrain)
end

-- ===========================================================================
-- Tetto basi navali (sostituisce IsNavalExpansionsAllowed nei nostri builder di fondazione)
-- ===========================================================================
-- Come il nativo: almeno il 20% d'acqua sulla mappa e meno basi navali del limite di lobby
-- (NavalExpansionsAllowed, default di lobby '4'); in piu' il nostro tetto OWPLUS_NAVAL_BASES_MAX.
-- Opzione assente (lancio da riga di comando) -> vale solo il nostro tetto.
function OWPlusNavalExpansionAllowed(aiBrain)
    if not OWPlusNavalCatalogEnabled() then
        return false
    end
    if aiBrain:GetMapWaterRatio() < 0.2 then
        return false
    end
    local cap = OWPLUS_NAVAL_BASES_MAX
    local lobby = tonumber(ScenarioInfo.Options and ScenarioInfo.Options.NavalExpansionsAllowed)
    if lobby and lobby < cap then
        cap = lobby
    end
    local exist = aiBrain:GetManagerCount('Naval Area')
    if exist ~= aiBrain.OWPlusNavalBasesLogged then
        aiBrain.OWPlusNavalBasesLogged = exist
        LOG('[OWPlus-NAVAL] OWPlusNavalExpansionAllowed: basi navali ' .. exist .. '/' .. cap
            .. ' (lobby=' .. tostring(lobby) .. ') [' .. tostring(aiBrain.Nickname) .. ']')
    end
    return exist < cap
end

-- ===========================================================================
-- Punto di costruzione per un cantiere, distanziato dagli altri
-- ===========================================================================
local function OWPlusIsWater(x, z)
    return GetSurfaceHeight(x, z) > GetTerrainHeight(x, z) + 0.5
end

-- Vero se il punto ha acqua tutto intorno (8 punti a OWPLUS_SHIPYARD_WATER_RING): spazio per le
-- navi che escono, al posto dell'ingombro del Tempest che Uveso usa nella sua ricerca nativa.
local function OWPlusHasWaterAround(x, z)
    local d = OWPLUS_SHIPYARD_WATER_RING
    local diag = d * 0.7071
    local offsets = { {d, 0}, {-d, 0}, {0, d}, {0, -d}, {diag, diag}, {diag, -diag}, {-diag, diag}, {-diag, -diag} }
    for _, o in ipairs(offsets) do
        if not OWPlusIsWater(x + o[1], z + o[2]) then
            return false
        end
    end
    return true
end

-- Cantieri esistenti (anche in costruzione) + prenotazioni recenti, come lista di {x, z}.
-- Le prenotazioni coprono i cantieri messi in coda dallo stesso ingegnere (BuildStructures con
-- due 'T1SeaFactory') prima che il primo esista come unita'.
local function OWPlusShipyardPoints(aiBrain)
    local now = GetGameTimeSeconds()
    local kept = {}
    for _, r in ipairs(aiBrain.OWPlusShipyardReservations or {}) do
        if now - r[3] < OWPLUS_SHIPYARD_RESERVATION_SECONDS then
            table.insert(kept, r)
        end
    end
    aiBrain.OWPlusShipyardReservations = kept
    local points = {}
    for _, r in ipairs(kept) do
        table.insert(points, { r[1], r[2] })
    end
    for _, u in ipairs(aiBrain:GetListOfUnits(OWPlusShipyardCategory, false) or {}) do
        if not u.Dead then
            local p = u:GetPosition()
            table.insert(points, { p[1], p[3] })
        end
    end
    return points
end

-- Restituisce {x, y, z} oppure nil. center = {x, y, z} (marker della base navale o centro della
-- base). Primo punto valido dal centro verso l'esterno: cantieri compatti ma mai piu' vicini di
-- OWPLUS_SHIPYARD_MIN_SPACING. maxRadius: fino a dove cercare (sess.102: dentro il raggio della
-- base, altrimenti il cantiere resta senza manager e Uveso ci fonda sopra una base nuova).
-- dryRun = true: solo verifica, nessuna prenotazione (usato dalla condizione del builder).
function OWPlusFindShipyardSpot(aiBrain, whatToBuild, center, maxRadius, dryRun)
    local points = OWPlusShipyardPoints(aiBrain)
    local area = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua').GetPlayableArea()
    local m = OWPLUS_SHIPYARD_MAP_MARGIN
    local minSq = OWPLUS_SHIPYARD_MIN_SPACING * OWPLUS_SHIPYARD_MIN_SPACING
    local tooClose, notBuildable = 0, 0
    local limit = maxRadius or OWPLUS_SHIPYARD_SEARCH_MAX_RADIUS
    local r = 0
    while r <= limit do
        local n = 1
        if r > 0 then
            n = math.floor(2 * math.pi * r / OWPLUS_SHIPYARD_RING_STEP)
        end
        for i = 0, n - 1 do
            local a = 2 * math.pi * i / n
            local x = math.floor(center[1] + r * math.cos(a) + 0.5)
            local z = math.floor(center[3] + r * math.sin(a) + 0.5)
            if x > area[1] + m and x < area[3] - m and z > area[2] + m and z < area[4] - m and OWPlusIsWater(x, z) then
                local free = true
                for _, p in ipairs(points) do
                    local dx, dz = p[1] - x, p[2] - z
                    if dx * dx + dz * dz < minSq then
                        free = false
                        break
                    end
                end
                if not free then
                    tooClose = tooClose + 1
                else
                    local pos = { x, GetSurfaceHeight(x, z), z }
                    if aiBrain:CanBuildStructureAt(whatToBuild, pos) and OWPlusHasWaterAround(x, z) then
                        if not dryRun then
                            local reservations = aiBrain.OWPlusShipyardReservations or {}
                            table.insert(reservations, { x, z, GetGameTimeSeconds() })
                            aiBrain.OWPlusShipyardReservations = reservations
                        end
                        return pos, r, table.getn(points)
                    end
                    notBuildable = notBuildable + 1
                end
            end
        end
        r = r + OWPLUS_SHIPYARD_RING_STEP
    end
    return nil, tooClose, notBuildable
end

-- ===========================================================================
-- Sess.102 (test del 2026-10-16: 25 cantieri e 4 basi per IA): tetto di cantieri PER BASE
-- ===========================================================================
-- I builder nativi 'U1 Factory Builders Naval' contano i cantieri a livello globale escludendo
-- le fabbriche di supporto: un cantiere potenziato a T2 diventa SUPPORTFACTORY, smette di
-- essere contato e ne nasce un altro, all'infinito. Per Overwhelm+ sono spenti
-- (OWPlus Naval Production.lua) e li sostituisce 'OWPlus Naval Shipyards' con questa condizione.
OWPLUS_NAVAL_SHIPYARDS_PER_BASE = 3
-- raggio di ricerca per i cantieri della fondazione (base non ancora esistente): sta dentro il
-- raggio minimo a cui Uveso stringe le basi vicine (35), centro + anello a 32 bastano per 3 cantieri
OWPLUS_SHIPYARD_FOUNDING_RADIUS = 34
local OWPLUS_NAVAL_SPOT_CHECK_SECONDS = 60
local OWPLUS_T1_SHIPYARD_BY_FACTION = { 'ueb0103', 'uab0103', 'urb0103', 'xsb0103' }

-- Centro e raggio di ricerca di una base (MAIN o 'Naval Area'): il raggio del FactoryManager
-- viene ristretto da Uveso quando le basi sono vicine; restiamo 2 dentro, tra 32 e 80.
function OWPlusNavalBaseCenterRadius(aiBrain, locationType)
    local mgr = aiBrain.BuilderManagers and aiBrain.BuilderManagers[locationType]
    if not mgr then
        return nil
    end
    local fm = mgr.FactoryManager
    local em = mgr.EngineerManager
    local pos = (fm and fm.Location) or (em and em.Location) or mgr.Position
    local radius = (fm and fm.Radius) or (em and em.Radius) or 40
    radius = math.max(32, math.min(80, radius - 2))
    return pos, radius, mgr
end

-- Cantieri (veri, anche in costruzione) + prenotazioni recenti entro 'radius' da 'pos'
local function OWPlusCountShipyardsNear(aiBrain, pos, radius)
    local n = 0
    for _, u in ipairs(aiBrain:GetUnitsAroundPoint(OWPlusShipyardCategory, pos, radius, 'Ally') or {}) do
        if not u.Dead and u:GetAIBrain() == aiBrain then
            n = n + 1
        end
    end
    local now = GetGameTimeSeconds()
    for _, r in ipairs(aiBrain.OWPlusShipyardReservations or {}) do
        if now - r[3] < OWPLUS_SHIPYARD_RESERVATION_SECONDS and VDist2(r[1], r[2], pos[1], pos[3]) <= radius then
            -- una prenotazione vecchia di pochi secondi puo' essere gia' un cantiere in costruzione:
            -- contata comunque (meglio un cantiere in meno per 90 s che uno di troppo)
            n = n + 1
        end
    end
    return n
end

-- Condizione del builder 'OWPlus Naval Shipyards': MAIN o base 'Naval Area' con meno di
-- OWPLUS_NAVAL_SHIPYARDS_PER_BASE cantieri e un punto valido dentro il raggio (verifica ogni 60 s:
-- MAIN lontano dal mare, come su Shards, non costruisce cantieri).
function OWPlusNavalShipyardNeeded(aiBrain, locationType)
    if not OWPlusNavalCatalogEnabled() then
        return false
    end
    local pos, radius, mgr = OWPlusNavalBaseCenterRadius(aiBrain, locationType)
    if not pos then
        return false
    end
    if locationType ~= 'MAIN' and mgr.BaseType ~= 'Naval Area' then
        return false
    end
    local count = OWPlusCountShipyardsNear(aiBrain, pos, radius + 16)
    if count >= OWPLUS_NAVAL_SHIPYARDS_PER_BASE then
        return false
    end
    aiBrain.OWPlusNavalSpotCheck = aiBrain.OWPlusNavalSpotCheck or {}
    local check = aiBrain.OWPlusNavalSpotCheck[locationType]
    local now = GetGameTimeSeconds()
    if not check or now - check.t >= OWPLUS_NAVAL_SPOT_CHECK_SECONDS then
        local yard = OWPLUS_T1_SHIPYARD_BY_FACTION[aiBrain:GetFactionIndex()] or 'ueb0103'
        local spot = OWPlusFindShipyardSpot(aiBrain, yard, pos, radius, true)
        check = { t = now, ok = spot ~= nil }
        aiBrain.OWPlusNavalSpotCheck[locationType] = check
        LOG('[OWPlus-NAVAL] OWPlusNavalShipyardNeeded: ' .. tostring(locationType) .. ' cantieri ' .. count .. '/'
            .. OWPLUS_NAVAL_SHIPYARDS_PER_BASE .. ', punto distanziato entro ' .. radius .. ': ' .. tostring(check.ok)
            .. ' [' .. tostring(aiBrain.Nickname) .. ']')
    end
    return check.ok
end

-- ===========================================================================
-- Sess.102 (decisione utente 2026-10-16): difese delle basi navali con la formula degli avamposti
-- ===========================================================================
-- Tetto per tipo = OWPlusGetTierDefenseTargets(tier attivo della base, secondi dall'ultimo salto
-- di tier), OWPlusOutpostDefensePool.lua: terra -> antinave, AA, scudi. Tier attivo = tier del
-- cantiere migliore della base. Si contano solo le difese del tier attivo o superiore (quelle
-- vecchie restano, non vengono riciclate come negli avamposti).
local OWPlusDefensePoolMod = nil
local function DefensePool()
    if not OWPlusDefensePoolMod then
        OWPlusDefensePoolMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusOutpostDefensePool.lua')
    end
    return OWPlusDefensePoolMod
end

-- difese antinave moddate senza la categoria ANTINAVY (#Marlos): riconosciute per ID
local OWPLUS_ANTINAVY_IDS = {
    brnt1advnavygun = true, brot1advnavygun = true, brmt1advnavygun = true, brpt1advnavygun = true,
    keb2301 = true, kab2301 = true, krb2301 = true, ksb2301 = true, web0404 = true, wsb2308 = true,
}

local function UnitTier(u)
    if EntityCategoryContains(categories.TECH3 + categories.EXPERIMENTAL, u) then return 3 end
    if EntityCategoryContains(categories.TECH2, u) then return 2 end
    return 1
end

local function IsDefenseKind(u, kind)
    if kind == 'antinavy' then
        return EntityCategoryContains(categories.ANTINAVY, u) or OWPLUS_ANTINAVY_IDS[u.UnitId] == true
    elseif kind == 'aa' then
        return EntityCategoryContains(categories.ANTIAIR, u)
    elseif kind == 'shield' then
        return EntityCategoryContains(categories.SHIELD, u)
    end
    return false
end

-- Tier attivo della base (cantiere migliore) e secondi da quando ci e' arrivata
function OWPlusNavalBaseTier(aiBrain, locationType, mgr)
    local tier = 0
    for _, f in ipairs((mgr.FactoryManager and mgr.FactoryManager.FactoryList) or {}) do
        if not f.Dead and EntityCategoryContains(OWPlusShipyardCategory, f) then
            local t = UnitTier(f)
            if t > tier then tier = t end
        end
    end
    aiBrain.OWPlusNavalTierTimer = aiBrain.OWPlusNavalTierTimer or {}
    local timer = aiBrain.OWPlusNavalTierTimer[locationType]
    local now = GetGameTimeSeconds()
    if tier > 0 and (not timer or timer.tier ~= tier) then
        timer = { tier = tier, since = now }
        aiBrain.OWPlusNavalTierTimer[locationType] = timer
        LOG('[OWPlus-NAVAL] OWPlusNavalBaseTier: base ' .. tostring(locationType) .. ' ora a tier ' .. tier
            .. ', timer difese azzerato [' .. tostring(aiBrain.Nickname) .. ']')
    end
    return tier, timer and (now - timer.since) or 0
end

-- Condizione dei builder 'OWPlus Naval Base Defenses': base 'Naval Area' al tier 'tier' con meno
-- difese di quel tipo (tier >= attivo) del tetto della formula.
function OWPlusNavalDefenseNeeded(aiBrain, locationType, kind, tier)
    if not OWPlusNavalCatalogEnabled() then
        return false
    end
    local pos, radius, mgr = OWPlusNavalBaseCenterRadius(aiBrain, locationType)
    if not pos or mgr.BaseType ~= 'Naval Area' then
        return false
    end
    local active, elapsed = OWPlusNavalBaseTier(aiBrain, locationType, mgr)
    if active ~= tier then
        return false
    end
    local antinavy, aa, _, shield = DefensePool().OWPlusGetTierDefenseTargets(tier, elapsed)
    local target = antinavy
    if kind == 'aa' then target = aa elseif kind == 'shield' then target = shield end
    local have = 0
    for _, u in ipairs(aiBrain:GetUnitsAroundPoint(categories.STRUCTURE * (categories.DEFENSE + categories.SHIELD), pos, radius + 10, 'Ally') or {}) do
        if not u.Dead and u:GetAIBrain() == aiBrain and UnitTier(u) >= tier and IsDefenseKind(u, kind) then
            have = have + 1
        end
    end
    local now = GetGameTimeSeconds()
    for _, r in ipairs(aiBrain.OWPlusNavalDefenseReservations or {}) do
        if r.kind == kind and r.loc == locationType and now - r.t < 45 then
            have = have + 1
        end
    end
    aiBrain.OWPlusNavalDefenseLog = aiBrain.OWPlusNavalDefenseLog or {}
    local key = tostring(locationType) .. ' ' .. kind
    local text = have .. '/' .. target
    if aiBrain.OWPlusNavalDefenseLog[key] ~= text then
        aiBrain.OWPlusNavalDefenseLog[key] = text
        LOG('[OWPlus-NAVAL] OWPlusNavalDefenseNeeded: base ' .. tostring(locationType) .. ' T' .. tier .. ' ' .. kind .. ' ' .. text
            .. ' (tier da ' .. math.floor(elapsed) .. ' s) [' .. tostring(aiBrain.Nickname) .. ']')
    end
    return have < target
end

-- Posto per una difesa della base: anelli da 12 al raggio della base, inizio a caso (Random(),
-- sincronizzato), almeno 14 dai cantieri (corsie d'uscita libere) e 6 dalle difese prenotate.
function OWPlusFindNavalDefenseSpot(aiBrain, unitId, center, radius)
    local yards = OWPlusShipyardPoints(aiBrain)
    local start = Random(0, 359) * math.pi / 180
    local r = 12
    while r <= radius do
        local n = math.floor(2 * math.pi * r / 6)
        for i = 0, n - 1 do
            local a = start + 2 * math.pi * i / n
            local x = math.floor(center[1] + r * math.cos(a) + 0.5)
            local z = math.floor(center[3] + r * math.sin(a) + 0.5)
            local ok = true
            for _, p in ipairs(yards) do
                local dx, dz = p[1] - x, p[2] - z
                if dx * dx + dz * dz < 196 then ok = false break end
            end
            if ok then
                for _, d in ipairs(aiBrain.OWPlusNavalDefenseReservations or {}) do
                    local dx, dz = d.x - x, d.z - z
                    if dx * dx + dz * dz < 36 then ok = false break end
                end
            end
            if ok then
                local y = GetSurfaceHeight(x, z)
                local pos = { x, y, z }
                if aiBrain:CanBuildStructureAt(unitId, pos) then
                    return pos
                end
            end
        end
        r = r + 6
    end
    return nil
end

function OWPlusReserveNavalDefense(aiBrain, locationType, kind, pos)
    local now = GetGameTimeSeconds()
    local kept = {}
    for _, r in ipairs(aiBrain.OWPlusNavalDefenseReservations or {}) do
        if now - r.t < 45 then
            table.insert(kept, r)
        end
    end
    table.insert(kept, { loc = locationType, kind = kind, x = pos[1], z = pos[3], t = now })
    aiBrain.OWPlusNavalDefenseReservations = kept
end

LOG('[OWPlus-NAVAL] OWPlusNavalCatalog.lua: OK, catalogo navale ' .. table.getn(OWPLUS_NAVAL_CATALOG)
    .. ' unita\' (attese 62), tetto basi navali ' .. OWPLUS_NAVAL_BASES_MAX .. ', cantieri per base ' .. OWPLUS_NAVAL_SHIPYARDS_PER_BASE
    .. ', distanza cantieri ' .. OWPLUS_SHIPYARD_MIN_SPACING .. ', disattivato=' .. tostring(OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled))
