
local OldOnCreateArmyBrainOWPlus = OnCreateArmyBrain
function OnCreateArmyBrain(index, brain, name, nickname)
    OldOnCreateArmyBrainOWPlus(index, brain, name, nickname)
    if brain.BrainType == 'AI' and nickname ~= 'civilian' then
        local owPlusCap = tonumber(ScenarioInfo.Options.OWPlusUnitCap)
        if owPlusCap and owPlusCap > 0 then
            local personality = ScenarioInfo.ArmySetup[brain.Name] and ScenarioInfo.ArmySetup[brain.Name].AIPersonality
            if personality == 'overwhelmplus' or personality == 'overwhelmpluscheat' then
                SetArmyUnitCap(index, owPlusCap)
            end
        end
    end
end

-- Sess.102 (test navale su Shards del 2026-10-16): la lista di punti navali che Uveso genera
-- (AIMarkerGenerator.CreateNavalExpansions, AI-Uveso/hook/lua/simInit.lua) contiene ogni
-- posizione DUE volte: marker 'Naval Area N' e 'Naval Area N+52' sullo stesso punto. Ogni marker
-- e' un'area "libera" per AIFindNavalAreaNeedsEngineer, quindi la stessa area veniva fondata due
-- volte (due BuilderManager sovrapposti, con tutti i loro builder). Qui si tiene un solo punto
-- ogni OWPLUS_NAVAL_MARKER_MIN_DISTANCE. I marker sono condivisi da tutte le IA (ordine della
-- lista invariato: deterministico); rollback con OWPlusNavalCatalogDisabled = true.
local OWPLUS_NAVAL_MARKER_MIN_DISTANCE = 10
local OWPlusOld_ConvertNavalExpansionsToFAF = ConvertNavalExpansionsToFAF
function ConvertNavalExpansionsToFAF(NavalMarkerPositions)
    local targets = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')
    if targets.OWPlusNavalCatalogDisabled or not NavalMarkerPositions then
        return OWPlusOld_ConvertNavalExpansionsToFAF(NavalMarkerPositions)
    end
    local kept = {}
    local minSq = OWPLUS_NAVAL_MARKER_MIN_DISTANCE * OWPLUS_NAVAL_MARKER_MIN_DISTANCE
    local total = 0
    for _, p in ipairs(NavalMarkerPositions) do
        total = total + 1
        local duplicate = false
        for _, q in ipairs(kept) do
            local dx, dz = p.x - q.x, p.z - q.z
            if dx * dx + dz * dz < minSq then
                duplicate = true
                break
            end
        end
        if not duplicate then
            table.insert(kept, p)
        end
    end
    LOG('[OWPlus-NAVAL] ConvertNavalExpansionsToFAF: OK, marker navali generati ' .. total .. ', tenuti ' .. table.getn(kept)
        .. ' (doppioni entro ' .. OWPLUS_NAVAL_MARKER_MIN_DISTANCE .. ' scartati: ' .. (total - table.getn(kept)) .. ')')
    return OWPlusOld_ConvertNavalExpansionsToFAF(kept)
end
