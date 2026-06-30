-- Brain class per OverwhelmPlus.
-- Estende uveso-ai.AIBrain e imposta self.Uveso = true per le nostre personality custom,
-- che non contengono "uveso" nel nome e non passerebbero il check in OnCreateAI di uveso-ai.lua.
-- Fa anche il monkey-patch di GetScoutTable via pcall per silenziare il crash nil/sort.

local UvesoAIBrainClass = import('/mods/AI-Uveso/lua/ai/uveso-ai.lua').AIBrain

local function PatchGetScoutTable()
    local mod = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua')
    -- rawget bypassa __index del modulo (strict mode FAF) per campi inesistenti
    if not mod or rawget(mod, '_scoutTablePatched') then return end
    mod._scoutTablePatched = true
    local origGetScoutTable = mod.GetScoutTable
    -- Wrap con pcall: l'originale ha HeatMap nel closure, pcall cattura il crash nil/sort
    -- e restituisce liste vuote anziche propagare l'errore.
    mod.GetScoutTable = function(armyIndex)
        local ok, highList, lowList = pcall(origGetScoutTable, armyIndex)
        if ok then
            return highList, lowList
        end
        return {}, {}
    end
end

-- Debug: ogni minuto stampa quante unità sono nel pool e quante sono in platoon.
-- Cerca '[OWPlus-DBG]' nel dev.log per filtrare l'output.
--   POOL   = unità nel pool, in attesa di essere prese da un former
--   PLATOONS = unità già assegnate a un plotone (attacco o altro)
-- Se vedi unità ferme in base E POOL > 0 → i former non le prendono (condizione fallita o InstanceCount esaurito)
-- Se vedi unità ferme in base E POOL = 0 → le unità sono in un plotone che non si muove (piano bloccato)
local function OWPlusPoolDebugThread(aiBrain)
    -- Attendi inizializzazione BuilderManagers (~60s di gioco)
    WaitSeconds(60)

    local armyIdx = aiBrain:GetArmyIndex()

    while true do

        -- ========== POOL ==========
        local pfm = aiBrain.BuilderManagers
                    and aiBrain.BuilderManagers['MAIN']
                    and aiBrain.BuilderManagers['MAIN'].PlatoonFormManager

        if pfm then
            local landPool, airPool, expPool = 0, 0, 0
            local ok, v

            ok, v = pcall(function()
                return pfm:GetNumCategoryUnits('Pool',
                    categories.MOBILE * categories.LAND
                    - categories.ENGINEER - categories.SCOUT - categories.EXPERIMENTAL)
            end)
            if ok then landPool = v or 0 end

            ok, v = pcall(function()
                return pfm:GetNumCategoryUnits('Pool',
                    categories.MOBILE * categories.AIR
                    - categories.SCOUT - categories.EXPERIMENTAL)
            end)
            if ok then airPool = v or 0 end

            ok, v = pcall(function()
                return pfm:GetNumCategoryUnits('Pool',
                    categories.MOBILE * categories.EXPERIMENTAL)
            end)
            if ok then expPool = v or 0 end

            LOG(string.format('[OWPlus-DBG] Army%d POOL: Land=%d Air=%d Exp=%d',
                armyIdx, landPool, airPool, expPool))
        end

        -- ========== PLATOONS ==========
        local ok2, platoons = pcall(function() return aiBrain:GetPlatoonsList() end)
        if ok2 and platoons then
            local totPlat, totUnits = 0, 0
            local owPlat, owUnits   = 0, 0

            for _, plat in platoons do
                totPlat = totPlat + 1
                local ok3, units = pcall(function() return plat:GetPlatoonUnits() end)
                local n = (ok3 and units and table.getn(units)) or 0
                totUnits = totUnits + n

                -- Identifica platoon creati dai nostri former OWPlus tramite BuilderName
                local bn = tostring(rawget(plat, 'BuilderName') or '')
                if string.find(bn, 'OWPlus') then
                    owPlat  = owPlat  + 1
                    owUnits = owUnits + n
                end
            end

            LOG(string.format(
                '[OWPlus-DBG] Army%d PLATOONS: tot=%d/%du  OWPlus=%d/%du  Other=%d/%du',
                armyIdx,
                totPlat,  totUnits,
                owPlat,   owUnits,
                totPlat - owPlat, totUnits - owUnits))
        end

        WaitSeconds(60)
    end
end

AIBrain = Class(UvesoAIBrainClass) {

    OnCreateAI = function(self, planName)
        UvesoAIBrainClass.OnCreateAI(self, planName)
        local per = ScenarioInfo.ArmySetup[self.Name].AIPersonality
        if per == 'overwhelmplus' or per == 'overwhelmpluscheat' then
            self.Uveso = true
        end
        -- FAF platoon-adaptive-reclaim.lua usa questi campi senza nil-guard.
        -- I brain FAF standard li inizializzano in OnCreateAI; uveso-ai.lua non lo fa.
        self.ReclaimFailCounter = 0
        self.ReclaimFailTimeStamp = 0
        PatchGetScoutTable()
        -- Avvia il thread di debug pool/platoon (vedi sopra per interpretazione)
        self:ForkThread(OWPlusPoolDebugThread)
        -- Memorizza le 4 sub-location diagonali in OWPlusSubBases (tabella custom sul brain).
        -- NON usare AddBuilderManagers: DeadBaseMonitor rimuove dopo 5s ogni manager non-MAIN
        -- che non ha ingegneri né fabbriche — le nostre sub-location vuote verrebbero eliminate.
        -- OWPlusDispersedBuildAI legge da aiBrain.OWPlusSubBases[locType] direttamente.
        local startX, startZ = self:GetArmyStartPos()
        local d = 46
        self.OWPlusSubBases = {
            BASE_NE = {startX + d, 0, startZ - d},
            BASE_SE = {startX + d, 0, startZ + d},
            BASE_SW = {startX - d, 0, startZ + d},
            BASE_NW = {startX - d, 0, startZ - d},
        }
        for name, pos in self.OWPlusSubBases do
            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            LOG('[OWPlus] OWPlusSubBases: ' .. name .. string.format(' = (%.0f, %.0f, %.0f)', pos[1], pos[2], pos[3]))
        end
    end,

}
