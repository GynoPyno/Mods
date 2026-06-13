-- Stub locale di BattlePackweapons per Antares WRL2466b (Storm Strider).
-- Fornisce EXCEMPArrayBeam01 come fallback neutro quando Swarm for Mayhem non e' installata.
-- Il hook WRL2466b_Script.lua sovrascrive comunque EXTargetPainter con ClassWeapon().
local DefaultBeamWeapon = import('/lua/sim/defaultweapons.lua').DefaultBeamWeapon
EXCEMPArrayBeam01 = DefaultBeamWeapon
