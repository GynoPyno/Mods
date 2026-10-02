-- AI-Uveso-child: hook di /lua/ai/aiutilities.lua (file FAF reale, appeso dopo l'hook di AI-Uveso).
--
-- DIAGNOSTICA TEMPORANEA (sess.100 parte 13, da togliere a indagine chiusa): i plotoni batch
-- terra di MAIN si formavano con 48-50 unita' ma partivano in marcia con 6-13 nello stesso
-- secondo. HeroFightPlatoon chiama MergeWithNearbyStatePlatoons(self, BuilderName, 40, 150, true):
-- un plotone assorbe TUTTE le unita' dei plotoni con lo stesso BuilderName entro 40. Qui si
-- logga ogni merge che coinvolge un plotone con marcia in formazione (PlatoonData.OWPlusFormationMarch),
-- con il numero progressivo assegnato in hook/lua/platoon.lua (HeroFightPlatoon). Nessun
-- cambiamento di comportamento: stessa funzione, stessi argomenti, stesso valore restituito.

local OWPlusOriginalMergeWithNearbyStatePlatoons = MergeWithNearbyStatePlatoons

MergeWithNearbyStatePlatoons = function(platoon, stateMachine, radius, maxMergeNumber, ignoreBase)
    local tracked = platoon and not IsDestroyed(platoon) and platoon.PlatoonData and platoon.PlatoonData.OWPlusFormationMarch
    local before = 0
    if tracked then
        before = table.getn(platoon:GetPlatoonUnits())
    end
    local merged = OWPlusOriginalMergeWithNearbyStatePlatoons(platoon, stateMachine, radius, maxMergeNumber, ignoreBase)
    if merged and tracked and not IsDestroyed(platoon) then
        LOG('[OWPlus-DIAG-PLATOON] #' .. tostring(platoon.OWPlusSerial or '?') .. ' "' .. tostring(platoon.BuilderName)
            .. '" MERGE: ha assorbito plotoni vicini con lo stesso nome, unita\' ' .. before .. ' -> ' .. table.getn(platoon:GetPlatoonUnits())
            .. ' (t=' .. string.format('%.0f', GetGameTimeSeconds()) .. ')')
    end
    return merged
end

LOG('[OWPlus-DIAG-PLATOON] aiutilities: OK, tracciamento MergeWithNearbyStatePlatoons agganciato')
