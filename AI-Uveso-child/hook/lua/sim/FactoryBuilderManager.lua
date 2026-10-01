-- FactoryBuilderManager.lua (hook)
-- Instrumentazione diagnostica temporanea (sess.73): capire perche' i builder
-- 'OWPlus Outpost Engineer Builders'/'OWPlus Outpost Factory Upgrade' non
-- vengono mai selezionati per i nostri avamposti, nonostante le loro
-- BuilderConditions risultino vere quando controllate dal vivo (vedi
-- OWPlusLogConditions.lua). Aggancia AssignBuildOrder (vanilla, /lua/sim/
-- FactoryBuilderManager.lua) — il punto esatto in cui il motore decide quale
-- builder far costruire a una fabbrica, o rinuncia e ripianifica un retry a
-- 2s (DelayBuildOrder). Pattern di subclassing (non copia integrale) identico
-- a quello gia' usato da BattlePack per hook/lua/sim/weapon.lua — nessuna
-- logica vanilla duplicata, solo un log prima di richiamare l'originale.
-- Da rimuovere/silenziare una volta diagnosticato.

local OWPlusOutpostOwnership = import('/mods/AI-Uveso-child/lua/AI/OWPlusOutpostOwnership.lua')
local OWPlusFactoryTargets = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')

local prevClass = FactoryBuilderManager

FactoryBuilderManager = Class(prevClass) {
    -- Fase G (sess.93): estende l'ownership esplicita (OWPlusOutpostOwnership.lua,
    -- Fase F/sess.88, finora solo strutture) agli ingegneri prodotti dalla
    -- fabbrica dedicata di un avamposto — il punto di produzione dominante nel
    -- tempo (l'ingegnere fondatore, evento singolo per avamposto, e' gestito a
    -- parte in platoon.lua/OWPlusDispersedBuildAI). Nativo (FactoryBuilderManager.lua
    -- vanilla): quando una fabbrica finisce di costruire un ingegnere, lo registra
    -- solo all'EngineerManager della location, mai al nostro modulo Ownership.
    -- Esclusioni STATIONASSISTPOD/SUBCOMMANDER coerenti con 'OWPlus Outpost
    -- Engineer Builders.lua' (stesso tipo di conteggio). Nessuna logica nativa
    -- duplicata, stesso pattern degli altri override sotto: guardia, poi sempre
    -- prevClass.FactoryFinishBuilding(...) come ultima riga.
    FactoryFinishBuilding = function(self, factory, finishedUnit)
        if self.LocationType and self.Brain and self.Brain.OWPlusOutpostLocationTypes
            and self.Brain.OWPlusOutpostLocationTypes[self.LocationType]
            and EntityCategoryContains(categories.MOBILE * categories.ENGINEER
                - categories.STATIONASSISTPOD - categories.SUBCOMMANDER, finishedUnit) then
            OWPlusOutpostOwnership.OWPlusClaimForOutpost(self.Brain, self.LocationType, finishedUnit,
                OWPlusOutpostOwnership.OWPlusOwnershipKindEngineer)
            LOG('[OWPlus-HOOK] FactoryFinishBuilding(' .. tostring(self.LocationType) .. '): OK, nuovo ingegnere ('
                .. tostring(finishedUnit.UnitId) .. ') registrato in OWPlusOutpostOwnedUnits (kind=engineer)')
        end
        prevClass.FactoryFinishBuilding(self, factory, finishedUnit)
    end,

    AssignBuildOrder = function(self, factory, bType)
        if self.LocationType and self.Brain and self.Brain.OWPlusOutpostLocationTypes
            and self.Brain.OWPlusOutpostLocationTypes[self.LocationType] then
            self.OWPlusDebugLastLog = self.OWPlusDebugLastLog or {}
            local now = GetGameTimeSeconds()
            local key = 'AssignBuildOrder_' .. tostring(bType)
            if not self.OWPlusDebugLastLog[key] or now - self.OWPlusDebugLastLog[key] >= 5 then
                self.OWPlusDebugLastLog[key] = now
                local builder = self:GetHighestBuilder(bType, {factory})
                LOG('[OWPlus-HOOK] AssignBuildOrder(' .. tostring(self.LocationType) .. ', bType=' .. tostring(bType)
                    .. ') -> ' .. tostring(builder and builder.BuilderName or 'NESSUN builder trovato, retry tra 2s')
                    .. ' -- NumBuilders totali registrati su questo manager: ' .. tostring(self.NumBuilders))
            end
        end

        -- Diagnostica sess.85: la diagnostica sopra si attiva solo se il MANAGER
        -- CHIAMANTE (self.LocationType) e' gia' riconosciuto come avamposto — nel
        -- test di sess.84 ha confermato che i 6 manager dedicati (OUT#) scelgono
        -- sempre e solo builder Engineer, mai unita' da combattimento, quindi la
        -- causa reale resta ignota. Questo secondo controllo e' complementare e
        -- INDIPENDENTE da self.LocationType: guarda la POSIZIONE FISICA della
        -- fabbrica contro gli slot avamposto noti (Brain.OWPlusSubBases, prefisso
        -- 'OUT') — se una fabbrica che si trova fisicamente su un avamposto viene
        -- decisa da un manager DIVERSO (es. 'MAIN', mai passato dal nostro
        -- riconoscimento), lo vediamo comunque, indipendentemente da chi la sta
        -- comandando in quel momento.
        --
        -- Fix sess.89 (falso positivo confermato su log reale): OWPlusSubBases
        -- contiene anche posizioni CANDIDATE mai costruite (registrate dal
        -- generatore avamposti, ma nessun ingegnere le ha mai rivendicate). Per
        -- caso geografico, alcune di queste candidate cadono entro 25u dalle
        -- sotto-basi diagonali proprie di MAIN (BASE_NE/SE/SW/NW,
        -- overwhelmplusai.lua — stesse 4 direzioni diagonali e distanze simili
        -- usate da OWPlusOutpostGenerator.lua) — il log segnalava le fabbriche
        -- LEGITTIME di MAIN come se fossero avamposti nostri "rubati". Aggiunto
        -- il controllo su OWPlusOutpostClaimed[slotKey] (settato in platoon.lua
        -- al momento della rivendicazione reale, riga ~169): il log scatta solo
        -- per slot davvero costruiti, non per candidati mai rivendicati.
        if factory and not factory.Dead and self.Brain and self.Brain.OWPlusSubBases then
            local fPos = factory:GetPosition()
            for slotKey, slotPos in self.Brain.OWPlusSubBases do
                if string.sub(slotKey, 1, 3) == 'OUT' and slotPos
                    and self.Brain.OWPlusOutpostClaimed and self.Brain.OWPlusOutpostClaimed[slotKey]
                    and VDist2(fPos[1], fPos[3], slotPos[1], slotPos[3]) < 25 then
                    factory.OWPlusWideDiagLastLog = factory.OWPlusWideDiagLastLog or {}
                    local now2 = GetGameTimeSeconds()
                    local key2 = 'wide_' .. tostring(bType)
                    if not factory.OWPlusWideDiagLastLog[key2] or now2 - factory.OWPlusWideDiagLastLog[key2] >= 5 then
                        factory.OWPlusWideDiagLastLog[key2] = now2
                        local builder2 = self:GetHighestBuilder(bType, {factory})
                        LOG('[OWPlus-DIAG-WIDE] Fabbrica fisicamente su ' .. slotKey .. ' (bp=' .. tostring(factory.UnitId)
                            .. ') e\' comandata dal manager "' .. tostring(self.LocationType) .. '" -> builder scelto: '
                            .. tostring(builder2 and builder2.BuilderName or 'nessuno, retry'))
                    end
                    break
                end
            end
        end

        prevClass.AssignBuildOrder(self, factory, bType)
    end,

    -- Diagnostica sess.78: nel test dell'8 minuti l'hook AssignBuildOrder sopra
    -- e' scattato UNA sola volta in tutta la partita (subito prima del riaggancio
    -- "fabbrica orfana"), mai piu' dopo, nonostante le BuilderConditions per
    -- Engineer T3 risultino verdi in continuazione nei log successivi — quei log
    -- vengono pero' da ManagerThread/CalculatePriority (bookkeeping periodico
    -- della classe base, vedi BuilderManager.lua), un ciclo COMPLETAMENTE
    -- separato da AssignBuildOrder/DelayBuildOrder. Se AssignBuildOrder fallisce
    -- una volta, vanilla pianifica SEMPRE un retry a 2s via
    -- ForkThread(DelayBuildOrder, factory, bType, 2) — a meno che
    -- factory.DelayThread sia gia' true in quel momento (guard mutex in
    -- DelayBuildOrder), nel qual caso il retry viene scartato in silenzio.
    -- Sospetto concreto: collisione tra il fork automatico a 0.1s di
    -- AddFactory/SetupFactoryCallbacks e la nostra chiamata esplicita di
    -- sicurezza (sess.77 septies) subito dopo, nello stesso istante. Questo
    -- hook osserva direttamente il guard ad ogni chiamata.
    DelayBuildOrder = function(self, factory, bType, time)
        if self.LocationType and self.Brain and self.Brain.OWPlusOutpostLocationTypes
            and self.Brain.OWPlusOutpostLocationTypes[self.LocationType] then
            LOG('[OWPlus-HOOK] DelayBuildOrder(' .. tostring(self.LocationType) .. ', factory=' .. tostring(factory.UnitId)
                .. ', time=' .. tostring(time) .. '): DelayThread=' .. tostring(factory.DelayThread)
                .. (factory.DelayThread and ' -- SCARTATO (guard attivo, nessun retry pianificato)' or ' -- OK, pianifico retry'))
        end
        prevClass.DelayBuildOrder(self, factory, bType, time)
    end,

    -- Fix sess.77 (octies): confermato via l'hook sopra che AssignBuildOrder ORA
    -- scatta (fix precedente) ma dice "NESSUN builder trovato" nonostante builder
    -- registrati e le nostre BuilderConditions verdi — la causa deve essere
    -- BuilderParamCheck (vanilla, FactoryBuilderManager.lua), un controllo
    -- SEPARATO dalle nostre condizioni: risolve il template reale (per
    -- fazione/tier) e chiama self.Brain:CanBuildPlatoon(template, params) — un
    -- controllo economico/di validita' che non passa dalle nostre
    -- BuilderConditions. Richiama l'originale per il risultato vero (nessuna
    -- logica duplicata), poi ri-deriva SOLO il template (chiamata read-only,
    -- innocua) per capire se il problema e' "template non risolto/fazione senza
    -- questa unita'" o qualcos'altro (economia, CanBuildPlatoon).
    BuilderParamCheck = function(self, builder, params)
        -- Sess.100 parte 9 (piano fabbriche): con piu' fabbriche per avamposto,
        -- OWPlusFactoryNotUpgrading (OWPlusLogConditions.lua) e' falsa solo se TUTTE sono in
        -- upgrade/claimate, quindi non protegge piu' la singola fabbrica in upgrade: un nuovo
        -- ordine di build cancellerebbe l'upgrade (vedi la nota su quella funzione). Protezione
        -- per FABBRICA: una fabbrica in upgrade o claimata non riceve MAI un builder. Solo per i
        -- manager avamposto e solo col sistema multi-fabbrica attivo (rollback: flag).
        local factory = params and params[1]
        if factory and not factory.Dead and self.LocationType and self.Brain
            and self.Brain.OWPlusOutpostLocationTypes and self.Brain.OWPlusOutpostLocationTypes[self.LocationType]
            and not OWPlusFactoryTargets.OWPlusMultiFactoryDisabled
            and (factory.OWPlusUpgradeClaimed or (factory.IsUnitState and factory:IsUnitState('Upgrading'))) then
            self.OWPlusUpgradeGateLog = self.OWPlusUpgradeGateLog or {}
            local now = GetGameTimeSeconds()
            if not self.OWPlusUpgradeGateLog[factory] or now - self.OWPlusUpgradeGateLog[factory] >= 30 then
                self.OWPlusUpgradeGateLog[factory] = now
                LOG('[OWPlus-FACTORY] BuilderParamCheck(' .. tostring(self.LocationType) .. '): fabbrica (' .. tostring(factory.UnitId)
                    .. ') in upgrade/claimata -- builder "' .. tostring(builder.BuilderName) .. '" rifiutato per questa fabbrica')
            end
            return false
        end
        local result = prevClass.BuilderParamCheck(self, builder, params)
        -- Log diagnostico disattivato (sess.91, richiesta esplicita utente): con
        -- 172 Builder Production, questo LOG (su ogni FALSE, la stragrande
        -- maggioranza delle valutazioni) gonfiava il dev.log fino a 654.200
        -- occorrenze in un test comparabile (vedi AI_Mod_Spec.md, B24). Diagnosi
        -- di sess.77 gia' conclusa, non piu' necessaria in condizioni normali —
        -- ripristinare togliendo il commento se serve una nuova diagnosi
        -- template/fazione su un builder OWPlus Outpost specifico.
        --[[
        if not result and self.LocationType and self.Brain and self.Brain.OWPlusOutpostLocationTypes
            and self.Brain.OWPlusOutpostLocationTypes[self.LocationType]
            and builder.BuilderName and string.find(builder.BuilderName, 'OWPlus Outpost') then
            local templateInfo = 'nil'
            local ok, template = pcall(function() return self:GetFactoryTemplate(builder:GetPlatoonTemplate(), params[1]) end)
            if ok and template then
                templateInfo = 'risolto, len=' .. tostring(table.getn(template))
            elseif not ok then
                templateInfo = 'ERRORE nel risolverlo: ' .. tostring(template)
            end
            LOG('[OWPlus-HOOK] BuilderParamCheck FALSE per "' .. tostring(builder.BuilderName) .. '" a ' .. tostring(self.LocationType)
                .. ' -- GetFactoryTemplate: ' .. templateInfo)
        end
        ]]
        return result
    end,
}
