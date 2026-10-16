-- OWPlus ExpansionNaval.lua
--
-- Sess.102 (approccio A, decisione utente 2026-10-15): template delle basi navali di Overwhelm+.
-- Copia di 'Uveso ExpansionNaval.lua' (che risponde -1 a ogni personalita' non sua) con la
-- produzione e i plotoni nostri al posto di quelli nativi:
--  * 'OWPlus Naval Production' invece di 'U123 Naval Builders' / 'withPath';
--  * 'OWPlus Naval Formers' invece di MilitaryZone / EnemyZone / Trasher (MilitaryZone teneva
--    fino a 50 navi in porto); resta PanicZone per la difesa con nemici vicini alla base.
-- Gli sperimentali navali restano quelli nativi fino alla fase dedicata.
-- Rollback: con OWPlusNavalCatalogDisabled = true ExpansionFunction risponde -1.

local OWPlusFactoryTargetsMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusFactoryTargets.lua')

BaseBuilderTemplate {
    BaseTemplateName = 'OWPlusExpansionNaval',
    Builders = {
        -- ==== Engineer ==== --
        'U123 Engineer Builders',
        'UC123 Assistees',

        -- ==== Factory ==== --
        -- Sess.102: al posto di 'U1 Factory Builders Naval' (tetto globale che non conta i cantieri
        -- potenziati: 25 cantieri per IA nel test del 2026-10-16), massimo 3 cantieri per base.
        'OWPlus Naval Shipyards',
        'U123 Factory Upgrader Naval',

        -- ==== Defenses (formula degli avamposti: antinave, AA, scudi) ==== --
        'OWPlus Naval Base Defenses',

        -- ==== Sea Units BUILDER / FORMER ==== --
        'OWPlus Naval Production',
        'OWPlus Naval Formers',
        'U123 Naval Formers PanicZone',

        -- ==== Air Units FORMER ==== --
        'U123 TorpedoBomber Formers',

        -- ==== EXPERIMENTALS ==== --
        'U4 Naval Experimental Builders',
        'U4 Naval Experimental Formers PanicZone',
        'U4 Naval Experimental Formers MilitaryZone',
        'U4 Naval Experimental Formers EnemyZone',
        'U4 Naval Experimental Formers Trasher',

        -- ==== Defenses BUILDER ==== --
        'U2 Tactical Missile Defenses Builder',
        'U4 Strategic Missile Defense Builders Naval',

        -- ==== Intel ==== --
        'U1 Sonar Builders',
        'U1 Sonar Upgraders',
    },

    BaseSettings = {
        FactoryCount = {
            Land = 0,
            Air = 0,
            Sea = 3,
            Gate = 0,
        },
        EngineerCount = {
            Tech1 = 2,
            Tech2 = 1,
            Tech3 = 1,
            SCU = 0,
        },
        MassToFactoryValues = {
            T1Value = 6,
            T2Value = 15,
            T3Value = 22.5,
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if markerType ~= 'Naval Area' then
            return -1
        end
        if OWPlusFactoryTargetsMod.OWPlusNavalCatalogDisabled then
            return -1
        end
        local setup = ScenarioInfo.ArmySetup and ScenarioInfo.ArmySetup[aiBrain.Name]
        local personality = setup and setup.AIPersonality
        if personality == 'overwhelmplus' or personality == 'overwhelmpluscheat' then
            LOG('[OWPlus-NAVAL] OWPlusExpansionNaval ExpansionFunction: OK, base navale con template OWPlusExpansionNaval a ('
                .. math.floor(location[1]) .. ',' .. math.floor(location[3]) .. ') [' .. tostring(aiBrain.Nickname) .. ']')
            return 1000, 'OWPlusExpansionNaval'
        end
        return -1
    end,
}
