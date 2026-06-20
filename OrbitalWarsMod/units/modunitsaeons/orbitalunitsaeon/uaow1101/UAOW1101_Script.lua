#****************************************************************************
#**
#**  File     :  /units/UAOW1101/UAOW1101_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  UAOW1101 eon spaceship UAOW1101
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local AAATemporalFizzWeapon = import('/Mods/OrbitalWarsMod/hook/lua/modweapons.lua').AAATemporalFizzWeapon
local AIFMissileTacticalSerpentineWeapon = import('/lua/aeonweapons.lua').AIFMissileTacticalSerpentineWeapon
local WeaponsFile = import('/Mods/OrbitalWarsMod/hook/lua/modweapons.lua')
local ADFCannonOblivion01Weapon = WeaponsFile.ADFCannonOblivion01Weapon
local fxutil = import('/lua/effectutilities.lua')


UAOW1101 = Class(AAirUnit) {

    DestroyNoFallRandomChance = 1.1,

    Weapons = {
        FirtGun = Class(AAATemporalFizzWeapon) {
            ChargeEffectMuzzles = {'TirLeger01', 'TirLeger02', 'TirLeger03', 'TirLeger04', 'TirLeger05', 'TirLeger06', 'TirLeger07'},
            PlayFxRackSalvoChargeSequence = function(self)
               AAATemporalFizzWeapon.PlayFxRackSalvoChargeSequence(self)
				self.Trash:Add(CreateAttachedEmitter( self.unit, 'TirLeger01', self.unit:GetArmy(), '/effects/emitters/temporal_fizz_muzzle_charge_02_emit.bp'))
				self.Trash:Add(CreateAttachedEmitter( self.unit, 'TirLeger02', self.unit:GetArmy(), '/effects/emitters/temporal_fizz_muzzle_charge_03_emit.bp'))
				self.Trash:Add(CreateAttachedEmitter( self.unit, 'TirLeger03', self.unit:GetArmy(), '/effects/emitters/temporal_fizz_muzzle_charge_02_emit.bp'))
				self.Trash:Add(CreateAttachedEmitter( self.unit, 'TirLeger04', self.unit:GetArmy(), '/effects/emitters/temporal_fizz_muzzle_charge_03_emit.bp'))
				self.Trash:Add(CreateAttachedEmitter( self.unit, 'TirLeger05', self.unit:GetArmy(), '/effects/emitters/temporal_fizz_muzzle_charge_02_emit.bp'))
				self.Trash:Add(CreateAttachedEmitter( self.unit, 'TirLeger06', self.unit:GetArmy(), '/effects/emitters/temporal_fizz_muzzle_charge_03_emit.bp'))
				self.Trash:Add(CreateAttachedEmitter( self.unit, 'TirLeger07', self.unit:GetArmy(), '/effects/emitters/temporal_fizz_muzzle_charge_03_emit.bp'))
            end,
        },
		SecondGun = Class(AIFMissileTacticalSerpentineWeapon) {},
		MainGun = Class(ADFCannonOblivion01Weapon) {
		FxMuzzleFlashScale = 2.5,
		},
	},
	
    OnStopBeingBuilt = function(self,builder,layer)
        AAirUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateRotator(self, 'Rot01', 'z', nil, -190, 0, -190))
        self.Trash:Add(CreateRotator(self, 'Rot02', 'z', nil, -190, 0, -190))
        self.Trash:Add(CreateRotator(self, 'Rot03', 'z', nil, -190, 0, -190))
		self.Trash:Add(CreateRotator(self, 'Rot04', 'z', nil, -190, 0, -190))
    end,		
	
    MovementAmbientExhaustBones = {
        'Exhaust01',
        'Exhaust02',
		'Exhaust03',
		'Exhaust04',
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

TypeClass = UAOW1101