#****************************************************************************
#**
#**  File     :  /units/UOB2101/UOB2101_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix modified by Asdrubaelvect 
#**
#**  Summary  :  UEF Orbital Heavy Defence Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TIFArtillery01Weapon = import('/Mods/OrbitalWarsMod/hook/lua/modweapons.lua').TIFArtillery01Weapon



UOB2101 = Class(TStructureUnit) {

    Weapons = {
        MainGun = Class(TIFArtillery01Weapon) {
		FxMuzzleFlashScale = 8,
        },
    },
}

TypeClass = UOB2101