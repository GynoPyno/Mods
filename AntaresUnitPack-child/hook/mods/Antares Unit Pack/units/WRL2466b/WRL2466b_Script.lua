local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local WeaponFile = import('/lua/sim/defaultweapons.lua')
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local CybranWeapons = import('/lua/cybranweapons.lua')
local CDFHvyProtonCannonWeapon = CybranWeapons.CDFHvyProtonCannonWeapon
local CDFElectronBolterWeapon = CybranWeapons.CDFElectronBolterWeapon
local CAAMissileNaniteWeapon = CybranWeapons.CAAMissileNaniteWeapon
local MissileRedirect = import('/lua/defaultantiprojectile.lua').MissileRedirect
local CollisionBeamFile = import('/lua/defaultcollisionbeams.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local explosion = import('/lua/defaultexplosions.lua')
local utilities = import('/lua/Utilities.lua')

-- EXCEMPArrayBeam01 da Swarm for Mayhem non disponibile: sostituito con beam Cybran equivalente
local EXTargetPainterBeam = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam02,
    FxMuzzleFlash = {},
}

WRL2466b = Class(CWalkingLandUnit) {

    Weapons = {
        EXTargetPainter    = ClassWeapon(EXTargetPainterBeam) {},
        ParticleGunRight   = ClassWeapon(CDFHvyProtonCannonWeapon) {
            FxMuzzleFlash = EffectTemplate.TIFArtilleryMuzzleFlash,
            FxMuzzleScale = 4,
        },
        ParticleGunLeft    = ClassWeapon(CDFHvyProtonCannonWeapon) {
            FxMuzzleFlash = EffectTemplate.TIFArtilleryMuzzleFlash,
            FxMuzzleScale = 4,
        },
        LeftBolterCannon1  = ClassWeapon(CDFElectronBolterWeapon) { FxMuzzleFlashScale = 3.5 },
        LeftBolterCannon2  = ClassWeapon(CDFElectronBolterWeapon) { FxMuzzleFlashScale = 3.5 },
        RightBolterCannon1 = ClassWeapon(CDFElectronBolterWeapon) { FxMuzzleFlashScale = 3.5 },
        RightBolterCannon2 = ClassWeapon(CDFElectronBolterWeapon) { FxMuzzleFlashScale = 3.5 },
        AAMissiles         = ClassWeapon(CAAMissileNaniteWeapon) {},
        FrontLaser01       = ClassWeapon(CDFElectronBolterWeapon) { FxMuzzleFlashScale = 3.5 },
        LeftLaser01        = ClassWeapon(CDFElectronBolterWeapon) { FxMuzzleFlashScale = 3.5 },
        RightLaser01       = ClassWeapon(CDFElectronBolterWeapon) { FxMuzzleFlashScale = 3.5 },
        TopBackLaser01     = ClassWeapon(CDFElectronBolterWeapon) { FxMuzzleFlashScale = 3.5 },
        BackLaser01        = ClassWeapon(CDFElectronBolterWeapon) { FxMuzzleFlashScale = 3.5 },
    },

    OnStartBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStartBeingBuilt(self, builder, layer)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationActivate, false):SetRate(0)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        local bp = self:GetBlueprint().Defense.AntiMissile
        local antiMissile = MissileRedirect {
            Owner = self,
            Radius = bp.Radius,
            AttachBone = bp.AttachBone,
            RedirectRateOfFire = bp.RedirectRateOfFire,
        }
        self.Trash:Add(antiMissile)
        self.UnitComplete = true
        if self.AnimationManipulator then
            self:SetUnSelectable(true)
            self.AnimationManipulator:SetRate(1)
            self:ForkThread(function()
                WaitSeconds(self.AnimationManipulator:GetAnimationDuration() * self.AnimationManipulator:GetRate())
                self:SetUnSelectable(false)
                self.AnimationManipulator:Destroy()
            end)
        end
    end,

    OnMotionHorzEventChange = function(self, new, old)
        CWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
        if old == 'Stopped' then
            local bpDisplay = self:GetBlueprint().Display
            if bpDisplay.AnimationWalk and self.Animator then
                self.Animator:SetDirectionalAnim(true)
                self.Animator:SetRate(bpDisplay.AnimationWalkRate)
            end
        end
    end,

    CreateDamageEffects = function(self, bone, army)
        for k, v in EffectTemplate.DamageFireSmoke01 do
            CreateAttachedEmitter(self, bone, army, v):ScaleEmitter(1.5)
        end
    end,

    CreateDeathExplosionDustRing = function(self)
        local blanketSides = 18
        local blanketAngle = (2 * math.pi) / blanketSides
        local blanketVelocity = 2.8
        for i = 0, (blanketSides - 1) do
            local blanketX = math.sin(i * blanketAngle)
            local blanketZ = math.cos(i * blanketAngle)
            self:CreateProjectile('/effects/entities/DestructionDust01/DestructionDust01_proj.bp', blanketX, 1.5, blanketZ + 4, blanketX, 0, blanketZ)
                :SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end
    end,

    CreateFirePlumes = function(self, army, bones, yBoneOffset)
        local basePosition = self:GetPosition()
        for k, vBone in bones do
            local position = self:GetPosition(vBone)
            local offset = utilities.GetDifferenceVector(position, basePosition)
            local velocity = utilities.GetDirectionVector(position, basePosition)
            velocity.x = velocity.x + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.z = velocity.z + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.y = velocity.y + utilities.GetRandomFloat(0.0, 0.3)
            local proj = self:CreateProjectile('/effects/entities/DestructionFirePlume01/DestructionFirePlume01_proj.bp', offset.x, offset.y + yBoneOffset, offset.z, velocity.x, velocity.y, velocity.z)
            proj:SetBallisticAcceleration(utilities.GetRandomFloat(-1, -2)):SetVelocity(utilities.GetRandomFloat(3, 4)):SetCollision(false)
            CreateEmitterOnEntity(proj, army, '/effects/emitters/destruction_explosion_fire_plume_02_emit.bp')
        end
    end,

    CreateExplosionDebris = function(self, army)
        for k, v in EffectTemplate.ExplosionDebrisLrg01 do
            CreateAttachedEmitter(self, 'UCX0101RV', army, v):OffsetEmitter(0, 5, 0)
        end
    end,

    DeathThread = function(self)
        self:PlayUnitSound('Destroyed')
        local army = self:GetArmy()
        explosion.CreateFlash(self, 'Left_Leg01_Segment01', 4.5, army)
        CreateAttachedEmitter(self, 'UCX0101RV', army, '/effects/emitters/destruction_explosion_concussion_ring_03_emit.bp'):ScaleEmitter(9):OffsetEmitter(0, 5, 0)
        CreateAttachedEmitter(self, 'UCX0101RV', army, '/effects/emitters/explosion_fire_sparks_02_emit.bp'):ScaleEmitter(9):OffsetEmitter(0, 5, 0)
        CreateAttachedEmitter(self, 'UCX0101RV', army, '/effects/emitters/distortion_ring_01_emit.bp'):ScaleEmitter(9)
        self:CreateFirePlumes(army, {'UCX0101RV'}, 9)
        self:CreateFirePlumes(army, {'Right_Leg01_Segment01', 'Right_Leg01_Segment02', 'Left_Leg02_Segment01'}, 4.5)
        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)
        WaitSeconds(1)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Head', 7.5)
        self:CreateDamageEffects('Head', army)
        self:CreateDamageEffects('LMG_Rack', army)
        WaitSeconds(1)
        self:CreateFirePlumes(army, {'Right_Leg01_Segment01', 'Right_Leg01_Segment02', 'Right_Leg01_Segment02'}, 4.5)
        WaitSeconds(0.3)
        self:CreateDeathExplosionDustRing()
        WaitSeconds(0.4)
        explosion.CreateDefaultHitExplosionAtBone(self, 'TLG01_Rack', 5)
        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)
        local x, y, z = unpack(self:GetPosition())
        z = z + 3
        DamageRing(self, {x, y, z}, 0.1, 3, 1, 'Force', true)
        WaitSeconds(0.5)
        explosion.CreateDefaultHitExplosionAtBone(self, 'TLG01_Rack', 18)
        DamageRing(self, {x, y, z}, 0.1, 3, 1, 'Force', true)
        local bp = self:GetBlueprint()
        for i, w in bp.Weapon do
            if w.Label == 'MegalithDeath' then
                DamageArea(self, self:GetPosition(), w.DamageRadius, w.Damage, w.DamageType, w.DamageFriendly)
                break
            end
        end
        explosion.CreateDefaultHitExplosionAtBone(self, 'RMG_Muzzle', 6)
        self:CreateFirePlumes(army, {'RMG_Muzzle'}, 5)
        self:CreateDamageEffects('LMG_Rack', army)
        WaitSeconds(0.5)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Left_Leg02_Segment02', 1.25)
        self:CreateDamageEffects('Shield_Gen', army)
        WaitSeconds(0.5)
        explosion.CreateDefaultHitExplosionAtBone(self, 'RMG_Muzzle', 5)
        self:CreateExplosionDebris(army)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Left_Leg01_Segment02', 1.25)
        self:CreateDamageEffects('LMG_Muzzle', army)
        WaitSeconds(0.5)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Left_Leg02_Segment02', 1.25)
        explosion.CreateDefaultHitExplosionAtBone(self, 'RMG_Muzzle', 10)
        self:CreateDamageEffects('Left_Leg01_Segment01', army)
        explosion.CreateFlash(self, 'Right_Leg01_Segment01', 9.6, army)
        self:CreateWreckage(0.1)
        self:Destroy()
    end,
}

TypeClass = WRL2466b
