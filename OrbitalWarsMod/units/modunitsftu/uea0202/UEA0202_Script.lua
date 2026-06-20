#****************************************************************************
#**
#**  File     :  /Mods/units/UEA0202/UEA0202_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Terran T 2 Interceptor Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TAirUnit = import('/lua/terranunits.lua').TAirUnit
local TAirToAirLinkedRailgun = import('/lua/terranweapons.lua').TAirToAirLinkedRailgun


UEA0202 = Class(TAirUnit) {
    PlayDestructionEffects = true,
    DamageEffectPullback = 0.25,
    DestroySeconds = 7.5,

    Weapons = {
        RightBeam = Class(TAirToAirLinkedRailgun) {},
        LeftBeam = Class(TAirToAirLinkedRailgun) {},
    },
	
}

TypeClass = UEA0202