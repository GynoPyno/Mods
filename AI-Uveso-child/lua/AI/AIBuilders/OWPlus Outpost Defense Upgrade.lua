-- OWPlus Outpost Defense Upgrade.lua
-- Fase C (B16 - Avamposti autonomi), sess.83: upgrade NATIVO in-place (1:1,
-- nessun duplicato) delle difese modded TotalMayhem con una versione MK2 nota
-- (Mayor/Thug UEF, Coyote/Pen Cybran — General.UpgradesTo nel .bp).
--
-- Perche' esiste (root cause dei due problemi segnalati dall'utente in game,
-- sess.82-83): (1) il nostro sistema a coda custom (build/reclaim in
-- platoon.lua) usava reclaim+ricostruzione per l'upgrade MK1->MK2 — un
-- meccanismo pensato per unita' SENZA upgrade nativo, che per queste 4
-- famiglie era inutilmente complesso (possibile finestra scoperta durante il
-- reclaim) quando esiste gia' un meccanismo in-place pulito, identico a
-- quello delle fabbriche (vedi OWPlus Outpost Factory Upgrade.lua, stesso
-- pattern PlatoonFormBuilder+UnitUpgradeAI). (2) il vecchio scan one-shot al
-- tier-up (in platoon.lua) perdeva le difese ancora in costruzione/in pausa
-- per risorse nell'istante esatto dello scan — non venivano mai piu'
-- ricontrollate. Questo BuilderGroup e' invece rivalutato di continuo dal
-- ciclo nativo di Uveso (PlatoonFormManager, ~5s), quindi trova anche le
-- difese che finiscono di costruirsi DOPO un qualunque evento — nessuno scan
-- one-shot necessario per queste 4 famiglie.
--
-- Difese vanilla generiche (T1GroundDefense/T1AADefense, senza UpgradesTo nel
-- .bp — verificato, nessun meccanismo nativo disponibile) restano gestite dal
-- sistema a coda in platoon.lua, invariato.

local categories = categories
local OWPlusLogCond = '/mods/AI-Uveso-child/lua/AI/OWPlusLogConditions.lua'

-- Stessa soglia storage di 'OWPlus Outpost Factory Upgrade.lua' (Fase B) —
-- coerenza con l'unica altra soglia economica gia' tarata per gli avamposti.
-- Nota: a differenza del reclaim custom rimosso, qui non c'e' MAI una finestra
-- "vecchia difesa gia' distrutta, nuova non ancora costruita" — l'upgrade
-- nativo trasforma la STESSA entita' in-place, quindi l'avamposto non resta
-- mai scoperto durante l'attesa economica.
local OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO = 0.15
local OUTPOST_DEFENSE_UPGRADE_INSTANCE_COUNT = 1

-- Fix sess.91 (richiesta esplicita utente): stesso tetto gia' usato come cap
-- massimo in 'OWPlus Outpost Engineer Builders.lua' (MAX_OUTPOST_ENGINEERS),
-- qui riusato come SOGLIA MINIMA prima di autorizzare l'upgrade difese.
local OUTPOST_DEFENSE_UPGRADE_MIN_ENGINEERS = 5

BuilderGroup {
    BuilderGroupName = 'OWPlus Outpost Defense Upgrade',
    BuildersType = 'PlatoonFormBuilder',

    Builder {
        BuilderName = 'OWPlus Outpost Defense Upgrade Mayor',
        PlatoonTemplate = 'OWPlusMayorUpgrade',
        Priority = 18400,
        InstanceCount = OUTPOST_DEFENSE_UPGRADE_INSTANCE_COUNT,
        FormRadius = 40,
        -- Sess.103: senza questo il piano non riceve la base (PlatoonData.LocationType nil)
        BuilderData = { LocationType = 'LocationType' },
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusDebugNoDefenseUpgradeInProgress', { 'LocationType', 'Defense Upgrade Mayor' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersAtLeast', { 'LocationType', OUTPOST_DEFENSE_UPGRADE_MIN_ENGINEERS, 'Defense Upgrade Mayor' } },
            { OWPlusLogCond, 'OWPlusDebugEconStorageRatio', { OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, 'Defense Upgrade Mayor' } },
            { OWPlusLogCond, 'OWPlusDefenseUpgradeCandidateExists', { 'LocationType', 'brnt1expd', 'Defense Upgrade Mayor' } },
            { OWPlusLogCond, 'OWPlusClaimDefenseUpgrade', { 'LocationType', 'brnt1expd', 'OWPlus Outpost Defense Upgrade Mayor' } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Outpost Defense Upgrade Thug',
        PlatoonTemplate = 'OWPlusThugUpgrade',
        Priority = 18400,
        InstanceCount = OUTPOST_DEFENSE_UPGRADE_INSTANCE_COUNT,
        FormRadius = 40,
        -- Sess.103: senza questo il piano non riceve la base (PlatoonData.LocationType nil)
        BuilderData = { LocationType = 'LocationType' },
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusDebugNoDefenseUpgradeInProgress', { 'LocationType', 'Defense Upgrade Thug' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersAtLeast', { 'LocationType', OUTPOST_DEFENSE_UPGRADE_MIN_ENGINEERS, 'Defense Upgrade Thug' } },
            { OWPlusLogCond, 'OWPlusDebugEconStorageRatio', { OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, 'Defense Upgrade Thug' } },
            { OWPlusLogCond, 'OWPlusDefenseUpgradeCandidateExists', { 'LocationType', 'brnt1hpd', 'Defense Upgrade Thug' } },
            { OWPlusLogCond, 'OWPlusClaimDefenseUpgrade', { 'LocationType', 'brnt1hpd', 'OWPlus Outpost Defense Upgrade Thug' } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Outpost Defense Upgrade Coyote',
        PlatoonTemplate = 'OWPlusCoyoteUpgrade',
        Priority = 18400,
        InstanceCount = OUTPOST_DEFENSE_UPGRADE_INSTANCE_COUNT,
        FormRadius = 40,
        -- Sess.103: senza questo il piano non riceve la base (PlatoonData.LocationType nil)
        BuilderData = { LocationType = 'LocationType' },
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusDebugNoDefenseUpgradeInProgress', { 'LocationType', 'Defense Upgrade Coyote' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersAtLeast', { 'LocationType', OUTPOST_DEFENSE_UPGRADE_MIN_ENGINEERS, 'Defense Upgrade Coyote' } },
            { OWPlusLogCond, 'OWPlusDebugEconStorageRatio', { OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, 'Defense Upgrade Coyote' } },
            { OWPlusLogCond, 'OWPlusDefenseUpgradeCandidateExists', { 'LocationType', 'brmt1pd', 'Defense Upgrade Coyote' } },
            { OWPlusLogCond, 'OWPlusClaimDefenseUpgrade', { 'LocationType', 'brmt1pd', 'OWPlus Outpost Defense Upgrade Coyote' } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'OWPlus Outpost Defense Upgrade Pen',
        PlatoonTemplate = 'OWPlusPenUpgrade',
        Priority = 18400,
        InstanceCount = OUTPOST_DEFENSE_UPGRADE_INSTANCE_COUNT,
        FormRadius = 40,
        -- Sess.103: senza questo il piano non riceve la base (PlatoonData.LocationType nil)
        BuilderData = { LocationType = 'LocationType' },
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusDebugNoDefenseUpgradeInProgress', { 'LocationType', 'Defense Upgrade Pen' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersAtLeast', { 'LocationType', OUTPOST_DEFENSE_UPGRADE_MIN_ENGINEERS, 'Defense Upgrade Pen' } },
            { OWPlusLogCond, 'OWPlusDebugEconStorageRatio', { OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, 'Defense Upgrade Pen' } },
            { OWPlusLogCond, 'OWPlusDefenseUpgradeCandidateExists', { 'LocationType', 'brmt1expd', 'Defense Upgrade Pen' } },
            { OWPlusLogCond, 'OWPlusClaimDefenseUpgrade', { 'LocationType', 'brmt1expd', 'OWPlus Outpost Defense Upgrade Pen' } },
        },
        BuilderType = 'Any',
    },
    -- Fix Fase F (sess.88): Tower Boss (BRNT2EPD T2->T3) — vedi nota nel file
    -- PlatoonTemplate per il perche' mancava. Stesso identico pattern dei 4
    -- Builder sopra, stesse funzioni condizione generiche (parametrizzate per
    -- ID), solo l'ID e il nome cambiano.
    Builder {
        BuilderName = 'OWPlus Outpost Defense Upgrade Tower Boss',
        PlatoonTemplate = 'OWPlusTowerBossUpgrade',
        Priority = 18400,
        InstanceCount = OUTPOST_DEFENSE_UPGRADE_INSTANCE_COUNT,
        FormRadius = 40,
        -- Sess.103: senza questo il piano non riceve la base (PlatoonData.LocationType nil)
        BuilderData = { LocationType = 'LocationType' },
        BuilderConditions = {
            { OWPlusLogCond, 'OWPlusIsOutpostLocation', { 'LocationType' } },
            { OWPlusLogCond, 'OWPlusDebugNoDefenseUpgradeInProgress', { 'LocationType', 'Defense Upgrade Tower Boss' } },
            { OWPlusLogCond, 'OWPlusDebugEngineersAtLeast', { 'LocationType', OUTPOST_DEFENSE_UPGRADE_MIN_ENGINEERS, 'Defense Upgrade Tower Boss' } },
            { OWPlusLogCond, 'OWPlusDebugEconStorageRatio', { OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, OUTPOST_DEFENSE_UPGRADE_STORAGE_RATIO, 'Defense Upgrade Tower Boss' } },
            { OWPlusLogCond, 'OWPlusDefenseUpgradeCandidateExists', { 'LocationType', 'brnt2epd', 'Defense Upgrade Tower Boss' } },
            { OWPlusLogCond, 'OWPlusClaimDefenseUpgrade', { 'LocationType', 'brnt2epd', 'OWPlus Outpost Defense Upgrade Tower Boss' } },
        },
        BuilderType = 'Any',
    },
}
