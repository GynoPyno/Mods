#****************************************************************************
#**
#**  File     :  /cdimage/units/UAA0101/UAA0101_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Scout Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************


local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local AAAAutocannonQuantumWeapon = import('/lua/aeonweapons.lua').AAAAutocannonQuantumWeapon

UAA0101 = Class(AAirUnit) {

    Weapons = {
        AutoCannon1 = Class(AAAAutocannonQuantumWeapon) {
			FxMuzzleFlash = {'/effects/emitters/sonic_pulse_muzzle_flash_02_emit.bp',},
        },
    },
}

TypeClass = UAA0101