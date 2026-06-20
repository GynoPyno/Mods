--[[#######################################################################
#  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#######################################################################]]--
local SAirFactoryUnit = import('/lua/seraphimunits.lua').SAirFactoryUnit


XSB0402 = Class(SAirFactoryUnit) {
    RollOffBones = { 'Pod01', 'Pod02', },

    OnStopBeingBuilt = function(self,builder,layer)
	local army = self:GetArmy()
        SAirFactoryUnit.OnStopBeingBuilt(self,builder,layer)

        self.Trash:Add(CreateRotator(self, 'Pod01', 'z', nil, 50, 0, 50))
		self.Trash:Add(CreateRotator(self, 'Pod02', 'z', nil, -50, 0, -50))
		self.Trash:Add(CreateRotator(self, 'Pod03', 'z', nil, 50, 0, 50))
		self.Trash:Add(CreateRotator(self, 'Pod04', 'z', nil, -50, 0, -50))
    end,

}

TypeClass = XSB0402