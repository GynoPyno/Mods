local BaseModBlueprints = ModBlueprints

function ModBlueprints(all_bps)
    BaseModBlueprints(all_bps)
    for id, bp in pairs(all_bps.Unit) do
        local lid = string.lower(id)

        if lid == 'euabest2' or lid == 'euebest2' or lid == 'eurbest2' or lid == 'exsbest2' then      -- Energy Storage T2 (tutte le fazioni)
            if bp.Economy then
                bp.Economy.StorageEnergy = 15000
                bp.Economy.BuildCostEnergy = 15000
                bp.Economy.BuildCostMass = 200
            end

        elseif lid == 'euabest3' or lid == 'euebest3' or lid == 'eurbest3' or lid == 'exsbest3' then  -- Energy Storage T3 (tutte le fazioni)
            if bp.Economy then
                bp.Economy.StorageEnergy = 45000
                bp.Economy.BuildCostEnergy = 67500
                bp.Economy.BuildCostMass = 400
            end

        elseif lid == 'euabmst2' or lid == 'euebmst2' then    -- Mass Storage T2 Aeon/UEF
            if bp.Economy then
                bp.Economy.StorageMass = 1500
                bp.Economy.BuildCostEnergy = 2250
                bp.Economy.BuildCostMass = 950
            end

        elseif lid == 'eurbmst2' or lid == 'exsbmst2' then    -- Mass Storage T2 Cybran/Seraphim (costo massa originale gia' asimmetrico vs Aeon/UEF)
            if bp.Economy then
                bp.Economy.StorageMass = 1500
                bp.Economy.BuildCostEnergy = 2250
                bp.Economy.BuildCostMass = 750
            end

        elseif lid == 'euabmst3' or lid == 'euebmst3' or lid == 'eurbmst3' or lid == 'exsbmst3' then  -- Mass Storage T3 (tutte le fazioni)
            if bp.Economy then
                bp.Economy.StorageMass = 4500
                bp.Economy.BuildCostEnergy = 4500
                bp.Economy.BuildCostMass = 3000
            end

        elseif lid == 'bab1106' or lid == 'beb1106' or lid == 'brb1106' or lid == 'bsb1106' then      -- Magazzino ibrido Massa+Energia T4 (tutte le fazioni)
            -- Storage a 2/3 (non 3/4 come il resto, richiesta esplicita utente), costo a 3/4 come tutti gli altri
            if bp.Economy then
                bp.Economy.StorageMass = 5000
                bp.Economy.StorageEnergy = 50000
                bp.Economy.BuildCostEnergy = 75000
                bp.Economy.BuildCostMass = 3750
            end
        end
    end

    -- Sess.104 (2026-11-22): il magazzino ibrido Massa+Energia T4 (bab1106/beb1106/brb1106/bsb1106) si otteneva solo
    -- potenziando il magazzino di MASSA T3. Ora anche dal magazzino di ENERGIA T3 della stessa fazione.
    -- Come funziona il motore (StructureUnit.OnStartBuild e construction.lua di FAF): l'ordine e' un potenziamento se, nel
    -- blueprint del BERSAGLIO, UpgradesFrom == id della sorgente, oppure UpgradesFromBase == id della sorgente. UpgradesFrom
    -- ha un solo valore (resta il magazzino di massa T3, percorso gia' funzionante), quindi si usa UpgradesFromBase per
    -- l'energia. Serve anche, sulla sorgente, General.UpgradesTo + Economy.BuildableCategory verso il T4 (CanBuild nativo).
    -- Limite noto: dall'energia mancano i flag "in potenziamento" di Unit.OnStartBuild (solo UpgradesFrom == sorgente):
    -- il T4 in costruzione puo' essere colpito e compare l'effetto cubo di costruzione. Estetica, nessun impatto di gioco.
    -- Flag di ripristino: OWPlusStorageT4FromEnergyEnabled = false torna al solo percorso da massa.
    local OWPlusStorageT4FromEnergyEnabled = true
    local OWPlusStorageT4FromEnergy = {
        { energy = 'euabest3', mass = 'euabmst3', t4 = 'bab1106' },   -- Aeon
        { energy = 'euebest3', mass = 'euebmst3', t4 = 'beb1106' },   -- UEF
        { energy = 'eurbest3', mass = 'eurbmst3', t4 = 'brb1106' },   -- Cybran
        { energy = 'exsbest3', mass = 'exsbmst3', t4 = 'bsb1106' },   -- Seraphim
    }
    if OWPlusStorageT4FromEnergyEnabled then
        LOG('[JaggedsInfrastructurePack-child] ModBlueprints: OK, percorso magazzino energia T3 -> magazzino ibrido T4')
        local byId = {}
        for id, bp in pairs(all_bps.Unit) do
            byId[string.lower(id)] = bp
        end
        local applied = 0
        for _, pair in ipairs(OWPlusStorageT4FromEnergy) do
            local src = byId[pair.energy]
            local dst = byId[pair.t4]
            if src and dst then
                src.General = src.General or {}
                src.Economy = src.Economy or {}
                src.General.UpgradesTo = pair.t4
                local already = false
                if src.Economy.BuildableCategory then
                    for _, c in ipairs(src.Economy.BuildableCategory) do
                        if string.lower(c) == pair.t4 then
                            already = true
                        end
                    end
                else
                    src.Economy.BuildableCategory = {}
                end
                if not already then
                    table.insert(src.Economy.BuildableCategory, pair.t4)
                end
                if not src.Economy.BuildRate then
                    src.Economy.BuildRate = 20
                end
                dst.General = dst.General or {}
                dst.General.UpgradesFromBase = pair.energy
                local from = dst.General.UpgradesFrom
                if not from or from == '' or from == 'none' then
                    dst.General.UpgradesFrom = pair.mass
                end
                applied = applied + 1
                LOG('[JaggedsInfrastructurePack-child] ModBlueprints: ' .. pair.energy .. ' -> ' .. pair.t4 .. ' OK (UpgradesFrom ' .. tostring(dst.General.UpgradesFrom)
                    .. ', UpgradesFromBase ' .. tostring(dst.General.UpgradesFromBase) .. ')')
            else
                WARN('[JaggedsInfrastructurePack-child] ModBlueprints: percorso ' .. pair.energy .. ' -> ' .. pair.t4 .. ' non applicato, blueprint mancante (sorgente '
                    .. tostring(src ~= nil) .. ', T4 ' .. tostring(dst ~= nil) .. ')')
            end
        end
        LOG('[JaggedsInfrastructurePack-child] ModBlueprints: percorsi energia -> T4 applicati ' .. applied .. ' di 4')
    else
        LOG('[JaggedsInfrastructurePack-child] ModBlueprints: OWPlusStorageT4FromEnergyEnabled=false, solo percorso da massa')
    end
end
