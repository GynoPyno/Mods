-- Nuovi PlatoonTemplate per la spinta offensiva terra "a batching" (sess.100,
-- vedi 'OWPlus Land Attack Batching.lua' per il BuilderGroup che li usa).
-- Alzano le taglie minime rispetto ai template nativi Uveso in
-- 'AI-Uveso/lua/AI/PlatoonTemplates/Uveso PlatoonTemplates Land.lua', cosi'
-- il motore nativo (che forma un plotone appena raggiunto il minimo) aspetta
-- un gruppo numeroso prima di partire, invece di 1-2 unita' (streaming).
--
-- Nota: 2 dei 5 Builder toccati riusano il template nativo gia' esistente
-- 'LandAttackHuntUveso 10 10' (identico alla taglia 10-10 voluta) - nessun
-- bisogno di duplicarlo qui, vedi 'OWPlus Land Attack Batching.lua'.

if not categories.STEALTHFIELD then categories.STEALTHFIELD = categories.SHIELD end

-- Sostituisce 'LandAttackHuntUveso 15 30' sul Builder 'Enemy Intercept'
-- (la spinta offensiva principale) - GlobalSquads identico all'originale,
-- solo min/max alzati.
PlatoonTemplate {
    Name = 'OWPlusLandAttackHunt 30 40',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.SHIELD - categories.STEALTHFIELD - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT - categories.COMMAND - categories.SUBCOMMANDER, 30, 40, 'Attack', 'none' },
        { categories.MOBILE * (categories.SHIELD + categories.STEALTHFIELD) - categories.ANTIAIR - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT - categories.COMMAND - categories.SUBCOMMANDER - categories.TRANSPORTFOCUS, 0, 7, 'support', 'none' }
    }
}

-- Sostituisce 'LandAttackHuntUveso Arty 1 20' sul Builder 'AntiDef+mex Early'
-- (caccia artiglieria contro difese/estrattori nemici) - stesso filtro
-- INDIRECTFIRE dell'originale, solo min alzato da 1 a 15.
PlatoonTemplate {
    Name = 'OWPlusLandAttackHunt Arty 15 20',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND * categories.INDIRECTFIRE - categories.SHIELD - categories.STEALTHFIELD - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT - categories.COMMAND - categories.SUBCOMMANDER, 15, 20, 'Attack', 'none' },
    }
}

-- Sostituisce 'LandAttackHuntUveso 6 8' sul Builder 'AntiMass Early'
-- (attacco a massa/difese nemiche) - stesso filtro generico dell'originale,
-- solo min/max alzati.
PlatoonTemplate {
    Name = 'OWPlusLandAttackHunt 20 25',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.SHIELD - categories.STEALTHFIELD - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT - categories.COMMAND - categories.SUBCOMMANDER, 20, 25, 'Attack', 'none' },
    }
}

-- Sess.100 parte 13 (decisione utente): plotoni di MAIN per FASCIA DI VELOCITA'.
-- Le categorie 'OWPLUSSPEED<n>' le assegna hook/lua/system/Blueprints.lua da
-- Physics.MaxSpeed (fascia 1 = la piu' lenta). Per ogni fascia n:
--   'OWPlusLandAttackHunt S<n> 30 40'  grande (solo fascia n)
--   'OWPlusLandAttackHunt S<n> 20 30'  medio  (solo fascia n)
--   'OWPlusLandAttackHunt S<n>+ 20 30' ripiego (fascia n + fascia n+1, se esiste)
-- Stesso filtro e supporto scudi di 'OWPlusLandAttackHunt 30 40'; anche gli scudi
-- mobili sono limitati alla fascia, altrimenti rallenterebbero il plotone.
-- Quante fasce esistono lo dice il motore (categories['OWPLUSSPEED'..n] ~= nil).
local OWPlusLandBandAttackCategory = categories.MOBILE * categories.LAND - categories.SHIELD - categories.STEALTHFIELD - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT - categories.COMMAND - categories.SUBCOMMANDER
local OWPlusLandBandSupportCategory = categories.MOBILE * (categories.SHIELD + categories.STEALTHFIELD) - categories.ANTIAIR - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT - categories.COMMAND - categories.SUBCOMMANDER - categories.TRANSPORTFOCUS

local function OWPlusLandBandTemplate(name, bandCategory, minSize, maxSize)
    PlatoonTemplate {
        Name = name,
        Plan = 'HeroFightPlatoon',
        GlobalSquads = {
            { OWPlusLandBandAttackCategory * bandCategory, minSize, maxSize, 'Attack', 'none' },
            { OWPlusLandBandSupportCategory * bandCategory, 0, 7, 'support', 'none' }
        }
    }
end

local owplusBandCount = 0
while categories['OWPLUSSPEED' .. (owplusBandCount + 1)] do
    owplusBandCount = owplusBandCount + 1
end
for band = 1, owplusBandCount do
    local bandCategory = categories['OWPLUSSPEED' .. band]
    OWPlusLandBandTemplate('OWPlusLandAttackHunt S' .. band .. ' 30 40', bandCategory, 30, 40)
    OWPlusLandBandTemplate('OWPlusLandAttackHunt S' .. band .. ' 20 30', bandCategory, 20, 30)
    if band < owplusBandCount then
        OWPlusLandBandTemplate('OWPlusLandAttackHunt S' .. band .. '+ 20 30', bandCategory + categories['OWPLUSSPEED' .. (band + 1)], 20, 30)
    end
end
if owplusBandCount == 0 then
    WARN('[OWPlus-SPEEDBAND] PlatoonTemplates: nessuna categoria OWPLUSSPEED<n> trovata (hook Blueprints.lua non eseguito?): template a fasce NON creati')
else
    LOG('[OWPlus-SPEEDBAND] PlatoonTemplates: OK, creati i template di ' .. owplusBandCount .. ' fasce di velocita\' (grande 30-40, medio 20-30, ripiego 20-30)')
end

-- Sess.100 parte 3: rush early-game di MAIN ('OWPlus Land T1 Rush 3 6' in
-- OWPlus Formers.lua) - stesso filtro di 'LandAttackInterceptUveso 2 3',
-- min/max alzati a 3-6 per evitare plotoni da 1-2 unita'.
PlatoonTemplate {
    Name = 'OWPlusLandAttackIntercept 3 6',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.SHIELD - categories.STEALTHFIELD - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT - categories.COMMAND - categories.SUBCOMMANDER, 3, 6, 'Attack', 'none' },
    }
}
