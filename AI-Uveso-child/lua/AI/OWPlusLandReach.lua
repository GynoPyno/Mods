-- OWPlusLandReach.lua
-- Sess.104 (Consegna E1, 2026-11-22): le unita' di terra dell'IA non devono essere prodotte quando non possono
-- raggiungere il nemico. Misura: partita su 'meridian_strike' (3 IA, 35 min), tutte e tre avevano dichiarato
-- "WATER map!" a 6 secondi ma gli avamposti ('OWPlus Outpost Production', nessun controllo di raggiungibilita')
-- hanno continuato a produrre carri, bot e artiglierie: 400-680 unita' ferme per IA, partita crashata per lentezza.
--
-- 1) OWPlusLandReachVerdict(aiBrain, locationType): verdetto PER BASE (MAIN o avamposto 'OUT#'), calcolato con la
--    mappa di navigazione di FAF (NavUtils.CanPathTo, layer 'Land' e 'Amphibious') dalla posizione della base alla
--    partenza del nemico corrente. Il controllo di Uveso ('CanPathToCurrentEnemy') usa sempre la partenza di MAIN,
--    salva il risultato per tutta la partita e ignora la base chiesta; questo si ricalcola ogni 60 s e al cambio di
--    nemico. Valori: 'Land' | 'Amphibious' | 'None' | 'Unknown' ('Unknown' = non bloccare: mai fermare l'IA per un dato
--    mancante).
-- 2) OWPlusLandCapOk(aiBrain): tetto di sicurezza sul numero di unita' di terra da combattimento vive, indipendente dal
--    verdetto (copre un verdetto sbagliato). Soglia = max(OWPLUS_LAND_CAP_FLOOR, OWPLUS_LAND_CAP_FRACTION x cap unita').
--
-- ROLLBACK: OWPlusLandReachGateDisabled = true (OWPlusFactoryTargets.lua) -> la condizione risponde sempre vero.

local categories = categories

local OWPLUS_LANDREACH_TTL = 60          -- secondi di validita' di un verdetto
local OWPLUS_LAND_CAP_FLOOR = 200        -- soglia minima del tetto (unita')
local OWPLUS_LAND_CAP_FRACTION = 0.25    -- quota del cap unita' dell'armata
local OWPLUS_LAND_COMBAT = categories.MOBILE * categories.LAND - categories.ENGINEER - categories.SCOUT
    - categories.COMMAND - categories.SUBCOMMANDER

-- Posizione di una base: MAIN = partenza dell'armata; avamposto = coordinate del suo manager.
local function OWPlusLocationPosition(aiBrain, locationType)
    if locationType == 'MAIN' then
        local x, z = aiBrain:GetArmyStartPos()
        if x and z then
            return { x, GetSurfaceHeight(x, z), z }
        end
        return nil
    end
    local mgr = aiBrain.BuilderManagers and aiBrain.BuilderManagers[locationType]
    if mgr then
        local m = mgr.EngineerManager or mgr.FactoryManager
        if m and m.GetLocationCoords then
            local pos = m:GetLocationCoords()
            if pos and pos[1] and pos[3] then
                return { pos[1], GetSurfaceHeight(pos[1], pos[3]), pos[3] }
            end
        end
    end
    return nil
end

function OWPlusLandReachVerdict(aiBrain, locationType)
    local cache = aiBrain.OWPlusLandReachCache
    if not cache then
        cache = {}
        aiBrain.OWPlusLandReachCache = cache
    end
    local now = GetGameTimeSeconds()
    local enemy = aiBrain:GetCurrentEnemy()
    local enemyIndex = -1
    if enemy then
        enemyIndex = enemy:GetArmyIndex()
    end
    local entry = cache[locationType]
    if entry and entry.enemy == enemyIndex and now - entry.time < OWPLUS_LANDREACH_TTL then
        return entry.verdict
    end

    local verdict = 'Unknown'
    local detail = 'dati mancanti'
    local origin = OWPlusLocationPosition(aiBrain, locationType)
    if enemy and origin then
        local ex, ez = enemy:GetArmyStartPos()
        if ex and ez then
            local NavUtils = import('/lua/sim/NavUtils.lua')
            if NavUtils.IsGenerated() then
                local dest = { ex, GetSurfaceHeight(ex, ez), ez }
                local landOk, landReason = NavUtils.CanPathTo('Land', origin, dest)
                if landOk == true then
                    verdict = 'Land'
                    detail = 'Land=true'
                else
                    local ambOk, ambReason = NavUtils.CanPathTo('Amphibious', origin, dest)
                    detail = 'Land=' .. tostring(landOk) .. '(' .. tostring(landReason) .. ') Amphibious=' .. tostring(ambOk) .. '(' .. tostring(ambReason) .. ')'
                    if ambOk == true then
                        verdict = 'Amphibious'
                    elseif landOk == nil and ambOk == nil then
                        verdict = 'Unknown'
                    else
                        verdict = 'None'
                    end
                end
            else
                detail = 'mappa di navigazione non generata'
            end
        end
    end

    local old = entry and entry.verdict
    if old ~= verdict then
        LOG('[OWPlus-LANDREACH] [' .. tostring(aiBrain.Nickname) .. '] base "' .. tostring(locationType) .. '": raggiungibilita nemico '
            .. tostring(old) .. ' -> ' .. verdict .. ' (' .. detail .. ') t=' .. string.format('%.0f', now))
    end
    cache[locationType] = { verdict = verdict, time = now, enemy = enemyIndex }
    return verdict
end

-- true = si puo' ancora produrre. Contano le unita' di terra da combattimento vive dell'armata (non ingegneri, scout, ACU).
function OWPlusLandCapOk(aiBrain)
    -- la condizione gira per 172 builder: il conteggio (chiamata al motore) si tiene in cache 5 s per armata
    local now = GetGameTimeSeconds()
    local c = aiBrain.OWPlusLandCapCache
    if not c or now - c.time >= 5 then
        local cap = GetArmyUnitCap(aiBrain:GetArmyIndex())
        c = {
            time = now,
            limit = math.max(OWPLUS_LAND_CAP_FLOOR, math.floor(OWPLUS_LAND_CAP_FRACTION * cap)),
            alive = aiBrain:GetCurrentUnits(OWPLUS_LAND_COMBAT),
        }
        aiBrain.OWPlusLandCapCache = c
    end
    return c.alive < c.limit, c.alive, c.limit
end

LOG('[OWPlus-LANDREACH] OWPlusLandReach.lua: OK, modulo caricato (verdetto per base ogni ' .. OWPLUS_LANDREACH_TTL .. ' s, tetto unita\' di terra max('
    .. OWPLUS_LAND_CAP_FLOOR .. ', ' .. OWPLUS_LAND_CAP_FRACTION .. ' x cap))')
