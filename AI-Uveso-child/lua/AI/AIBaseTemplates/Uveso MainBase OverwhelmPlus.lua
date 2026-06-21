BaseBuilderTemplate {
    BaseTemplateName = 'overwhelmplus',
    Builders = {
        -----------------------------------------------------------------------------
        -- ==== ACU ==== --
        -----------------------------------------------------------------------------
        'UC ACU Attack Former',
        'UC ACU Support Platoon',

        -----------------------------------------------------------------------------
        -- ==== Expansion Builders ==== --
        -----------------------------------------------------------------------------
        'U1 Expansion Builder',

        -----------------------------------------------------------------------------
        -- ==== SCU ==== --
        -----------------------------------------------------------------------------
        'U3 SACU Builder',
        'U3 SACU Teleport Formers',

        -----------------------------------------------------------------------------
        -- ==== Engineer ==== --
        -----------------------------------------------------------------------------
        'U123 Engineer Builders',
        'U2 Hive+Kennel',
        'U23 Hive+Kennel Upgrade',
        'UC123 Assistees',
        'U1 Engineer Reclaim',

        -----------------------------------------------------------------------------
        -- ==== Mass ==== --
        -----------------------------------------------------------------------------
        'U1 MassBuilders',
        'U123 ExtractorUpgrades',
        'U1 MassStorage Builder',

        -----------------------------------------------------------------------------
        -- ==== Energy ==== --
        -----------------------------------------------------------------------------
        'U123 Energy Builders',
        'U123 Energy Builders Recover',
        'U123 EnergyStorage Builders',
        'U123 Reclaim Energy Buildings',

        -----------------------------------------------------------------------------
        -- ==== Factory ==== --
        -----------------------------------------------------------------------------
        'U1 Factory Builders 1st',
        'U1 Factory Builders ADAPTIVE',
        'U1 Factory Builders RECOVER',
        'U1 Gate Builders',
        'U123 Factory Upgrader Rush',
        'U2 Air Staging Platform Builders',
        'U1 Factory Builders Naval',
        'U123 Factory Upgrader Naval',

        -----------------------------------------------------------------------------
        -- ==== Land Units BUILDER ==== --
        -----------------------------------------------------------------------------
        'U123 Land Builders Panic',
        'U123 Land Builders ADAPTIVE',

        -----------------------------------------------------------------------------
        -- ==== Land Units FORMER ==== --
        -----------------------------------------------------------------------------
        'U123 Land Formers PanicZone',
        'U123 Land Formers MilitaryZone',
        'U123 Land Formers EnemyZone',
        'U123 Land Formers Trasher',
        'U123 Land Formers Guards',

        -----------------------------------------------------------------------------
        -- ==== Hover Units FORMER ==== --
        -----------------------------------------------------------------------------
        'U123 Hover Formers PanicZone',
        'U123 Hover Formers MilitaryZone',
        'U123 Hover Formers EnemyZone',
        'U123 Hover Formers Trasher',

        -----------------------------------------------------------------------------
        -- ==== Amphibious Units BUILDER ==== --
        -----------------------------------------------------------------------------
        'U123 Amphibious Builders',

        -----------------------------------------------------------------------------
        -- ==== Amphibious Units FORMER ==== --
        -----------------------------------------------------------------------------
        'U123 Amphibious Formers PanicZone',
        'U123 Amphibious Formers MilitaryZone',
        'U123 Amphibious Formers EnemyZone',
        'U123 Amphibious Formers Trasher',

        -----------------------------------------------------------------------------
        -- ==== Air Units BUILDER ==== --
        -----------------------------------------------------------------------------
        'U123 Air Builders ADAPTIVE',
        'U123 Air Builders Anti-Experimental',
        'U123 Air Transport Builders',

        -----------------------------------------------------------------------------
        -- ==== Air Units FORMER ==== --
        -----------------------------------------------------------------------------
        'U123 Air Formers PanicZone',
        'U123 Air Formers MilitaryZone',
        'U123 Air Formers EnemyZone',
        'U123 Air Formers Trasher',
        'U123 TorpedoBomber Formers',

        -----------------------------------------------------------------------------
        -- ==== Sea Units BUILDER ==== --
        -----------------------------------------------------------------------------
        'U123 Naval Builders',
        'U123 Naval Builders withPath',

        -----------------------------------------------------------------------------
        -- ==== Sea Units FORMER ==== --
        -----------------------------------------------------------------------------
        'U123 Naval Formers PanicZone',
        'U123 Naval Formers MilitaryZone',
        'U123 Naval Formers EnemyZone',
        'U123 Naval Formers Trasher',

        -----------------------------------------------------------------------------
        -- ==== EXPERIMENTALS BUILDER ==== --
        -----------------------------------------------------------------------------
        'U4 Land Experimental Builders',
        'U4 Air Experimental Builders',
        'U4 Economic Experimental Builders',
        'Paragon Turbo Experimentals',
        'Paragon Turbo FactoryUpgrader',
        'Paragon Turbo Air',
        'Paragon Turbo Land',

        -----------------------------------------------------------------------------
        -- ==== EXPERIMENTALS FORMER ==== --
        -----------------------------------------------------------------------------
        'U4 Land Experimental Formers PanicZone',
        'U4 Land Experimental Formers MilitaryZone',
        'U4 Land Experimental Formers EnemyZone',
        'U4 Land Experimental Formers Trasher',
        'U4 Air Experimental Formers PanicZone',
        'U4 Air Experimental Formers MilitaryZone',
        'U4 Air Experimental Formers EnemyZone',
        'U4 Air Experimental Formers Trasher',

        -----------------------------------------------------------------------------
        -- ==== Structure Shield BUILDER ==== --
        -----------------------------------------------------------------------------
        'U23 Shields Builder',
        'U23 Shields Upgrader',
        'U234 Repair Shields Former',

        -----------------------------------------------------------------------------
        -- ==== Defenses BUILDER ==== --
        -----------------------------------------------------------------------------
        'U2 Tactical Missile Launcher minimum',
        'U2 Tactical Missile Launcher maximum',
        'U2 Tactical Missile Launcher Builder',
        'U2 Tactical Missile Defenses Builder',
        'U3 Strategic Missile Launcher Builder',
        'U4 Strategic Missile Launcher NukeAI',
        'U4 Strategic Missile Defense Builders MAIN',
        'U4 Strategic Missile Defense Anti-NukeAI',
        'U234 Artillery Builders',
        'U34 Artillery Formers',
        'U4 Satellite Formers',
        'U123 Defense Anti Air Builders',
        'U123 Defense Anti Ground Builders',

        -----------------------------------------------------------------------------
        -- ==== FireBase BUILDER ==== --
        -----------------------------------------------------------------------------
        'U1 FirebaseBuilders',

        -----------------------------------------------------------------------------
        -- ==== Scout BUILDER ==== --
        -----------------------------------------------------------------------------
        'U1 Land Scout Builders',
        'U1 Air Scout Builders',

        -----------------------------------------------------------------------------
        -- ==== Scout FORMER ==== --
        -----------------------------------------------------------------------------
        'U1 Land Scout Formers',
        'U13 Air Scout Formers',

        -----------------------------------------------------------------------------
        -- ==== Intel/CounterIntel BUILDER ==== --
        -----------------------------------------------------------------------------
        'U1 Land Radar Builders',
        'U1 Land Radar Upgrader',
        'U1 Sonar Builders',
        'U1 Sonar Upgraders',

        'CounterIntelBuilders',
        'CybranOptics',

        -----------------------------------------------------------------------------
        -- ==== MOD BUILDER ==== --
        -----------------------------------------------------------------------------
        'Total Mayhem HEAVYASSAULT Builder',
        'Total Mayhem FactoryBuilder',
        'Total Mayhem Former',

    },
    NonCheatBuilders = {

    },

    BaseSettings = {
        FactoryCount = {
            Land = 3,
            Air  = 3,
            Sea  = 2,
            Gate = 1,
        },
        EngineerCount = {
            Tech1 = 6,
            Tech2 = 3,
            Tech3 = 3,
            SCU   = 3,
        },
        MassToFactoryValues = {
            T1Value  = 6,
            T2Value  = 15,
            T3Value  = 22.5,
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return -1
    end,
    FirstBaseFunction = function(aiBrain)
        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if personality == 'overwhelmplus' then
            return 1000, 'overwhelmplus'
        end
        return -1
    end,
}
