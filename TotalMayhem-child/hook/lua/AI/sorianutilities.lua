-- TotalMayhem-child: hook di /lua/AI/sorianutilities.lua (file FAF reale, appeso al modulo originale).
--
-- Le strutture "perimetro" sugli idrocarburi (BRM/BRN/BRO/BRPBT1PERI, BRNBAAFAC) sono rese non
-- costruibili in hook/lua/system/Blueprints.lua (tolte tutte le categorie BUILTBY*). Ma Total
-- Mayhem le propone ancora alle IA via CustomUnits (lua/CustomUnits/all units 1/2.lua, voce
-- T1HydroCarbon, peso 50): l'ingegnere prova a costruirle al posto della vera centrale, fallisce
-- e il log si riempie di "Unknown builder category" / "DecideWhatToBuild() failed" (1088 per
-- partita per l'IA UEF nel test 2026-10-01).
--
-- Qui, subito dopo il caricamento della lista (per OGNI IA), si toglie qualunque sostituzione
-- verso un'unita' che non ha nessuna categoria BUILTBY* o non esiste: non potrebbe mai essere
-- costruita. Criterio generico (nessun elenco di ID): copre anche future unita' disattivate allo
-- stesso modo o riferite da mod non attive. Una fazione senza sostituzioni viene tolta (nil),
-- cosi' FAF usa direttamente l'unita' vanilla.

local OWChildTMOriginalAddCustomUnitSupport = AddCustomUnitSupport

local function OWChildTMIsBuildable(unitId)
    local bp = __blueprints[string.lower(tostring(unitId))]
    if not (bp and bp.Categories) then
        return false
    end
    for _, cat in bp.Categories do
        if string.find(cat, 'BUILTBY', 1, true) then
            return true
        end
    end
    return false
end

function AddCustomUnitSupport(aiBrain)
    OWChildTMOriginalAddCustomUnitSupport(aiBrain)
    if not aiBrain.CustomUnits then
        return
    end
    local nick = tostring(aiBrain.Nickname)
    local removed = 0
    for templateName, byFaction in aiBrain.CustomUnits do
        for faction, entries in byFaction do
            for i = table.getn(entries), 1, -1 do
                local unitId = entries[i][1]
                if not OWChildTMIsBuildable(unitId) then
                    table.remove(entries, i)
                    removed = removed + 1
                    LOG('[TotalMayhem-child] [' .. nick .. '] OK, rimossa sostituzione CustomUnits non costruibile ' .. tostring(templateName)
                        .. ' / ' .. tostring(faction) .. ' -> ' .. tostring(unitId))
                end
            end
            if table.getn(entries) == 0 then
                byFaction[faction] = nil
            end
        end
    end
    LOG('[TotalMayhem-child] [' .. nick .. '] OK, filtro CustomUnits non costruibili completato: ' .. removed .. ' sostituzioni rimosse')
end
