#****************************************************************************
#**
#**  File     :  /cdimage/units/XSOW1101/XSOW1101_script.lua
#**
#**  Summary  :  Seraphim Frigate Script: XSS0103
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SAAShleoCannonWeapon = SeraphimWeapons.SAAShleoCannonWeapon
local SDFUltraChromaticBeamGenerator = import('/Mods/OrbitalWarsMod/hook/lua/seraphweapons.lua').SDFUltraChromaticBeamGenerator

XSOW1101 = Class(SAirUnit) {
	DestroyNoFallRandomChance = 1.1,
	
    Weapons = {
        SonicPulseBattery01 = Class(SAAShleoCannonWeapon) {},
		SonicPulseBattery02 = Class(SAAShleoCannonWeapon) {},
		SonicPulseBattery03 = Class(SAAShleoCannonWeapon) {},
		SonicPulseBattery04 = Class(SAAShleoCannonWeapon) {},
		SonicPulseBattery05 = Class(SAAShleoCannonWeapon) {},
		SonicPulseBattery06 = Class(SAAShleoCannonWeapon) {},
		
		ASGun = Class(SDFUltraChromaticBeamGenerator) {},
    },
	
    OnStopBeingBuilt = function(self,builder,layer)
	local army = self:GetArmy()
        SAirUnit.OnStopBeingBuilt(self,builder,layer)
		self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_06_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_05_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_04_emit.bp'):OffsetEmitter( 0, 0, 0 ))
	    self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_03_emit.bp'):OffsetEmitter( 0, -2, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_02_emit.bp'):OffsetEmitter( 0, -2, 0 ))
		
        self.Trash:Add(CreateRotator(self, 'Pod01', 'z', nil, 120, 0, 120))
    end,		
	
}
TypeClass = XSOW1101
