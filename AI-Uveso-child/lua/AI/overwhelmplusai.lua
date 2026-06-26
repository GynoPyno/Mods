-- Brain class per OverwhelmPlus.
-- Estende uveso-ai.AIBrain e imposta self.Uveso = true per le nostre personality custom,
-- che non contengono "uveso" nel nome e non passerebbero il check in OnCreateAI di uveso-ai.lua.
-- Fa anche il monkey-patch di GetScoutTable via pcall per silenziare il crash nil/sort.

local UvesoAIBrainClass = import('/mods/AI-Uveso/lua/ai/uveso-ai.lua').AIBrain

local function PatchGetScoutTable()
    local mod = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua')
    if not mod or mod._scoutTablePatched then return end
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
    end,

}
