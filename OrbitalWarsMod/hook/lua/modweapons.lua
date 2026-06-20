#****************************************************************************
#**
#**  File     :  /cdimage/lua/modules/modweapons.lua
#**  Author(s):  John Comes, David Tomandl, Gordon Duclos modified by Asdrubaelvect
#**
#**  Summary  :  Mod specific weapon definitions
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local WeaponFile = import('/lua/sim/defaultweapons.lua') ---
local CollisionBeams = import('/lua/defaultcollisionbeams.lua') ---
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local GinsuCollisionBeam = CollisionBeams.GinsuCollisionBeam
local EffectTemplate = import('/lua/EffectTemplates.lua')


--ANTI ORBITAL LOURD TEK1
TIFArtillery01Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

CDFHeavyElectronBolter01Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CElectronBolterMuzzleFlash02,
}

ADFCannonOblivion01Weapon = Class(DefaultProjectileWeapon) {
	FxMuzzleFlash = EffectTemplate.AOblivionCannonMuzzleFlash02,
    FxChargeMuzzleFlash = EffectTemplate.AOblivionCannonChargeMuzzleFlash02,

}

--ANTI ORBITAL MOYEN MOBIL TEK1
TDFMediumPlasmaCannon01Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

--ANTI ORBITAL LEGER TEK1
TDFHeavyPlasmaCannon01Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

--SOUTIEN ORBITAL LEGER TEK1

TDFLightPlasmaCannon01Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonLightMuzzleFlash,
}

--ANTI ORBITAL LOURD MOBIL TEK1

TAAGinsuRapidPulse01Weapon = Class(DefaultProjectileWeapon) {
	--FxMuzzleFlash = {},
	FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}

--Orbital Leger AntiFighter Cybran 

CDFProtonCannon01Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/proton_cannon_muzzle_01_emit.bp',
                     '/effects/emitters/proton_cannon_muzzle_02_emit.bp',},
}

--ORBITAL MOYEN CYBRAN 

CDFLaserPulseLight01Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash01,
}

--ORBITAL MOYEN CYBRAN 

CDFLaserPulseLight02Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash01,
}

-- ORBITAL LIGHT AEONS ANTI CHASSEURS

AAATemporalFizzWeapon = Class(DefaultProjectileWeapon) {
    FxChargeEffects = { '/effects/emitters/temporal_fizz_muzzle_charge_01_emit.bp', },
    FxMuzzleFlash = { '/effects/emitters/temporal_fizz_muzzle_flash_01_emit.bp',},
    ChargeEffectMuzzles = {},

    PlayFxRackSalvoChargeSequence = function(self)
        DefaultProjectileWeapon.PlayFxRackSalvoChargeSequence(self)
        local army = self.unit:GetArmy()
        for keyb, valueb in self.ChargeEffectMuzzles do
            for keye, valuee in self.FxChargeEffects do
                CreateAttachedEmitter(self.unit,valueb,army, valuee)
            end
        end
    end,

}
-- ORBITAL DEFENCES SUPPORT SHIP

CDFHeavyElectronBolter02Weapon = Class(DefaultProjectileWeapon) {
    --FxMuzzleFlash = EffectTemplate.TPlasmaCannonLightMuzzleFlash,
}

ADFCannonQuantum01Weapon = Class(DefaultProjectileWeapon) {
		FxMuzzleFlash = EffectTemplate.AQuantumCannonMuzzle01,
}


--ORBITAL SERAPHIM ANTI SPACESHIPS

SDFHeavyQuarnon01Cannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.SDFExperimentalPhasonProjMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.SDFExperimentalPhasonProjChargeMuzzleFlash,
    ChargeEffectMuzzles = {},
	FxChargeMuzzleFlashScale = 3,
	ChargeEffectMuzzlesScale = 3,
}

--ORBITAL UEF ANTI SPACESHIPS

TAAGinsuRapidPulse01Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.TPlasmaCannonHeavyMuzzleFlash,
}