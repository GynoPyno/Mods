local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local WeaponFile = import('/lua/sim/defaultweapons.lua')
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local CollisionBeamFile = import('/lua/defaultcollisionbeams.lua')

local SCUStyleDeathWeapon = ClassWeapon(BareBonesWeapon) {
    OnFire = function(self) end,
    Fire = function(self)
        local bp = self:GetBlueprint()
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:PassDamageData(self:GetDamageTable())
    end,
}

local CDFMicrowaveLaserGenerator = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam02,
    FxMuzzleFlash = {},
}

CT4_PD2 = Class(CStructureUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(SCUStyleDeathWeapon) {},
        MainGun     = ClassWeapon(CDFMicrowaveLaserGenerator) { FxMuzzleFlash = {} },
    },
}

TypeClass = CT4_PD2
