#****************************************************************************
#**
#**  File     :  /units/URA0202/URA0202_script.lua
#**  Author(s):  David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran T 2 Interceptor Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local CAAAutocannon = import('/lua/cybranweapons.lua').CAAAutocannon

URA0202 = Class(CAirUnit) {
	
	Weapons = {
        RightBeam = Class(CAAAutocannon) {},
        LeftBeam = Class(CAAAutocannon) {},
    },
}
TypeClass = URA0202