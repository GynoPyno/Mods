-- Hook GSMB319: il file originale Antares crasha in FAF moderno perche'
-- SIFCommanderDeathWeapon non e' accessibile via modulo (stesso bug di GMAB407/AIFCommanderDeathWeapon).
-- Questo hook ridefinisce la classe da zero con import corretti.
local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SIFExperimentalStrategicMissile = import('/lua/seraphimweapons.lua').SIFExperimentalStrategicMissile
local ACUDeathWeapon = import('/lua/sim/defaultweapons.lua').ACUDeathWeapon

GSMB319 = Class(SStructureUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(ACUDeathWeapon) {},
        InainoMIRVMissile = ClassWeapon(SIFExperimentalStrategicMissile) {},
    },
}
TypeClass = GSMB319
