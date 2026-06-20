#****************************************************************************
#**
#**  File     :  /effects/entities/UnitTeleport03/UnitTeleport03_script.lua
#**  Author(s):  Gordon Duclos (then hacked up by Matt M)
#**
#**  Summary  :  Unit Teleport effect entity
#**
#**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

UnitTeleportEffect03 = Class(NullShell) {

    OnCreate = function(self)
        NullShell.OnCreate(self)
        self:ForkThread(self.TeleportEffectThread)
    end,

    TeleportEffectThread = function(self)
        local army = self:GetArmy()
		for k, v in EffectTemplate.CBrackmanCrabPegAmbient01 do
            CreateEmitterOnEntity( self, army, v )
        end
		for k, v in EffectTemplate.CBrackmanCrabPegHit01 do
            CreateEmitterOnEntity( self, army, v )
        end


        # Initial light flashs
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
        WaitSeconds(0.5)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(0.6)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(0.75)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(1)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(1.25)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(1.45)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(1.6)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
        WaitSeconds(0.5)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(0.65)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(0.75)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(1)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(1.25)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(1.45)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(1.6)
		for k, v in EffectTemplate.CBrackmanCrabPegHit01 do
            CreateEmitterOnEntity( self, army, v )
        end
		for k, v in EffectTemplate.CBrackmanCrabPegAmbient01 do
            CreateEmitterOnEntity( self, army, v )
        end
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
        WaitSeconds(1.75)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
        WaitSeconds(1.85)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
        WaitSeconds(2.0)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
        WaitSeconds(2.15)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(2.25)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(2.35)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(2.45)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(2.60)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(2.85)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(2.95)
		 CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(3.0)
		 CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(3.15)
		 CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(3.25)
		 CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(3.35)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(3.45)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
        WaitSeconds(1.85)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(2.25)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(2.35)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(2.45)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(2.55)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(2.65)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(2.75)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(2.85)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(2.95)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(3.05)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(3.25)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(3.45)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		for k, v in EffectTemplate.CBrackmanCrabPegHit01 do
            CreateEmitterOnEntity( self, army, v )
        end
		for k, v in EffectTemplate.CBrackmanCrabPegAmbient01 do
            CreateEmitterOnEntity( self, army, v )
        end
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
        WaitSeconds(3.75)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(3.95)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(4.15)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(4.25)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(4.35)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(4.45)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(4.55)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(4.65)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(4.75)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(4.85)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(4.95)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.0)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.15)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.25)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.35)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.45)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.55)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.65)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.75)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.85)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(5.95)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(6.05)
		CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_13' )
		WaitSeconds(6.15)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
        WaitSeconds(6.25)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(5.25)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(4.85)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )
		WaitSeconds(3.45)
        CreateLightParticleIntel( self, -1, army, 5, 5, 'flare_lens_add_02', 'ramp_red_12' )	
		for k, v in EffectTemplate.CBrackmanCrabPegHit01 do
            CreateEmitterOnEntity( self, army, v )
        end
		for k, v in EffectTemplate.CBrackmanCrabPegAmbient01 do
            CreateEmitterOnEntity( self, army, v )
        end
    end,





}

TypeClass = UnitTeleportEffect03

