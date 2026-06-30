BaseBuilderTemplate {
    BaseTemplateName = 'overwhelmplus',
    Builders = {
        -----------------------------------------------------------------------------
        -- ==== ACU ==== --
        -- UC ACU Attack Former rimosso: il CDR non attacca autonomamente.
        -- UC ACU Support Platoon rimosso: era escort del champion platoon (non più usato).
        -- OWPlus CDR Upgrades: potenzia il CDR (T2→T3→T4 engineering) prima di qualsiasi altra cosa.
        -- OWPlus ACU Assist (19000-18700): assiste solo dopo che ExperimentalEngineering è installato.
        -----------------------------------------------------------------------------
        'OWPlus CDR Upgrades',
        'OWPlus ACU Assist',

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
        'OWPlus Engineer Builders',   -- sostituisce U123 Engineer Builders: T1 bloccati se T3 factory esiste
        'U2 Hive+Kennel',
        'U23 Hive+Kennel Upgrade',
        'UC123 Assistees',
        'OWPlus Assist Experimentals',     -- fix bug Uveso: AssisteeType='Engineer' per T4 mobili (non strutture)
        'U1 Engineer Reclaim',

        -----------------------------------------------------------------------------
        -- ==== Mass ==== --
        -----------------------------------------------------------------------------
        'U1 MassBuilders',
        'U123 ExtractorUpgrades',
        'U1 MassStorage Builder',
        'OWPlus Mass Storage Adjacency',    -- soglia energia 50% (orig 90% — mai raggiunta con ×2 eco)

        -----------------------------------------------------------------------------
        -- ==== Energy ==== --
        -----------------------------------------------------------------------------
        'U123 Energy Builders',
        'U123 Energy Builders Recover',
        'U123 EnergyStorage Builders',
        'U123 Reclaim Energy Buildings',
        'OWPlus Economy T1 Reclaim',        -- soglia energia 50% (orig 100% — mai raggiunta con ×2 eco)
        'OWPlus Energy T2T3',               -- priority 18100/18200 per bypassare loop T1 (U123 ha T1@17900 > T2@17000)

        -----------------------------------------------------------------------------
        -- ==== Factory ==== --
        -----------------------------------------------------------------------------
        'U1 Factory Builders 1st',
        'OWPlus Factory Builders',          -- CDR: 1 land factory al centro (MAIN). Air/land extra → dispersed.
        'OWPlus Dispersed Base',            -- schema 'x': 4 land + 4 air factory ai nodi NE/SE/SW/NW (46 unità in diagonale)
        'OWPlus Factory Builders RECOVER',  -- rimpiazza RECOVER: stessa logica, usa FACTORY*LAND senza -SUPPORTFACTORY
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
        'OWPlus Land T2T3',             -- priority 18100/18200: T2/T3 factories producono T2/T3 (sopra Uveso 150-350)

        -----------------------------------------------------------------------------
        -- ==== Land Units FORMER ==== --
        -- Rimossi: PanicZone/MilitaryZone/EnemyZone/Trasher/Guards
        -- → avevano priority 60-90 e prendevano unità in difesa quando OWPlus (280-300) era al cap
        -- OWPlus Land Formers Aggressive gestisce tutto l'attacco terra
        -----------------------------------------------------------------------------

        -----------------------------------------------------------------------------
        -- ==== Hover Units FORMER ==== --
        -- Rimossi: PanicZone/MilitaryZone/EnemyZone/Trasher
        -- → Le unità hover Aeon (Mantis/Obsidian/Harbinger) sono LAND+HOVER:
        --   matchano già OWPlus Land Formers Aggressive (prio 270-300).
        --   I former hover difensivi le trattenevano in base come i land formers rimossi prima.
        -----------------------------------------------------------------------------

        -----------------------------------------------------------------------------
        -- ==== Amphibious Units BUILDER ==== --
        -----------------------------------------------------------------------------
        'U123 Amphibious Builders',

        -----------------------------------------------------------------------------
        -- ==== Amphibious Units FORMER ==== --
        -- Rimossi: PanicZone/MilitaryZone/EnemyZone/Trasher
        -- → stessa logica dei Hover Formers: unità anfibie vanno agli OWPlus Land Formers
        -----------------------------------------------------------------------------

        -----------------------------------------------------------------------------
        -- ==== Air Units BUILDER ==== --
        -----------------------------------------------------------------------------
        'U123 Air Builders ADAPTIVE',
        'U123 Air Builders Anti-Experimental',
        'U123 Air Transport Builders',

        -----------------------------------------------------------------------------
        -- ==== Air Units FORMER ==== --
        -- Rimossi: PanicZone/MilitaryZone/EnemyZone/Trasher (priority 70-90, trattenevano unità in difesa)
        -- OWPlus Air Formers gestisce l'attacco aria; torpedo manteniamo per il navale
        -----------------------------------------------------------------------------
        'U123 TorpedoBomber Formers',

        -----------------------------------------------------------------------------
        -- ==== Sea Units BUILDER ==== --
        -----------------------------------------------------------------------------
        'U123 Naval Builders',
        'U123 Naval Builders withPath',
        'OWPlus Naval T2T3',            -- priority 18700/18800: bypassa panic sub T1 (18600) per fabbriche T2/T3

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
        'OWPlus Experimental Land',     -- priority 18200-18300: bypassa ItsTimeForGameender (default 25min), scala T4 con eco storage
        'OWPlus Experimental Air',      -- priority 18200-18300: sperimentali aria quando T3 air factory + eco overflow
        'U4 Land Experimental Builders',
        'U4 Air Experimental Builders',
        'U4 Economic Experimental Builders',
        'Paragon Turbo Experimentals',
        'Paragon Turbo FactoryUpgrader',
        'Paragon Turbo Air',
        'Paragon Turbo Land',

        -----------------------------------------------------------------------------
        -- ==== EXPERIMENTALS FORMER ==== --
        -- Rimossi: U4 Land/Air Experimental Formers PanicZone/MilitaryZone
        -- → trattenevano T4 (incluso CZAR) in difesa base
        -- OWPlus Experimental Formers gestisce tutto; EnemyZone/Trasher Uveso rimangono come fallback
        -----------------------------------------------------------------------------
        'OWPlus Experimental Formers',      -- priority 460-500: bypassa NoRush1stPhaseActive, manda T4 all'attacco appena pronti
        'OWPlus Land Formers Aggressive',   -- priority 270-300: gruppi T1/T2/T3 senza gate NoRush (T1 Rush: 2 unità bastano)
        'OWPlus Air Formers',               -- priority 240-260: caccia e gunship attaccano appena disponibili
        'U4 Land Experimental Formers EnemyZone',
        'U4 Land Experimental Formers Trasher',
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
        -- 'U34 Artillery Formers' rimosso: ex-PanicZone/MilitaryZone trattenevano artiglierie in difesa.
        -- Le artiglierie matchano OWPlus Land Formers Aggressive (LAND MOBILE T3) e vanno all'attacco.
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
    -- FirstBaseFunction: SOLO funzione di priorità — usata da GetHighestBuilder per selezionare
    -- quale template usare. NON registrare sub-location qui: questa funzione viene chiamata
    -- PRIMA dell'init PBM (PBMAddBuildLocation non è ancora disponibile).
    -- La registrazione delle sub-location BASE_NE/SE/SW/NW avviene in
    -- overwhelmplusai.lua:InitializePlatoonBuildManager(), chiamata dopo l'init PBM.
    FirstBaseFunction = function(aiBrain)
        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if personality == 'overwhelmplus' or personality == 'overwhelmpluscheat' then
            return 1000, 'overwhelmplus'
        end
        return -1
    end,
}
