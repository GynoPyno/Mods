#****************************************************************************
#**
#**  File     :  /units/UAOW1102/UAOW1102_script.lua
#**  Author(s):  John Comes Modified by Asdrubaelvect
#**
#**  Summary  :  UAOW1102 Anti Spaceship
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit

local WeaponsFile = import ('/lua/aeonweapons.lua')
local ADFPhasonLaser = WeaponsFile.ADFPhasonLaser
local AAAAutocannonQuantumWeapon = import('/lua/aeonweapons.lua').AAALightDisplacementAutocannonMissileWeapon
local ACruiseMissileWeapon = import('/lua/aeonweapons.lua').ACruiseMissileWeapon
local fxutil = import('/lua/effectutilities.lua')

UAOW1102 = Class(AAirUnit) {
	DestroyNoFallRandomChance = 1.1,
    Weapons = {
        
		AutoCannon01 = Class(AAAAutocannonQuantumWeapon) {},
		AutoCannon02 = Class(AAAAutocannonQuantumWeapon) {},
		AutoCannon03 = Class(AAAAutocannonQuantumWeapon) {},
		AutoCannon04 = Class(AAAAutocannonQuantumWeapon) {},
		AutoCannon05 = Class(AAAAutocannonQuantumWeapon) {},
		
		EyeWeapon = Class(ADFPhasonLaser) {},
		EyeWeapon02 = Class(ADFPhasonLaser) {},
		
		CruiseMissile = Class(ACruiseMissileWeapon) {},
  },
  
     OnStopBeingBuilt = function(self,builder,layer)
        AAirUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateRotator(self, 'Rot01', 'z', nil, -100, 0, -100))
        self.Trash:Add(CreateRotator(self, 'Rot02', 'z', nil, -100, 0, -100))
        self.Trash:Add(CreateRotator(self, 'Rot03', 'z', nil, -100, 0, -100))
    end,	

    MovementAmbientExhaustBones = {
        'Exhaust01',
        'Exhaust02',
		 'Exhaust03',
        'Exhaust04',
		 'Exhaust05',
        'Exhaust06',

    },
	
	
    OnMotionHorzEventChange = function(self, new, old )
		AAirUnit.OnMotionHorzEventChange(self, new, old)
	
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
				'/effects/emitters/aeon_serp_flash_02_emit.bp',
				'/effects/emitters/aeon_serp_flash_03_emit.bp',	
			}
			local ExhaustBeam = '/effects/emitters/aeon_nuke_exhaust_beam_01_emit.bp'
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

TypeClass = UAOW1102

