-- AI-Uveso-child: hook Blueprints.lua
-- Sess.87: KEB2304 ("Thor", #Marlos mods compilation) risultava sempre
-- CanBuild=false per qualunque ingegnere (152 fallimenti confermati in un
-- solo test, mai un successo) — causa: nel .bp sorgente della mod
-- 'BUILTBYTIER3ENGINEER' e 'BUILTBYTIER3COMMANDER' sono COMMENTATE (WIP mai
-- completato dal modder), quindi l'unita' non e' costruibile da nessuno.
-- Non tocchiamo il file sorgente (mod terza, sola lettura per convenzione di
-- progetto) — le riattiviamo qui via ModBlueprints, stesso meccanismo gia'
-- usato da AntaresUnitPack-child per casi analoghi.
local BaseModBlueprints = ModBlueprints

-- Sess.100 parte 13 (decisione utente): fasce di velocita' per i plotoni terra di MAIN.
-- In marcia in formazione il plotone va alla velocita' dell'unita' piu' lenta; il motore
-- forma i plotoni SOLO per categoria (CanFormPlatoon/FormPlatoon compilati), quindi ogni
-- unita' terrestre mobile riceve qui una categoria 'OWPLUSSPEED<n>' calcolata da
-- Physics.MaxSpeed: nessun elenco di ID, vale anche per unita' di mod future. Limiti
-- superiori esclusivi; l'ultima fascia prende tutto il resto. I template dei plotoni
-- (OWPlus PlatoonTemplates Land Attack.lua) scoprono da soli quante fasce esistono.
-- Categoria nuova aggiunta in ModBlueprints: stesso meccanismo di FAF ('DRAGBUILD'),
-- PostModBlueprints ricalcola CategoriesHash.
local OWPlusSpeedBandUpperLimits = { 2.0, 2.5, 3.0, 3.5, 4.0 }

local function OWPlusAddSpeedBandCategories(all_bps)
    local perBand = {}
    for id, bp in pairs(all_bps.Unit) do
        if bp.Categories and table.find(bp.Categories, 'MOBILE') and table.find(bp.Categories, 'LAND') then
            local speed = (bp.Physics and bp.Physics.MaxSpeed) or 0
            local band = table.getn(OWPlusSpeedBandUpperLimits) + 1
            for i, limit in ipairs(OWPlusSpeedBandUpperLimits) do
                if speed < limit then
                    band = i
                    break
                end
            end
            table.insert(bp.Categories, 'OWPLUSSPEED' .. band)
            perBand[band] = (perBand[band] or 0) + 1
        end
    end
    for band = 1, table.getn(OWPlusSpeedBandUpperLimits) + 1 do
        LOG('[OWPlus-SPEEDBAND] Blueprints: OK, fascia OWPLUSSPEED' .. band .. ' assegnata a ' .. tostring(perBand[band] or 0) .. ' unita\' terrestri mobili')
    end
end

function ModBlueprints(all_bps)
    if BaseModBlueprints then
        BaseModBlueprints(all_bps)
    end
    OWPlusAddSpeedBandCategories(all_bps)
    for id, bp in pairs(all_bps.Unit) do
        if string.lower(id) == 'keb2304' then
            if bp.Categories then
                table.insert(bp.Categories, 'BUILTBYTIER3ENGINEER')
                table.insert(bp.Categories, 'BUILTBYTIER3COMMANDER')
                LOG('[OWPlus] Blueprints: OK, KEB2304 - riabilitate BUILTBYTIER3ENGINEER/COMMANDER (erano commentate nel .bp sorgente)')
            end
        end
    end
end
