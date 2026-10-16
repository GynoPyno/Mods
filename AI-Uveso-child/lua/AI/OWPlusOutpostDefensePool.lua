-- OWPlusOutpostDefensePool.lua
-- Fase C (B16 - Avamposti autonomi): pool di unita' difensive T1 per avamposto,
-- vanilla + TotalMayhem (unica mod verificata con difese T1 aggiuntive reali —
-- Antares/BattlePack/BlackOps/ExpShield non hanno nulla di nuovo a T1, verificato
-- durante il brainstorming B16 in AI_Mod_Spec.md).
--
-- Unita' TotalMayhem confermate (ricerca dedicata, Categories verificate nei file
-- .bp: STRUCTURE+DEFENSE+TECH1+DIRECTFIRE/ANTIAIR, no EXPERIMENTAL/TECH2/3):
--   Cybran:   BRMT1PD, BRMT1EXPD (ground)
--   UEF:      BRNT1HPD (ground), BRNT1EXPD (ground+AA ibrida)
--             [BRNBAAFAC era listata come AA ma richiede BuildRestriction
--              'RULEUBR_OnHydrocarbonDeposit' — impossibile piazzarla come difesa
--              libera (mai un marker idro nell'anello 7-15), rimossa dal pool sess.81]
--   Aeon:     BROT1HPD, BROT1EXPD (solo ground, nessuna AA T1 extra da TotalMayhem)
--   Seraphim: BRPT1PD, BRPT1EXPD (solo ground, nessuna AA T1 extra da TotalMayhem)
--
-- Fase D-difese (sess.86): T2/T3 hanno ora pool propri (vedi
-- GroundDefensePoolT2/T3, AADefensePoolT2/T3 sotto) — catalogo mod esteso
-- (Antares/BattlePack/BlackOps Unleashed/#Marlos) trovato e integrato, non piu'
-- solo stringhe generiche vanilla. LIMITE NOTO CONFERMATO: 'T3GroundDefense'
-- esiste in BuildingTemplates.lua (vanilla) SOLO per UEF ('XEB2306') — verificato
-- sess.86 sui dati dell'installazione FAF reale: Aeon/Cybran/Seraphim non hanno
-- MAI avuto una vera Point Defense T3 a fuoco diretto nel gioco base (asimmetria
-- reale del design originale, non un buco di dati) — per quelle 3 fazioni il
-- pool T3 terra e' quindi sempre modded (sentinel OWPLUS_NO_VANILLA). L'AA invece
-- ha 'T3AADefense' per tutte e 4 le fazioni — upgrade vanilla completo T1->T2->T3.

local GroundDefensePoolT1 = {
    UEF      = { 'T1GroundDefense', 'BRNT1HPD', 'BRNT1EXPD' },
    Aeon     = { 'T1GroundDefense', 'BROT1HPD', 'BROT1EXPD' },
    Cybran   = { 'T1GroundDefense', 'BRMT1PD', 'BRMT1EXPD' },
    Seraphim = { 'T1GroundDefense', 'BRPT1PD', 'BRPT1EXPD' },
}

local AADefensePoolT1 = {
    UEF      = { 'T1AADefense', 'BRNT1EXPD' },
    Aeon     = { 'T1AADefense' },
    Cybran   = { 'T1AADefense' },
    Seraphim = { 'T1AADefense' },
}

-- Fase D-difese (sess.86): pool T2 e T3, stessa struttura di sopra — indice 1
-- e' sempre il token/ID vanilla per convenzione. Quando una fazione non ha
-- ALCUNA difesa vanilla a quel tier (vedi T3 terra sotto), l'indice 1 e' il
-- sentinel OWPLUS_NO_VANILLA invece di una stringa: PickListFromPool lo
-- riconosce e sceglie sempre e solo tra le varianti modded (indici 2+), senza
-- preferenza artificiale verso la prima voce modded messa in lista.
local OWPLUS_NO_VANILLA = false

-- Ground T2: vanilla 'T2GroundDefense' esiste per tutte e 4 le fazioni (gia'
-- usato da OWPlusPickUpgradeDefense sotto, invariata). Modded: #Marlos "Point
-- Defense", unica mod con difese T2 terra confermate per tutte e 4 le fazioni
-- (verificato sess.86 — Categories STRUCTURE+DEFENSE+TECH2+DIRECTFIRE).
-- Sess.87: aggiunta la famiglia TotalMayhem (prefisso BRN/BRM/BRO/BRP+T2,
-- trovata per pattern di ID dopo che la ricerca testuale per nome visualizzato
-- falliva — vedi Conoscenze_acquisite_39.md §56). BRNT2EPD "Tower Boss" resta
-- SOLO terra nonostante Categories includa ANTIAIR: nessun weapon ha 'Air' in
-- FireTargetLayerCapsTable, confermato anche in game dall'utente — Category
-- fuorviante/vestigiale del modder, vedi §57 stesso file conoscenze.
local GroundDefensePoolT2 = {
    UEF      = { 'T2GroundDefense', 'keb2201', 'BRNT2EPD', 'BRNT2PD2' },
    Aeon     = { 'T2GroundDefense', 'kab2201', 'BROT2EPD' },
    Cybran   = { 'T2GroundDefense', 'krb2201', 'BRMT2EPD', 'BRMT2PD' },
    Seraphim = { 'T2GroundDefense', 'ksb2201', 'BRPT2EXPD' },
}

-- AA T2: vanilla 'T2AADefense' universale. Modded: Antares UEF (SAM T2 —
-- Description del .bp dice "T4" ma le Categories sono TECH2, refuso del
-- modder). Sess.87: aggiunta TotalMayhem per Aeon/Cybran/Seraphim — weapon
-- dedicato o omnidirezionale con 'Air' in FireTargetLayerCapsTable, verificato
-- per ciascuna (BRNT2EPD UEF ESCLUSA di proposito, vedi nota su
-- GroundDefensePoolT2 sopra: non ha davvero un'arma anti-aerea).
local AADefensePoolT2 = {
    UEF      = { 'T2AADefense', 'veb2302' },
    Aeon     = { 'T2AADefense', 'BROT2EPD' },
    Cybran   = { 'T2AADefense', 'BRMT2EPD' },
    Seraphim = { 'T2AADefense', 'BRPT2EXPD' },
}

-- Ground T3: l'UEF e' l'UNICA fazione con una vera Point Defense T3 vanilla
-- ('XEB2306') — verificato sess.86 direttamente sui dati dell'installazione
-- FAF reale (non nel dump statico di riferimento, incompleto per questa
-- unita'): Aeon/Cybran/Seraphim non hanno MAI avuto un edificio T3 a fuoco
-- diretto dedicato nel gioco base — si fermano al Point Defense T2 (asimmetria
-- reale del design originale di Forged Alliance, non un buco nei nostri dati).
-- Per le altre 3 fazioni il pool e' quindi sempre e solo modded (sentinel).
-- [keb2301 (#Marlos, "Heavy Naval Artillery Bunker") rimossa dal pool terra
--  sess.87: Categories ha DEFENSE ma WeaponCategory='Anti Navy' e
--  FireTargetLayerCapsTable={Land='Water|Seabed', Water='Water|Seabed'} —
--  non puo' MAI colpire bersagli di terra, era ~4 pick su 10 sprecati in un
--  avamposto terrestre. Segnalata dall'utente in test live.]
-- Sess.87: aggiunta la famiglia TotalMayhem T3. BRNT3SHPD "Ex-Catalyst" resta
-- SOLO terra nonostante Categories includa ANTIAIR — stesso caso di BRNT2EPD
-- sopra, nessuno dei suoi due weapon ha 'Air' in FireTargetLayerCapsTable.
-- 'Perses' (BRNT3PERSES, vero TECH3 Experimental) NON e' qui: ha uno slot a
-- parte piu' raro, vedi OWPlusTrueExperimentalT3 sotto.
local GroundDefensePoolT3 = {
    UEF      = { 'XEB2306', 'keb2303', 'BRNT3PDRO', 'BRNT3SHPD' },
    Aeon     = { OWPLUS_NO_VANILLA, 'kab2301', 'bab2306', 'BROT3PDRO', 'BROT3SHPD' },
    Cybran   = { OWPLUS_NO_VANILLA, 'krb2301', 'wrb4302', 'brb2306', 'BRMT3PD', 'BRMT3PDRO' },
    Seraphim = { OWPLUS_NO_VANILLA, 'ksb2301', 'xsb2306', 'bsb2306', 'BRPT3PD' },
}

-- AA T3: vanilla 'T3AADefense' universale (gia' usato da OWPlusPickUpgradeDefense,
-- invariata). Modded T3 AA trovato per UEF (#Marlos, sess.86) e Aeon
-- (TotalMayhem 'Brute'/BROT3SHPD, sess.87 — unico hybrid T3 con vero weapon
-- anti-aereo verificato; Cybran/Seraphim non hanno equivalente in nessuna mod
-- attiva).
local AADefensePoolT3 = {
    UEF      = { 'T3AADefense', 'keb2304', 'keb2305' },
    Aeon     = { 'T3AADefense', 'BROT3SHPD' },
    Cybran   = { 'T3AADefense' },
    Seraphim = { 'T3AADefense' },
}

-- Fase E (sess.88): scudi/artiglieria/SMD — stesso principio dei pool sopra
-- (indice 1 sempre il token vanilla o OWPLUS_NO_VANILLA), catalogo verificato
-- su TotalMayhem/#Marlos/Antares/BlackOps-Unleashed/BattlePack/NuclearRepulsorShields
-- (Categories confermate via grep diretto sui .bp, MOBILE escluso — solo vere
-- STRUCTURE costruibili da un ingegnere).
--
-- Scudi T2/T3: vanilla T2ShieldDefense/T3ShieldDefense universali. Nessuna mod
-- aggiunge scudi T2/T3 normali eccetto Cybran T3 (urb4207 NuclearRepulsorShields,
-- BRB4207 BlackOps-Unleashed, WRB4207 BattlePack — tutti STRUCTURE+DEFENSE+TECH3+
-- SHIELD, colmano la lacuna nota di Cybran: nei dati vanilla T2ShieldDefense e
-- T3ShieldDefense puntano ALLO STESSO ID urb4202, verificato in
-- BuildingTemplates.lua — non e' un bug nostro, e' cosi' nel gioco base).
-- Nessun T1: nessun token vanilla ne' unita' modded trovata a questo tier.
local ShieldPoolT2 = {
    UEF      = { 'T2ShieldDefense' },
    Aeon     = { 'T2ShieldDefense' },
    Cybran   = { 'T2ShieldDefense' },
    Seraphim = { 'T2ShieldDefense' },
}
local ShieldPoolT3 = {
    UEF      = { 'T3ShieldDefense' },
    Aeon     = { 'T3ShieldDefense' },
    Cybran   = { 'T3ShieldDefense', 'urb4207', 'BRB4207', 'WRB4207' },
    Seraphim = { 'T3ShieldDefense' },
}

-- Missile Difesa Tattica (Fase G, sess.88, richiesta esplicita utente durante
-- test live): SOLO T2Missiledefense esiste come token vanilla generico
-- (verificato in BuildingTemplates.lua — nessun T1MissileDefense ne'
-- T3MissileDefense, il gioco base si ferma a T2 per questa categoria).
-- Catalogo modded non ancora esplorato per questa fase (nessuna caccia al
-- catalogo fatta per mancanza di tempo durante il test live) — solo vanilla
-- per ora, stesso pattern "parti dal vanilla, estendi dopo" gia' seguito per
-- le altre categorie in Fase C.
local TacticalMissileDefensePoolT2 = {
    UEF      = { 'T2MissileDefense' },
    Aeon     = { 'T2MissileDefense' },
    Cybran   = { 'T2MissileDefense' },
    Seraphim = { 'T2MissileDefense' },
}

-- Artiglieria T1/T2/T3: NESSUN token vanilla a T1 (T2Artillery/T3Artillery sono
-- gli unici generici in BuildingTemplates.lua) — pool T1 sempre e solo modded
-- (sentinel), vuoto per le fazioni senza candidati (guardia lista vuota sopra).
-- T1: TotalMayhem UEF (BRNT1EXART, BRNBT1HART) e Cybran (BRMT1ADVART). Aeon/
-- Seraphim: nessuna trovata in nessuna mod di riferimento.
-- T2: vanilla T2Artillery + TotalMayhem UEF (BRNT2EXART) + #Marlos UEF/Aeon
-- (KEB2202/KAB2202) + BlackOps-Unleashed tutte e 4 le fazioni (BAB2303/BEB2303/
-- BRB2303/BSB2303).
-- T3: vanilla T3Artillery + Antares UEF (UEB2210 — ha ANCHE Categories DEFENSE,
-- gestito escludendo ARTILLERY dallo scan conteggio difese terra in platoon.lua
-- per non farla contare due volte) + Antares UEF/Aeon/Seraphim (LEB2320/LAB2320/
-- LSB2320) + Antares Cybran (GMRB305, GMRB302 — ha ANCHE EXPERIMENTAL ma resta
-- TECH3 puro, tier normale non slot raro) + BattlePack Cybran (WRB2302) +
-- Antares Seraphim (GSMB317).
local ArtilleryPoolT1 = {
    UEF      = { OWPLUS_NO_VANILLA, 'BRNT1EXART', 'BRNBT1HART' },
    Aeon     = { OWPLUS_NO_VANILLA },
    Cybran   = { OWPLUS_NO_VANILLA, 'BRMT1ADVART' },
    Seraphim = { OWPLUS_NO_VANILLA },
}
local ArtilleryPoolT2 = {
    UEF      = { 'T2Artillery', 'BRNT2EXART', 'KEB2202', 'BEB2303' },
    Aeon     = { 'T2Artillery', 'KAB2202', 'BAB2303' },
    Cybran   = { 'T2Artillery', 'BRB2303' },
    Seraphim = { 'T2Artillery', 'BSB2303' },
}
local ArtilleryPoolT3 = {
    UEF      = { 'T3Artillery', 'UEB2210', 'LEB2320' },
    Aeon     = { 'T3Artillery', 'LAB2320' },
    Cybran   = { 'T3Artillery', 'GMRB305', 'GMRB302', 'WRB2302' },
    Seraphim = { 'T3Artillery', 'GSMB317', 'LSB2320' },
}

-- SMD (antimissili strategici): SOLO T3, nessun token T1/T2 esiste (design
-- vanilla originale, non un buco di dati). Modded: Antares UEF (SMP0080 — ANCHE
-- scudo ibrido T3 non-Experimental; GEB2401 — Experimental con ANTIAIR+
-- ANTIMISSILE ibrido) + BattlePack UEF (WEB4301) + BlackOps-Unleashed Aeon
-- (BAB4307) + Antares Seraphim (GMSB402 — Experimental). Cybran: nessun
-- candidato modded trovato, solo vanilla. Pool piatto (nessuna sostituzione
-- Experimental separata: la rarita' qui la fa gia' il tiro unico 0-3, vedi
-- OWPlusRollSMDCount sotto).
local SMDPoolT3 = {
    UEF      = { 'T3StrategicMissileDefense', 'SMP0080', 'GEB2401', 'WEB4301' },
    Aeon     = { 'T3StrategicMissileDefense', 'BAB4307' },
    Cybran   = { 'T3StrategicMissileDefense' },
    Seraphim = { 'T3StrategicMissileDefense', 'GMSB402' },
}

-- Lanciamissili strategico OFFENSIVO (Fase H, sess.88, richiesta esplicita
-- utente): 'T3StrategicMissile' — token vanilla generico confermato in
-- BuildingTemplates.lua per tutte e 4 le fazioni (stessa famiglia di
-- T3StrategicMissileDefense sopra, diverso token). SOLO il vanilla per ora
-- (richiesta esplicita: "implementiamo solamente l'edificio tech tre che c'e'
-- per tutte quante le fazioni") — il MIRV (Cybran, Experimental, unita' unica
-- non simmetrica sulle altre fazioni) resta fuori, da affrontare come
-- discussione separata quando si decide come trattare un caso non simmetrico.
local StrategicMissilePoolT3 = {
    UEF      = { 'T3StrategicMissile' },
    Aeon     = { 'T3StrategicMissile' },
    Cybran   = { 'T3StrategicMissile' },
    Seraphim = { 'T3StrategicMissile' },
}

-- Slot bonus (Fase D-difese, sess.86): un ingegnere di tier N costruisce
-- occasionalmente una difesa modded di tier N-1 con "sapore" da esperimentale
-- (nome/icona 'Experimental' nel blueprint, ma meccanicamente lo stesso tier
-- normale — vedi intestazione file, verificato sul campo per BRNT1EXPD:
-- Description='Experimental Gatling Defense System', Categories=TECH1 puro).
-- Per bonus-a-T2 riusa le 4 varianti EXPD gia' nel pool T1 sopra (restano
-- DISPONIBILI anche li', non e' un'esclusiva — deciso esplicitamente in
-- sess.86). Per bonus-a-T3 riusa direttamente le varianti modded del pool T2
-- terra sopra (nessun pool nuovo dedicato, stesso principio "un tier sotto,
-- solo modded, mai vanilla" — gestito direttamente in OWPlusPickTierDefenses).
local OWPlusExperimentalFlavorT1 = {
    UEF      = 'brnt1expd',
    Aeon     = 'brot1expd',
    Cybran   = 'brmt1expd',
    Seraphim = 'brpt1expd',
}

-- Slot "sperimentale vero" T3 (sess.87): a differenza del bonus sopra (un
-- tier sotto, sempre flavor-text), questo SOSTITUISCE con piccola probabilita'
-- un singolo pick del pool terra T3 PRINCIPALE con un'unita' che e' davvero
-- TECH3 Experimental nel motore (Categories EXPERIMENTAL, TechLevel =
-- RULEUTL_Experimental, non solo testo in Description) — riservato a chi ce
-- l'ha in mod (oggi solo UEF/TotalMayhem, 'Perses'/BRNT3PERSES: 4 armi
-- separate, molto potente). Percentuale e meccanismo (sostituzione, non
-- aggiunta extra) decisi esplicitamente dall'utente dopo averlo notato "mai
-- costruito" pur essendo gia' presente nel catalogo mod.
local OWPlusTrueExperimentalT3 = {
    UEF = 'brnt3perses',
}
local OWPLUS_TRUE_EXPERIMENTAL_CHANCE = 0.1

-- Slot "sperimentale vero" per SCUDI e ARTIGLIERIA (Fase E, sess.88): stesso
-- principio di OWPlusTrueExperimentalT3/OWPLUS_TRUE_EXPERIMENTAL_CHANCE sopra
-- (Perses), ma con una LISTA di alternative per fazione invece di un singolo
-- ID — il catalogo ha rivelato piu' varianti Experimental per alcune fazioni
-- (es. scudo UEF: sia ExpShield_MK_II che il primo anello della catena
-- NuclearRepulsorShields). Quando la sostituzione scatta pesca a caso tra le
-- alternative disponibili. Tabelle e funzione SEPARATE da OWPlusTrueExperimentalT3/
-- OWPlusPickTierMainline sotto — quella logica e' gia' testata in game (sess.87,
-- confermato "costruito cinque Perses"), non la tocchiamo per non rischiarla.
--
-- Scudo Experimental: ExpShield_MK_II (tutte e 4 le fazioni, TechLevel Secret,
-- costo enorme 750k/60k, one-shot senza catena).
--
-- Fix Fase E (sess.88, correzione dell'utente durante il test): NuclearRepulsorShields
-- NON e' una catena unica MK1->MK2->MK3 come scritto qui in un primo momento —
-- verificato leggendo TUTTI e 12 i .bp (3 tier x 4 fazioni): il tier piu'
-- economico (qeb4408/qab4408/qrb4208/qsb4408, 150k/9k, "Village Shield" e
-- affini) NON ha ALCUN General.UpgradesTo, e' un vicolo cieco — l'upgrade-in-place
-- nativo non lo fara' MAI progredire. L'UNICO anello reale della catena e' il
-- tier centrale (qeb4409/qab4409/qrb4409/qsb4409, "City Shield" e affini,
-- 750k/45k) che ha General.UpgradesTo verso il tier piu' caro (qeb4410 ecc.,
-- 3.75M/225k) — quello si' progredisce da solo. Per Cybran il tier centrale ha
-- convenzione di ID diversa (qrb4208 non qrb4408, gia' notato quando aggiunto
-- a ShieldPoolT3 sopra come upgrade di urb4207). Entrambi i tier (economico
-- senza crescita + centrale con crescita reale verso il tetto) sono ora nel
-- pool: piu' varieta', e chi pesca il tier centrale ottiene la progressione
-- automatica per davvero invece che per un'assunzione sbagliata.
local OWPlusTrueExperimentalShieldT3 = {
    UEF      = { 'expshduef001', 'qeb4408', 'qeb4409' },
    Aeon     = { 'expshdaeon001', 'qab4408', 'qab4409' },
    Cybran   = { 'expshdcyb001', 'qrb4208', 'qrb4409' },
    Seraphim = { 'expshdser001', 'qsb4408', 'qsb4409' },
}
-- Artiglieria Experimental: Antares UEF (UEB2310, "Experimental Quad Cannon
-- Artillery Installation" — 8.25M energia/475k massa, il candidato piu' caro
-- trovato in assoluto, rarita' garantita dal costo oltre che dalla probabilita')
-- e Antares Seraphim (GMSB403). Aeon/Cybran: nessun candidato puro Experimental
-- trovato (Cybran ha GMRB302, TECH3+EXPERIMENTAL insieme, lasciata nel pool
-- normale ArtilleryPoolT3 sopra invece che qui, dato che porta comunque TECH3).
local OWPlusTrueExperimentalArtilleryT3 = {
    UEF      = { 'ueb2310' },
    Seraphim = { 'gmsb403' },
}

-- Ordine confermato in /lua/factions.lua vanilla ("the order here will determine
-- the faction index, it's the automatically assigned array index"): UEF=1, Aeon=2,
-- Cybran=3, Seraphim=4.
local FactionNames = { 'UEF', 'Aeon', 'Cybran', 'Seraphim' }

local function GetFactionName(aiBrain)
    local idx = aiBrain:GetFactionIndex()
    return FactionNames[idx] or 'UEF'
end

-- Fix sess.82 (richiesta esplicita utente: "limitare i punti di difesa
-- vanilla"): l'indice 1 di ogni array di pool e' SEMPRE il token vanilla
-- generico per convenzione (vedi GroundDefensePoolT1/AADefensePoolT1 sopra) —
-- gli indici successivi sono le varianti modded TotalMayhem. Invece di un pick
-- uniforme su tutta la lista (che dava al vanilla la stessa probabilita' di
-- ogni singola variante modded), il vanilla ha ora una probabilita' fissa
-- ridotta; il resto va alle varianti modded quando esistono per la fazione.
-- Se la fazione non ha varianti modded (es. AA per Aeon/Cybran/Seraphim), il
-- vanilla resta l'unica scelta possibile — comportamento invariato.
local OWPLUS_VANILLA_DEFENSE_CHANCE = 0.2

-- Fase D-difese (sess.86): riconosce il sentinel OWPLUS_NO_VANILLA all'indice
-- 1 (fazioni senza alcuna difesa vanilla a quel tier, es. T3 terra non-UEF) —
-- in quel caso sceglie sempre e solo tra le varianti modded (indici 2+),
-- niente diverso per il resto della logica. Comportamento con vanilla reale
-- all'indice 1 invariato rispetto a prima.
local function PickListFromPool(aiBrain, pool, count)
    local faction = GetFactionName(aiBrain)
    local options = pool[faction] or pool['UEF']
    local hasVanilla = options[1] ~= OWPLUS_NO_VANILLA
    -- Fix Fase E (sess.88): pool nuovi (artiglieria/scudi) possono avere ZERO
    -- candidati reali per una fazione (es. artiglieria T1 Aeon/Seraphim, nessuna
    -- unita' modded trovata in nessuna mod di riferimento) — in quel caso
    -- 'options' e' solo { OWPLUS_NO_VANILLA } (lunghezza 1, hasVanilla=false).
    -- Senza questa guardia il codice sotto cadrebbe comunque su
    -- 'pick = options[1]' = OWPLUS_NO_VANILLA (cioe' il booleano false) e lo
    -- inserirebbe in lista, propagandosi fino a IssueBuildMobile con un
    -- unitType inutilizzabile. Ritorna lista vuota invece di 'count' false.
    local realCount = table.getn(options)
    if not hasVanilla then
        realCount = realCount - 1
    end
    if realCount <= 0 then
        LOG('[OWPlus] OWPlusOutpostDefensePool: OK, pool vuoto per ' .. faction
            .. ' — nessun candidato reale, 0/' .. count .. ' pick')
        return {}
    end
    local list = {}
    local vanillaCount = 0
    for i = 1, count do
        local pick = options[1]
        if table.getn(options) > 1 and (not hasVanilla or Random(1, 100) > OWPLUS_VANILLA_DEFENSE_CHANCE * 100) then
            pick = options[Random(2, table.getn(options))]
        elseif hasVanilla then
            vanillaCount = vanillaCount + 1
        end
        table.insert(list, pick)
    end
    LOG('[OWPlus] OWPlusOutpostDefensePool: OK, pick pesato (' .. faction .. ') ' .. vanillaCount
        .. '/' .. count .. ' vanilla, ' .. (count - vanillaCount) .. '/' .. count .. ' modded')
    return list
end

-- Fase C: lista iniziale difese T1 per un nuovo avamposto — 3-7 point-defense
-- terra + 4-9 AA, pescati a caso (con ripetizione) dal pool vanilla+TotalMayhem
-- della fazione dell'aiBrain.
function OWPlusPickInitialOutpostDefenses(aiBrain)
    local groundCount = Random(3, 7)
    local aaCount = Random(4, 9)
    return {
        ground = PickListFromPool(aiBrain, GroundDefensePoolT1, groundCount),
        aa = PickListFromPool(aiBrain, AADefensePoolT1, aaCount),
    }
end

-- Fase D-difese (sess.86, PRIMA versione): lotto una tantum al tier-up,
-- range casuale fisso. SOSTITUITA (sess.86, stessa sessione) dal sistema a
-- tetto logaritmico crescente sotto — commentata come riferimento invece di
-- cancellata, stesso principio gia' seguito per OWPlusModdedUpgradeChain.
--[[
function OWPlusPickTierDefenses(aiBrain, tier)
    local groundPool, aaPool
    if tier >= 3 then
        groundPool, aaPool = GroundDefensePoolT3, AADefensePoolT3
    else
        groundPool, aaPool = GroundDefensePoolT2, AADefensePoolT2
    end
    local groundCount = Random(3, 7)
    local aaCount = Random(4, 9)
    local result = {
        ground = PickListFromPool(aiBrain, groundPool, groundCount),
        aa = PickListFromPool(aiBrain, aaPool, aaCount),
        bonus = {},
    }

    local faction = GetFactionName(aiBrain)
    local bonusCount = 2
    while Random(1, 100) <= 40 and bonusCount < 5 do
        bonusCount = bonusCount + 1
    end
    if tier == 2 then
        local bonusId = OWPlusExperimentalFlavorT1[faction]
        if bonusId then
            for i = 1, bonusCount do
                table.insert(result.bonus, bonusId)
            end
        end
    elseif tier >= 3 then
        local t2Options = GroundDefensePoolT2[faction] or GroundDefensePoolT2['UEF']
        if table.getn(t2Options) > 1 then
            for i = 1, bonusCount do
                table.insert(result.bonus, t2Options[Random(2, table.getn(t2Options))])
            end
        end
    end
    LOG('[OWPlus] OWPlusOutpostDefensePool: OK, lotto tier ' .. tier .. ' (' .. faction .. '): '
        .. table.getn(result.ground) .. ' terra, ' .. table.getn(result.aa) .. ' AA, '
        .. table.getn(result.bonus) .. ' bonus')
    return result
end
]]

-- Fase D-difese, crescita logaritmica (sess.86): tetto(t) = base +
-- floor(fattore * ln(1 + t/300)) — t in secondi dal timer del TIER ATTIVO
-- (fondazione per T1, ultimo tier-up per T2/T3 — vedi OWPlusOutpostTierTimer
-- in platoon.lua). Basi e fattori decisi esplicitamente dall'utente: T1 piu'
-- economico cresce piu' in fretta, T3 piu' costoso piu' lentamente, ma senza
-- scarti eccessivi (crescita logaritmica gia' di per se' auto-limitante).
-- Fix Fase F (sess.88, richiesta esplicita utente dopo test live: "troppe
-- difese... riportiamole ai tuoi valori originali, dividiamole per tre"):
-- tornati al target ORIGINALE 12/8/4 (terra o AA) a 60 minuti — quello
-- prima del ×3 a 36/24/12 documentato qui sotto. Stesso principio gia'
-- annotato: il fattore non scala linearmente col target per via di
-- floor()+base additiva, quindi i fattori sotto sono ricalcolati per
-- arrivare esattamente a 12/8/4 (verificato: 5+floor(3*ln(13))=12,
-- 3+floor(2*ln(13))=8, 2+floor(1*ln(13))=4), non semplicemente divisi per 3.
-- Solo terra/AA (richiesta esplicita "solo i punti di difesa") — scudi,
-- artiglieria, bonus e SMD restano ai valori di Fase E, invariati.
--
-- Cronologia precedente (per riferimento): fattori tarati per ottenere
-- 36/24/12 a 60 minuti (richiesta esplicita: valori precedenti "12/8/4"
-- moltiplicati - il fattore NON scala linearmente col risultato finale per
-- via di floor()+base additiva, quindi i fattori erano stati ricalcolati per
-- arrivare esattamente li', non semplicemente moltiplicati per 3).
local OWPLUS_TIER_DEFENSE_BASE = { [1] = 5, [2] = 3, [3] = 2 }
local OWPLUS_TIER_DEFENSE_FACTOR = { [1] = 3, [2] = 2, [3] = 1 }
-- Slot bonus: base invariata (2, decisa in sess.86 prima parte), fattore meta'
-- di quello del tier attivo — cresce anche lui ma piu' lentamente, resta un
-- bonus e non sorpassa mai il principale. Indicizzato per TIER ATTIVO (2 o 3
-- — non esiste bonus a tier 1, non c'e' un tier 0 sotto cui pescare).
local OWPLUS_BONUS_DEFENSE_BASE = 2
local OWPLUS_BONUS_DEFENSE_FACTOR = { [2] = 4, [3] = 2 }

-- Tetti scudi/artiglieria (Fase E, sess.88): stessa formula logaritmica sopra,
-- base/fattore PROPRI e piu' bassi (decisi esplicitamente dall'utente in fase
-- di brainstorming — "non 700000 [scudi] ma comunque presenti", "artiglieria
-- segue le regole dei tier gia' stabilite" inteso come STESSO MECCANISMO,
-- numeri propri dato il peso economico diverso da un singolo punto difesa).
-- Scudi: nessuna voce per tier 1 (niente scudi finche' l'avamposto non arriva
-- a T2, come il vanilla stesso). Target indicativi a 60min: T2 1->3, T3 1->4.
local OWPLUS_SHIELD_BASE = { [2] = 1, [3] = 1 }
local OWPLUS_SHIELD_FACTOR = { [2] = 1, [3] = 1.5 }
-- Artiglieria: presente da T1 (TotalMayhem ne aggiunge di modded a quel tier),
-- stessa forma a scalare di terra/AA (T1 > T2 > T3 nel fattore, tier piu' economico
-- cresce piu' in fretta). Target indicativi a 60min: T1 1->11, T2 1->8, T3 1->6.
local OWPLUS_ARTILLERY_BASE = { [1] = 1, [2] = 1, [3] = 1 }
local OWPLUS_ARTILLERY_FACTOR = { [1] = 4, [2] = 3, [3] = 2 }

-- Missile Difesa Tattica (Fase G, sess.88): stessa forma di crescita degli
-- scudi (nessuna voce a T1, solo da T2 in su) — mai un tetto T3 dedicato dato
-- che il token vanilla si ferma a T2, chi resta a T2Missiledefense anche a
-- T3 outpost e' comportamento corretto (non un tetto mancante). Stessi
-- numeri di base/fattore degli scudi T2 (1->3 a 60min), stesso ordine di
-- grandezza per una categoria "presente ma non invadente".
local OWPLUS_TACTICAL_MD_BASE = { [2] = 1, [3] = 1 }
local OWPLUS_TACTICAL_MD_FACTOR = { [2] = 1, [3] = 1 }

function OWPlusTierDefenseCap(base, factor, elapsedSeconds)
    if not elapsedSeconds or elapsedSeconds < 0 then
        elapsedSeconds = 0
    end
    return base + math.floor(factor * math.log(1 + elapsedSeconds / 300))
end

-- Ritorna i 3 tetti correnti (terra, AA, bonus) per il tier attivo di un
-- avamposto, dato da quanti secondi e' attivo quel tier. Funzione pura, non
-- tocca lo stato di gioco — la scansione fisica/il confronto/l'accodamento
-- vivono nel watcher in platoon.lua (basso accoppiamento, checklist punto 3).
function OWPlusGetTierDefenseTargets(tier, elapsedSeconds)
    local base = OWPLUS_TIER_DEFENSE_BASE[tier] or OWPLUS_TIER_DEFENSE_BASE[3]
    local factor = OWPLUS_TIER_DEFENSE_FACTOR[tier] or OWPLUS_TIER_DEFENSE_FACTOR[3]
    local groundTarget = OWPlusTierDefenseCap(base, factor, elapsedSeconds)
    local aaTarget = OWPlusTierDefenseCap(base, factor, elapsedSeconds)
    local bonusTarget = 0
    local bonusFactor = OWPLUS_BONUS_DEFENSE_FACTOR[tier]
    if bonusFactor then
        bonusTarget = OWPlusTierDefenseCap(OWPLUS_BONUS_DEFENSE_BASE, bonusFactor, elapsedSeconds)
    end
    -- Fase E (sess.88): scudi (0 a tier 1, nessuna voce in OWPLUS_SHIELD_BASE)
    -- e artiglieria (presente da tier 1) — stessa formula, tetti indipendenti.
    local shieldTarget = 0
    local shieldBase = OWPLUS_SHIELD_BASE[tier]
    local shieldFactor = OWPLUS_SHIELD_FACTOR[tier]
    if shieldBase and shieldFactor then
        shieldTarget = OWPlusTierDefenseCap(shieldBase, shieldFactor, elapsedSeconds)
    end
    local artilleryBase = OWPLUS_ARTILLERY_BASE[tier] or OWPLUS_ARTILLERY_BASE[3]
    local artilleryFactor = OWPLUS_ARTILLERY_FACTOR[tier] or OWPLUS_ARTILLERY_FACTOR[3]
    local artilleryTarget = OWPlusTierDefenseCap(artilleryBase, artilleryFactor, elapsedSeconds)
    -- Fase G (sess.88): Missile Difesa Tattica, stessa forma degli scudi (0 a
    -- tier 1).
    local tacticalMDTarget = 0
    local tacticalMDBase = OWPLUS_TACTICAL_MD_BASE[tier]
    local tacticalMDFactor = OWPLUS_TACTICAL_MD_FACTOR[tier]
    if tacticalMDBase and tacticalMDFactor then
        tacticalMDTarget = OWPlusTierDefenseCap(tacticalMDBase, tacticalMDFactor, elapsedSeconds)
    end
    return groundTarget, aaTarget, bonusTarget, shieldTarget, artilleryTarget, tacticalMDTarget
end

-- Pesca ESATTAMENTE 'count' difese principali (terra o AA) del tier dato dal
-- pool giusto — stesso PickListFromPool di sempre, solo con un conteggio
-- calcolato invece di un range casuale.
function OWPlusPickTierMainline(aiBrain, tier, groundCount, aaCount)
    local groundPool, aaPool
    if tier >= 3 then
        groundPool, aaPool = GroundDefensePoolT3, AADefensePoolT3
    elseif tier == 2 then
        groundPool, aaPool = GroundDefensePoolT2, AADefensePoolT2
    else
        groundPool, aaPool = GroundDefensePoolT1, AADefensePoolT1
    end
    local groundList = PickListFromPool(aiBrain, groundPool, groundCount)
    if tier >= 3 then
        local trueExpId = OWPlusTrueExperimentalT3[GetFactionName(aiBrain)]
        if trueExpId then
            local swapped = 0
            for i = 1, table.getn(groundList) do
                if Random(1, 100) <= OWPLUS_TRUE_EXPERIMENTAL_CHANCE * 100 then
                    groundList[i] = trueExpId
                    swapped = swapped + 1
                end
            end
            if swapped > 0 then
                LOG('[OWPlus] OWPlusOutpostDefensePool: OK, sostituiti ' .. swapped .. '/' .. groundCount
                    .. ' pick terra con sperimentale vero (' .. trueExpId .. ')')
            end
        end
    end
    return groundList, PickListFromPool(aiBrain, aaPool, aaCount)
end

-- Fix Fase E (sess.88): questa funzione DEVE stare dopo la dichiarazione di
-- GetFactionName sopra (non prima, come nel primo tentativo) — in Lua un
-- 'local function' successivo non e' visibile a una funzione gia' definita
-- prima nel file, la chiamata risolverebbe su una global inesistente (nil) e
-- crasherebbe al primo utilizzo reale (tier>=3). Stesso principio della
-- regola generale su ordine/scope degli identificatori non-locali.
local function OWPlusSubstituteExperimentalList(aiBrain, list, expTableByFaction, label)
    local options = expTableByFaction[GetFactionName(aiBrain)]
    if not options or table.getn(options) == 0 then
        return list
    end
    local swapped = 0
    for i = 1, table.getn(list) do
        if Random(1, 100) <= OWPLUS_TRUE_EXPERIMENTAL_CHANCE * 100 then
            list[i] = options[Random(1, table.getn(options))]
            swapped = swapped + 1
        end
    end
    if swapped > 0 then
        LOG('[OWPlus] OWPlusOutpostDefensePool: OK, sostituiti ' .. swapped .. ' pick ' .. label
            .. ' con variante Experimental vera')
    end
    return list
end

-- Pesca scudi e artiglieria per il tier attivo dato (Fase E, sess.88), stesso
-- schema di OWPlusPickTierMainline sopra: pool giusto per il tier, poi
-- sostituzione rara verso la variante Experimental (solo a tier>=3, tramite
-- OWPlusSubstituteExperimentalList). Gli scudi restano lista vuota sotto
-- tier 2 (nessun pool esiste per tier 1, vedi ShieldPoolT2/T3 sopra) — il
-- chiamante in platoon.lua passa comunque shieldCount=0 in quel caso dato che
-- OWPlusGetTierDefenseTargets gia' torna shieldTarget=0 a tier 1, questo e'
-- solo un secondo livello di sicurezza.
function OWPlusPickTierShieldArtillery(aiBrain, tier, shieldCount, artilleryCount)
    local shieldList = {}
    if shieldCount > 0 and tier >= 2 then
        local shieldPool = (tier >= 3) and ShieldPoolT3 or ShieldPoolT2
        shieldList = PickListFromPool(aiBrain, shieldPool, shieldCount)
        if tier >= 3 then
            shieldList = OWPlusSubstituteExperimentalList(aiBrain, shieldList, OWPlusTrueExperimentalShieldT3, 'scudo')
        end
    end

    local artilleryList = {}
    if artilleryCount > 0 then
        local artilleryPool = ArtilleryPoolT1
        if tier >= 3 then
            artilleryPool = ArtilleryPoolT3
        elseif tier == 2 then
            artilleryPool = ArtilleryPoolT2
        end
        artilleryList = PickListFromPool(aiBrain, artilleryPool, artilleryCount)
        if tier >= 3 then
            artilleryList = OWPlusSubstituteExperimentalList(aiBrain, artilleryList, OWPlusTrueExperimentalArtilleryT3, 'artiglieria')
        end
    end

    return shieldList, artilleryList
end

-- Missile Difesa Tattica (Fase G, sess.88): pool piatto, nessuna sostituzione
-- Experimental (non ne esiste una modded nota) — stesso schema minimale di
-- OWPlusPickSMD sotto.
function OWPlusPickTacticalMissileDefense(aiBrain, tier, count)
    if count <= 0 or tier < 2 then
        return {}
    end
    return PickListFromPool(aiBrain, TacticalMissileDefensePoolT2, count)
end

-- SMD (Fase E, sess.88): a differenza di tutte le altre categorie NON e' un
-- pool a crescita nel tempo — e' un tiro unico fatto una sola volta quando
-- l'avamposto raggiunge tier 3 (deciso esplicitamente dall'utente: "il numero
-- resta quello per il resto della partita"). Distribuzione pesata verso il
-- basso invece di un Random(0,3) piatto, MA resa piu' generosa in Fase G
-- (sess.88, richiesta esplicita utente dopo test live: "più SMD" — solo la
-- distribuzione, il meccanismo a tiro unico resta invariato). Originale
-- (Fase E): 30/40/20/10. Nuova: 10% zero, 35% uno, 35% due, 20% tre — zero
-- molto piu' raro (era lo spreco piu' fastidioso), due e tre molto piu'
-- probabili. platoon.lua e' responsabile di chiamare questa funzione UNA
-- SOLA VOLTA per avamposto (flag dedicato, vedi watcher).
function OWPlusRollSMDCount()
    local roll = Random(1, 100)
    local count
    if roll <= 10 then
        count = 0
    elseif roll <= 45 then
        count = 1
    elseif roll <= 80 then
        count = 2
    else
        count = 3
    end
    LOG('[OWPlus] OWPlusOutpostDefensePool: OK, tiro SMD (roll=' .. roll .. '/100) -> ' .. count .. ' antimissili strategici')
    return count
end

function OWPlusPickSMD(aiBrain, count)
    if count <= 0 then
        return {}
    end
    return PickListFromPool(aiBrain, SMDPoolT3, count)
end

-- Lanciamissili strategico (Fase H, sess.88): stesso principio dell'SMD sopra
-- (tiro unico a tier 3, mai ripetuto — deciso esplicitamente dall'utente
-- "un po' come l'antimissile strategico"), ma range 0-4 invece di 0-3 e
-- distribuzione CENTRATA invece che pesata verso il basso (richiesta
-- esplicita: "probabilita' piu' centrali... scegli te"). Pesi proporzionali
-- ai coefficienti binomiali di grado 4 (1-4-6-4-1, su 16) — la forma "a
-- campana" piu' naturale per un range discreto di 5 valori, 2 e' il piu'
-- probabile (37.5%), 0 e 4 i piu' rari (6.25% ciascuno) in modo simmetrico.
function OWPlusRollStrategicMissileCount()
    local roll = Random(1, 100)
    local count
    if roll <= 6 then
        count = 0
    elseif roll <= 31 then
        count = 1
    elseif roll <= 69 then
        count = 2
    elseif roll <= 94 then
        count = 3
    else
        count = 4
    end
    LOG('[OWPlus] OWPlusOutpostDefensePool: OK, tiro lanciamissili strategico (roll=' .. roll .. '/100) -> ' .. count .. ' lanciamissili')
    return count
end

function OWPlusPickStrategicMissile(aiBrain, count)
    if count <= 0 then
        return {}
    end
    return PickListFromPool(aiBrain, StrategicMissilePoolT3, count)
end

-- Elenco (minuscolo) degli ID che contano come "bonus" per il tier attivo
-- dato — usato sia per pescare nuove difese bonus sia dal watcher in
-- platoon.lua per CONTARE quante ne esistono gia' vicino all'avamposto
-- (stessa lista, cosi' pick e conteggio non possono mai disallinearsi).
function OWPlusGetBonusIdList(aiBrain, tier)
    local faction = GetFactionName(aiBrain)
    local ids = {}
    if tier == 2 then
        local id = OWPlusExperimentalFlavorT1[faction]
        if id then table.insert(ids, string.lower(id)) end
    elseif tier >= 3 then
        local t2Options = GroundDefensePoolT2[faction] or GroundDefensePoolT2['UEF']
        for i = 2, table.getn(t2Options) do
            table.insert(ids, string.lower(t2Options[i]))
        end
    end
    return ids
end

-- Pesca 'count' difese bonus per il tier attivo dato (vuoto se il tier non ha
-- slot bonus, es. tier 1). Per tier==3 pesca indipendentemente ad ogni
-- istanza tra le varianti modded T2 terra, per varieta'.
function OWPlusPickBonusDefenses(aiBrain, tier, count)
    local ids = OWPlusGetBonusIdList(aiBrain, tier)
    local result = {}
    if table.getn(ids) == 0 then
        return result
    end
    for i = 1, count do
        table.insert(result, ids[Random(1, table.getn(ids))])
    end
    return result
end

-- Fase C: stringa generica per un upgrade difesa a un tier >1 (dopo reclaim).
-- Vedi nota in testa al file sul limite T3 lato terra.
function OWPlusPickUpgradeDefense(aiBrain, tier, isAA)
    if isAA then
        if tier >= 3 then
            return 'T3AADefense'
        elseif tier == 2 then
            return 'T2AADefense'
        end
        return 'T1AADefense'
    end
    if tier >= 2 then
        return 'T2GroundDefense'
    end
    return 'T1GroundDefense'
end

-- Fase C (B16), sess.81: mappa MK1 -> MK2 delle difese TotalMayhem. Le difese T1
-- modded (Mayor/Thug/Coyote/Pen) sono costruibili SOLO da un ingegnere T1
-- (verificato in game: uel0208/uel0309 danno CanBuild=false sulla base MK1). Ogni
-- MK1 ha pero' una versione potenziata MK2 (UpgradesTo nel .bp) che gli ingegneri
-- T2/T3 SANNO costruire. Cosi' un ingegnere di tier alto costruisce direttamente
-- la MK2 invece di sprecare pick sulla MK1 che non puo' fare. UEF e Cybran hanno
-- la catena; Aeon e Seraphim no (nessun UpgradesTo nei loro .bp). Chiavi in
-- minuscolo (match con string.lower(unitType), come le chiavi di __blueprints).
--
-- Fase D-difese (sess.86): sostituita da una lettura generica del blueprint a
-- runtime (vedi OWPlusModdedUpgradeFor sotto) — qualunque difesa, nota oggi o
-- aggiunta in futuro (nostra o di terzi), con General.UpgradesTo compilato nel
-- .bp viene raccolta automaticamente, zero manutenzione di una lista scritta a
-- mano. Tabella COMMENTATA (non cancellata) come riferimento/fallback: se
-- un'unita' futura non usa questo campo standard per il proprio upgrade, si
-- torna a un caso esplicito come questi invece del meccanismo generico.
--[[
local OWPlusModdedUpgradeChain = {
    brnt1expd = 'brnt1expdt2',   -- Mayor  MK1 -> MK2 (UEF)
    brnt1hpd  = 'brnt1hpdt2',    -- Thug   MK1 -> MK2 (UEF)
    brmt1pd   = 'brmt1pdt2',     -- Coyote MK1 -> MK2 (Cybran)
    brmt1expd = 'brmt1expdt2',   -- Pen    MK1 -> MK2 (Cybran)
}
]]

-- Ritorna l'ID (minuscolo) della versione potenziata di una difesa modded (da
-- General.UpgradesTo nel blueprint), o nil se l'unita' non ha upgrade. baseId
-- puo' essere in qualsiasi case. Verificato sul campo reale (sess.86): Mayor
-- MK1 (brnt1expd) ha General.UpgradesTo='brnt1expdt2' nel .bp.
--
-- Fix bug reale (sess.86, stesso test): un'unita' SENZA UpgradesTo nel proprio
-- .bp (es. KEB2201, #Marlos, nessuna catena) risultava comunque
-- General.UpgradesTo='' (stringa vuota) A RUNTIME — probabile default
-- ereditato dallo schema base del motore per le unita' che non lo
-- sovrascrivono. '' e' truthy in Lua: il controllo 'bp.General.UpgradesTo'
-- da solo tornava un valore "vero" per QUALUNQUE unita', sostituendo l'ID con
-- una stringa vuota e rompendo la build in silenzio (confermato in game: zero
-- difese T2/T3 modded nuove costruite, log "sostituita MK1 (...) con MK2 ()"
-- — parentesi vuote). Serve escludere esplicitamente la stringa vuota, non
-- solo nil/false.
function OWPlusModdedUpgradeFor(baseId)
    local bp = __blueprints and __blueprints[string.lower(tostring(baseId))]
    local target = bp and bp.General and bp.General.UpgradesTo
    if target and target ~= '' then
        return target
    end
    return nil
end

-- ===========================================================================
-- Sess.102 (decisione utente 2026-10-16): difese delle BASI NAVALI con la stessa formula e gli
-- stessi pool degli avamposti (OWPlusGetTierDefenseTargets + PickListFromPool: 20% vanilla,
-- resto moddate). Al posto delle difese di terra: le antinave. Censimento dai blueprint
-- (ANTINAVY / arma principale 'Anti Navy', costruibili da ingegnere; Nomadi esclusi):
--   T1: torpediniere vanilla + 'Anti-Navy Defense' Total Mayhem (4 fazioni)
--   T2: solo torpediniere vanilla (nessuna moddata)
--   T3: vanilla solo Cybran (xrb2308); #Marlos 'Heavy Naval Artillery Bunker' (4 fazioni, sulla
--       costa), BattlePack WEB0404 (UEF, in acqua), Antares/BattlePack WSB2308 (Seraphim)
-- Alcune vanno in acqua, altre sulla costa: il posto lo sceglie OWPlusFindNavalDefenseSpot
-- (OWPlusNavalCatalog.lua) con CanBuildStructureAt sul pezzo scelto.
-- ===========================================================================
local NavalDefensePoolT1 = {
    UEF      = { 'T1NavalDefense', 'BRNT1ADVNAVYGUN' },
    Aeon     = { 'T1NavalDefense', 'BROT1ADVNAVYGUN' },
    Cybran   = { 'T1NavalDefense', 'BRMT1ADVNAVYGUN' },
    Seraphim = { 'T1NavalDefense', 'BRPT1ADVNAVYGUN' },
}
local NavalDefensePoolT2 = {
    UEF      = { 'T2NavalDefense' },
    Aeon     = { 'T2NavalDefense' },
    Cybran   = { 'T2NavalDefense' },
    Seraphim = { 'T2NavalDefense' },
}
local NavalDefensePoolT3 = {
    UEF      = { OWPLUS_NO_VANILLA, 'KEB2301', 'WEB0404' },
    Aeon     = { OWPLUS_NO_VANILLA, 'KAB2301' },
    Cybran   = { 'T3NavalDefense', 'KRB2301' },
    Seraphim = { OWPLUS_NO_VANILLA, 'KSB2301', 'WSB2308' },
}

local OWPlusNavalBasePools = {
    antinavy = { NavalDefensePoolT1, NavalDefensePoolT2, NavalDefensePoolT3 },
    aa       = { AADefensePoolT1, AADefensePoolT2, AADefensePoolT3 },
    shield   = { nil, ShieldPoolT2, ShieldPoolT3 },
}

-- Una difesa per la base navale: token vanilla (es. 'T2NavalDefense') o ID moddato, oppure nil
-- se a quel tier il tipo non ha candidati (scudi a T1).
function OWPlusPickNavalBaseDefense(aiBrain, kind, tier)
    local pools = OWPlusNavalBasePools[kind]
    local pool = pools and pools[tier]
    if not pool then
        return nil
    end
    local list = PickListFromPool(aiBrain, pool, 1)
    return list[1]
end
