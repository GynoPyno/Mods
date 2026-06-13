-- Compat globali per Antares Unit Pack (UELB0401) — richiesti dallo script originale
-- TIFCommanderDeathWeapon: rimosso da FAF, ora e' ACUDeathWeapon in /lua/sim/defaultweapons.lua
TIFCommanderDeathWeapon = import('/lua/sim/defaultweapons.lua').ACUDeathWeapon

-- Toggled: usato come pseudo-commento con ####Toggled nello script originale (invalido in FAF strict mode)
Toggled = 0
