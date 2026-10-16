-- OWPlus Outpost Engineer Builders.lua
-- Fase A (B16 - Avamposti autonomi): ingegneri propri per ogni avamposto (OUT#),
-- indipendenti dal pool ingegneri di MAIN.
--
-- Un builder per tier (T1/T2/T3): si attiva SOLO su un LocationType riconosciuto
-- come avamposto (OWPlusIsOutpostLocation, popolato in platoon.lua al momento
-- della registrazione della prima fabbrica, 9-F19/20) E la cui fabbrica e'
-- ESATTAMENTE al tier di quel builder (OWPlusOutpostFactoryIsTech) — quando la
-- fabbrica sale di tier, il builder del tier precedente smette di produrre da
-- solo (nessun HaveLessThanUnitsWithCategory globale necessario, a differenza
-- di NoT3Factory in OWPlus Engineer Builders.lua: qui lo scoping e' gia'
-- per-location). Gli ingegneri del tier superato vengono riassorbiti ad assist
-- permanente da un watcher dedicato in platoon.lua, non da questo file.
--
-- Cap: 5 ingegneri per tier (OWPlusDebugEngineersLessAtLocation, mappa
-- ownership per-avamposto — Fase H sess.93, sostituisce PoolLessAtLocation/
-- ArmyPool: quel conteggio aveva gia' mostrato disallineamenti col reale,
-- vedi commento sess.78 in OWPlusLogConditions.lua).
--
-- Priorita' crescenti per tier (sess.74): con priorita' identica (18700 per
-- tutti e tre), in caso di sovrapposizione della cache condizioni
-- (ConditionsMonitor, fino a ~7s di ritardo — vedi Conoscenze_AI_34/35) T2 e
-- T3 potevano risultare ENTRAMBI validi per una finestra breve subito dopo un
-- upgrade, e GetHighestBuilder (motore, BuilderManager.lua) spezza i pareggi
-- di priorita' A CASO — osservato in game: la fabbrica costruiva T3, poi T2,
-- poi T3 di nuovo, alternando invece di restare sul tier corretto. Dando ad
-- ogni tier una priorita' leggermente piu' alta del precedente, un eventuale
-- doppio-vero non e' piu' un pareggio: vince sempre il tier piu' alto.
--
-- Fix sess.91 (bug reale trovato in game: ingegneri T3 quasi mai costruiti
-- nonostante fabbrica e condizioni sempre idonee): +1000 su tutti e tre i
-- valori. Causa: 'OWPlus Outpost Production.lua' (stessa coda FactoryBuilder,
-- stessa fabbrica) usa PriorityFunction = BASE + Random(1, 1000) per
-- competere tra i propri candidati — il margine di soli 30 punti verso gli
-- Engineer (18670/80/90 vs 18700/10/20) viene sommerso dal roll random di
-- Production in ~970 casi su 1000 (Random(1,1000) > 30). Gli ingegneri
-- vincevano solo in early game, quando il gate 'OWPlusDebugEngineersAtLeast'
-- teneva Production bloccata del tutto. +1000 supera il tetto massimo
-- possibile del roll di Production (BASE+1000), garantendo che l'ingegnere
-- vinca SEMPRE quando le sue condizioni sono vere, senza toccare la
-- randomizzazione tra candidati Production stessi.

local categories = categories
-- UCBC (UnitCountBuildConditions) rimosso temporaneamente (sess.72): le condizioni
-- PoolLessAtLocation/LocationFactoriesBuildingLess passano ora dai wrapper
-- diagnostici OWPlusDebug* in OWPlusLogConditions.lua, da rimettere dirette a
-- diagnosi completata.
local OWPlusLogCond = '/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua'

local MAX_OUTPOST_ENGINEERS = 5

BuilderGroup {
    BuilderGroupName = 'OWPlus Outpost Engineer Builders',
    BuildersType = 'FactoryBuilder',

    Builder {
        BuilderName = 'OWPlus Outpost Engineer T1',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 19700,
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusOutpostFactoryIsTech', { 'LocationType', 1 } },
            { OWPlusLogCond, 'OWPlusFactoryNotUpgrading', { 'LocationType', 'Engineer T1' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersLessAtLocation', { 'LocationType', MAX_OUTPOST_ENGINEERS, categories.TECH1, 'Engineer T1' } },
            { OWPlusLogCond, 'OWPlusDebugLocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH1, 'Engineer T1' } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus Outpost Engineer T2',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 19710,
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusOutpostFactoryIsTech', { 'LocationType', 2 } },
            { OWPlusLogCond, 'OWPlusFactoryNotUpgrading', { 'LocationType', 'Engineer T2' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersLessAtLocation', { 'LocationType', MAX_OUTPOST_ENGINEERS, categories.TECH2, 'Engineer T2' } },
            { OWPlusLogCond, 'OWPlusDebugLocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH2, 'Engineer T2' } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'OWPlus Outpost Engineer T3',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 19720,
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusOutpostFactoryIsTech', { 'LocationType', 3 } },
            { OWPlusLogCond, 'OWPlusFactoryNotUpgrading', { 'LocationType', 'Engineer T3' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersLessAtLocation', { 'LocationType', MAX_OUTPOST_ENGINEERS, categories.TECH3, 'Engineer T3' } },
            { OWPlusLogCond, 'OWPlusDebugLocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH3, 'Engineer T3' } },
        },
        BuilderType = 'Land',
    },

    -- Sess.102: avamposti NAVALI. I cantieri costruiscono ingegneri (BuildableCategory
    -- 'MOBILE CONSTRUCTION' del tier): stessi tre builder con BuilderType 'Sea', cosi' i builder
    -- di terra restano identici per gli avamposti di terra. Stesse condizioni: la fabbrica
    -- tracciata dell'avamposto navale e' il suo cantiere.
    Builder {
        BuilderName = 'OWPlus Outpost Engineer T1 Sea',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 19700,
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusOutpostFactoryIsTech', { 'LocationType', 1 } },
            { OWPlusLogCond, 'OWPlusFactoryNotUpgrading', { 'LocationType', 'Engineer T1 Sea' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersLessAtLocation', { 'LocationType', MAX_OUTPOST_ENGINEERS, categories.TECH1, 'Engineer T1 Sea' } },
            { OWPlusLogCond, 'OWPlusDebugLocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH1, 'Engineer T1 Sea' } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'OWPlus Outpost Engineer T2 Sea',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 19710,
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusOutpostFactoryIsTech', { 'LocationType', 2 } },
            { OWPlusLogCond, 'OWPlusFactoryNotUpgrading', { 'LocationType', 'Engineer T2 Sea' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersLessAtLocation', { 'LocationType', MAX_OUTPOST_ENGINEERS, categories.TECH2, 'Engineer T2 Sea' } },
            { OWPlusLogCond, 'OWPlusDebugLocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH2, 'Engineer T2 Sea' } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'OWPlus Outpost Engineer T3 Sea',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 19720,
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusOutpostFactoryIsTech', { 'LocationType', 3 } },
            { OWPlusLogCond, 'OWPlusFactoryNotUpgrading', { 'LocationType', 'Engineer T3 Sea' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersLessAtLocation', { 'LocationType', MAX_OUTPOST_ENGINEERS, categories.TECH3, 'Engineer T3 Sea' } },
            { OWPlusLogCond, 'OWPlusDebugLocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH3, 'Engineer T3 Sea' } },
        },
        BuilderType = 'Sea',
    },
}

LOG('[OWPlus-NAVAL] OWPlus Outpost Engineer Builders: OK, registrati 3 builder ingegneri di terra + 3 dai cantieri (avamposti navali)')
