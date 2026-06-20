
local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local CIFBombNeutronWeapon = import('/lua/cybranweapons.lua').CIFBombNeutronWeapon
local CAANanoDartWeapon = import('/lua/cybranweapons.lua').CAANanoDartWeapon
local fxutil = import('/lua/effectutilities.lua')

UROW1103 = Class(CAirUnit) {
	DestroyNoFallRandomChance = 1.1,

	Weapons = {
		Bomb01 = Class(CIFBombNeutronWeapon) {},
		Bomb02 = Class(CIFBombNeutronWeapon) {},
		Bomb03 = Class(CIFBombNeutronWeapon) {},
		Bomb04 = Class(CIFBombNeutronWeapon) {},
		
		AAGun01 = Class(CAANanoDartWeapon) {},
		AAGun02 = Class(CAANanoDartWeapon) {},
		AAGun03 = Class(CAANanoDartWeapon) {},
		AAGun04 = Class(CAANanoDartWeapon) {},
	},

    MovementAmbientExhaustBones = {
		'Reacteur02',
		'Reacteur01',
		'Reacteur03',
		'Reacteur04',		
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
			local ExhaustBeam = '/Mods/OrbitalWarsMod/hook/effects/emitters/cybran_missile_exhaust_fire_beam_11_emit.bp'
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

TypeClass = UROW1103
