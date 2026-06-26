
local OldOnCreateArmyBrainOWPlus = OnCreateArmyBrain
function OnCreateArmyBrain(index, brain, name, nickname)
    OldOnCreateArmyBrainOWPlus(index, brain, name, nickname)
    if brain.BrainType == 'AI' and nickname ~= 'civilian' then
        local owPlusCap = tonumber(ScenarioInfo.Options.OWPlusUnitCap)
        if owPlusCap and owPlusCap > 0 then
            local personality = ScenarioInfo.ArmySetup[brain.Name] and ScenarioInfo.ArmySetup[brain.Name].AIPersonality
            if personality == 'overwhelmplus' or personality == 'overwhelmpluscheat' then
                SetArmyUnitCap(index, owPlusCap)
            end
        end
    end
end
