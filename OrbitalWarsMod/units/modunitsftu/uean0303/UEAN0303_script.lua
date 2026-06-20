--[[#######################################################################
#  File	 :  /units/UEA0306/UEA0306_script.lua
#  Author(s):  John Comes, David Tomandl
#  Summary  :  UEF Tech 3 fighter bomber UEA0306 / UEO306
#  -----------------------------
#  Modif.by :  AsdrubaelVect
#  Rev.Date :  5 septembre 2009
#  -----------------------------
#  Revis.by :  Manimal
#  Rev.Date :  20 novembre 2009
#  -----------------------------
#  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#######################################################################]]--


local TAirUnit = import('/lua/terranunits.lua').TAirUnit
local TAAGinsuRapidPulseWeapon = import('/lua/terranweapons.lua').TAAGinsuRapidPulseWeapon

UEA0306 = Class(TAirUnit) {
	
	Weapons = {
	    RightBeam = Class(TAAGinsuRapidPulseWeapon) {},
		LeftBeam = Class(TAAGinsuRapidPulseWeapon) {},
    },
	
}

TypeClass = UEA0306
