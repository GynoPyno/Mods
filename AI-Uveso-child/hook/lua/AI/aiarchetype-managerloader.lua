-- Minimal hook per AI-Uveso-child
-- Redefine SOLO EcoManagerThread per aggiungere 'overwhelmpluscheat' alla condizione personality.
-- NON ridefinire ExecutePlan né OldExecutePlanFunctionUveso: farlo causerebbe ricorsione
-- infinita su qualsiasi brain non-Uveso (player umano, civilian army) → sim freeze.
local Buff = import('/lua/sim/Buff.lua')
local UvesoOffsetaiarchetypeLUA = 0
local HighestThreat = {}
local CanGraphAreaTo = import("/mods/AI-Uveso/lua/AI/AIMarkerGenerator.lua").CanGraphAreaTo

-- Uveso AI

function EcoManagerThread(aiBrain)
    -- Start Ecomanager at game minute 4
    while GetGameTimeSeconds() < 60*4 + aiBrain:GetArmyIndex() do
        coroutine.yield(10)
    end
    local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
    aiBrain.CheatMult = tonumber(ScenarioInfo.Options.CheatMult)
    aiBrain.BuildMult = tonumber(ScenarioInfo.Options.BuildMult)
    if aiBrain.CheatMult ~= aiBrain.BuildMult then
        aiBrain.CheatMult = math.max(aiBrain.CheatMult,aiBrain.BuildMult)
        aiBrain.BuildMult = math.max(aiBrain.CheatMult,aiBrain.BuildMult)
    end
    if aiBrain.CheatEnabled then
        AILog('* AI-Uveso: Function EcoManagerThread() started! - Cheat(eco)Factor:( '..repr(aiBrain.CheatMult)..' ) - BuildFactor:( '..repr(aiBrain.BuildMult)..' ) - ['..aiBrain.Nickname..']', true, UvesoOffsetaiarchetypeLUA)
    else
        AILog('* AI-Uveso: Function EcoManagerThread() started! - No Cheat(eco) or BuildFactor', true, UvesoOffsetaiarchetypeLUA)
    end
    local lastCall = 0
    local bussy
    -- Set all variables for the ecomanager
    local massNeed = math.floor(aiBrain:GetEconomyRequested('MASS') * 10)
    local massIncome = math.floor(aiBrain:GetEconomyIncome( 'MASS' ) * 10)
    local massTrend = massIncome - massNeed
    local energyNeed = math.floor(aiBrain:GetEconomyRequested('ENERGY') * 10)
    local energyIncome = math.floor(aiBrain:GetEconomyIncome( 'ENERGY' ) * 10)
    local energyTrend = energyIncome - energyNeed
    local safeguard
    -- splitted from table to single variables. (faster)
    local maxEnergyConsumptionUnitindex
    local maxEnergyConsumption
    local minEnergyConsumptionUnitindex
    local minEnergyConsumption
    local maxMassConsumptionUnitindex
    local maxMassConsumption
    local minMassConsumptionUnitindex
    local minMassConsumption
    local EcoUnits = {}
    local BasePanicZone, BaseMilitaryZone, BaseEnemyZone
    local baseposition
    local numUnitsPanicZone
    local AllUnits
    local time, energy, mass
    local function SetArmyPoolBuff(aiBrain, CheatMult, BuildMult)
        -- we are looping over all units with this, so we make it local
        local Buff = Buff
        -- Modify Buildrate buff
        local buffDef = Buffs['CheatBuildRate']
        local buffAffects = buffDef.Affects
        buffAffects.BuildRate.Mult = BuildMult
        -- Modify CheatIncome buff
        buffDef = Buffs['CheatIncome']
        buffAffects = buffDef.Affects
        buffAffects.EnergyProduction.Mult = CheatMult
        buffAffects.MassProduction.Mult = CheatMult
        allUnits = aiBrain:GetListOfUnits(categories.ALLUNITS, false, false)
        for _, unit in allUnits do
            -- Remove old build rate and income buffs
            Buff.RemoveBuff(unit, 'CheatIncome', true) -- true = removeAllCounts
            Buff.RemoveBuff(unit, 'CheatBuildRate', true) -- true = removeAllCounts
            -- Apply new build rate and income buffs
            Buff.ApplyBuff(unit, 'CheatIncome')
            Buff.ApplyBuff(unit, 'CheatBuildRate')
        end
    end
    while aiBrain.Status ~= "Defeat" do
        while not aiBrain:IsOpponentAIRunning() do
            coroutine.yield(10)
        end
        --AILog('* AI-Uveso: Function EcoManagerThread() beat. ['..aiBrain.Nickname..']')
        coroutine.yield(1)
        -- Cheatbuffs
        if personality == 'uvesooverwhelm' or personality == 'overwhelmplus' or personality == 'overwhelmpluscheat' then
            -- Check every 60 seconds
            if (GetGameTimeSeconds() > ScenarioInfo.Options.AIOverwhelmDelay * 60) and lastCall+60 < GetGameTimeSeconds() then
                lastCall = GetGameTimeSeconds()
                aiBrain.CheatMult = aiBrain.CheatMult + ScenarioInfo.Options.AIOverwhelmIncrease  -- with the default of 0.025, +0.1 after 4 min. +1.0 after 40 min.
                aiBrain.BuildMult = aiBrain.BuildMult + ScenarioInfo.Options.AIOverwhelmIncrease
                if aiBrain.CheatMult > 8 then aiBrain.CheatMult = 8 end
                if aiBrain.BuildMult > 8 then aiBrain.BuildMult = 8 end
                AIDebug('Setting new values for ['..aiBrain.Nickname..'] aiBrain.CheatMult:'..aiBrain.CheatMult..' - aiBrain.BuildMult:'..aiBrain.BuildMult)
                SetArmyPoolBuff(aiBrain, aiBrain.CheatMult, aiBrain.BuildMult)
            end
        end
        -- Set all variables for the ecomanager
        massNeed = math.floor(aiBrain:GetEconomyRequested('MASS') * 10)
        massIncome = math.floor(aiBrain:GetEconomyIncome( 'MASS' ) * 10)
        massTrend = massIncome - massNeed
        energyNeed = math.floor(aiBrain:GetEconomyRequested('ENERGY') * 10)
        energyIncome = math.floor(aiBrain:GetEconomyIncome( 'ENERGY' ) * 10)
        energyTrend = energyIncome - energyNeed
        -- check if we have enemy units inside the base panic zone.
        BasePanicZone, BaseMilitaryZone, BaseEnemyZone = import('/mods/AI-Uveso/lua/AI/AITargetManager.lua').GetDangerZoneRadii()
        baseposition = aiBrain.BuilderManagers['MAIN'].FactoryManager.Location
        numUnitsPanicZone = aiBrain:GetNumUnitsAroundPoint(categories.MOBILE * categories.LAND - categories.SCOUT, baseposition, BasePanicZone, 'Enemy')
        -- ECO manager
        EcoUnits = {}
        bussy = false
        if aiBrain:GetEconomyStoredRatio('ENERGY') < 0.50 then
            AllUnits = aiBrain:GetListOfUnits( (categories.FACTORY - categories.TECH1) + (categories.ENGINEER - categories.POD) + categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE + categories.MASSFABRICATION + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD) + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO ) - categories.COMMAND , false, false) -- also gets unbuilded units (planed to build)
            if energyTrend < 0 then
                --AllUnits = aiBrain:GetListOfUnits(categories.ALLUNITS - categories.COMMAND - categories.SHIELD - categories.MASSEXTRACTION, false, false) -- also gets unbuilded units (planed to build)
                for index, unit in AllUnits do
                    if unit.pausedMass or unit.pausedEnergy then continue end
                    -- filter units that are not finished
                    if unit:GetFractionComplete() < 1 then continue end
                    -- if we build massextractors or energyproduction, don't pause it
                    if unit.UnitBeingBuilt and EntityCategoryContains( ( categories.MASSEXTRACTION + (categories.ENERGYPRODUCTION - categories.EXPERIMENTAL) + categories.ENERGYSTORAGE ) , unit.UnitBeingBuilt) then
                        continue
                    end
                    -- if we build tech1 factories, don't pause it
                    if unit.UnitBeingBuilt and EntityCategoryContains( categories.FACTORY * categories.TECH1 , unit.UnitBeingBuilt) then
                        continue
                    end
                    -- if we build tech 1 units from a factory, don't pause it
                    if unit.UnitBeingBuilt and EntityCategoryContains( categories.MOBILE * categories.TECH1 , unit.UnitBeingBuilt) then
                        continue
                    end
                    -- don't pause any ACU assisting
                    if unit.UnitBeingAssist and EntityCategoryContains( categories.COMMAND, unit.UnitBeingAssist) then
                        continue
                    end
                    -- don't pause strategic missile defense
                    if unit.UnitBeingAssist and EntityCategoryContains( categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * (categories.TECH3 + categories.EXPERIMENTAL), unit.UnitBeingAssist) then
                        continue
                    end
                    if personality == 'uvesorush' then
                        -- If we are rushing, never pause any factory building units
                        if unit.UnitBeingBuilt and EntityCategoryContains( categories.MOBILE, unit.UnitBeingBuilt ) then
                            continue
                        end
                        -- if we build or upgrade  factories, don't pause it
                        if unit.UnitBeingBuilt and EntityCategoryContains( categories.FACTORY, unit.UnitBeingBuilt) then
                            continue
                        end
                    end
                    if unit.pausedMass or unit.pausedEnergy then continue end
                    if EntityCategoryContains( (categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO, unit) then
                        -- siloBuildRate is only for debugging, we don't use it inside the code
                        --local siloBuildRate = unit:GetBuildRate() or 1
                        time, energy, mass = unit:GetBuildCosts(unit.SiloProjectile)
--                        AILog('* AI-Uveso: ECO Buildcost time '..time..' - mass '..mass..' - energy '..energy..' - siloBuildRate '..siloBuildRate)
                        energy = (energy / time)
                        mass = (mass / time)
--                        AILog('* AI-Uveso: ECO Buildcost time '..time..' - mass '..mass..' - energy '..energy..' - siloBuildRate '..siloBuildRate)
                        unit.ConsumptionPerSecondEnergy = energy
                    else
                        unit.ConsumptionPerSecondEnergy = unit:GetConsumptionPerSecondEnergy()
                    end
                    if unit.ConsumptionPerSecondEnergy > 0 then
                        table.insert(EcoUnits, unit)
                    end
                end
                -- Disable units until energytrend is positive
                safeguard = table.getn(EcoUnits)
                while energyTrend < 0 do
                    -- find unit with most energy consumption
                    maxEnergyConsumptionUnitindex = nil
                    maxEnergyConsumption = nil
                    if EcoUnits[1] then
                        for index, unit in EcoUnits do
                            if unit.pausedMass or unit.pausedEnergy then continue end
                            if not maxEnergyConsumption or maxEnergyConsumption < unit.ConsumptionPerSecondEnergy then
                                maxEnergyConsumption = unit.ConsumptionPerSecondEnergy
                                maxEnergyConsumptionUnitindex = index
                            end
                        end
                    else
                        break
                    end
                    if maxEnergyConsumptionUnitindex then
--                        AILog(' ')
--                        AILog('* AI-Uveso: ECO energyTrend < 0  ('..energyTrend..')')
                        bussy = true
                        energyTrend = energyTrend + maxEnergyConsumption
                        if EntityCategoryContains(categories.FACTORY + (categories.ENGINEER - categories.POD) + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD) + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO), EcoUnits[maxEnergyConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[maxEnergyConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[maxEnergyConsumptionUnitindex].Blueprint.Description)..') unit:SetPaused( true ) Saving ('..maxEnergyConsumption..') energy')
                            EcoUnits[maxEnergyConsumptionUnitindex]:SetPaused( true )
                            EcoUnits[maxEnergyConsumptionUnitindex].pausedEnergy = true
                            EcoUnits[maxEnergyConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.COUNTERINTELLIGENCE, EcoUnits[maxEnergyConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[maxEnergyConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[maxEnergyConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( IntelToggle, true ) Saving ('..maxEnergyConsumption..') energy')
                            EcoUnits[maxEnergyConsumptionUnitindex]:SetScriptBit('RULEUTC_IntelToggle', true)
                            EcoUnits[maxEnergyConsumptionUnitindex].pausedEnergy = true
                            EcoUnits[maxEnergyConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.MASSFABRICATION, EcoUnits[maxEnergyConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[maxEnergyConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[maxEnergyConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( ProductionToggle, true ) Saving ('..maxEnergyConsumption..') energy')
                            EcoUnits[maxEnergyConsumptionUnitindex]:SetScriptBit('RULEUTC_ProductionToggle', true)
                            EcoUnits[maxEnergyConsumptionUnitindex].pausedEnergy = true
                            EcoUnits[maxEnergyConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE, EcoUnits[maxEnergyConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[maxEnergyConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[maxEnergyConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( JammingToggle, true ) Saving ('..maxEnergyConsumption..') energy')
                            EcoUnits[maxEnergyConsumptionUnitindex]:SetScriptBit('RULEUTC_JammingToggle', true)
                            EcoUnits[maxEnergyConsumptionUnitindex].pausedEnergy = true
                            EcoUnits[maxEnergyConsumptionUnitindex].managed = true
                        else
                            AIWarn('* AI-Uveso: Unit with unknown Category('..LOC(EcoUnits[maxEnergyConsumptionUnitindex].Blueprint.Description)..') ['..EcoUnits[maxEnergyConsumptionUnitindex].UnitId..']', true, UvesoOffsetaiarchetypeLUA)
                        end
                    else
--                        AIDebug('* AI-Uveso: ECO cant pause any unit. break!')
                        break
                    end
--                    AILog('* AI-Uveso: ECO new energyTrend = '..energyTrend..'')
                    -- Never remove this safeguard! Modded units can screw it up and cause a DeadLoop!!!
                    safeguard = safeguard - 1
                    if safeguard < 0 then
                        AIWarn('* AI-Uveso: ECO E safeguard < 0', true, UvesoOffsetaiarchetypeLUA)
                        break
                    end
                end
            end
        end
        coroutine.yield(1)
        if bussy then
            --AIWarn('* AI-Uveso: ECOmanager low energy is bussy')
            continue -- while true do
        end
        EcoUnits = {}
        if aiBrain:GetEconomyStoredRatio('ENERGY') >= 0.50 then
            AllUnits = aiBrain:GetListOfUnits( (categories.FACTORY - categories.TECH1) + (categories.ENGINEER - categories.POD) + categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE + categories.MASSFABRICATION + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD) + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO ) - categories.COMMAND , false, false) -- also gets unbuilded units (planed to build)
--            AILog('* AI-Uveso: ECO conomyStoredRatio(ENERGY) > 0.50')
            if energyTrend > 0 then
                --AllUnits = aiBrain:GetListOfUnits(categories.ALLUNITS - categories.COMMAND - categories.SHIELD - categories.MASSEXTRACTION, false, false) -- also gets unbuilded units (planed to build)
                for index, unit in AllUnits do
                    if not unit.pausedEnergy then continue end
                    -- filter units that are not finished
                    if unit:GetFractionComplete() < 1 then continue end
--                    AILog('* AI-Uveso: ECO checking unit ['..index..']  paused:('..repr(unit.pausedMass)..'/'..repr(unit.pausedEnergy)..') '..LOC(unit.Blueprint.Description))
                    if unit.ConsumptionPerSecondEnergy > 0 then
--                        AILog('* AI-Uveso: ECO Adding unit ['..index..'] to table '..LOC(unit.Blueprint.Description))
                        table.insert(EcoUnits, unit)
                    end
                end
                -- Enable units until energytrend is negative
                safeguard = table.getn(EcoUnits)
                while energyTrend > 0 do
--                    AIDebug('* AI-Uveso: ECO safeguard = '..safeguard)
                    -- find unit with most energy consumption
                    minEnergyConsumptionUnitindex = nil
                    minEnergyConsumption = nil
                    if EcoUnits[1] then
                        for index, unit in EcoUnits do
                            if not unit.pausedEnergy then continue end
                            if not minEnergyConsumption or minEnergyConsumption > unit.ConsumptionPerSecondEnergy then
                                minEnergyConsumption = unit.ConsumptionPerSecondEnergy
                                minEnergyConsumptionUnitindex = index
                            end
                        end
                    else
                        break
                    end
                    if minEnergyConsumptionUnitindex then
--                        AILog(' ')
--                        AILog('* AI-Uveso: ECO energyTrend > 0  ('..energyTrend..')')
                        energyTrend = energyTrend - minEnergyConsumption
                        bussy = true
                        if EntityCategoryContains(categories.FACTORY + (categories.ENGINEER - categories.POD) + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO)), EcoUnits[minEnergyConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[minEnergyConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[minEnergyConsumptionUnitindex].Blueprint.Description)..') unit:SetPaused( false ) Consuming ('..minEnergyConsumption..') energy')
                            EcoUnits[minEnergyConsumptionUnitindex]:SetPaused( false )
                            EcoUnits[minEnergyConsumptionUnitindex].pausedEnergy = false
                            EcoUnits[minEnergyConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.COUNTERINTELLIGENCE, EcoUnits[minEnergyConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[minEnergyConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[minEnergyConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( IntelToggle, false ) Consuming ('..minEnergyConsumption..') energy')
                            EcoUnits[minEnergyConsumptionUnitindex]:SetScriptBit('RULEUTC_IntelToggle', false)
                            EcoUnits[minEnergyConsumptionUnitindex].pausedEnergy = false
                            EcoUnits[minEnergyConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.MASSFABRICATION, EcoUnits[minEnergyConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[minEnergyConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[minEnergyConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( ProductionToggle, false ) Consuming ('..minEnergyConsumption..') energy')
                            EcoUnits[minEnergyConsumptionUnitindex]:SetScriptBit('RULEUTC_ProductionToggle', false)
                            EcoUnits[minEnergyConsumptionUnitindex].pausedEnergy = false
                            EcoUnits[minEnergyConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE, EcoUnits[minEnergyConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[minEnergyConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[minEnergyConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( JammingToggle, false ) Consuming ('..minEnergyConsumption..') energy')
                            EcoUnits[minEnergyConsumptionUnitindex]:SetScriptBit('RULEUTC_JammingToggle', false)
                            EcoUnits[minEnergyConsumptionUnitindex].pausedEnergy = false
                            EcoUnits[minEnergyConsumptionUnitindex].managed = true
                        else
                            AIWarn('* AI-Uveso: Unit with unknown Category('..LOC(EcoUnits[minEnergyConsumptionUnitindex].Blueprint.Description)..') ['..EcoUnits[minEnergyConsumptionUnitindex].UnitId..']', true, UvesoOffsetaiarchetypeLUA)
                        end
--                            EcoUnits[minEnergyConsumptionUnitindex]:OnProductionUnpaused()
--                            EcoUnits[minEnergyConsumptionUnitindex]:SetActiveConsumptionActive()
                    else
--                        AIDebug('* AI-Uveso: ECO cant activate any unit. break!')
                        break
                    end
--                    AILog('* AI-Uveso: ECO new energyTrend = '..energyTrend..'')
                    -- Never remove this safeguard! Modded units can screw it up and cause a DeadLoop!!!
                    safeguard = safeguard - 1
                    if safeguard < 0 then
                        AIWarn('* AI-Uveso: ECO E safeguard > 0', true, UvesoOffsetaiarchetypeLUA)
                        break
                    end
                end
            end
        end
        coroutine.yield(1)
        if bussy then
            --AIWarn('* AI-Uveso: ECOmanager high energy is bussy')
            continue -- while true do
        end
        EcoUnits = {}
        if aiBrain:GetEconomyStoredRatio('MASS') < 0.15 then
            --AllUnits = aiBrain:GetListOfUnits( (categories.FACTORY - categories.TECH1) + (categories.ENGINEER - categories.POD) + categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE + categories.MASSFABRICATION + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD) + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO ) - categories.COMMAND , false, false) -- also gets unbuilded units (planed to build)
            AllUnits = aiBrain:GetListOfUnits( (categories.ENGINEER - categories.POD) + categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE + categories.MASSFABRICATION + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD) + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO ) - categories.COMMAND , false, false) -- also gets unbuilded units (planed to build)
            if massTrend < 0 then
                --AllUnits = aiBrain:GetListOfUnits(categories.ALLUNITS - categories.COMMAND - categories.SHIELD - categories.MASSEXTRACTION, false, false) -- also gets unbuilded units (planed to build)
                for index, unit in AllUnits do
                    if unit.pausedMass or unit.pausedEnergy then continue end
                    -- filter units that are not finished
                    if unit:GetFractionComplete() < 1 then continue end
                    -- if we build massextractors or energyproduction, don't pause it
                    if unit.UnitBeingBuilt and EntityCategoryContains( ( categories.MASSEXTRACTION + (categories.ENERGYPRODUCTION - categories.EXPERIMENTAL) + categories.ENERGYSTORAGE ) , unit.UnitBeingBuilt) then
                        continue
                    end
                    -- if we build tech1 factories, don't pause it
                    if unit.UnitBeingBuilt and EntityCategoryContains( categories.FACTORY * categories.TECH1 , unit.UnitBeingBuilt) then
                        continue
                    end
                    -- if we build tech 1 units from a factory, don't pause it
                    if unit.UnitBeingBuilt and EntityCategoryContains( categories.MOBILE * categories.TECH1 , unit.UnitBeingBuilt) then
                        continue
                    end
                    -- don't pause any ACU assisting
                    if unit.UnitBeingAssist and EntityCategoryContains( categories.COMMAND, unit.UnitBeingAssist) then
                        continue
                    end
                    if personality == 'uvesorush' then
                        -- If we are rushing, never pause any factory building units
                        if unit.UnitBeingBuilt and EntityCategoryContains( categories.MOBILE, unit.UnitBeingBuilt ) then
                            continue
                        end
                        -- if we build or upgrade  factories, don't pause it
                        if unit.UnitBeingBuilt and EntityCategoryContains( categories.FACTORY, unit.UnitBeingBuilt) then
                            continue
                        end
                    end
                    unit.ConsumptionPerSecondMass = unit:GetConsumptionPerSecondMass()
                    if unit.ConsumptionPerSecondMass > 0 then
--                        AILog('* AI-Uveso: ECO Adding unit ['..index..'] to table '..LOC(unit.Blueprint.Description))
                        table.insert(EcoUnits, unit)
                    end
                end
                -- Disable units until massTrend is positive
                safeguard = table.getn(EcoUnits)
                while massTrend < 0 do
                    -- find unit with most mass consumption
                    maxMassConsumptionUnitindex = nil
                    maxMassConsumption = nil
                    if EcoUnits[1] then
                        for index, unit in EcoUnits do
                            -- Don't pause factories if we have enemies inside the Paniczone
                            if numUnitsPanicZone > 0 and EntityCategoryContains( categories.FACTORY, unit) then continue end
                            if unit.pausedMass or unit.pausedEnergy then continue end
                            if not maxMassConsumption or maxMassConsumption < unit.ConsumptionPerSecondMass then
                                maxMassConsumption = unit.ConsumptionPerSecondMass
                                maxMassConsumptionUnitindex = index
                            end
                        end
                    else
--                        AILog('* AI-Uveso: ECO low mass; EcoUnits empty array. break!')
                        break
                    end
                    if maxMassConsumptionUnitindex then
--                        AILog(' ')
--                        AILog('* AI-Uveso: ECO massTrend < 0  ('..massTrend..')')
                        bussy = true
                        massTrend = massTrend + maxMassConsumption
                        if EntityCategoryContains(categories.FACTORY + categories.ENGINEER + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO)), EcoUnits[maxMassConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[maxMassConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[maxMassConsumptionUnitindex].Blueprint.Description)..') unit:SetPaused( true ) Saving ('..maxMassConsumption..') mass')
                            EcoUnits[maxMassConsumptionUnitindex]:SetPaused( true )
                            EcoUnits[maxMassConsumptionUnitindex].pausedMass = true
                            EcoUnits[maxMassConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.COUNTERINTELLIGENCE, EcoUnits[maxMassConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[maxMassConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[maxMassConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( IntelToggle, true ) Saving ('..maxMassConsumption..') mass')
                            EcoUnits[maxMassConsumptionUnitindex]:SetScriptBit('RULEUTC_IntelToggle', true)
                            EcoUnits[maxMassConsumptionUnitindex].pausedMass = true
                            EcoUnits[maxMassConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.MASSFABRICATION, EcoUnits[maxMassConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[maxMassConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[maxMassConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( ProductionToggle, true ) Saving ('..maxMassConsumption..') mass')
                            EcoUnits[maxMassConsumptionUnitindex]:SetScriptBit('RULEUTC_ProductionToggle', true)
                            EcoUnits[maxMassConsumptionUnitindex].pausedMass = true
                            EcoUnits[maxMassConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE, EcoUnits[maxMassConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[maxMassConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[maxMassConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( JammingToggle, true ) Saving ('..maxMassConsumption..') mass')
                            EcoUnits[maxMassConsumptionUnitindex]:SetScriptBit('RULEUTC_JammingToggle', true)
                            EcoUnits[maxMassConsumptionUnitindex].pausedMass = true
                            EcoUnits[maxMassConsumptionUnitindex].managed = true
                        else
                            AIWarn('* AI-Uveso: Unit with unknown Category('..LOC(EcoUnits[maxMassConsumptionUnitindex].Blueprint.Description)..') ['..EcoUnits[maxMassConsumptionUnitindex].UnitId..']', true, UvesoOffsetaiarchetypeLUA)
                        end
                    else
--                        AIDebug('* AI-Uveso: ECO cant pause any unit. break!')
                        break
                    end
--                    AILog('*ECO new massTrend = '..massTrend..'')
                    -- Never remove this safeguard! Modded units can screw it up and cause a DeadLoop!!!
                    safeguard = safeguard - 1
                    if safeguard < 0 then
                        AIWarn('* AI-Uveso: ECO M safeguard < 0', true, UvesoOffsetaiarchetypeLUA)
                        break
                    end
                end
            end
        end
        coroutine.yield(1)
        if bussy then
            --AIWarn('* AI-Uveso: ECOmanager low mass is bussy')
            continue -- while true do
        end
        EcoUnits = {}
        if aiBrain:GetEconomyStoredRatio('MASS') >= 0.15 then
            AllUnits = aiBrain:GetListOfUnits( (categories.FACTORY - categories.TECH1) + (categories.ENGINEER - categories.POD) + categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE + categories.MASSFABRICATION + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD) + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO ) - categories.COMMAND , false, false) -- also gets unbuilded units (planed to build)
            if massTrend > 0 then
                --AllUnits = aiBrain:GetListOfUnits(categories.ALLUNITS - categories.COMMAND - categories.SHIELD - categories.MASSEXTRACTION, false, false) -- also gets unbuilded units (planed to build)
                for index, unit in AllUnits do
                    if not unit.pausedMass then continue end
                    -- filter units that are not finished
                    if unit:GetFractionComplete() < 1 then continue end
--                    AILog('* AI-Uveso: ECO checking unit ['..index..']  paused:('..repr(unit.pausedMass)..'/'..repr(unit.pausedEnergy)..') '..LOC(unit.Blueprint.Description))
                    if unit.ConsumptionPerSecondMass > 0 then
--                        AILog('* AI-Uveso: ECO Adding unit ['..index..'] to table '..LOC(unit.Blueprint.Description))
                        table.insert(EcoUnits, unit)
                    end
                end
                -- Enable units until massTrend is negative
                safeguard = table.getn(EcoUnits)
                while massTrend > 0 do
--                    AIDebug('* AI-Uveso: ECO safeguard = '..safeguard)
                    -- find unit with most mass consumption
                    minMassConsumptionUnitindex = nil
                    minMassConsumption = nil
                    if EcoUnits[1] then
                        for index, unit in EcoUnits do
                            if not unit.pausedMass then continue end
                            if not minMassConsumption or minMassConsumption > unit.ConsumptionPerSecondMass then
                                minMassConsumption = unit.ConsumptionPerSecondMass
                                minMassConsumptionUnitindex = index
                            end
                        end
                    else
--                        AILog('* AI-Uveso: ECO high mass; EcoUnits empty array ')
                        break
                    end
                    if minMassConsumptionUnitindex then
--                        AILog(' ')
--                        AILog('* AI-Uveso: ECO massTrend > 0  ('..massTrend..')')
                        massTrend = massTrend - minMassConsumption
                        bussy = true
                        if EntityCategoryContains(categories.FACTORY + (categories.ENGINEER - categories.POD) + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO)), EcoUnits[minMassConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[minMassConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[minMassConsumptionUnitindex].Blueprint.Description)..') unit:SetPaused( false ) Consuming ('..minMassConsumption..') mass')
                            EcoUnits[minMassConsumptionUnitindex]:SetPaused( false )
                            EcoUnits[minMassConsumptionUnitindex].pausedMass = false
                            EcoUnits[minMassConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.COUNTERINTELLIGENCE, EcoUnits[minMassConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[minMassConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[minMassConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( IntelToggle, false ) Consuming ('..minMassConsumption..') mass')
                            EcoUnits[minMassConsumptionUnitindex]:SetScriptBit('RULEUTC_IntelToggle', false)
                            EcoUnits[minMassConsumptionUnitindex].pausedMass = false
                            EcoUnits[minMassConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.MASSFABRICATION, EcoUnits[minMassConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[minMassConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[minMassConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( ProductionToggle, false ) Consuming ('..minMassConsumption..') mass')
                            EcoUnits[minMassConsumptionUnitindex]:SetScriptBit('RULEUTC_ProductionToggle', false)
                            EcoUnits[minMassConsumptionUnitindex].pausedMass = false
                            EcoUnits[minMassConsumptionUnitindex].managed = true
                        elseif EntityCategoryContains(categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE, EcoUnits[minMassConsumptionUnitindex]) then
--                            AILog('* AI-Uveso: ECO ['..EcoUnits[minMassConsumptionUnitindex].UnitId..'] ('..LOC(EcoUnits[minMassConsumptionUnitindex].Blueprint.Description)..') unit:SetScriptBit( JammingToggle, false ) Consuming ('..minMassConsumption..') mass')
                            EcoUnits[minMassConsumptionUnitindex]:SetScriptBit('RULEUTC_JammingToggle', false)
                            EcoUnits[minMassConsumptionUnitindex].pausedMass = false
                            EcoUnits[minMassConsumptionUnitindex].managed = true
                        else
                            AIWarn('* AI-Uveso: Unit with unknown Category('..LOC(EcoUnits[minMassConsumptionUnitindex].Blueprint.Description)..') ['..EcoUnits[minMassConsumptionUnitindex].UnitId..']', true, UvesoOffsetaiarchetypeLUA)
                        end
--                            EcoUnits[minMassConsumptionUnitindex]:OnProductionUnpaused()
--                            EcoUnits[minMassConsumptionUnitindex]:SetActiveConsumptionActive()
                    else
--                        AIDebug('* AI-Uveso: ECO cant activate any unit. break!')
                        break
                    end
--                    AILog('* AI-Uveso: ECO new massTrend = '..massTrend..'')
                    -- Never remove this safeguard! Modded units can screw it up and cause a DeadLoop!!!
                    safeguard = safeguard - 1
                    if safeguard < 0 then
                        AIWarn('* AI-Uveso: ECO M safeguard > 0', true, UvesoOffsetaiarchetypeLUA)
                        break
                    end
                end
            end
        end
        coroutine.yield(1)
        if bussy then
            --AIWarn('* AI-Uveso: ECOmanager high mass is bussy')
            continue -- while true do
        end
        EcoUnits = {}
        if aiBrain:GetEconomyStoredRatio('ENERGY') >= 0.60 and aiBrain:GetEconomyStoredRatio('MASS') >= 0.20 then
            AllUnits = aiBrain:GetListOfUnits( (categories.FACTORY - categories.TECH1) + (categories.ENGINEER - categories.POD) + categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE + categories.MASSFABRICATION + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD) + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO ) - categories.COMMAND , false, false) -- also gets unbuilded units (planed to build)
            for index, unit in AllUnits do
                if not unit.managed then
                    continue
                end
                -- filter units that are not finished
                if unit:GetFractionComplete() < 1 then continue end
                if EntityCategoryContains(categories.FACTORY + (categories.ENGINEER - categories.POD) + (categories.ENGINEERSTATION - categories.STATIONASSISTPOD + ((categories.NUKE + categories.TACTICALMISSILEPLATFORM) * categories.SILO)), unit) then
                    unit:SetPaused( false )
                    unit.pausedMass = false
                    unit.pausedEnergy = false
                    unit.managed = false
                elseif EntityCategoryContains(categories.RADAR + categories.OMNI + categories.OPTICS + categories.SONAR + categories.COUNTERINTELLIGENCE, unit) then
                    unit:SetScriptBit('RULEUTC_IntelToggle', false)
                    unit.pausedMass = false
                    unit.pausedEnergy = false
                    unit.managed = false
                elseif EntityCategoryContains(categories.MASSFABRICATION, unit) then
                    unit:SetScriptBit('RULEUTC_ProductionToggle', false)
                    unit.pausedMass = false
                    unit.pausedEnergy = false
                    unit.managed = false
                elseif EntityCategoryContains(categories.OVERLAYCOUNTERINTEL + categories.COUNTERINTELLIGENCE, unit) then
                    unit:SetScriptBit('RULEUTC_JammingToggle', false)
                    unit.pausedMass = false
                    unit.pausedEnergy = false
                    unit.managed = false
                else
                    AIWarn('* AI-Uveso: Unit with unknown Category('..LOC(unit.Blueprint.Description)..') ['..unit.UnitId..']', true, UvesoOffsetaiarchetypeLUA)
                    unit:SetPaused( false )
                    unit.pausedMass = false
                    unit.pausedEnergy = false
                    unit.managed = false
                end
                -- we only check 1 unit per tick.
                break -- for index, unit in AllUnits do
            end
        end
    end
end
