#****************************************************************************
#**
#**  File     :  /cdimage/units/XSS0103/XSS0103_script.lua
#**
#**  Summary  :  Seraphim Frigate Script: XSS0103
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SDFUltraChromaticBeamGenerator = import('/lua/seraphimweapons.lua').SDFUltraChromaticBeamGenerator
local SAAOlarisCannonWeapon = SeraphimWeapons.SAAOlarisCannonWeapon
local SDFOverChargeWeapon = SeraphimWeapons.SDFChronotronCannonWeapon

XSOW1102 = Class(SAirUnit) {

	DestroyNoFallRandomChance = 1.1,
    Weapons = {
		HeavyGun01 = Class(SDFUltraChromaticBeamGenerator) {},
		HeavyGun02 = Class(SDFUltraChromaticBeamGenerator) {},
		HeavyGun03 = Class(SDFUltraChromaticBeamGenerator) {},
		HeavyGun04 = Class(SDFUltraChromaticBeamGenerator) {},
		
		AntiAir01 = Class(SAAOlarisCannonWeapon) {},
		AntiAir02 = Class(SAAOlarisCannonWeapon) {},
		AntiAir03 = Class(SAAOlarisCannonWeapon) {},
		AntiAir04 = Class(SAAOlarisCannonWeapon) {},
		AntiAir05 = Class(SAAOlarisCannonWeapon) {},
		AntiAir06 = Class(SAAOlarisCannonWeapon) {},
		
		AirLandWeapon01 = Class(SDFOverChargeWeapon) {},
		AirLandWeapon02 = Class(SDFOverChargeWeapon) {},
		AirLandWeapon03 = Class(SDFOverChargeWeapon) {},
		AirLandWeapon04 = Class(SDFOverChargeWeapon) {},
		AirLandWeapon05 = Class(SDFOverChargeWeapon) {},
    },
	
    OnStopBeingBuilt = function(self,builder,layer)
	local army = self:GetArmy()
        SAirUnit.OnStopBeingBuilt(self,builder,layer)
		self.Trash:Add(CreateAttachedEmitter(self, 'Pod01', army, '/effects/emitters/seraphim_gate_06_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Pod01', army, '/effects/emitters/seraphim_gate_05_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Pod01', army, '/effects/emitters/seraphim_gate_04_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Pod01', army, '/effects/emitters/seraphim_gate_03_emit.bp'):OffsetEmitter( 0, -2, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Pod01', army, '/effects/emitters/seraphim_gate_02_emit.bp'):OffsetEmitter( 0, -2, 0 ))
		
		self.Trash:Add(CreateAttachedEmitter(self, 'Object06', army, '/effects/emitters/seraphim_gate_06_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Object06', army, '/effects/emitters/seraphim_gate_05_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Object06', army, '/effects/emitters/seraphim_gate_04_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Object06', army, '/effects/emitters/seraphim_gate_03_emit.bp'):OffsetEmitter( 0, -2, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Object06', army, '/effects/emitters/seraphim_gate_02_emit.bp'):OffsetEmitter( 0, -2, 0 ))
		
		self.Trash:Add(CreateAttachedEmitter(self, 'Object04', army, '/effects/emitters/seraphim_gate_06_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Object04', army, '/effects/emitters/seraphim_gate_05_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Object04', army, '/effects/emitters/seraphim_gate_04_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Object04', army, '/effects/emitters/seraphim_gate_03_emit.bp'):OffsetEmitter( 0, -2, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Object04', army, '/effects/emitters/seraphim_gate_02_emit.bp'):OffsetEmitter( 0, -2, 0 ))
		
        self.Trash:Add(CreateRotator(self, 'Pod01', 'z', nil, 50, 0, 50))
		self.Trash:Add(CreateRotator(self, 'Pod02', 'z', nil, 80, 0, 80))
		self.Trash:Add(CreateRotator(self, 'Pod03', 'z', nil, 80, 0, 80))
		self.Trash:Add(CreateRotator(self, 'Pod04', 'z', nil, -130, 0, -130))
		self.Trash:Add(CreateRotator(self, 'Pod05', 'z', nil, -130, 0, -130))
    end,		
	
}
TypeClass = XSOW1102
