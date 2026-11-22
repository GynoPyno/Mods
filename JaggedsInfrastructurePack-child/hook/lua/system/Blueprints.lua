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
    -- potenziando il magazzino di MASSA T3; si vorrebbe ottenerlo anche dal magazzino di ENERGIA T3 della stessa fazione.
    -- Serve, sulla sorgente, General.UpgradesTo + Economy.BuildableCategory verso il T4 (CanBuild nativo); e nel bersaglio
    -- il motore deve riconoscere un POTENZIAMENTO (StructureUnit.OnStartBuild e construction.lua: UpgradesFrom == sorgente,
    -- oppure UpgradesFromBase uguale tra bersaglio e sorgente / uguale alla sorgente). UpgradesFrom ha un solo valore.
    -- REGRESSIONE (stessa sessione): la prima versione, UpgradesFromBase = magazzino di energia sul solo T4, ha rotto anche il
    -- percorso da MASSA (pulsante e shortcut non avviavano piu' il potenziamento, segnalazione dell'utente). Il motore valida
    -- l'ordine con codice compilato non leggibile: ora tre modalita' da provare UNA ALLA VOLTA (default 'off').
    -- MODALITA' (e' anche il flag di ripristino):
    --   'off'            = nessuna modifica ai blueprint (stato originale: solo percorso da massa)
    --   'solo-sorgente'  = energia T3: UpgradesTo + BuildableCategory verso il T4; nessun UpgradesFromBase
    --   'base-condivisa' = come sopra + lo stesso UpgradesFromBase (radice della catena di massa, come le catene vanilla)
    --                      su massa T3, energia T3 e T4
    -- In tutte le modalita' il log scrive i campi di potenziamento dei magazzini T3/T4 dopo ModBlueprints.
    local OWPlusStorageT4FromEnergyMode = 'off'
    local OWPlusStorageT4Family = {
        { energy = 'euabest3', mass = 'euabmst3', t4 = 'bab1106', root = 'uab1106' },   -- Aeon
        { energy = 'euebest3', mass = 'euebmst3', t4 = 'beb1106', root = 'ueb1106' },   -- UEF
        { energy = 'eurbest3', mass = 'eurbmst3', t4 = 'brb1106', root = 'urb1106' },   -- Cybran
        { energy = 'exsbest3', mass = 'exsbmst3', t4 = 'bsb1106', root = 'xsb1106' },   -- Seraphim
    }
    do
        local mode = OWPlusStorageT4FromEnergyMode
        if mode ~= 'off' and mode ~= 'solo-sorgente' and mode ~= 'base-condivisa' then
            WARN('[JaggedsInfrastructurePack-child] ModBlueprints: modalita magazzino T4 non valida "' .. tostring(mode) .. '", uso "off"')
            mode = 'off'
        end
        LOG('[JaggedsInfrastructurePack-child] ModBlueprints: percorso magazzino energia T3 -> T4, modalita "' .. mode .. '"')
        local byId = {}
        for id, bp in pairs(all_bps.Unit) do
            byId[string.lower(id)] = bp
        end
        local function Fields(bp)
            if not bp then
                return 'MANCANTE'
            end
            local g = bp.General or {}
            local e = bp.Economy or {}
            local cats = ''
            if e.BuildableCategory then
                cats = table.concat(e.BuildableCategory, ',')
            end
            return 'UpgradesFrom=' .. tostring(g.UpgradesFrom) .. ' UpgradesFromBase=' .. tostring(g.UpgradesFromBase)
                .. ' UpgradesTo=' .. tostring(g.UpgradesTo) .. ' BuildableCategory={' .. cats .. '}'
        end
        local applied = 0
        for _, f in ipairs(OWPlusStorageT4Family) do
            local src = byId[f.energy]
            local srcMass = byId[f.mass]
            local dst = byId[f.t4]
            if mode ~= 'off' then
                if src and dst then
                    src.General = src.General or {}
                    src.Economy = src.Economy or {}
                    src.General.UpgradesTo = f.t4
                    local already = false
                    if src.Economy.BuildableCategory then
                        for _, c in ipairs(src.Economy.BuildableCategory) do
                            if string.lower(c) == f.t4 then
                                already = true
                            end
                        end
                    else
                        src.Economy.BuildableCategory = {}
                    end
                    if not already then
                        table.insert(src.Economy.BuildableCategory, f.t4)
                    end
                    if not src.Economy.BuildRate then
                        src.Economy.BuildRate = 20
                    end
                    dst.General = dst.General or {}
                    local from = dst.General.UpgradesFrom
                    if not from or from == '' or from == 'none' then
                        dst.General.UpgradesFrom = f.mass
                    end
                    if mode == 'base-condivisa' then
                        dst.General.UpgradesFromBase = f.root
                        src.General.UpgradesFromBase = f.root
                        if srcMass then
                            srcMass.General = srcMass.General or {}
                            srcMass.General.UpgradesFromBase = f.root
                        end
                    end
                    applied = applied + 1
                else
                    WARN('[JaggedsInfrastructurePack-child] ModBlueprints: percorso ' .. f.energy .. ' -> ' .. f.t4 .. ' non applicato, blueprint mancante (sorgente '
                        .. tostring(src ~= nil) .. ', T4 ' .. tostring(dst ~= nil) .. ')')
                end
            end
            LOG('[JaggedsInfrastructurePack-child] ModBlueprints: diag ' .. f.mass .. ' ' .. Fields(srcMass))
            LOG('[JaggedsInfrastructurePack-child] ModBlueprints: diag ' .. f.energy .. ' ' .. Fields(src))
            LOG('[JaggedsInfrastructurePack-child] ModBlueprints: diag ' .. f.t4 .. ' ' .. Fields(dst))
        end
        if mode ~= 'off' then
            LOG('[JaggedsInfrastructurePack-child] ModBlueprints: percorsi energia -> T4 applicati ' .. applied .. ' di 4 (modalita "' .. mode .. '")')
        else
            LOG('[JaggedsInfrastructurePack-child] ModBlueprints: modalita "off", blueprint dei magazzini lasciati com\'erano')
        end
    end
end
