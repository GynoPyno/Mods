#****************************************************************************
#**
#**  File     :  /cdimage/units/XSOW1103/XSOW1103_script.lua
#**
#**  Summary  :  Seraphim Frigate Script: XSOW1103
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SAAShleoCannonWeapon = import('/lua/seraphimweapons.lua').SAAShleoCannonWeapon
local SDFUltraChromaticBeamGenerator = import('/Mods/OrbitalWarsMod/hook/lua/seraphweapons.lua').SDFUltraChromaticBeamGenerator
local SDFHeavyQuarnon01Cannon = import('/Mods/OrbitalWarsMod/hook/lua/seraphweapons.lua').SDFHeavyQuarnon01Cannon

XSOW1103 = Class(SAirUnit) {
	DestroyNoFallRandomChance = 1.1,
	
    Weapons = {
        MainGun = Class(SDFUltraChromaticBeamGenerator) {},
        AAGun = Class(SAAShleoCannonWeapon) {},
		AntiVaisseaux = Class(SDFHeavyQuarnon01Cannon) {},
    },
	
    OnStopBeingBuilt = function(self,builder,layer)
	local army = self:GetArmy()
        SAirUnit.OnStopBeingBuilt(self,builder,layer)
		self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_06_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_05_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_04_emit.bp'):OffsetEmitter( 0, 0, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_03_emit.bp'):OffsetEmitter( 0, -2, 0 ))
		self.Trash:Add(CreateAttachedEmitter(self, 'Effect01', army, '/effects/emitters/seraphim_gate_02_emit.bp'):OffsetEmitter( 0, -2, 0 ))
        self.Trash:Add(CreateRotator(self, 'Rotator01', 'z', nil, 50, 0, 50))
    end,		
	
}
TypeClass = XSOW1103
