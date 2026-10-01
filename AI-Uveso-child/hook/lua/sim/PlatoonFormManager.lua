-- PlatoonFormManager.lua (hook)
-- Instrumentazione diagnostica temporanea (sess.73): stesso scopo di
-- hook/lua/sim/FactoryBuilderManager.lua, ma per Fase B ('OWPlus Outpost
-- Factory Upgrade', BuildersType='PlatoonFormBuilder'). A differenza di
-- FactoryBuilderManager (che decide via AssignBuildOrder su eventi di
-- completamento), PlatoonFormManager decide TUTTO dentro ManagerLoopBody,
-- richiamato dal loop periodico condiviso (BuilderManager.ManagerThread,
-- BuilderCheckInterval=5s per questo tipo di manager). Se GetBuilderStatus()
-- e CheckInstanceCount() sono veri ma nessun upgrade avviene mai (confermato
-- da SelectedBuilder assente in sess.71-73), il sospetto e' che
-- poolPlatoon:CanFormPlatoon(...) (ricerca spaziale del match GlobalSquads
-- entro FormRadius, interna al metodo originale, non duplicata qui) fallisca
-- silenziosamente — questo hook lo isola per eliminazione, loggando lo stato
-- appena PRIMA che il metodo originale tenti il form. Pattern di subclassing
-- identico a hook/lua/sim/FactoryBuilderManager.lua. Da rimuovere/silenziare
-- una volta diagnosticato.
--
-- Sess.98: usato temporaneamente per diagnosticare 'OWPlus Extractor Upgrade
-- T4' (confermato: poolPlatoon:CanFormPlatoon(...) tornava sempre false anche
-- con FormRadius=10000 esplicito -- causa nativa/compilata, non identificabile
-- a livello Lua). Diagnosi conclusa, builder rimosso (vedi 'OWPlus Economy
-- Upgrade.lua' e hook/lua/platoon.lua per il meccanismo sostitutivo) --
-- rimossa anche la relativa estensione diagnostica qui.
--
-- Sess.98 (bis): riusato per 'OWPlus Energy Generator Upgrade T4' -- il fix
-- BuildableCategory ha sbloccato il PRIMO upgrade (T4=1 confermato in game).
-- Diagnosi InstanceCount confermata (CheckInstanceCount=false permanente
-- dopo il primo successo) e fix implementato (subclass UnitUpgradeAI,
-- hook/lua/platoon.lua). Rimossa la chiamata diagnostica a CanFormPlatoon
-- qui: sospetto (non confermato) che chiamarla "a vuoto" come sonda possa
-- interferire con la chiamata reale del motore subito dopo (stessa risorsa
-- condivisa ArmyPool) -- un test successivo con questa sonda attiva ha
-- mostrato zero tentativi di upgrade nonostante candidati disponibili,
-- diversamente dal test precedente senza rilanci ravvicinati della sonda.
-- Da rivalutare se necessario, ma per ora si preferisce non rischiare falsi
-- negativi nei test futuri.
--
-- Sess.100: estensione temporanea per verificare il fix "streaming ->
-- batching" dei plotoni offensivi terra (EnemyZone, vedi 'OWPlus Land Attack
-- Batching.lua'). A differenza della diagnostica avamposti sopra (solo
-- GetBuilderStatus/CheckInstanceCount, mai la size reale), qui confrontiamo
-- aiBrain:GetPlatoonsList() PRIMA e DOPO la chiamata nativa: se e' comparso
-- un plotone in piu', lo assumiamo formato da QUESTA chiamata (nessun altro
-- Builder viene valutato nel frattempo, ManagerLoopBody e' sincrono) e ne
-- logghiamo la size reale via GetPlatoonUnits(). Da rimuovere dopo la
-- conferma (checklist: log temporanei puliti a fine indagine).

local OWPlusLandAttackBatchingBuilderNames = {
    ['U123 Enemy Unprotected Mass Land 2 2'] = true,
    ['OWPlus Enemy Unprotected Mass Land Batch 10'] = true,
    ['U123 Enemy Intercept 15 30 (200)'] = true,
    ['OWPlus Enemy Intercept Batch 30 40'] = true,
    ['U123 Enemy Unprotected Land 1 2'] = true,
    ['OWPlus Enemy Unprotected Land Batch 10'] = true,
    ['U123 AntiDef+mex Early 1 20 (300)'] = true,
    ['OWPlus AntiDef+mex Batch 15 20'] = true,
    ['U123 AntiMass Early 6 8'] = true,
    ['OWPlus AntiMass Batch 20 25'] = true,
    -- MAIN (OWPlus Formers.lua, sess.100 parte 3): batch + originali a streaming
    ['OWPlus Land Batch 10'] = true,
    ['OWPlus Land Batch 20 25'] = true,
    ['OWPlus Land Batch 30 40'] = true,
    ['OWPlus Land T1 Rush 3 6'] = true,
    ['OWPlus Land Intercept Small'] = true,
    ['OWPlus Land Attack Medium'] = true,
    ['OWPlus Land T1 Rush'] = true,
}

-- Sess.100 (seconda parte): stessa tecnica, ora su 'U123 Air Formers
-- EnemyZone' (vedi 'OWPlus Air Attack Batching.lua') -- 9 builder nativi
-- (fallback) + 5 nuovi consolidati AntiAir/AntiGround a batching.
local OWPlusAirAttackBatchingBuilderNames = {
    ['U123 Enemy ScoutHunter EnemyZone 1 2'] = true,
    ['U123 Enemy AntiAir EnemyZone'] = true,
    ['U12 Enemy AntiMass Gunship'] = true,
    ['U12 Enemy AntiMass Bomber 3 5'] = true,
    ['U12 Enemy Unprotected Gunship 3 5'] = true,
    ['U12 Enemy Unprotected Bomber 1 3'] = true,
    ['U123 Enemy AntiGround Bomber'] = true,
    ['U123 Enemy AntiGround Gunship'] = true,
    ['U123 Enemy AntiEngineer Bomber'] = true,
    ['OWPlus Enemy AntiAir Batch 15'] = true,
    ['OWPlus Enemy AntiAir Batch 25'] = true,
    ['OWPlus Enemy AntiAir Batch 35'] = true,
    ['OWPlus Enemy AntiGround Batch 15'] = true,
    ['OWPlus Enemy AntiGround Batch 25'] = true,
    -- MAIN (OWPlus Formers.lua, sess.100 parte 3): batch + originali a streaming
    ['OWPlus Air AntiAir Batch 15'] = true,
    ['OWPlus Air AntiAir Batch 25'] = true,
    ['OWPlus Air AntiAir Batch 35'] = true,
    ['OWPlus Air AntiGround Batch 15'] = true,
    ['OWPlus Air AntiGround Batch 25'] = true,
    ['OWPlus Air Fighter Small'] = true,
    ['OWPlus Air Gunship Solo'] = true,
    ['OWPlus Air Gunship Group'] = true,
}

-- Sess.100 (seconda parte, diagnosi zero-formazioni): filtri identici a
-- quelli usati nei nuovi PlatoonTemplate aria, per contare quante unita'
-- possiede davvero l'AI (totali e idle) -- verifica se il problema e' "zero
-- unita' prodotte" (a monte, produzione) o "prodotte ma non nel pool libero".
local OWPlusAirAttackFighterCategory = categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR - categories.GROUNDATTACK - categories.BOMBER - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL - categories.ANTINAVY
local OWPlusAirAttackBomberGunshipCategory = categories.MOBILE * categories.AIR * ( categories.GROUNDATTACK + categories.BOMBER ) - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL - categories.ANTINAVY
-- Sess.100 parte 9: stesso filtro dei template di attacco terra (OWPlus PlatoonTemplates Land Attack.lua)
-- (categories.STEALTHFIELD puo' non esistere in alcune build: stesso guard dei template terra)
local OWPlusLandAttackCategory = categories.MOBILE * categories.LAND - categories.SHIELD - (categories.STEALTHFIELD or categories.SHIELD) - categories.EXPERIMENTAL
    - categories.ENGINEER - categories.SCOUT - categories.COMMAND - categories.SUBCOMMANDER
local OWPlusOutpostDiagRemovedLogged = false
local OWPlusAirAnyDiagLogged = false

-- Sess.100 parte 11: diagnostica generica "chi forma plotoni aerei piccoli?" (sintomo utente: aerei singoli
-- mandati all'attacco appena costruiti, nonostante il batching MAIN da 15). Si applica ai soli builder con
-- template aereo (esclusi gli upgrade di fabbrica) per non pesare sul resto: logga OGNI plotone formato con
-- builder, template, dimensione e location, cosi' un singolo test dice quale builder lo produce.
local function OWPlusIsAirFormTemplate(tplName)
    if type(tplName) ~= 'string' or string.find(tplName, 'Upgrade') then
        return false
    end
    return string.find(tplName, 'Air') ~= nil or string.find(tplName, 'Interceptor') ~= nil
        or string.find(tplName, 'Torpedo') ~= nil or string.find(tplName, 'Suicide') ~= nil
        or string.find(tplName, 'Gunship') ~= nil or string.find(tplName, 'Bomber') ~= nil
        or string.find(tplName, 'Fighter') ~= nil or string.find(tplName, 'Transport') ~= nil
end

local prevClass = PlatoonFormManager

PlatoonFormManager = Class(prevClass) {
    -- Sess.100 parte 3: cooldown 'DelayEqualBuildPlattons' per i PlatoonFormBuilder.
    -- Nel motore (BuilderManager.lua, GetHighestBuilder) il timestamp viene SCRITTO solo
    -- per i builder scelti da EngineerManager/FactoryBuilderManager; PlatoonFormManager
    -- non passa mai da li' (ManagerLoopBody forma ogni builder in autonomia), quindi la
    -- condizione 'CheckBuildPlattonDelay' era sempre vera e il cooldown non scattava mai.
    -- Qui completiamo il contratto: se il builder ha il campo e una chiamata nativa ha
    -- appena formato un plotone (snapshot before/after, chiamata sincrona, stessa
    -- tecnica della diagnostica sotto), armiamo il timer del gruppo.
    ManagerLoopBody = function(self, builder, bType)
        local delay = builder.DelayEqualBuildPlattons
        local aiBrain = self.Brain
        if not delay or not aiBrain or not aiBrain.GetPlatoonsList or not aiBrain.DelayEqualBuildPlattons then
            self:OWPlusLoopBodyDiag(builder, bType)
            return
        end
        local before = table.getn(aiBrain:GetPlatoonsList())
        self:OWPlusLoopBodyDiag(builder, bType)
        if table.getn(aiBrain:GetPlatoonsList()) > before then
            aiBrain.DelayEqualBuildPlattons[delay[1]] = GetGameTimeSeconds() + delay[2]
            LOG('[OWPlus-COOLDOWN] OK: [' .. tostring(aiBrain.Nickname) .. '] builder "' .. tostring(builder.BuilderName) .. '" ha formato un plotone, gruppo "'
                .. tostring(delay[1]) .. '" bloccato per ' .. tostring(delay[2]) .. 's (t=' .. string.format('%.0f', GetGameTimeSeconds()) .. ')')
        end
    end,

    -- Conteggi di un pool di unita' per la diagnostica: fisici (totali/idle), ArmyPool nel raggio
    -- del manager valutante e ArmyPool TOTALE dell'IA (CanFormPlatoon con FormRadius enorme vede
    -- questo). Un'unita' idle ma fuori dall'ArmyPool (membro di un altro plotone) non e' formabile.
    OWPlusPoolCounts = function(self, aiBrain, category)
        local total = table.getn(aiBrain:GetListOfUnits(category, false))
        local idle = table.getn(aiBrain:GetListOfUnits(category, true))
        local poolLocal, poolAll = 'n/a', 'n/a'
        local poolPlatoon = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
        if poolPlatoon then
            poolAll = 0
            for _, u in poolPlatoon:GetPlatoonUnits() do
                if not u.Dead and EntityCategoryContains(category, u) then
                    poolAll = poolAll + 1
                end
            end
            local engManager = self.LocationType and aiBrain.BuilderManagers[self.LocationType] and aiBrain.BuilderManagers[self.LocationType].EngineerManager
            if engManager then
                poolLocal = poolPlatoon:GetNumCategoryUnits(category, engManager:GetLocationCoords(), engManager.Radius)
            end
        end
        return total, idle, poolLocal, poolAll
    end,

    OWPlusLoopBodyDiag = function(self, builder, bType)
        -- Sess.100 parte 9: throttle PER BRAIN (prima era una variabile di modulo condivisa: con 2 IA
        -- ne loggava una sola per finestra, mescolando le serie) e nickname del brain in ogni riga.
        if self.Brain and builder.BuilderName and OWPlusAirAttackBatchingBuilderNames[builder.BuilderName] then
            local now = GetGameTimeSeconds()
            local aiBrain = self.Brain
            if now - (aiBrain.OWPlusAirPoolDiagLast or -100) >= 15 then
                aiBrain.OWPlusAirPoolDiagLast = now
                local fighters, fightersIdle, fightersPool, fightersPoolAll = self:OWPlusPoolCounts(aiBrain, OWPlusAirAttackFighterCategory)
                local bombers, bombersIdle, bombersPool, bombersPoolAll = self:OWPlusPoolCounts(aiBrain, OWPlusAirAttackBomberGunshipCategory)
                LOG('[OWPlus-DIAG-AirAttack-Pool] [' .. tostring(aiBrain.Nickname) .. '] fighter_totali=' .. tostring(fighters) .. ' fighter_idle=' .. tostring(fightersIdle)
                    .. ' fighter_ArmyPool=' .. tostring(fightersPool) .. ' fighter_ArmyPool_tutta=' .. tostring(fightersPoolAll)
                    .. ' bomber+gunship_totali=' .. tostring(bombers) .. ' bomber+gunship_idle=' .. tostring(bombersIdle)
                    .. ' bomber+gunship_ArmyPool=' .. tostring(bombersPool) .. ' bomber+gunship_ArmyPool_tutta=' .. tostring(bombersPoolAll))
            end
        end
        -- Sess.100 parte 9: stessa fotografia per la TERRA (sintomo "unita' ferme in base che non partono").
        if self.Brain and builder.BuilderName and OWPlusLandAttackBatchingBuilderNames[builder.BuilderName] then
            local now = GetGameTimeSeconds()
            local aiBrain = self.Brain
            if now - (aiBrain.OWPlusLandPoolDiagLast or -100) >= 15 then
                aiBrain.OWPlusLandPoolDiagLast = now
                local land, landIdle, landPool, landPoolAll = self:OWPlusPoolCounts(aiBrain, OWPlusLandAttackCategory)
                local hold = 0
                if aiBrain.OWPlusOutpostAttackPool then
                    for _, holdPlat in aiBrain.OWPlusOutpostAttackPool do
                        if holdPlat and holdPlat.GetPlatoonUnits then
                            hold = hold + table.getn(holdPlat:GetPlatoonUnits())
                        end
                    end
                end
                LOG('[OWPlus-DIAG-LandAttack-Pool] [' .. tostring(aiBrain.Nickname) .. '] terra_totali=' .. tostring(land) .. ' terra_idle=' .. tostring(landIdle)
                    .. ' terra_ArmyPool=' .. tostring(landPool) .. ' terra_ArmyPool_tutta=' .. tostring(landPoolAll)
                    .. ' in_attesa_avamposti=' .. tostring(hold))
            end
        end
        -- Sess.100 parte 9: RIMOSSA la vecchia diagnostica sess.73 dei builder 'OWPlus Outpost' (PFMLoopBody_...).
        -- Chiamava builder:GetBuilderStatus() solo per loggarlo, ma nei builder di upgrade l'ultima condizione
        -- (OWPlusClaimFactoryUpgrade / claim upgrade difesa) ha un EFFETTO COLLATERALE (rivendica la fabbrica):
        -- la diagnostica consumava il claim PRIMA che il motore lo usasse, quindi il ManagerLoopBody nativo
        -- trovava la fabbrica gia' rivendicata e non formava l'upgrade (589 claim, 66 partiti, 519 "MAI partito").
        if not OWPlusOutpostDiagRemovedLogged then
            OWPlusOutpostDiagRemovedLogged = true
            LOG('[OWPlus-FACTORY] PlatoonFormManager: OK, diagnostica avamposti con GetBuilderStatus (effetti collaterali sui claim upgrade) rimossa')
        end

        if builder.BuilderName and OWPlusLandAttackBatchingBuilderNames[builder.BuilderName] then
            self.OWPlusDebugLastLog = self.OWPlusDebugLastLog or {}
            local now = GetGameTimeSeconds()
            local key = 'LandAttackBatch_' .. tostring(builder.BuilderName)
            if not self.OWPlusDebugLastLog[key] or now - self.OWPlusDebugLastLog[key] >= 5 then
                self.OWPlusDebugLastLog[key] = now
                local aiBrain = self.Brain
                local beforeCount = 0
                if aiBrain and aiBrain.GetPlatoonsList then
                    local platoons = aiBrain:GetPlatoonsList()
                    if platoons then beforeCount = table.getn(platoons) end
                end

                prevClass.ManagerLoopBody(self, builder, bType)

                local afterCount = beforeCount
                local newestUnits = nil
                if aiBrain and aiBrain.GetPlatoonsList then
                    local platoons = aiBrain:GetPlatoonsList()
                    if platoons then
                        afterCount = table.getn(platoons)
                        if afterCount > beforeCount then
                            local newest = platoons[afterCount]
                            if newest and newest.GetPlatoonUnits then
                                newestUnits = table.getn(newest:GetPlatoonUnits())
                            end
                        end
                    end
                end
                if newestUnits then
                    LOG('[OWPlus-DIAG-LandAttack] FORMATO: [' .. tostring(aiBrain.Nickname) .. '] builder="' .. tostring(builder.BuilderName)
                        .. '" template="' .. tostring(builder:GetPlatoonTemplate()) .. '" unita=' .. tostring(newestUnits))
                else
                    LOG('[OWPlus-DIAG-LandAttack] valutato, non formato: [' .. tostring(aiBrain.Nickname) .. '] builder="' .. tostring(builder.BuilderName)
                        .. '" GetBuilderStatus=' .. tostring(builder:GetBuilderStatus())
                        .. ' CheckInstanceCount=' .. tostring(builder:CheckInstanceCount()))
                end
                return
            end
        end

        if builder.BuilderName and OWPlusAirAttackBatchingBuilderNames[builder.BuilderName] then
            self.OWPlusDebugLastLog = self.OWPlusDebugLastLog or {}
            local now = GetGameTimeSeconds()
            local key = 'AirAttackBatch_' .. tostring(builder.BuilderName)
            if not self.OWPlusDebugLastLog[key] or now - self.OWPlusDebugLastLog[key] >= 5 then
                self.OWPlusDebugLastLog[key] = now
                local aiBrain = self.Brain
                local beforeCount = 0
                if aiBrain and aiBrain.GetPlatoonsList then
                    local platoons = aiBrain:GetPlatoonsList()
                    if platoons then beforeCount = table.getn(platoons) end
                end

                prevClass.ManagerLoopBody(self, builder, bType)

                local afterCount = beforeCount
                local newestUnits = nil
                if aiBrain and aiBrain.GetPlatoonsList then
                    local platoons = aiBrain:GetPlatoonsList()
                    if platoons then
                        afterCount = table.getn(platoons)
                        if afterCount > beforeCount then
                            local newest = platoons[afterCount]
                            if newest and newest.GetPlatoonUnits then
                                newestUnits = table.getn(newest:GetPlatoonUnits())
                            end
                        end
                    end
                end
                if newestUnits then
                    LOG('[OWPlus-DIAG-AirAttack] FORMATO: [' .. tostring(aiBrain.Nickname) .. '] builder="' .. tostring(builder.BuilderName)
                        .. '" template="' .. tostring(builder:GetPlatoonTemplate()) .. '" unita=' .. tostring(newestUnits))
                else
                    LOG('[OWPlus-DIAG-AirAttack] valutato, non formato: [' .. tostring(aiBrain.Nickname) .. '] builder="' .. tostring(builder.BuilderName)
                        .. '" GetBuilderStatus=' .. tostring(builder:GetBuilderStatus())
                        .. ' CheckInstanceCount=' .. tostring(builder:CheckInstanceCount()))
                end
                return
            end
        end

        local diagBrain = self.Brain
        if diagBrain and diagBrain.GetPlatoonsList and (builder.Priority or 0) >= 1
            and OWPlusIsAirFormTemplate(builder:GetPlatoonTemplate()) then
            if not OWPlusAirAnyDiagLogged then
                OWPlusAirAnyDiagLogged = true
                LOG('[OWPlus-DIAG-AirAny] OK: blocco diagnostico plotoni aerei raggiunto (primo builder aereo: "' .. tostring(builder.BuilderName) .. '")')
            end
            local before = table.getn(diagBrain:GetPlatoonsList())
            prevClass.ManagerLoopBody(self, builder, bType)
            local platoons = diagBrain:GetPlatoonsList()
            local after = table.getn(platoons)
            if after > before then
                local newest = platoons[after]
                local size = (newest and newest.GetPlatoonUnits) and table.getn(newest:GetPlatoonUnits()) or -1
                LOG('[OWPlus-DIAG-AirAny] FORMATO: [' .. tostring(diagBrain.Nickname) .. '] builder="' .. tostring(builder.BuilderName)
                    .. '" template="' .. tostring(builder:GetPlatoonTemplate()) .. '" unita=' .. tostring(size)
                    .. ' loc=' .. tostring(self.LocationType) .. ' t=' .. string.format('%.0f', GetGameTimeSeconds()))
            end
            return
        end

        prevClass.ManagerLoopBody(self, builder, bType)
    end,
}
