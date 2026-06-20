#****************************************************************************
#**
#**  File     :  /cdimage/units/URO1101/URO1101_script.lua
#**  Author(s):  David Tomandl, Jessica St. Croix
#**					Modified By Asdrubaelvect
#**  Summary  :  Cybran Anti Spaceships Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CAirUnit = import('/lua/cybranunits.lua').CAirUnit

local CDFParticleCannonWeapon = import('/lua/cybranweapons.lua').CDFParticleCannonWeapon
local CAAMissileNaniteWeapon = import('/lua/cybranweapons.lua').CAAMissileNaniteWeapon
local CDFHeavyElectronBolter01Weapon = import('/Mods/OrbitalWarsMod/hook/lua/modweapons.lua').CDFHeavyElectronBolter01Weapon

local fxutil = import('/lua/effectutilities.lua')
local Effects = import('/lua/effecttemplates.lua')

UROW1102 = Class(CAirUnit) {
	DestroyNoFallRandomChance = 1.1,
    Weapons = {
		LateralGaucheGun01 = Class(CDFParticleCannonWeapon) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },
		LateralGaucheGun02 = Class(CDFParticleCannonWeapon) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },
		LateralGaucheGun03 = Class(CDFParticleCannonWeapon) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },
		LateralGaucheGun04 = Class(CDFParticleCannonWeapon) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },
		LateralDroitGun05 = Class(CDFParticleCannonWeapon) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },
		LateralDroitGun06 = Class(CDFParticleCannonWeapon) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },
		LateralDroitGun07 = Class(CDFParticleCannonWeapon) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },
		LateralDroitGun08 = Class(CDFParticleCannonWeapon) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },	
		
		 Missile01 = Class(CAAMissileNaniteWeapon) {},
		 Missile02 = Class(CAAMissileNaniteWeapon) {},
		 Missile03 = Class(CAAMissileNaniteWeapon) {},
		 
		AntiSpaceShipsGun = Class(CDFHeavyElectronBolter01Weapon) {
			FxMuzzleFlashScale = 1.5,
		},		
				
	},
	

    MovementAmbientExhaustBones = {
		'Reacteur02',
		'Reacteur01',
    },

    OnMotionHorzEventChange = function(self, new, old )
		CAirUnit.OnMotionHorzEventChange(self, new, old)
	
		if self.ThrustExhaustTT1 == nil then 
			if self.MovementAmbientExhaustEffectsBag then
				fxutil.CleanupEffectBag(self,'MovementAmbientExhaustEffectsBag')
			else
				self.MovementAmbientExhaustEffectsBag = {}
			end
			self.ThrustExhaustTT1 = self:ForkThread(self.MovementAmbientExhaustThread)
		end
		
        if new == 'Stopped' and self.ThrustExhaustTT1 ~= nil then
			KillThread(self.ThrustExhaustTT1)
			fxutil.CleanupEffectBag(self,'MovementAmbientExhaustEffectsBag')
			self.ThrustExhaustTT1 = nil
        end		 
    end,
    
    MovementAmbientExhaustThread = function(self)
		while not self.Dead do
			local ExhaustEffects = {
				'/effects/emitters/missile_cruise_munition_trail_01_emit.bp',
				--'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',	
			}
			local ExhaustBeam = '/Mods/OrbitalWarsMod/hook/effects/emitters/cybran_missile_exhaust_fire_beam_13_emit.bp'
						--'/Mods/OrbitalWarsMod/hook/effects/emitters/cybran_missile_exhaust_fire_beam_11_emit.bp'
			local army = self:GetArmy()			
			
			for kE, vE in ExhaustEffects do
				for kB, vB in self.MovementAmbientExhaustBones do
					table.insert( self.MovementAmbientExhaustEffectsBag, CreateAttachedEmitter(self, vB, army, vE ))
					table.insert( self.MovementAmbientExhaustEffectsBag, CreateBeamEmitterOnEntity( self, vB, army, ExhaustBeam ))
				end
			end
			
			WaitSeconds(5)
			fxutil.CleanupEffectBag(self,'MovementAmbientExhaustEffectsBag')
		end	
    end,		
}

TypeClass = UROW1102