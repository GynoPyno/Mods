-- OWPlus PlatoonTemplates SACU.lua
-- Template per l'utilizzo dei Sub-Commandos (SACU) come ingegneri potenziati.
-- I SACU hanno build rate ~3x rispetto ai T3 engineer.
-- ManagerEngineerAssistAI: SACU assiste l'ingegnere che sta costruendo il bersaglio.
-- ManagerEngineerBuildAI:  SACU avvia direttamente la costruzione di un'unità.

PlatoonTemplate {
    Name = 'SACUEngineerAssist',
    Plan = 'ManagerEngineerAssistAI',
    GlobalSquads = {
        { categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'SACUEngineerBuilder',
    Plan = 'ManagerEngineerBuildAI',
    GlobalSquads = {
        { categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}
