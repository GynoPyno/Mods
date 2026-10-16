-- Sess.98 (bis): hook minimale (funzione sciolta) su un bug NATIVO del
-- motore FAF, non introdotto da questo progetto. In AIBuildAdjacency
-- (/lua/ai/aibuildstructures.lua) il campo che dice alla scelta finale di
-- posizionamento "preferisci vicino a questo punto" viene letto con un typo
-- case-sensitive: 'BuildManagerdata' (d minuscola) invece di
-- 'BuildManagerData' (D maiuscola, usato correttamente due righe sopra nello
-- stesso costrutto if). Lua e' case-sensitive: quel campo non esiste mai su
-- 'builder', quindi baseLocation resta sempre {nil, nil, nil} (il default
-- dichiarato subito sopra) e la funzione nativa FindPlaceToBuild riceve
-- sempre nil come punto di preferenza.
--
-- Impatto osservato in game: builder con Construction.AdjacencyCategory
-- (es. i nostri magazzini massa/energia, radius 9999 da sess.98) continuano
-- a costruire solo vicino a MAIN nonostante candidati liberi esistano su
-- tutta la mappa -- allargare il raggio di RICERCA (gia' fatto) non basta,
-- perche' il bug e' nella scelta FINALE tra i candidati trovati, non nella
-- ricerca stessa. Fix: copia esatta della funzione nativa con la sola
-- correzione del typo. Impatta globalmente ogni builder (non solo Uveso) che
-- passi da AIBuildAdjacency -- effetto atteso positivo, nessuna logica
-- cambiata a parte il campo corretto.
LOG('[AI-Uveso-child] aibuildstructures.lua: OK, hook AIBuildAdjacency attivo (fix typo nativo BuildManagerdata->BuildManagerData)')

function AIBuildAdjacency(aiBrain, builder, buildingType, closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
    local whatToBuild = aiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
    if whatToBuild then
        local unitSize = aiBrain:GetUnitBlueprint(whatToBuild).Physics
        local template = {}
        table.insert(template, {})
        table.insert(template[1], { buildingType })
        for k, v in reference do
            if not v.Dead then
                local targetSize = v:GetBlueprint().Physics
                local targetPos = v:GetPosition()
                targetPos[1] = targetPos[1] - (targetSize.SkirtSizeX/2)
                targetPos[3] = targetPos[3] - (targetSize.SkirtSizeZ/2)
                -- Top/bottom of unit
                for i=0,((targetSize.SkirtSizeX/2)-1) do
                    local testPos = { targetPos[1] + 1 + (i * 2), targetPos[3]-(unitSize.SkirtSizeZ/2), 0 }
                    local testPos2 = { targetPos[1] + 1 + (i * 2), targetPos[3]+targetSize.SkirtSizeZ+(unitSize.SkirtSizeZ/2), 0 }
                    if testPos[1] > 8 and testPos[1] < ScenarioInfo.size[1] - 8 and testPos[2] > 8 and testPos[2] < ScenarioInfo.size[2] - 8 then
                        table.insert(template[1], testPos)
                    end
                    if testPos2[1] > 8 and testPos2[1] < ScenarioInfo.size[1] - 8 and testPos2[2] > 8 and testPos2[2] < ScenarioInfo.size[2] - 8 then
                        table.insert(template[1], testPos2)
                    end
                end
                -- Sides of unit
                for i=0,((targetSize.SkirtSizeZ/2)-1) do
                    local testPos = { targetPos[1]+targetSize.SkirtSizeX + (unitSize.SkirtSizeX/2), targetPos[3] + 1 + (i * 2), 0 }
                    local testPos2 = { targetPos[1]-(unitSize.SkirtSizeX/2), targetPos[3] + 1 + (i*2), 0 }
                    if testPos[1] > 8 and testPos[1] < ScenarioInfo.size[1] - 8 and testPos[2] > 8 and testPos[2] < ScenarioInfo.size[2] - 8 then
                        table.insert(template[1], testPos)
                    end
                    if testPos2[1] > 8 and testPos2[1] < ScenarioInfo.size[1] - 8 and testPos2[2] > 8 and testPos2[2] < ScenarioInfo.size[2] - 8 then
                        table.insert(template[1], testPos2)
                    end
                end
            end
        end
        -- build near the base the engineer is part of, rather than the engineer location
        local baseLocation = {nil, nil, nil}
        if builder.BuildManagerData and builder.BuildManagerData.EngineerManager then
            -- Sess.98 (bis): fix typo nativo -- 'BuildManagerdata' -> 'BuildManagerData'
            baseLocation = builder.BuildManagerData.EngineerManager.Location
        end
        local location = aiBrain:FindPlaceToBuild(buildingType, whatToBuild, template, false, builder, baseLocation[1], baseLocation[3])
        if location then
            if location[1] > 8 and location[1] < ScenarioInfo.size[1] - 8 and location[2] > 8 and location[2] < ScenarioInfo.size[2] - 8 then
                AddToBuildQueue(aiBrain, builder, whatToBuild, location, false)
                return true
            end
        end
        -- Build in a regular spot if adjacency not found
        return AIExecuteBuildStructure(aiBrain, builder, buildingType, builder, true, buildingTemplate, baseTemplate)
    end
    return false
end

-- Sess.102 (decisione utente 2026-10-15/16): cantieri navali di Overwhelm+ distanziati di almeno
-- OWPLUS_SHIPYARD_MIN_SPACING (32) tra i centri, perche' le navi grandi restavano incastrate tra
-- cantieri attaccati. Uveso (AI-Uveso/hook/lua/AI/aibuildstructures.lua) cerca il posto con
-- FindPlaceToBuild e l'ingombro del Tempest, senza alcuna distanza dagli altri cantieri. Qui, solo
-- per 'T1SeaFactory' e solo per Overwhelm+, il punto lo sceglie OWPlusFindShipyardSpot
-- (OWPlusNavalCatalog.lua); se non trova nulla si ricade sul comportamento di Uveso. Il centro
-- della ricerca segue lo stesso ordine di Uveso: reference, ingegnere, base dell'ingegnere, partenza.
-- Import pigro: questo modulo e' importato da molti file, il catalogo navale solo quando serve.
local OWPlusOld_AIExecuteBuildStructure = AIExecuteBuildStructure
function AIExecuteBuildStructure(aiBrain, builder, buildingType, closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
    if buildingType == 'T1SeaFactory' and aiBrain.Uveso then
        local nav = import('/mods/AI-Uveso-child/lua/AI/OWPlusNavalCatalog.lua')
        if nav.OWPlusNavalCatalogEnabled() and nav.OWPlusIsPlusBrain(aiBrain) then
            local whatToBuild = aiBrain:DecideWhatToBuild(builder, buildingType, buildingTemplate)
            if whatToBuild then
                local center
                if reference and type(reference) == 'table' then
                    center = reference
                elseif closeToBuilder then
                    center = builder:GetPosition()
                elseif builder.BuilderManagerData and builder.BuilderManagerData.EngineerManager then
                    center = builder.BuilderManagerData.EngineerManager.Location
                else
                    local sx, sz = aiBrain:GetArmyStartPos()
                    center = { sx, 0, sz }
                end
                -- Sess.102 (test del 2026-10-16): ricerca DENTRO il raggio della base. Fondazione
                -- (reference = marker, base appena creata): raggio fisso; altrimenti il raggio della
                -- base dell'ingegnere, con il centro della base (non la posizione dell'ingegnere).
                local maxRadius = nav.OWPLUS_SHIPYARD_FOUNDING_RADIUS
                if not (reference and type(reference) == 'table') then
                    local em = builder.BuilderManagerData and builder.BuilderManagerData.EngineerManager
                    local locType = em and em.LocationType
                    local basePos, baseRadius = nil, nil
                    if locType then
                        basePos, baseRadius = nav.OWPlusNavalBaseCenterRadius(aiBrain, locType)
                    end
                    if basePos then
                        center, maxRadius = basePos, baseRadius
                    end
                end
                local pos, a, b = nav.OWPlusFindShipyardSpot(aiBrain, whatToBuild, center, maxRadius)
                local builderName = builder.PlatoonHandle and builder.PlatoonHandle.BuilderName
                if pos then
                    LOG('[OWPlus-NAVAL] AIExecuteBuildStructure: OK, cantiere ' .. tostring(whatToBuild) .. ' a (' .. pos[1] .. ',' .. pos[3]
                        .. '), ' .. a .. ' dal centro (' .. math.floor(center[1]) .. ',' .. math.floor(center[3]) .. '), raggio max ' .. maxRadius
                        .. ', cantieri/prenotazioni considerati ' .. b .. ', builder ' .. tostring(builderName) .. ' [' .. tostring(aiBrain.Nickname) .. ']')
                    AddToBuildQueue(aiBrain, builder, whatToBuild, NormalToBuildLocation(pos), false)
                    return true
                end
                -- Sess.102: niente ripiego sul piazzamento nativo (non rispetta la distanza e mette
                -- cantieri fuori dal raggio, che diventano basi nuove): il cantiere non si costruisce.
                LOG('[OWPlus-NAVAL] AIExecuteBuildStructure: nessun punto distanziato entro ' .. maxRadius .. ' dal centro ('
                    .. math.floor(center[1]) .. ',' .. math.floor(center[3]) .. ') (troppo vicini ' .. tostring(a) .. ', non costruibili '
                    .. tostring(b) .. '), builder ' .. tostring(builderName) .. ' -> cantiere NON costruito [' .. tostring(aiBrain.Nickname) .. ']')
                return false
            end
        end
    end
    -- Sess.102: difese delle basi navali ('OWPlus Naval Base Defenses', token 'OWPlusNavalDef_<tipo>_<tier>')
    if type(buildingType) == 'string' and string.sub(buildingType, 1, 15) == 'OWPlusNavalDef_' then
        return OWPlusBuildNavalBaseDefense(aiBrain, builder, buildingType, buildingTemplate)
    end
    return OWPlusOld_AIExecuteBuildStructure(aiBrain, builder, buildingType, closeToBuilder, relative, buildingTemplate, baseTemplate, reference, NearMarkerType)
end

local OWPlusNavalDefenseFallbackToken = {
    -- T3: solo il token T3 (esiste solo Cybran); un ripiego T2 non conterebbe nel tetto T3 e
    -- verrebbe ricostruito all'infinito
    antinavy = { 'T1NavalDefense', 'T2NavalDefense', 'T3NavalDefense' },
    aa       = { 'T1AADefense', 'T2AADefense', 'T3AADefense' },
    shield   = { nil, 'T2ShieldDefense', 'T3ShieldDefense' },
}

-- Traduce un token vanilla nell'ID della fazione dell'ingegnere, oppure restituisce l'ID moddato
-- (minuscolo); nil se l'ingegnere non lo sa costruire.
local function OWPlusResolveDefenseId(aiBrain, builder, pick, buildingTemplate)
    if not pick then
        return nil
    end
    local id = string.lower(pick)
    if not __blueprints[id] then
        id = aiBrain:DecideWhatToBuild(builder, pick, buildingTemplate)
    end
    if id and __blueprints[id] and builder:CanBuild(id) then
        return id
    end
    return nil
end

function OWPlusBuildNavalBaseDefense(aiBrain, builder, buildingType, buildingTemplate)
    local nav = import('/mods/AI-Uveso-child/lua/AI/OWPlusNavalCatalog.lua')
    local pool = import('/mods/AI-Uveso-child/lua/AI/OWPlusOutpostDefensePool.lua')
    local _, _, kind, tierText = string.find(buildingType, '^OWPlusNavalDef_(%a+)_(%d)$')
    local tier = tonumber(tierText)
    local em = builder.BuilderManagerData and builder.BuilderManagerData.EngineerManager
    local locType = em and em.LocationType
    if not kind or not tier or not locType then
        WARN('[OWPlus-NAVAL] OWPlusBuildNavalBaseDefense: token o base non validi (' .. tostring(buildingType) .. ', ' .. tostring(locType) .. ')')
        return false
    end
    local center, radius = nav.OWPlusNavalBaseCenterRadius(aiBrain, locType)
    if not center then
        return false
    end
    local pick = pool.OWPlusPickNavalBaseDefense(aiBrain, kind, tier)
    local id = OWPlusResolveDefenseId(aiBrain, builder, pick, buildingTemplate)
    local usedFallback = false
    if not id then
        local fallback = OWPlusNavalDefenseFallbackToken[kind] and OWPlusNavalDefenseFallbackToken[kind][tier]
        id = OWPlusResolveDefenseId(aiBrain, builder, fallback, buildingTemplate)
        usedFallback = true
    end
    if not id then
        LOG('[OWPlus-NAVAL] OWPlusBuildNavalBaseDefense: nessuna difesa ' .. kind .. ' T' .. tier .. ' costruibile da ' .. tostring(builder.UnitId)
            .. ' (scelta ' .. tostring(pick) .. ') a ' .. tostring(locType) .. ' [' .. tostring(aiBrain.Nickname) .. ']')
        return false
    end
    local pos = nav.OWPlusFindNavalDefenseSpot(aiBrain, id, center, radius)
    if not pos then
        LOG('[OWPlus-NAVAL] OWPlusBuildNavalBaseDefense: nessun posto per ' .. id .. ' (' .. kind .. ' T' .. tier .. ') entro ' .. radius
            .. ' da ' .. tostring(locType) .. ' [' .. tostring(aiBrain.Nickname) .. ']')
        return false
    end
    nav.OWPlusReserveNavalDefense(aiBrain, locType, kind, pos)
    LOG('[OWPlus-NAVAL] OWPlusBuildNavalBaseDefense: OK, ' .. kind .. ' T' .. tier .. ' ' .. id .. ' (scelta ' .. tostring(pick)
        .. (usedFallback and ', ripiego vanilla' or '') .. ') a (' .. pos[1] .. ',' .. pos[3] .. ') base ' .. tostring(locType)
        .. ' [' .. tostring(aiBrain.Nickname) .. ']')
    AddToBuildQueue(aiBrain, builder, id, NormalToBuildLocation(pos), false)
    return true
end
LOG('[AI-Uveso-child] aibuildstructures.lua: OK, hook AIExecuteBuildStructure attivo (cantieri Overwhelm+ distanziati, difese basi navali)')
