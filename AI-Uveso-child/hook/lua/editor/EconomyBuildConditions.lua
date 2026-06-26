-- uveso-ai.lua sostituisce EconomyMonitor vanilla con una versione no-op (si auto-uccide dopo 10 tick),
-- quindi EconomyOverTimeCurrent.MassIncome rimane nil forever per tutti i brain Uveso.
-- GreaterThanMassIncomeToFactory (vanilla EBC l.386) accede a quel campo senza nil-guard → crash.
local _GreaterThanMassIncomeToFactory = GreaterThanMassIncomeToFactory
function GreaterThanMassIncomeToFactory(aiBrain, t1Drain, t2Drain, t3Drain)
    if not aiBrain.EconomyOverTimeCurrent or aiBrain.EconomyOverTimeCurrent.MassIncome == nil then
        return false
    end
    return _GreaterThanMassIncomeToFactory(aiBrain, t1Drain, t2Drain, t3Drain)
end
