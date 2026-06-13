local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local BareBonesWeapon = import('/lua/sim/defaultweapons.lua').BareBonesWeapon
local WeaponsFile = import('/lua/terranweapons.lua')
local TDFLandGaussCannonWeapon = WeaponsFile.TDFLandGaussCannonWeapon

local OriginalMainGun = UEB2310 and UEB2310.Weapons and UEB2310.Weapons.MainGun
local BaseWeapon = OriginalMainGun or TDFLandGaussCannonWeapon

local SCUStyleDeathWeapon = ClassWeapon(BareBonesWeapon) {
    OnFire = function(self) end,
    Fire = function(self)
        local bp = self:GetBlueprint()
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:PassDamageData(self:GetDamageTable())
    end,
}

UEB2310 = Class(TStructureUnit) {

    OnCreate = function(self, spec)
        TStructureUnit.OnCreate(self, spec)
    end,

    Weapons = {
        MainGun = ClassWeapon(BaseWeapon) {
            OnCreate = function(self)
                BaseWeapon.OnCreate(self)
            end,
        },
        DeathWeapon = ClassWeapon(SCUStyleDeathWeapon) {},
    },
}

TypeClass = UEB2310
