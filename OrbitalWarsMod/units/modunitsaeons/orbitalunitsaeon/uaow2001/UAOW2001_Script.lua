#****************************************************************************
#**
#**  File     :  /units/UAOW2001/UAOW2001_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UAOW2001 Aeon heavy orbital defense UAOW2001
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local WeaponsFile = import('/Mods/OrbitalWarsMod/hook/lua/modweapons.lua')
local ADFCannonOblivion01Weapon = WeaponsFile.ADFCannonOblivion01Weapon

UAOW2001 = Class(AStructureUnit) {

    Weapons = {
        MainGun = Class(ADFCannonOblivion01Weapon) {
		FxMuzzleFlashScale = 2.5,
		},
    },
}

TypeClass = UAOW2001