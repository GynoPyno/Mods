-- Fix GEB2401: tutte le armi usavano Class(...) invece di ClassWeapon(...) — non compatibile con FAF.
-- La DeathWeapon non si agganciava al C++, l'unità non despawnava alla morte.

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local WeaponsFile    = import('/lua/terranweapons.lua')
local TDFGaussCannonWeapon = WeaponsFile.TDFGaussCannonWeapon
local TSAMLauncher         = WeaponsFile.TSAMLauncher
local TAMPhalanxWeapon     = WeaponsFile.TAMPhalanxWeapon

local BareBonesWeapon = import('/lua/sim/defaultweapons.lua').BareBonesWeapon

local SCUStyleDeathWeapon = ClassWeapon(BareBonesWeapon) {
    OnFire = function(self) end,
    Fire = function(self)
        local bp = self:GetBlueprint()
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:PassDamageData(self:GetDamageTable())
    end,
}

GEB2401 = Class(TStructureUnit) {
    Weapons = {
        MainGun     = ClassWeapon(TDFGaussCannonWeapon) {},
        MissileRack = ClassWeapon(TSAMLauncher) {},
        Turret      = ClassWeapon(TAMPhalanxWeapon) {
            PlayFxWeaponUnpackSequence = function(self)
                if not self.SpinManip then
                    self.SpinManip = CreateRotator(self.unit, 'TMD_Rotator', 'z', nil, 270, 180, 60)
                    self.unit.Trash:Add(self.SpinManip)
                end
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(270)
                end
                TAMPhalanxWeapon.PlayFxWeaponUnpackSequence(self)
            end,
            PlayFxWeaponPackSequence = function(self)
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(0)
                end
                TAMPhalanxWeapon.PlayFxWeaponPackSequence(self)
            end,
        },
        DeathWeapon = ClassWeapon(SCUStyleDeathWeapon) {},
    },
}

TypeClass = GEB2401
