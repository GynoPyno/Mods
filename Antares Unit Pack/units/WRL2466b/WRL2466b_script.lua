#****************************************************************************
#**
#**  File     :  /cdimage/units/URL0402/URL0402_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
#**
#**  Summary  :  Cybran Spider Bot Script
#**
#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local WeaponsFile = import('/lua/terranweapons.lua')
local WeaponsFile2 = import('/lua/cybranweapons.lua')
#local WeaponsFile3 = import('/mods/Swarm for Mayhem/lua/BattlePackweapons.lua')
local CDFHvyProtonCannonWeapon = WeaponsFile2.CDFHvyProtonCannonWeapon
local CDFElectronBolterWeapon = WeaponsFile2.CDFElectronBolterWeapon
local MissileRedirect = import('/lua/defaultantiprojectile.lua').MissileRedirect
local CAAMissileNaniteWeapon = WeaponsFile2.CAAMissileNaniteWeapon
local EXCEMPArrayBeam01 = import('/lua/sim/defaultweapons.lua').DefaultBeamWeapon

local MobileUnit = import('/lua/defaultunits.lua').MobileUnit
local explosion = import('/lua/defaultexplosions.lua')
local CreateDeathExplosion = explosion.CreateDefaultHitExplosionAtBone
local EffectTemplate = import('/lua/EffectTemplates.lua')
local utilities = import('/lua/Utilities.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity

WRL2466b = Class(CWalkingLandUnit) {

    Weapons = {
		EXTargetPainter = Class(EXCEMPArrayBeam01) {},
		ParticleGunRight = Class(CDFHvyProtonCannonWeapon) {
		FxMuzzleFlash = EffectTemplate.TIFArtilleryMuzzleFlash,			
			FxMuzzleScale = 4,
		},
        ParticleGunLeft = Class(CDFHvyProtonCannonWeapon) {
		FxMuzzleFlash = EffectTemplate.TIFArtilleryMuzzleFlash,			
			FxMuzzleScale = 4,
		},
		LeftBolterCannon1 = Class(CDFElectronBolterWeapon) {
		FxMuzzleFlashScale = 3.5,
		},
		LeftBolterCannon2 = Class(CDFElectronBolterWeapon) {
		FxMuzzleFlashScale = 3.5,
		},
		RightBolterCannon1 = Class(CDFElectronBolterWeapon) {
		FxMuzzleFlashScale = 3.5,
		},		
		RightBolterCannon2 = Class(CDFElectronBolterWeapon) {
		FxMuzzleFlashScale = 3.5,
		},		
		AAMissiles = Class(CAAMissileNaniteWeapon) {},
		FrontLaser01 = Class(CDFElectronBolterWeapon) {
		FxMuzzleFlashScale = 3.5,
		},
        LeftLaser01 = Class(CDFElectronBolterWeapon) {
		FxMuzzleFlashScale = 3.5,
		},
        RightLaser01 = Class(CDFElectronBolterWeapon) {
		FxMuzzleFlashScale = 3.5,
		},
        TopBackLaser01 = Class(CDFElectronBolterWeapon) {
		FxMuzzleFlashScale = 3.5,
		},
        BackLaser01 = Class(CDFElectronBolterWeapon) {
		FxMuzzleFlashScale = 3.5,
		},
    },
	
	OnStartBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStartBeingBuilt(self, builder, layer)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationActivate, false):SetRate(0)
    end,
	
	OnStopBeingBuilt = function(self,builder,layer)
        CWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)
        local bp = self:GetBlueprint().Defense.AntiMissile
        local antiMissile = MissileRedirect {
            Owner = self,
            Radius = bp.Radius,
            AttachBone = bp.AttachBone,
            RedirectRateOfFire = bp.RedirectRateOfFire
        }
        self.Trash:Add(antiMissile)
        self.UnitComplete = true
		
		if self.AnimationManipulator then
            self:SetUnSelectable(true)
            self.AnimationManipulator:SetRate(1)
            
            self:ForkThread(function()
                WaitSeconds(self.AnimationManipulator:GetAnimationDuration()*self.AnimationManipulator:GetRate())
                self:SetUnSelectable(false)
                self.AnimationManipulator:Destroy()
            end)
        end
    end,
	
	    CreateDamageEffects = function(self, bone, army )
        for k, v in EffectTemplate.DamageFireSmoke01 do
            CreateAttachedEmitter( self, bone, army, v ):ScaleEmitter(1.5)
        end
    end,	

    CreateDeathExplosionDustRing = function( self )
        local blanketSides = 18
        local blanketAngle = (2*math.pi) / blanketSides
        local blanketStrength = 1
        local blanketVelocity = 2.8

        for i = 0, (blanketSides-1) do
            local blanketX = math.sin(i*blanketAngle)
            local blanketZ = math.cos(i*blanketAngle)

            local Blanketparts = self:CreateProjectile('/effects/entities/DestructionDust01/DestructionDust01_proj.bp', blanketX, 1.5, blanketZ + 4, blanketX, 0, blanketZ)
                :SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end        
    end,

    CreateFirePlumes = function( self, army, bones, yBoneOffset )
        local proj, position, offset, velocity
        local basePosition = self:GetPosition()
        for k, vBone in bones do
            position = self:GetPosition(vBone)
            offset = utilities.GetDifferenceVector( position, basePosition )
            velocity = utilities.GetDirectionVector( position, basePosition ) # 
            velocity.x = velocity.x + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.z = velocity.z + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.y = velocity.y + utilities.GetRandomFloat( 0.0, 0.3)
            proj = self:CreateProjectile('/effects/entities/DestructionFirePlume01/DestructionFirePlume01_proj.bp', offset.x, offset.y + yBoneOffset, offset.z, velocity.x, velocity.y, velocity.z)
            proj:SetBallisticAcceleration(utilities.GetRandomFloat(-1, -2)):SetVelocity(utilities.GetRandomFloat(3, 4)):SetCollision(false)
            
            local emitter = CreateEmitterOnEntity(proj, army, '/effects/emitters/destruction_explosion_fire_plume_02_emit.bp')

            local lifetime = utilities.GetRandomFloat( 12, 22 )
        end
    end,

    CreateExplosionDebris = function( self, army )
        for k, v in EffectTemplate.ExplosionDebrisLrg01 do
            CreateAttachedEmitter( self, 'UCX0101RV', army, v ):OffsetEmitter( 0, 5, 0 )
        end
    end,

    DeathThread = function(self)
        self:PlayUnitSound('Destroyed')
        local army = self:GetArmy()

        # Create Initial explosion effects
        explosion.CreateFlash( self, 'Left_Leg01_Segment01', 4.5 * 1, army )
        CreateAttachedEmitter(self, 'UCX0101RV', army, '/effects/emitters/destruction_explosion_concussion_ring_03_emit.bp'):ScaleEmitter(9):OffsetEmitter( 0, 5, 0 )
        CreateAttachedEmitter(self,'UCX0101RV', army, '/effects/emitters/explosion_fire_sparks_02_emit.bp'):ScaleEmitter(9):OffsetEmitter( 0, 5, 0 )
        CreateAttachedEmitter(self,'UCX0101RV', army, '/effects/emitters/distortion_ring_01_emit.bp'):ScaleEmitter(9)
        self:CreateFirePlumes( army, {'UCX0101RV'}, 9 )

        self:CreateFirePlumes( army, {'Right_Leg01_Segment01','Right_Leg01_Segment02','Left_Leg02_Segment01',}, 0.5 * 9 )

        self:CreateExplosionDebris( army )
        self:CreateExplosionDebris( army )
        self:CreateExplosionDebris( army )

        WaitSeconds(1)
        
        # Create damage effects on turret bone
        CreateDeathExplosion( self, 'Head', 1.5 * 5)
        self:CreateDamageEffects( 'Head', army )
        self:CreateDamageEffects( 'LMG_Rack', army )

        WaitSeconds( 1 )
        self:CreateFirePlumes( army, {'Right_Leg01_Segment01','Right_Leg01_Segment02','Right_Leg01_Segment02',}, 0.5 * 9 )
        WaitSeconds(0.3)
        self:CreateDeathExplosionDustRing()
        WaitSeconds(0.4)


        # When the spider bot impacts with the ground
        # Effects: Explosion on turret, dust effects on the muzzle tip, large dust ring around unit
        # Other: Damage force ring to force trees over and camera shake
        #self:ShakeCamera(40, 4, 1, 3.8)
        CreateDeathExplosion( self, 'TLG01_Rack', 1 * 5)

        self:CreateExplosionDebris( army )
        self:CreateExplosionDebris( army )

        local x, y, z = unpack(self:GetPosition())
        z = z + 3
        DamageRing(self, {x,y,z}, 0.1, 3, 1, 'Force', true)
        WaitSeconds(0.5)
        CreateDeathExplosion( self, 'TLG01_Rack', 2 * 9)

        # Finish up force ring to push trees
        DamageRing(self, {x,y,z}, 0.1, 3, 1, 'Force', true)

        local bp = self:GetBlueprint()
        for i, numWeapons in bp.Weapon do
            if(bp.Weapon[i].Label == 'MegalithDeath') then
                DamageArea(self, self:GetPosition(), bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                break
            end
        end

        # Explosion on and damage fire on various bones
        CreateDeathExplosion( self, 'RMG_Muzzle', 2 * 3)
        self:CreateFirePlumes( army, {'RMG_Muzzle'}, 5 )
        self:CreateDamageEffects( 'LMG_Rack', army )
        WaitSeconds(0.5)
        
        CreateDeathExplosion( self, 'Left_Leg02_Segment02', 0.25 * 5)
        self:CreateDamageEffects( 'Shield_Gen', army )
        WaitSeconds(0.5)
        CreateDeathExplosion( self, 'RMG_Muzzle', 1 * 5)
        self:CreateExplosionDebris( army )
        
        CreateDeathExplosion( self, 'Left_Leg01_Segment02', 0.25 * 5)
        self:CreateDamageEffects( 'LMG_Muzzle', army )
        WaitSeconds(0.5)
        
        CreateDeathExplosion( self, 'Left_Leg02_Segment02', 0.25 * 5)
        CreateDeathExplosion( self, 'RMG_Muzzle', 2 * 5)
        self:CreateDamageEffects( 'Left_Leg01_Segment01', army )
        explosion.CreateFlash( self, 'Right_Leg01_Segment01', 3.2 * 3, army )        

        self:CreateWreckage(0.1)
        #self:ShakeCamera(3, 2, 0, 0.15)
        self:Destroy()
    end,
    
    
    OnMotionHorzEventChange = function( self, new, old )
        CWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
        
        if ( old == 'Stopped' ) then
            local bpDisplay = self:GetBlueprint().Display
            if bpDisplay.AnimationWalk and self.Animator then
                self.Animator:SetDirectionalAnim(true)
                self.Animator:SetRate(bpDisplay.AnimationWalkRate)
            end
         end
    end,
}

TypeClass = WRL2466b
