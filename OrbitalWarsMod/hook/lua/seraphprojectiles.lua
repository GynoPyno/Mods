#****************************************************************************
#**
#**  File     :  /cdimage/lua/seraphimprojectiles.lua
#**  Author(s):  Gordon Duclos, Greg Kohne, Matt Vainio, Aaron Lundquist
#**
#**  Summary  : Seraphim projectile base class definitions
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

#------------------------------------------------------------------------
#  SERAPHIM PROJECTILES SCRIPTS
#------------------------------------------------------------------------
local DefaultProjectileFile = import('/lua/sim/defaultprojectiles.lua')
local SinglePolyTrailProjectile = DefaultProjectileFile.SinglePolyTrailProjectile
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile 
local SingleBeamProjectile = DefaultProjectileFile.SingleBeamProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile
local util = import('utilities.lua')
local RandomInt = util.GetRandomInt


------------------------------------------------------------------------
#  SERAPHIM HEAVY QUARNON ORBITAL CANNON
#------------------------------------------------------------------------

SHeavyQuarnonOrbitalCannon = Class(MultiPolyTrailProjectile) {
	FxImpactLand = EffectTemplate.SHeavyQuarnonCannonLandHit,
    FxImpactNone = EffectTemplate.SHeavyQuarnonCannonHit,
    FxImpactProp = EffectTemplate.SHeavyQuarnonCannonHit,    
    FxImpactUnit = EffectTemplate.SHeavyQuarnonCannonUnitHit,
    PolyTrails = EffectTemplate.SHeavyQuarnonCannonProjectilePolyTrails,
    PolyTrailOffset = {0,0,0},
    FxTrails = EffectTemplate.SHeavyQuarnonCannonProjectileFxTrails,
    FxImpactWater = EffectTemplate.SHeavyQuarnonCannonWaterHit,
}