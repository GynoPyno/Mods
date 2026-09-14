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
}

local prevClass = PlatoonFormManager

PlatoonFormManager = Class(prevClass) {
    ManagerLoopBody = function(self, builder, bType)
        if self.LocationType and self.Brain and self.Brain.OWPlusOutpostLocationTypes
            and self.Brain.OWPlusOutpostLocationTypes[self.LocationType]
            and builder.BuilderName and string.find(builder.BuilderName, 'OWPlus Outpost') then
            self.OWPlusDebugLastLog = self.OWPlusDebugLastLog or {}
            local now = GetGameTimeSeconds()
            local key = 'PFMLoopBody_' .. tostring(builder.BuilderName)
            if not self.OWPlusDebugLastLog[key] or now - self.OWPlusDebugLastLog[key] >= 5 then
                self.OWPlusDebugLastLog[key] = now
                local status = builder:GetBuilderStatus()
                local instOk = builder:CheckInstanceCount()
                LOG('[OWPlus-HOOK] PlatoonFormManager(' .. tostring(self.LocationType) .. '): builder "' .. tostring(builder.BuilderName)
                    .. '" GetBuilderStatus=' .. tostring(status) .. ' CheckInstanceCount=' .. tostring(instOk)
                    .. ' (se entrambi true e nessun upgrade avviene, il sospetto ricade su CanFormPlatoon/FormRadius, non loggato qui)')
            end
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
                    LOG('[OWPlus-DIAG-LandAttack] FORMATO: builder="' .. tostring(builder.BuilderName)
                        .. '" template="' .. tostring(builder:GetPlatoonTemplate()) .. '" unita=' .. tostring(newestUnits))
                else
                    LOG('[OWPlus-DIAG-LandAttack] valutato, non formato: builder="' .. tostring(builder.BuilderName)
                        .. '" GetBuilderStatus=' .. tostring(builder:GetBuilderStatus())
                        .. ' CheckInstanceCount=' .. tostring(builder:CheckInstanceCount()))
                end
                return
            end
        end

        prevClass.ManagerLoopBody(self, builder, bType)
    end,
}
