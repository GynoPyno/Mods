-- Fix TBU1000: tutte le armi usavano Class(...) invece di ClassWeapon(...) — non compatibile con FAF.
-- La DeathWeapon non si agganciava al C++ → no despawn alla morte.
-- MissileRack01 rotto → tutti i missili sparavano insieme (C++ fallback) invece di ciclare MuzzleSalvoSize=1.

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TSAMLauncher   = import('/lua/terranweapons.lua').TSAMLauncher

local BareBonesWeapon = import('/lua/sim/defaultweapons.lua').BareBonesWeapon

local SCUStyleDeathWeapon = ClassWeapon(BareBonesWeapon) {
    OnFire = function(self) end,
    Fire = function(self)
        local bp = self:GetBlueprint()
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:PassDamageData(self:GetDamageTable())
    end,
}

TBU1000 = Class(TStructureUnit) {
    Weapons = {
        MissileRack01 = ClassWeapon(TSAMLauncher) {},
        DeathWeapon   = ClassWeapon(SCUStyleDeathWeapon) {},
    },
}

TypeClass = TBU1000
