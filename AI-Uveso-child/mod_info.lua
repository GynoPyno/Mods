name         = "AI-Uveso Child Mod — OverwhelmPlus"
uid          = "5615da14-328a-442c-baf1-fd68916cd0b0"
version      = 1
copyright    = "2026 Matteo"
description  = "Aggiunge la personalità OverwhelmPlus: miglioramento di Uveso Overwhelm con progressione tech, unità mod, avamposti e fix economia."
author       = "Matteo"
url          = ""
selectable   = true
enabled      = true
exclusive    = false
ui_only      = false

requires = {
    "62e2j64a-AIUV-116-89465-146as555a8u3",  -- AI-Uveso
}
requiresNames = {
    ["62e2j64a-AIUV-116-89465-146as555a8u3"] = "AI-Uveso",
}
conflicts = {}
before = {}
after = {
    "62e2j64a-AIUV-116-89465-146as555a8u3",  -- carica DOPO AI-Uveso
}
