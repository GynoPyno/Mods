#****************************************************************************
#**
#**  File     :  /data/projectiles/AIFGuidedMissile01/AIFGuidedMissile01_script.lua
#**  Author(s):  Matt Vainio, Gordon Duclos
#**
#**  Summary  :  Aeon Guided Missile, DAA0206
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AGuidedMissileProjectile = import('/lua/aeonprojectiles.lua').AGuidedMissileProjectile
local RandF = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFGuidedMissile = Class(AGuidedMissileProjectile) {
    OnCreate = function(self)
		AGuidedMissileProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.MovementTurnLevel = 1
        self:ForkThread( self.MovementThread )
    end,

    SplitThread = function(self)
		
        ###Create/play the split effects.
		for k,v in EffectTemplate.AMercyGuidedMissileSplit do
            CreateEmitterOnEntity(self,self:GetArmy(),v)
        end 
    end,  
}
TypeClass = AIFGuidedMissile

