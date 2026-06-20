#****************************************************************************
#**
#**  File     : /lua/terranprojectiles.lua
#**  Author(s): John Comes, Gordon Duclos
#**
#**  Summary  :
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
#------------------------------------------------------------------------
#  TERRAN PROJECTILES SCRIPTS
#------------------------------------------------------------------------
local DefaultProjectileFile = import('/lua/sim/defaultprojectiles.lua')
local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat
local DefaultExplosion = import('/lua/defaultexplosions.lua')
local DepthCharge = import('/lua/defaultantiprojectile.lua').DepthCharge
local EffectTemplate = import('/lua/EffectTemplates.lua')
local Projectile = import('/lua/sim/projectile.lua').Projectile
local Explosion = import('/lua/defaultexplosions.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local util = import('/lua/utilities.lua')
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile
local OnWaterEntryEmitterProjectile = DefaultProjectileFile.OnWaterEntryEmitterProjectile
local SingleBeamProjectile = DefaultProjectileFile.SingleBeamProjectile
local SinglePolyTrailProjectile = DefaultProjectileFile.SinglePolyTrailProjectile
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile
local SingleCompositeEmitterProjectile = DefaultProjectileFile.SingleCompositeEmitterProjectile
local MultiCompositeEmitterProjectile = DefaultProjectileFile.MultiCompositeEmitterProjectile
local NullShell = DefaultProjectileFile.NullShell
local MultiBeamProjectile = DefaultProjectileFile.MultiBeamProjectile

###############################################################################################
#			##		##		########		   ##	 		##			  ## 	##		##	  #
#			##		##		########		  ####			 ##			 ##		 ##	   ##	  #
#			## 	 	##		##				 ##	 ##			  ##		##		  ##  ##	  #
#			##########		########		##	  ##		   ##	   ##		   ####		  #
#			##########		########       ##########	        ##    ##			##        #
#			##		##		##			  ############			 ##  ##            ##         #
#			##		##		########	 ##	         ##           ####			  ##	      #
#			##	 	##		########	##			  ##		   ##			 ##			  #
###############################################################################################
#	#######		########	##########	 #########	   ####		##	 ###########   ########## #								 	
#	#########	########	##########	 #########	   #### 	##	 ###########   ########## #					 
#	##	   ##	##			##			 ##			   ## ##	##   ##            ##         # 
#	##	   ##	########	#######		 #########	   ##  ##   ##	 ##			   ########## #
#   ##     ##	########	#######      #########     ##   ##  ##   ##            ########## #
#	##	   ##	##			##	         ##            ##    ## ##   ##            ##         #
#	#########   ########    ##			 #########     ##     ####   ###########   ########## #
#	#######		########	##			 #########	   ##	   ###   ###########   ########## #
###############################################################################################

#------------------------------------------------------------------------
#  TERRAN ORBITAL HEAVY PLASMA CANNON PROJECTILES
#------------------------------------------------------------------------
TOrbitalHeavyPlasmaCannonProjectile = Class(MultiPolyTrailProjectile) {
    FxTrails = EffectTemplate.TPlasmaCannonHeavyMunition,
	FxTrailScale = 9,   --TPlasmaCannonHeavyMunition02
    RandomPolyTrails = 5,
    PolyTrailOffset = {0,0,0},
    PolyTrails = EffectTemplate.TPlasmaCannonHeavyPolyTrails,
	PolyTrailsScale = 20,
	FxImpactAirUnit = EffectTemplate.TPlasmaCannonHeavyHitUnit01,    --EffectTemplate.TAAGinsuHitUnit
    FxAirUnitHitScale = 13,
}

#------------------------------------------------------------------------
#  CYBRAN ORBITAL HEAVY BOLTER CANNON PROJECTILES
#------------------------------------------------------------------------

COrbitalHeavyBolterCanonProjectile = Class(MultiPolyTrailProjectile) {

    PolyTrails = {
		'/effects/emitters/electron_bolter_trail_01_emit.bp',
		'/effects/emitters/default_polytrail_05_emit.bp',
	},
	PolyTrailOffset = {0,0},  
    FxTrails = {'/effects/emitters/electron_bolter_munition_02_emit.bp',},
	FxTrailScale = 4,
	
	# Hit Effects
	FxUnitHitScale = 20,
    FxImpactAirUnit = EffectTemplate.CElectronBolterHit04,
	FxAirUnitHitScale = 13,

    OnImpact = function(self, targetType, targetEntity)
        local army = self:GetArmy()
        CreateLightParticle( self, -1, army, 12, 28, 'glow_03', 'ramp_proton_flash_02' )
        CreateLightParticle( self, -1, army, 8, 22, 'glow_03', 'ramp_antimatter_02' )
        if targetType == 'Terrain' then
            CreateSplat( self:GetPosition(), 0, 'scorch_011_albedo', 12, 12, 150, 200, army )
        end

        local blanketSides = 12
        local blanketAngle = (2*math.pi) / blanketSides
        local blanketStrength = 1
        local blanketVelocity = 6.25

        for i = 0, (blanketSides-1) do
            local blanketX = math.sin(i*blanketAngle)
            local blanketZ = math.cos(i*blanketAngle)
            self:CreateProjectile('/effects/entities/EffectProtonAmbient01/EffectProtonAmbient01_proj.bp', blanketX, 0.5, blanketZ, blanketX, 0, blanketZ)
                :SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end

        EmitterProjectile.OnImpact(self, targetType, targetEntity)
    end,
}


#------------------------------------------------------------------------
#  AEON ORBITAL HEAVY LAZER CANNON PROJECTILES
#------------------------------------------------------------------------

AOrbitalHeavyLazerProjectile = Class(MultiPolyTrailProjectile) {
	FxImpactTrajectoryAligned = false,
    PolyTrails = {
		'/effects/emitters/aeon_laser_trail_02_emit.bp',
		'/effects/emitters/default_polytrail_03_emit.bp',
	},
	PolyTrailOffset = {0,0},
	--PolyTrailScale = 10,
	FxTrails = {
        '/effects/emitters/oblivion_cannon_munition_01_emit.bp',
        '/effects/emitters/quantum_cannon_munition_04_emit.bp',
    },
	--FxTrails = {'/effects/emitters/oblivion_cannon_munition_01_emit.bp'},
	--FxTrails = EffectTemplate.AMiasmaMunition01,
	FxTrailScale = 10,
	
# Hit Effects
    FxImpactUnit = EffectTemplate.AQuarkBombHitUnit01,
    FxImpactProp = EffectTemplate.AQuarkBombHitUnit01,
    FxImpactAirUnit = EffectTemplate.AQuarkBombHitAirUnit01,
    FxImpactLand = EffectTemplate.AQuarkBombHitLand01,
	FxAirUnitHitScale = 5,
    FxImpactUnderWater = {},
    FxSplatScale = 5,

    OnImpact = function(self, TargetType, targetEntity)
        CreateLightParticle(self, -1,self:GetArmy(), 26, 6, 'sparkle_white_add_08', 'ramp_white_02' )
        DefaultExplosion.CreateScorchMarkSplat( self, 3 )

        EmitterProjectile.OnImpact( self, TargetType, targetEntity )
    end,
}

#------------------------------------------------------------------------
#  SERAPHIM HEAVY QUARNON ORBITAL CANNON
#------------------------------------------------------------------------

SHeavyQuarnonOrbitalCannon = Class(MultiPolyTrailProjectile) {
    FxImpactNone = EffectTemplate.SHeavyQuarnonCannonHit,   
    FxImpactAirUnit = EffectTemplate.SHeavyQuarnonCannonUnitHit,
    PolyTrails = EffectTemplate.SHeavyQuarnonCannonProjectilePolyTrails,
	PolyTrailsScale = 5,
    PolyTrailOffset = {0,0,0},
    FxTrails = EffectTemplate.SHeavyQuarnonCannonProjectileFxTrails,
	FxTrailScale = 5,
	FxAirUnitHitScale = 5,
}

###############################################################################################

##            ##		##           ######## 
 ##          ##		   ####	         ########
  ##        ##        ##  ##            ##
   ##      ##        ##    ##           ##
    ##	  ##	    ##########          ##
	 ##  ##        ############         ## 
	  ####        ##          ##     ########
	   ##        ##            ##	 ########
###############################################################################################
--------------------------------------------------- ARMES VAISSEAUX ANTI CHASSEURS------------------------------------------------------------------------



################################################################################################
##																							  ##
##                 VAISSEAU SERAPHIME ANTI CHASSEURS ORBITAUX                                 ##
##																							  ##
################################################################################################
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#  SERAPHIM LIGHT ANTI ORBITAL LIGHT CANON													   #		
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
SShriekerAutoOrbitalCannon = Class(MultiPolyTrailProjectile) {
	
    FxImpactAirUnit = EffectTemplate.ShriekerCannonHitUnit,
	FxAirUnitHitScale = 5,
    FxTrails = {},
    PolyTrails = EffectTemplate.SDFSniperShotNormalPolytrail,  
	FxTrailScale = 0.50,
    FxImpactWater = EffectTemplate.ShriekerCannonHit,
    FxImpactUnderWater = EffectTemplate.ShriekerCannonHit,
    PolyTrailOffset = {0,0,0},
}

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#  SERAPHIM ANTI ORBITAL MEDIUM CANON														   #  		
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
SThunthoOrbitalShell = Class(MultiPolyTrailProjectile) {

    FxImpactAirUnit = EffectTemplate.ShriekerCannonHitUnit,
	FxAirUnitHitScale = 5, 
    FxTrails =  EffectTemplate.SAireauBolterProjectileFxTrails,  
	FxTrailScale = 8,
    PolyTrails = EffectTemplate.ShriekerCannonPolyTrail,
	PolyTrailScale = 5,
	FxSplatScale = 5,
    PolyTrailOffset = {0,0},    
}
 --interressant l effet:p--EffectTemplate.SShleoCannonProjectileTrails
  --interressant l effet:EffectTemplate.SChronotronCannonProjectileFxTrails
  
################################################################################################
##																							  ##
##                 VAISSEAU FEDERATION UNIE TERRIENNE ANTI CHASSEURS ORBITAUX                 ##
##																							  ##
################################################################################################

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#  TERRAN ORBITAL LIGHT PLASMA CANNON PROJECTILES											   #  
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

TLightOrbitalPlasmaCannonProjectile = Class(MultiPolyTrailProjectile) {
    FxTrails = EffectTemplate.TPlasmaCannonHeavyMunition,
	--FxTrailScale = 1,
    --RandomPolyTrails = 1,
    PolyTrailOffset = {0,0,0},
    PolyTrails = EffectTemplate.TPlasmaCannonHeavyPolyTrails,
    FxImpactAirUnit = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
	FxAirUnitHitScale = 1, 
}

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#  TERRAN ORBITAL MEDIUM PLASMA CANNON PROJECTILES											   #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

TMediumOrbitalPlasmaCannonProjectile = Class(MultiPolyTrailProjectile) {
    FxTrails = EffectTemplate.TPlasmaCannonHeavyMunition,
	FxTrailScale = 3,
    --RandomPolyTrails = 2,
    PolyTrailOffset = {0,0,0},
    PolyTrails = EffectTemplate.TPlasmaCannonHeavyPolyTrails,
    FxImpactAirUnit = EffectTemplate.TPlasmaCannonHeavyHitUnit01,
	FxAirUnitHitScale = 2, 
}

################################################################################################
##																							  ##
##                 VAISSEAU CYBRAN ANTI CHASSEURS ORBITAUX                 					  ##
##																							  ##
################################################################################################

#--------------------------------------
# CYBRAN ANTI ORBITAL LEGER FIGHTERS BOLTER PROJECTILE
#--------------------------------------

CDFBolterLegerCannonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
		EffectTemplate.CProtonCannonPolyTrail,
		'/effects/emitters/default_polytrail_01_emit.bp',
	},
	PolyTrailOffset = {0,0}, 
	--PolyTrailScale = 3,
	
    FxTrails = EffectTemplate.CProtonCannonFXTrail01,
	FxTrailScale = 3,
	FxTrailOffset = 3,
    #PolyTrail = EffectTemplate.CProtonCannonPolyTrail,
    FxImpactAirUnit = EffectTemplate.CProtonCannonHit01,
    FxAirUnitHitScale = 2,
}

#------------------------------------------------------------------------
#  CYBRAN ANTI ORBITAL MOYEN BOLTER PROJECTILE
#------------------------------------------------------------------------
CBolterMoyenCanonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
        '/mods/OrbitalWarsMod/hook/effects/emitters/cybranBolterTrailMoyen_emit.bp',  --Mods\OrbitalWarsMod\hook\effects\emitters
		'/effects/emitters/default_polytrail_02_emit.bp',
	},
	PolyTrailOffset = {0,0}, 

    # Hit Effects
    FxImpactAirUnit = EffectTemplate.CLaserHitUnit01,
    FxAirUnitHitScale = 10,
}

################################################################################################
##																							  ##
##                 VAISSEAU AEON ANTI CHASSEURS ORBITAUX                 					  ##
##																							  ##
################################################################################################

#------------------------------------------------------------------------
#  AEON ANTI ORBITALS LEGER ANTI FIGHTERS
#------------------------------------------------------------------------

AAntiOrbitalFightersProjectile = Class(SingleCompositeEmitterProjectile) {
    BeamName = '/effects/emitters/temporal_fizz_munition_beam_01_emit.bp',
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxImpactAirUnit = EffectTemplate.ATemporalFizzHit01,
    FxAirUnitHitScale = 1,
}

###############################################################################################

##            ##		##           ######## 
 ##          ##		   ####	         ########
  ##        ##        ##  ##            ##
   ##      ##        ##    ##           ##
    ##	  ##	    ##########          ##
	 ##  ##        ############         ## 
	  ####        ##          ##     ########
	   ##        ##            ##	 ########
###############################################################################################
--------------------------------------------------- ARMES VAISSEAUX ANTI VAISSEAUX------------------------------------------------------------------------

#------------------------------------------------------------------------
#  SERAPHIM HEAVY QUARNON ORBITAL CANNON MOBILE
#------------------------------------------------------------------------

SHeavyQuarnonOrbital02Proj = Class(MultiPolyTrailProjectile) {
    FxImpactNone = EffectTemplate.SHeavyQuarnonCannonHit,   
    FxImpactAirUnit = EffectTemplate.SHeavyQuarnonCannonUnitHit,
    FxTrails = EffectTemplate.SChronotronCannonProjectileFxTrails,
    PolyTrails = EffectTemplate.SChronotronCannonProjectileTrails,
	PolyTrailsScale = 6,
    PolyTrailOffset = {0,0,0},
    --FxTrails = EffectTemplate.SHeavyQuarnonCannonProjectileFxTrails,
	FxTrailScale = 6,
	FxAirUnitHitScale = 5,
}

#--------------------------------------
# UEF ANTI ORBITAL LOURD PLASMA PROJECTILE
#--------------------------------------
TPlasmaLourdMobilAntiOrbitalProjectile = Class(SingleBeamProjectile) {
    BeamName = '/Mods/OrbitalWarsMod/hook/effects/emitters/AntiOrbitalLourdMobilFTU_emit.bp',    --/Mods/OrbitalWarsMod/hook/effects/emitters/AntiOrbitalLourdMobilFTU
	FxImpactAirUnit = EffectTemplate.TPlasmaGatlingCannonUnitHit,
    FxImpactUnderWater = {},
	FxAirUnitHitScale = 15,
}

###############################################################################################

##            ##		##           ######## 
 ##          ##		   ####	         ########
  ##        ##        ##  ##            ##
   ##      ##        ##    ##           ##
    ##	  ##	    ##########          ##
	 ##  ##        ############         ## 
	  ####        ##          ##     ########
	   ##        ##            ##	 ########
###############################################################################################
--------------------------------------------------- ARMES VAISSEAUX ANTI VAISSEAUX------------------------------------------------------------------------


#------------------------------------------------------------------------
#  CYBRAN HEAVY GROUND BOLTER PROJECTILE
#------------------------------------------------------------------------

COrbitalGroundBolterCanonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
		'/effects/emitters/auto_cannon_trail_01_emit.bp',
		'/effects/emitters/default_polytrail_03_emit.bp',
	},
	PolyTrailOffset = {0,0},
	PolyTrailScale = 1,
    
	FxTrails = EffectTemplate.CProtonCannonFXTrail01,
	FxTrailScale = 5,
	
    # Hit Effects
    FxImpactUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactProp ={'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactAirUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  CYBRAN LIGHT SUPPORT SHIP BOLTER PROJECTILE
#------------------------------------------------------------------------

COrbitalLightSupportBolterCanonProjectile = Class(MultiPolyTrailProjectile) {
    PolyTrails = {
		'/effects/emitters/auto_cannon_trail_01_emit.bp',
		'/effects/emitters/default_polytrail_03_emit.bp',
	},
	PolyTrailOffset = {0,0},
	PolyTrailScale = 1,
    
	--FxTrails = EffectTemplate.CProtonCannonFXTrail01,
	--FxTrailScale = 1,
	
    # Hit Effects
    FxImpactUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactProp ={'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactAirUnit = {'/effects/emitters/auto_cannon_hit_flash_01_emit.bp', },
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
}

#------------------------------------------------------------------------
#  TERRAN PLASMA CANNON SOUTIEN SOL PROJECTILES
#------------------------------------------------------------------------
TPlasmaSoutienCannonProjectile = Class(SinglePolyTrailProjectile) {
	EffectScale = 8,
    FxTrails = EffectTemplate.TPlasmaCannonLightMunition,
	FxTrailScale = 8,
    PolyTrailOffset = 0,
	--PolyTrailScale = 1,
	PolyTrailScale = 8,
    PolyTrail = EffectTemplate.TPlasmaCannonLightPolyTrail,
    FxImpactUnit = EffectTemplate.TPlasmaCannonLightHitUnit01,
    FxImpactProp = EffectTemplate.TPlasmaCannonLightHitUnit01,
    FxImpactLand = EffectTemplate.TPlasmaCannonLightHitLand01,
}

#------------------------------------------------------------------------
#  AEON ORBITAL SOL PROJECTILES
#------------------------------------------------------------------------
AOrbitalSolCannonProjectile = Class(SinglePolyTrailProjectile) {
    FxTrails = {
        '/effects/emitters/quantum_cannon_munition_03_emit.bp',
        '/effects/emitters/quantum_cannon_munition_04_emit.bp',
    },
	FxTrailsScale = 2,
    PolyTrail = '/effects/emitters/quantum_cannon_polytrail_01_emit.bp',
	PolyTraulScale = 2,
    FxImpactUnit = EffectTemplate.AQuantumCannonHit01,
    FxImpactProp = EffectTemplate.AQuantumCannonHit01,
    FxImpactLand = EffectTemplate.AQuantumCannonHit01,
	FxUnitHitScale = 3,
    FxLandHitScale = 3,
    FxWaterHitScale = 3,
}