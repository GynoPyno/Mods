local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local AIFQuantumWarhead = import('/lua/aeonweapons.lua').AIFQuantumWarhead
local ACUDeathWeapon = import('/lua/sim/defaultweapons.lua').ACUDeathWeapon

GMAB407 = Class(AStructureUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(ACUDeathWeapon) {},
        NukeMissiles = ClassWeapon(AIFQuantumWarhead) {},
    },
}
TypeClass = GMAB407
