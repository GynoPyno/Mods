-- OWPlusAirCatalog.lua
--
-- Sess.101 (decisioni utente 2026-10-10 / 2026-10-14): produzione AEREA dal catalogo, come la
-- terra ('OWPlus Main Land Production'), a MAIN e agli avamposti.
--
--  * Catalogo: 57 unita' (27 vanilla + 30 moddate), censite dai blueprint con le STESSE regole
--    di categoria dei plotoni aria (OWPlus PlatoonTemplates Air Attack.lua): un aereo che nessun
--    plotone accetta resterebbe fermo in base per sempre. Esclusi: aerei costruiti dagli
--    ingegneri (Total Mayhem TMADVANCEDAIRUNIT), sperimentali, siluranti, trasporti, scout, radar.
--    Un template per unita' (OWPlus PlatoonTemplates Air Catalog.lua): salta anche le sostituzioni
--    casuali di CustomUnits, che oggi infilano tra i caccia aerei radar mai inquadrati.
--  * Ruolo adattivo: ogni OWPLUS_AIR_RATIO_INTERVAL secondi l'IA confronta la propria aviazione
--    d'attacco con quella dei nemici, per NUMERO e per MASSA (sperimentali aerei compresi):
--      rapporto combinato = massa^0.7 * numero^0.3, ogni rapporto limitato a [0.25, 4]
--      >= 2 -> 40% caccia | >= 1 -> 60% | > 0.5 -> 80% | <= 0.5 -> 90% (massimo, mai 100%)
--      regola extra: numero E massa sotto 1 -> almeno 80%; entrambi <= 0.5 -> 90%.
--    Ogni OWPLUS_AIR_ROLE_INTERVAL secondi si tira il ruolo da produrre con quella percentuale
--    (Random(), sincronizzato tra i client; mai math.random).
--    NB (decisione utente 2026-10-15): la quota divide il TEMPO DI FABBRICA, quindi l'investimento
--    (massa), NON il numero di aerei. Un bombardiere T3 costa 4-14 volte un caccia T3: nel test
--    OWTEST del 2026-10-14 agli avamposti 88% caccia per numero ma 60% per massa. Voluto cosi'.
--  * Tetto: al massimo OWPLUS_AIR_WAITING_MAX aerei d'attacco in attesa di plotone su TUTTA la
--    mappa (i former aria di MAIN raccolgono con FormRadius = 10000, il pool e' unico).
--  * Pattuglia: gli aerei in attesa fermi girano in un piccolo quadrato attorno a dove si trovano;
--    quando entrano in un plotone l'ordine di pattuglia (infinito) va cancellato, vedi
--    OWPlusAirClearPatrolOnNewPlatoons chiamata da hook/lua/sim/PlatoonFormManager.lua.
--
-- Rollback: OWPlusAirCatalogDisabled = true (OWPlusFactoryTargets.lua).
-- Determinismo (regola 38t): solo array con ipairs, nessun pairs() su chiavi-oggetto.

local categories = categories
local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')

OWPLUS_AIR_WAITING_MAX = 100       -- sess.101 (utente 2026-10-14): era 60
-- quota massima di caccia nello svantaggio estremo: resta sempre un 10% d'attacco al suolo
-- (sess.101, utente 2026-10-14: era 100%)
local OWPLUS_AIR_FIGHTER_SHARE_MAX = 0.9
local OWPLUS_AIR_RATIO_INTERVAL = 30
local OWPLUS_AIR_ROLE_INTERVAL = 5
local OWPLUS_AIR_MASS_WEIGHT = 0.7
local OWPLUS_AIR_RATIO_MIN = 0.25
local OWPLUS_AIR_RATIO_MAX = 4
local OWPLUS_AIR_PATROL_INTERVAL = 10
local OWPLUS_AIR_PATROL_HALF_SIDE = 15

-- Categorie identiche ai PlatoonTemplate dei plotoni aria (OWPlus PlatoonTemplates Air Attack.lua)
OWPlusAirFighterCategory = categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR
    - categories.GROUNDATTACK - categories.BOMBER - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL - categories.ANTINAVY
OWPlusAirGroundCategory = categories.MOBILE * categories.AIR * (categories.GROUNDATTACK + categories.BOMBER)
    - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL - categories.ANTINAVY
local OWPlusAirAttackCategory = OWPlusAirFighterCategory + OWPlusAirGroundCategory
-- Forza aerea per il rapporto: in piu' gli sperimentali aerei (5 Czar devono pesare davvero)
local OWPlusAirStrengthCategory = OWPlusAirAttackCategory + categories.MOBILE * categories.AIR * categories.EXPERIMENTAL
    - categories.SCOUT - categories.TRANSPORTFOCUS - categories.POD - categories.SATELLITE

-- { ruolo, tier, fazione, id } -- generato dal censimento dei blueprint (sess.101)
OWPLUS_AIR_CATALOG = {
    { 'Fighter', 1, 'UEF', 'uea0102' }, -- Vanilla: Cyclone (Interceptor), massa 50
    { 'Fighter', 1, 'UEF', 'brnat1intc' }, -- TotalMayhem: Pugnator (Fighter), massa 115
    { 'Fighter', 1, 'Aeon', 'uaa0102' }, -- Vanilla: Conservator (Interceptor), massa 50
    { 'Fighter', 1, 'Aeon', 'broat1fig' }, -- TotalMayhem: Vaikana (Fighter), massa 100
    { 'Fighter', 1, 'Aeon', 'broat1intc' }, -- TotalMayhem: Musca (Interceptor), massa 75
    { 'Fighter', 1, 'Cybran', 'ura0102' }, -- Vanilla: Prowler (Interceptor), massa 50
    { 'Fighter', 1, 'Cybran', 'anc_ura102' }, -- Antares Unit Pack: Mosquito (Cybran High-Speed Swarm Craft), massa 7
    { 'Fighter', 1, 'Cybran', 'brmat1advfig' }, -- TotalMayhem: Venom (Combat Fighter), massa 70
    { 'Fighter', 1, 'Cybran', 'brmat1intc' }, -- TotalMayhem: Velox (Interceptor), massa 105
    { 'Fighter', 1, 'Seraphim', 'xsa0102' }, -- Vanilla: Ia-atha (Interceptor), massa 50
    { 'Fighter', 2, 'UEF', 'uea0202' }, -- OrbitalWarsMod: EF Tempest (Interceptor), massa 250
    { 'Fighter', 2, 'Aeon', 'xaa0202' }, -- Vanilla: Swift Wind (Combat Fighter), massa 235
    { 'Fighter', 2, 'Aeon', 'broat2fibo' }, -- TotalMayhem: Twilight (Fighter/Bomber), massa 500
    { 'Fighter', 2, 'Cybran', 'brmat2fig1' }, -- TotalMayhem: Firefly (Stealth Fighter), massa 450
    { 'Fighter', 2, 'Cybran', 'ura0202' }, -- OrbitalWarsMod: Fast Bat (Interceptor), massa 225
    { 'Fighter', 2, 'Cybran', 'wra0202' }, -- BattlePack: Stalker (Combat Interceptor), massa 200
    { 'Fighter', 2, 'Seraphim', 'brpat2figbo' }, -- TotalMayhem: Uhthesinn (Fighter), massa 400
    { 'Fighter', 2, 'Seraphim', 'wsa0201' }, -- BattlePack: Talium (Combat Fighter), massa 200
    { 'Fighter', 3, 'UEF', 'uea0303' }, -- Vanilla: Wasp (Air Superiority Fighter), massa 450
    { 'Fighter', 3, 'UEF', 'brnat3airsup' }, -- TotalMayhem: Falcon (Stealth Fighter), massa 380
    { 'Fighter', 3, 'UEF', 'uean0303' }, -- OrbitalWarsMod: Wasp (Air-Superiority Fighter), massa 400
    { 'Fighter', 3, 'Aeon', 'uaa0303' }, -- Vanilla: Corona (Air Superiority Fighter), massa 450
    { 'Fighter', 3, 'Aeon', 'broat3asup' }, -- TotalMayhem: Stinger (Stealth Fighter), massa 410
    { 'Fighter', 3, 'Cybran', 'ura0303' }, -- Vanilla: Gemini (Air Superiority Fighter), massa 450
    { 'Fighter', 3, 'Cybran', 'brmat3asup' }, -- TotalMayhem: Cobra (Multi-Purpose Fighter), massa 500
    { 'Fighter', 3, 'Cybran', 'wra0305' }, -- BattlePack: Bion (Advanced Multipurpose Fighter), massa 1650
    { 'Fighter', 3, 'Seraphim', 'xsa0303' }, -- Vanilla: Iazyne (Air Superiority Fighter), massa 450
    { 'Ground', 1, 'UEF', 'uea0103' }, -- Vanilla: Scorcher (Attack Bomber), massa 90
    { 'Ground', 1, 'UEF', 'kea0101' }, -- #Marlos mods compilation: Blackfish (Gunship), massa 240
    { 'Ground', 1, 'Aeon', 'uaa0103' }, -- Vanilla: Shimmer (Attack Bomber), massa 90
    { 'Ground', 1, 'Cybran', 'ura0103' }, -- Vanilla: Zeus (Attack Bomber), massa 90
    { 'Ground', 1, 'Cybran', 'xra0105' }, -- Vanilla: Jester (Light Gunship), massa 170
    { 'Ground', 1, 'Seraphim', 'xsa0103' }, -- Vanilla: Sinnve (Attack Bomber), massa 90
    { 'Ground', 2, 'UEF', 'dea0202' }, -- Vanilla: Janus (Fighter/Bomber), massa 360
    { 'Ground', 2, 'Aeon', 'uaa0203' }, -- Vanilla: Specter (Gunship), massa 270
    { 'Ground', 2, 'Cybran', 'dra0202' }, -- Vanilla: Corsair (Fighter/Bomber), massa 420
    { 'Ground', 2, 'Cybran', 'ura0203' }, -- Vanilla: Renegade (Gunship), massa 270
    { 'Ground', 2, 'Cybran', 'umr_a0301' }, -- Antares Unit Pack: Terror (Suppression Bomber), massa 3000
    { 'Ground', 2, 'Seraphim', 'xsa0202' }, -- Vanilla: Notha (Fighter/Bomber), massa 420
    { 'Ground', 2, 'Seraphim', 'xsa0203' }, -- Vanilla: Vulthoo (Gunship), massa 500
    { 'Ground', 3, 'UEF', 'uea0304' }, -- Vanilla: Ambassador (Strategic Bomber), massa 1750
    { 'Ground', 3, 'UEF', 'uea0305' }, -- Vanilla: Broadsword (Heavy Gunship), massa 1500
    { 'Ground', 3, 'UEF', 'kea0301' }, -- #Marlos mods compilation: B-52 Stratofortress (Nuclear Bomber), massa 6295
    { 'Ground', 3, 'UEF', 'uea0309' }, -- Antares Unit Pack: S-7 Defendor (AA Gunship), massa 1220
    { 'Ground', 3, 'UEF', 'wea0305' }, -- BattlePack: Ripper (Strategic Missile Bomber), massa 2100
    { 'Ground', 3, 'Aeon', 'uaa0304' }, -- Vanilla: Shocker (Strategic Bomber), massa 1750
    { 'Ground', 3, 'Aeon', 'xaa0305' }, -- Vanilla: Restorer (AA Gunship), massa 1200
    { 'Ground', 3, 'Aeon', 'waa0305' }, -- BattlePack: Fury (Attack Bomber), massa 2100
    { 'Ground', 3, 'Cybran', 'ura0304' }, -- Vanilla: Revenant (Strategic Bomber), massa 1750
    { 'Ground', 3, 'Cybran', 'xra0305' }, -- Vanilla: Wailer (Heavy Gunship), massa 1500
    { 'Ground', 3, 'Cybran', 'gmra201' }, -- Antares Unit Pack: Iron Hawk (Multipurpose Heavy Bomber), massa 4250
    { 'Ground', 3, 'Cybran', 'gmra302' }, -- Antares Unit Pack: Stingray (Assault Gunship), massa 3000
    { 'Ground', 3, 'Cybran', 'gmra305' }, -- Antares Unit Pack: Cyberhawk (Heavy Assault Gunship), massa 1300
    { 'Ground', 3, 'Cybran', 'wra0303' }, -- BattlePack: Regegade MK II (Heavy Gunship), massa 1680
    { 'Ground', 3, 'Seraphim', 'xsa0304' }, -- Vanilla: Sinntha (Strategic Bomber), massa 1750
    { 'Ground', 3, 'Seraphim', 'bsa0310' }, -- BlackOpsFAF-Unleashed: Vulthatha-Ioz (Missile Gunship), massa 1680
    { 'Ground', 3, 'Seraphim', 'xsa0306' }, -- Antares Unit Pack: Virutola (Gunship), massa 1800
}

-- Nome del PlatoonTemplate di un candidato (OWPlus PlatoonTemplates Air Catalog.lua)
function OWPlusAirTemplateName(c)
    return 'OWPlus Air ' .. c[1] .. ' T' .. c[2] .. ' ' .. c[3] .. ' ' .. c[4]
end

function OWPlusAirCatalogEnabled()
    return not OWPlusFactoryTargetsMod.OWPlusAirCatalogDisabled
end

-- Vero se il brain e' un'IA OverwhelmPlus (risultato memorizzato sul brain)
function OWPlusIsPlusBrain(aiBrain)
    if aiBrain.OWPlusIsPlus == nil then
        local setup = ScenarioInfo.ArmySetup and ScenarioInfo.ArmySetup[aiBrain.Name]
        local per = setup and setup.AIPersonality
        aiBrain.OWPlusIsPlus = (per == 'overwhelmplus' or per == 'overwhelmpluscheat')
    end
    return aiBrain.OWPlusIsPlus
end

-- ===========================================================================
-- Forza aerea e scaglione caccia/attacco al suolo
-- ===========================================================================

local function OWPlusAirStrength(brain)
    local count, mass = 0, 0
    for _, u in ipairs(brain:GetListOfUnits(OWPlusAirStrengthCategory, false) or {}) do
        if not u.Dead and u:GetFractionComplete() >= 1 then
            count = count + 1
            local bp = u:GetBlueprint()
            mass = mass + ((bp and bp.Economy and bp.Economy.BuildCostMass) or 0)
        end
    end
    return count, mass
end

local function OWPlusAirClampRatio(own, enemy)
    if enemy <= 0 then
        if own <= 0 then
            return 1
        end
        return OWPLUS_AIR_RATIO_MAX
    end
    local r = own / enemy
    if r < OWPLUS_AIR_RATIO_MIN then
        return OWPLUS_AIR_RATIO_MIN
    elseif r > OWPLUS_AIR_RATIO_MAX then
        return OWPLUS_AIR_RATIO_MAX
    end
    return r
end

-- Restituisce la quota di caccia (0.4 / 0.6 / 0.8 / OWPLUS_AIR_FIGHTER_SHARE_MAX) e il rapporto combinato
function OWPlusAirComputeFighterShare(ratioCount, ratioMass)
    local combined = math.pow(ratioMass, OWPLUS_AIR_MASS_WEIGHT) * math.pow(ratioCount, 1 - OWPLUS_AIR_MASS_WEIGHT)
    local share
    if combined >= 2 then
        share = 0.4
    elseif combined >= 1 then
        share = 0.6
    elseif combined > 0.5 then
        share = 0.8
    else
        share = OWPLUS_AIR_FIGHTER_SHARE_MAX
    end
    -- regola extra (decisione utente): se sia numero sia massa sono sotto, l'IA e' davvero indietro
    if ratioCount < 1 and ratioMass < 1 and share < 0.8 then
        share = 0.8
    end
    if ratioCount <= 0.5 and ratioMass <= 0.5 then
        share = OWPLUS_AIR_FIGHTER_SHARE_MAX
    end
    return share, combined
end

-- Thread per brain (forkato da overwhelmplusai.lua): aggiorna aiBrain.OWPlusAirFighterShare
function OWPlusAirSuperiorityThread(aiBrain)
    LOG('[OWPlus-AIR] [' .. tostring(aiBrain.Nickname) .. '] OK, thread superiorita\' aerea avviato (ogni '
        .. OWPLUS_AIR_RATIO_INTERVAL .. ' s, peso massa ' .. OWPLUS_AIR_MASS_WEIGHT .. ')')
    aiBrain.OWPlusAirFighterShare = aiBrain.OWPlusAirFighterShare or 0.6
    while true do
        if aiBrain:IsDefeated() then
            LOG('[OWPlus-AIR] [' .. tostring(aiBrain.Nickname) .. '] brain sconfitto, thread superiorita\' aerea terminato')
            return
        end
        local myIndex = aiBrain:GetArmyIndex()
        local ownCount, ownMass = OWPlusAirStrength(aiBrain)
        local enemyCount, enemyMass, enemies = 0, 0, 0
        for _, brain in ipairs(ArmyBrains) do
            local idx = brain:GetArmyIndex()
            if idx ~= myIndex and IsEnemy(myIndex, idx) and not brain:IsDefeated() then
                local c, m = OWPlusAirStrength(brain)
                enemyCount = enemyCount + c
                enemyMass = enemyMass + m
                enemies = enemies + 1
            end
        end
        local ratioCount = OWPlusAirClampRatio(ownCount, enemyCount)
        local ratioMass = OWPlusAirClampRatio(ownMass, enemyMass)
        local share, combined = OWPlusAirComputeFighterShare(ratioCount, ratioMass)
        local rolls = aiBrain.OWPlusAirRoleRolls or { Fighter = 0, Ground = 0 }
        LOG('[OWPlus-AIR] [' .. tostring(aiBrain.Nickname) .. '] t=' .. string.format('%.0f', GetGameTimeSeconds())
            .. ' propri=' .. ownCount .. ' (' .. string.format('%.0f', ownMass) .. ' massa) nemici=' .. enemyCount
            .. ' (' .. string.format('%.0f', enemyMass) .. ' massa, ' .. enemies .. ' armate)'
            .. ' rapporto numero=' .. string.format('%.2f', ratioCount) .. ' massa=' .. string.format('%.2f', ratioMass)
            .. ' combinato=' .. string.format('%.2f', combined) .. ' -> caccia ' .. string.format('%.0f', share * 100)
            .. '% (prima ' .. string.format('%.0f', aiBrain.OWPlusAirFighterShare * 100) .. '%)'
            .. ' | tiri ultimi ' .. OWPLUS_AIR_RATIO_INTERVAL .. ' s: caccia=' .. rolls.Fighter .. ' suolo=' .. rolls.Ground
            .. ' | in attesa=' .. OWPlusAirWaitingCount(aiBrain) .. '/' .. OWPLUS_AIR_WAITING_MAX)
        aiBrain.OWPlusAirFighterShare = share
        aiBrain.OWPlusAirRoleRolls = { Fighter = 0, Ground = 0 }
        WaitSeconds(OWPLUS_AIR_RATIO_INTERVAL)
    end
end

-- Vero se il ruolo 'Fighter'/'Ground' e' quello da produrre adesso. Il ruolo si ritira ogni
-- OWPLUS_AIR_ROLE_INTERVAL secondi con la quota dello scaglione corrente.
function OWPlusAirRoleAllowed(aiBrain, role)
    local now = GetGameTimeSeconds()
    if not aiBrain.OWPlusAirRoleUntil or now >= aiBrain.OWPlusAirRoleUntil then
        local share = aiBrain.OWPlusAirFighterShare or 0.6
        if Random(1, 100) <= share * 100 then
            aiBrain.OWPlusAirRole = 'Fighter'
        else
            aiBrain.OWPlusAirRole = 'Ground'
        end
        aiBrain.OWPlusAirRoleUntil = now + OWPLUS_AIR_ROLE_INTERVAL
        aiBrain.OWPlusAirRoleRolls = aiBrain.OWPlusAirRoleRolls or { Fighter = 0, Ground = 0 }
        aiBrain.OWPlusAirRoleRolls[aiBrain.OWPlusAirRole] = aiBrain.OWPlusAirRoleRolls[aiBrain.OWPlusAirRole] + 1
    end
    return aiBrain.OWPlusAirRole == role
end

-- ===========================================================================
-- Aerei in attesa di plotone (ArmyPool, tutta la mappa) e tetto
-- ===========================================================================

function OWPlusAirWaitingCount(aiBrain)
    local now = GetGameTimeSeconds()
    if aiBrain.OWPlusAirWaitingAt == now and aiBrain.OWPlusAirWaitingValue then
        return aiBrain.OWPlusAirWaitingValue
    end
    local n = 0
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    if pool then
        for _, u in ipairs(pool:GetPlatoonUnits() or {}) do
            if not u.Dead and EntityCategoryContains(OWPlusAirAttackCategory, u) then
                n = n + 1
            end
        end
    end
    aiBrain.OWPlusAirWaitingAt = now
    aiBrain.OWPlusAirWaitingValue = n
    return n
end

-- BuilderCondition: meno di maxUnits aerei d'attacco in attesa su tutta la mappa
function OWPlusAirWaitingBelow(aiBrain, maxUnits)
    return OWPlusAirWaitingCount(aiBrain) < maxUnits
end

-- ===========================================================================
-- Pattuglia degli aerei in attesa
-- ===========================================================================

local function OWPlusAirClampToMap(x, z)
    local size = ScenarioInfo.size
    local maxX = (size and size[1]) or 4096
    local maxZ = (size and size[2]) or 4096
    if x < 5 then x = 5 elseif x > maxX - 5 then x = maxX - 5 end
    if z < 5 then z = 5 elseif z > maxZ - 5 then z = maxZ - 5 end
    return x, z
end

-- Thread per brain (forkato da overwhelmplusai.lua)
function OWPlusAirPatrolThread(aiBrain)
    LOG('[OWPlus-AIR-PATROL] [' .. tostring(aiBrain.Nickname) .. '] OK, thread pattuglia aerei in attesa avviato (ogni '
        .. OWPLUS_AIR_PATROL_INTERVAL .. ' s, quadrato di lato ' .. (OWPLUS_AIR_PATROL_HALF_SIDE * 2) .. ')')
    aiBrain.OWPlusAirPatrolUnits = aiBrain.OWPlusAirPatrolUnits or {}
    local lastWarn = -1000
    while true do
        WaitSeconds(OWPLUS_AIR_PATROL_INTERVAL)
        if aiBrain:IsDefeated() then
            LOG('[OWPlus-AIR-PATROL] [' .. tostring(aiBrain.Nickname) .. '] brain sconfitto, thread pattuglia terminato')
            return
        end
        local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
        local inPool = {}
        local assigned = 0
        if pool then
            for _, u in ipairs(pool:GetPlatoonUnits() or {}) do
                if not u.Dead and EntityCategoryContains(OWPlusAirAttackCategory, u) then
                    inPool[u:GetEntityId()] = true
                    if not u.OWPlusAirPatrol and u:IsIdleState() then
                        local pos = u:GetPosition()
                        local h = OWPLUS_AIR_PATROL_HALF_SIDE
                        local corners = { { -h, -h }, { h, -h }, { h, h }, { -h, h } }
                        for _, c in ipairs(corners) do
                            local x, z = OWPlusAirClampToMap(pos[1] + c[1], pos[3] + c[2])
                            IssuePatrol({ u }, { x, GetTerrainHeight(x, z), z })
                        end
                        u.OWPlusAirPatrol = true
                        table.insert(aiBrain.OWPlusAirPatrolUnits, u)
                        assigned = assigned + 1
                    end
                end
            end
        end
        -- Rete di sicurezza: un aereo ancora marcato ma fuori dall'ArmyPool e' entrato in un plotone
        -- senza che la pattuglia venisse cancellata (OWPlusAirClearPatrolOnNewPlatoons non l'ha visto).
        local kept, stale = {}, 0
        for _, u in ipairs(aiBrain.OWPlusAirPatrolUnits) do
            if not u.Dead and u.OWPlusAirPatrol then
                if inPool[u:GetEntityId()] then
                    table.insert(kept, u)
                else
                    stale = stale + 1
                    u.OWPlusAirPatrol = nil
                end
            end
        end
        aiBrain.OWPlusAirPatrolUnits = kept
        if assigned > 0 then
            LOG('[OWPlus-AIR-PATROL] [' .. tostring(aiBrain.Nickname) .. '] t=' .. string.format('%.0f', GetGameTimeSeconds())
                .. ' pattuglia assegnata a ' .. assigned .. ' aerei, in pattuglia=' .. table.getn(kept)
                .. ', in attesa=' .. OWPlusAirWaitingCount(aiBrain))
        end
        if stale > 0 and GetGameTimeSeconds() - lastWarn >= 60 then
            lastWarn = GetGameTimeSeconds()
            WARN('[OWPlus-AIR-PATROL] [' .. tostring(aiBrain.Nickname) .. '] ' .. stale
                .. ' aerei usciti dall\'ArmyPool con la pattuglia ancora attiva (cancellazione alla formazione mancata)')
        end
    end
end

-- Chiamata dal PlatoonFormManager subito dopo la chiamata nativa (sincrona): per ogni plotone
-- comparso dopo l'indice 'before' cancella la pattuglia degli aerei marcati, prima che il piano
-- del plotone dia i suoi ordini (il thread del piano parte al prossimo resume).
function OWPlusAirClearPatrolOnNewPlatoons(aiBrain, before)
    local platoons = aiBrain:GetPlatoonsList()
    local after = table.getn(platoons)
    if after <= before then
        return
    end
    for i = before + 1, after do
        local plat = platoons[i]
        if plat and plat.GetPlatoonUnits then
            local cleared = 0
            for _, u in ipairs(plat:GetPlatoonUnits() or {}) do
                if not u.Dead and u.OWPlusAirPatrol then
                    IssueClearCommands({ u })
                    u.OWPlusAirPatrol = nil
                    cleared = cleared + 1
                end
            end
            if cleared > 0 then
                LOG('[OWPlus-AIR-PATROL] [' .. tostring(aiBrain.Nickname) .. '] OK, plotone "' .. tostring(plat.BuilderName)
                    .. '" formato: pattuglia cancellata a ' .. cleared .. ' aerei')
            end
        end
    end
end
