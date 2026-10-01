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
        -- Fase 9-F18: 'OWPlus Vacant Expansion Area' (Tier1/2/1b/2b, ricerca marker
        -- di scena) rimosso — sostituito dal generatore avamposti indipendente
        -- (OWPlusOutpostGenerator.lua), vedi 'OWPlus Outpost Factory' sotto ==Factory==.
        -- Fase 9-F20: rimosso anche 'U1 Expansion Builder' (stock Uveso) — e' il
        -- builder che rivendica gli slot ARMY_X vuoti di altri giocatori come "big
        -- expansion", producendo le basi enormi e senza controllo di dimensione
        -- ("blob" da 20+ fabbriche osservati in test) di cui l'utente non vuole
        -- piu' — ora abbiamo il nostro sistema avamposti dedicato.

        -----------------------------------------------------------------------------
        -- ==== SCU ==== --
        -----------------------------------------------------------------------------
        'U3 SACU Builder',
        'U3 SACU Teleport Formers',

        -----------------------------------------------------------------------------
        -- ==== Engineer ==== --
        -----------------------------------------------------------------------------
        'U123 Engineer Builders',   -- sess.76: rinominato da 'OWPlus Engineer Builders' — ora sostituisce davvero lo stock (registry override-by-same-name), non solo per MAIN ma anche per il template UvesoExpansionArea usato dagli avamposti. T1 bloccati se T3 factory esiste
        -- Fix sess.84 (bug reale confermato in game): 'OWPlus Outpost Engineer
        -- Builders' NON va qui — la condizione OWPlusIsOutpostLocation doveva
        -- escludere MAIN, ma le BuilderConditions non fanno vero short-circuit
        -- AND (Conoscenze_AI_34 §34): l'ultima condizione della catena ha
        -- comunque effetto anche quando le precedenti sono false. Rimosso —
        -- resta agganciato correttamente ai singoli avamposti tramite
        -- AddGlobalBuilderGroup dinamico (platoon.lua), mai a MAIN.
        'U2 Hive+Kennel',
        'U23 Hive+Kennel Upgrade',
        'UC123 Assistees',
        -- Barriera temporanea test (sess.73, richiesta utente): sospetto che lo spam
        -- sperimentali assorba troppi ingegneri T2/T3/SACU a scapito degli avamposti.
        -- Disattivata insieme a 'OWPlus Experimental Land/Air' sotto, per isolare
        -- l'effetto durante i test — ripristinare togliendo il commento quando si
        -- torna a bilanciare gli sperimentali.
        -- 'OWPlus Assist Experimentals',     -- fix bug Uveso: AssisteeType='Engineer' per T4 mobili (non strutture)
        'U1 Engineer Reclaim',

        -----------------------------------------------------------------------------
        -- ==== Mass ==== --
        -----------------------------------------------------------------------------
        'U1 MassBuilders',
        'U123 ExtractorUpgrades',
        'U1 MassStorage Builder',
        'OWPlus Mass Storage Adjacency',    -- soglia energia 50% (orig 90% — mai raggiunta con ×2 eco), tetto rimosso sess.94
        'OWPlus Economy Upgrade',           -- sess.94: upgrade in-place estrattori T4 + magazzini T2/T3 (Jaggeds)

        -----------------------------------------------------------------------------
        -- ==== Energy ==== --
        -----------------------------------------------------------------------------
        'U123 Energy Builders',
        'U123 Energy Builders Recover',
        'U123 EnergyStorage Builders',
        'U123 Reclaim Energy Buildings',
        'OWPlus Economy T1 Reclaim',        -- soglia energia 50% (orig 100% — mai raggiunta con ×2 eco)
        'OWPlus Energy T2T3',               -- priority 18100/18200 per bypassare loop T1 (U123 ha T1@17900 > T2@17000)
        'OWPlus Energy Storage Adjacency',  -- sess.94: gemello energia di Mass Storage Adjacency, tetto 48/96
        'OWPlus Hydrocarbon Push',          -- sess.94: priorità fissa, bypassa crollo NeedEnergyTech1 del nativo

        -----------------------------------------------------------------------------
        -- ==== Factory ==== --
        -----------------------------------------------------------------------------
        'U1 Factory Builders 1st',
        'OWPlus Factory Builders',          -- CDR: 1 land factory al centro (MAIN). Air/land extra → dispersed.
        'OWPlus Dispersed Base',            -- schema 'x': 4 land + 4 air factory ai nodi NE/SE/SW/NW (46 unità in diagonale)
        'OWPlus Outpost Factory',           -- Fase 9-F18: rivendica avamposti OUT# generati da OWPlusOutpostGenerator.lua (8 direzioni fisse, nessun marker)
        'OWPlus Factory Builders RECOVER',  -- rimpiazza RECOVER: stessa logica, usa FACTORY*LAND senza -SUPPORTFACTORY
        'U1 Gate Builders',
        'U123 Factory Upgrader Rush',
        -- Fix sess.84 (bug reale confermato in game, 13 upgrade reali su
        -- fabbriche MAIN in un solo test): stessa causa della rimozione di
        -- 'OWPlus Outpost Engineer Builders' sopra — rimosso, resta
        -- agganciato correttamente ai singoli avamposti tramite
        -- AddGlobalBuilderGroup dinamico (platoon.lua), mai a MAIN.
        'U2 Air Staging Platform Builders',
        'U1 Factory Builders Naval',
        'U123 Factory Upgrader Naval',

        -----------------------------------------------------------------------------
        -- ==== Land Units BUILDER ==== --
        -- Rimossi (Fase 9-F4, riequilibrio MAIN): 'U123 Land Builders Panic',
        -- 'U123 Land Builders ADAPTIVE'. Le fabbriche terra a MAIN producono
        -- PRIMARIAMENTE ingegneri (OWPlus Engineer Builders, priority 18400-19100)
        -- ed experimental (OWPlus Experimental Land) — non unità T1 generiche da combattimento.
        --
        -- Fase 9-F15: 'OWPlus Land T2T3' riaggiunto come FALLBACK (priority 18100-18200,
        -- piu' bassa di tutti i builder ingegneri) — osservato in gioco che con economia
        -- abbondante (Paragon) le fabbriche restavano ferme una volta raggiunto il cap
        -- ingegneri (MaxCapEngineers in OWPlus Engineer Builders.lua) invece di produrre
        -- qualcos'altro. Ora, solo quando NESSUN builder ingegnere ha condizioni valide
        -- (cap raggiunto), le fabbriche T2/T3 di MAIN passano a costruire unità da
        -- combattimento invece di restare ferme. Stesso BuilderGroup gia' usato in FORWARD
        -- (Uveso Forward Base OverwhelmPlus.lua, lista Builders indipendente).
        -----------------------------------------------------------------------------
        'OWPlus Land T2T3',
        -- Sess.100 parte 12: catalogo vanilla+mod (172 candidati) al posto dei 5 builder
        -- vanilla qui sopra (spenti dal flag OWPlusMainCatalogProductionDisabled).
        'OWPlus Main Land Production',

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
        'OWPlus Outpost Transport',         -- Fase 9-F24: pool dedicato trasporti T1 per raggiungere gli avamposti OUT# (vedi platoon.lua MoveToLocationInclTransport)

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
        -- Barriera temporanea test (sess.73): vedi nota su 'OWPlus Assist Experimentals'
        -- piu' sopra in questo file — stesso motivo, stessa disattivazione temporanea.
        -- 'OWPlus Experimental Land',     -- priority 18200-18300: bypassa ItsTimeForGameender (default 25min), scala T4 con eco storage
        -- 'OWPlus Experimental Air',      -- priority 18200-18300: sperimentali aria quando T3 air factory + eco overflow
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
