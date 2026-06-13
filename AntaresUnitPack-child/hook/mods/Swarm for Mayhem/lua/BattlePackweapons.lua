-- Stub per compatibilita' con Antares Unit Pack (WRL2466b) quando Swarm for Mayhem non e' installata.
-- EXCEMPArrayBeam01 e' sostituita con DefaultBeamWeapon come fallback neutro.
local DefaultBeamWeapon = import('/lua/sim/defaultweapons.lua').DefaultBeamWeapon
EXCEMPArrayBeam01 = DefaultBeamWeapon
