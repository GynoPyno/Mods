-- AI-Uveso-child: hook platoon.lua
-- OWPlusDispersedBuildAI: PlatoonAI custom per costruire nelle sub-location BASE_NE/SE/SW/NW.
--
-- PROBLEMA: EngineerBuildAI (branch else) passa reference=true (booleano) ad AIExecuteBuildStructure.
-- Uveso's AIExecuteBuildStructure usa closeToBuilder → posizione dell'ingegnere (= MAIN).
-- Construction.LocationType nel builder non viene mai letto in questo path.
--
-- SOLUZIONE: questo PlatoonAI legge cons.LocationType, trova le coordinate in
-- aiBrain.OWPlusSubBases[locType] (tabella custom, immune a DeadBaseMonitor),
-- e passa targetPos come 'reference' (tabella) ad AIExecuteBuildStructure.
-- Uveso controlla per primo "reference and type(reference) == 'table'" → usa targetPos come centro.
--
-- NOTA: NON si usa aiBrain.BuilderManagers per le sub-location perché DeadBaseMonitor
-- rimuove ogni manager non-MAIN senza ingegneri/fabbriche dopo 5 secondi dalla creazione.

local AIBuildStructures = import('/lua/AI/aibuildstructures.lua')

CopyOfOldPlatoonClassOWPlusChild = Platoon
Platoon = Class(CopyOfOldPlatoonClassOWPlusChild) {

    OWPlusDispersedBuildAI = function(self)
        local aiBrain = self:GetBrain()
        local cons = self.PlatoonData and self.PlatoonData.Construction
        if not cons or not cons.BuildStructures then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end

        -- Trova le coordinate della sub-location target (es. 'BASE_NE')
        local targetLocType = cons.LocationType
        local targetPos
        if targetLocType then
            -- Legge da OWPlusSubBases (tabella custom sul brain, immune a DeadBaseMonitor).
            -- BuilderManagers NON viene usato: i manager vuoti vengono rimossi dopo 5s.
            targetPos = aiBrain.OWPlusSubBases and aiBrain.OWPlusSubBases[targetLocType]
            LOG('[OWPlus-DBG] OWPlusDispersedBuildAI: targetLocType=' .. targetLocType
                .. ' subBases=' .. tostring(aiBrain.OWPlusSubBases ~= nil)
                .. ' targetPos=' .. tostring(targetPos ~= nil))
        end

        if not targetPos then
            LOG('[OWPlus-WARN] OWPlusDispersedBuildAI: sub-base ' .. tostring(targetLocType) .. ' non trovata in OWPlusSubBases')
            self:EngineerBuildAI()
            return
        end

        -- Trova l'ingegnere
        local eng
        for _, v in self:GetPlatoonUnits() do
            if not v.Dead and EntityCategoryContains(categories.ENGINEER, v) then
                IssueClearCommands({v})
                if not eng then
                    eng = v
                else
                    IssueGuard({v}, eng)
                end
            end
        end

        if not eng or eng.Dead then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end

        local factionLookup = { UEF = 1, AEON = 2, CYBRAN = 3, SERAPHIM = 4, NOMADS = 5 }
        local factionIndex = cons.FactionIndex or factionLookup[eng.factionCategory] or 1
        local buildingTmplFile = import(cons.BuildingTemplateFile or '/lua/BuildingTemplates.lua')
        local baseTmplFile = import(cons.BaseTemplateFile or '/lua/BaseTemplates.lua')
        local buildingTmpl = buildingTmplFile[(cons.BuildingTemplate or 'BuildingTemplates')][factionIndex]
        local baseTmpl = baseTmplFile[(cons.BaseTemplate or 'BaseTemplates')][factionIndex]
        local baseTmplAtTarget = AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, targetPos)

        self.SetupEngineerCallbacks(eng)

        -- Costruisce vicino a targetPos.
        -- closeToBuilder=nil, reference=targetPos (tabella) → AIExecuteBuildStructure di Uveso
        -- entra nel branch "reference and type(reference)=='table'" → relativeTo = targetPos.
        for _, buildType in cons.BuildStructures do
            if aiBrain:PlatoonExists(self) and not eng.Dead then
                AIBuildStructures.AIExecuteBuildStructure(
                    aiBrain, eng, buildType,
                    nil,             -- closeToBuilder nil → non usa posizione eng
                    false,           -- relative false
                    buildingTmpl,
                    baseTmplAtTarget,
                    targetPos,       -- reference tabella → Uveso usa come centro di ricerca
                    nil
                )
            end
        end

        if not eng.Dead and not eng:IsUnitState('Building') then
            self.ProcessBuildCommand(eng, false)
        end
    end,
}
