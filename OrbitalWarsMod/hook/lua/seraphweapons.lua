#****************************************************************************
#**
#**  File     :  /Mods/OrbitalWarsMod/hook/lua/modseraphweapons.lua
#**  Author(s):  Greg Kohne, Gordon Duclos, 
#**              Matt Vainio, Aaron Lundquist, Dru Staltman, Jessica St. Croix
#**
#**  Summary  :  Default definitions of Seraphim weapons
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local CollisionBeamFile = import('/lua/defaultcollisionbeams.lua')
local CollisionBeams = import('/lua/defaultcollisionbeams.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local Explosion = import('/lua/defaultexplosions.lua')
local Util = import('/lua/utilities.lua')

local DisruptorBeamCollisionBeam = CollisionBeamFile.DisruptorBeamCollisionBeam
local QuantumBeamGeneratorCollisionBeam = CollisionBeamFile.QuantumBeamGeneratorCollisionBeam
local PhasonLaserCollisionBeam = CollisionBeamFile.PhasonLaserCollisionBeam
local TractorClawCollisionBeam = CollisionBeamFile.TractorClawCollisionBeam
local KamikazeWeapon = WeaponFile.KamikazeWeapon
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local GinsuCollisionBeam = CollisionBeams.GinsuCollisionBeam


SDFHeavyQuarnon01Cannon = Class(DefaultProjectileWeapon) {
	FxMuzzleFlash = EffectTemplate.SHeavyQuarnonCannonMuzzleFlash,
}

SDFUltraChromaticBeamGenerator = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.UnstablePhasonLaserCollisionBeam,
	FxBeamTypeScale = 0.1,
    FxMuzzleFlash = {},
	FxMuzzleFlashScale = 0.1,
    FxChargeMuzzleFlash = {},
	FxChargeMuzzleFlashScale = 0.1,
    FxUpackingChargeEffects = EffectTemplate.SChargeUltraChromaticBeamGenerator,
    FxUpackingChargeEffectScale = 0.1,
    FxChargeMuzzleFlashScale = 0.1,
	ChargeEffectMuzzlesScale = 0.1,

    PlayFxWeaponUnpackSequence = function( self )
        if not self.ContBeamOn then
            local army = self.unit:GetArmy()
            local bp = self:GetBlueprint()
            for k, v in self.FxUpackingChargeEffects do
                for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, ev, army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

