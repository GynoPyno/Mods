#****************************************************************************
#**
#**  File     :  /cdimage/units/URB2303/URB2303_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran Light Artillery Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CDFHeavyElectronBolter01Weapon = import('/Mods/OrbitalWarsMod/hook/lua/modweapons.lua').CDFHeavyElectronBolter01Weapon

URO2001 = Class(CStructureUnit) {

    Weapons = {
        MainGun = Class(CDFHeavyElectronBolter01Weapon) {
		FxMuzzleFlashScale = 0.5,
        },
    },
}

TypeClass = URO2001
