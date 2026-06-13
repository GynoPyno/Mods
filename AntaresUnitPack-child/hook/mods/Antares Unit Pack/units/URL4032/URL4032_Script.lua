local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local WeaponFile = import('/lua/sim/defaultweapons.lua')
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local CybranWeapons = import('/lua/cybranweapons.lua')
local CDFHvyProtonCannonWeapon = CybranWeapons.CDFHvyProtonCannonWeapon
local CDFElectronBolterWeapon = CybranWeapons.CDFElectronBolterWeapon
local CAAMissileNaniteWeapon = CybranWeapons.CAAMissileNaniteWeapon
local CollisionBeamFile = import('/lua/defaultcollisionbeams.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')

local SCUStyleDeathWeapon = ClassWeapon(BareBonesWeapon) {
    OnFire = function(self) end,
    Fire = function(self)
        local bp = self:GetBlueprint()
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:PassDamageData(self:GetDamageTable())
    end,
}

local CDFMicrowaveLaserGenerator = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam02,
    FxMuzzleFlash = {},
}

URL4032 = Class(CWalkingLandUnit) {
    WalkingAnimRate = 2.0,
    AmbientExhaustBones = {},

    Weapons = {
        DeathWeapon    = ClassWeapon(SCUStyleDeathWeapon) {},
        MainGun        = ClassWeapon(CDFMicrowaveLaserGenerator) { FxMuzzleFlash = {} },
        ParticleGun    = ClassWeapon(CDFHvyProtonCannonWeapon) {},
        ParticleGunG   = ClassWeapon(CDFHvyProtonCannonWeapon) {},
        ParticleGunD   = ClassWeapon(CDFHvyProtonCannonWeapon) {},
        LaserTurretI   = ClassWeapon(CDFElectronBolterWeapon) {},
        LaserTurretII  = ClassWeapon(CDFElectronBolterWeapon) {},
        LaserTurretIII = ClassWeapon(CDFElectronBolterWeapon) {},
        LaserTurretIV  = ClassWeapon(CDFElectronBolterWeapon) {},
        LaserTurretV   = ClassWeapon(CDFElectronBolterWeapon) {},
        LaserTurretVI  = ClassWeapon(CDFElectronBolterWeapon) {},
        LaserTurretVII  = ClassWeapon(CDFElectronBolterWeapon) {},
        LaserTurretVIII = ClassWeapon(CDFElectronBolterWeapon) {},
        AntiAirMissileI   = ClassWeapon(CAAMissileNaniteWeapon) {},
        AntiAirMissileII  = ClassWeapon(CAAMissileNaniteWeapon) {},
        AntiAirMissileIII = ClassWeapon(CAAMissileNaniteWeapon) {},
        AntiAirMissileIV  = ClassWeapon(CAAMissileNaniteWeapon) {},
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
        if self.AnimationManipulator then
            self:SetUnSelectable(true)
            self.AnimationManipulator:SetRate(0.7)
            self:ForkThread(function()
                WaitSeconds(self.AnimationManipulator:GetAnimationDuration() * self.AnimationManipulator:GetRate())
                self:SetUnSelectable(false)
                self.AnimationManipulator:Destroy()
            end)
        end
        self:SetMaintenanceConsumptionActive()
        self.WeaponsEnabled = true
    end,

    AmbientLandExhaustEffects = {
        '/effects/emitters/dirty_exhaust_smoke_02_emit.bp',
        '/effects/emitters/dirty_exhaust_sparks_02_emit.bp',
    },

    AmbientSeabedExhaustEffects = {
        '/effects/emitters/underwater_vent_bubbles_02_emit.bp',
    },

    CreateUnitAmbientEffect = function(self, layer)
        if self.AmbientEffectThread ~= nil then
            self.AmbientEffectThread:Destroy()
        end
        if self.AmbientExhaustEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'AmbientExhaustEffectsBag')
        end
        self.AmbientEffectThread = nil
        self.AmbientExhaustEffectsBag = {}
        if layer == 'Land' then
            self.AmbientEffectThread = self:ForkThread(self.UnitLandAmbientEffectThread)
        elseif layer == 'Seabed' then
            local army = self:GetArmy()
            for kE, vE in self.AmbientSeabedExhaustEffects do
                for kB, vB in self.AmbientExhaustBones do
                    table.insert(self.AmbientExhaustEffectsBag, CreateAttachedEmitter(self, vB, army, vE))
                end
            end
        end
    end,

    UnitLandAmbientEffectThread = function(self)
        local utilities = import('/lua/Utilities.lua')
        while not self:IsDead() do
            local army = self:GetArmy()
            for kE, vE in self.AmbientLandExhaustEffects do
                for kB, vB in self.AmbientExhaustBones do
                    table.insert(self.AmbientExhaustEffectsBag, CreateAttachedEmitter(self, vB, army, vE))
                end
            end
            WaitSeconds(2)
            EffectUtil.CleanupEffectBag(self, 'AmbientExhaustEffectsBag')
            WaitSeconds(utilities.GetRandomFloat(1, 7))
        end
    end,

    CreateDamageEffects = function(self, bone, army)
        for k, v in EffectTemplate.DamageFireSmoke01 do
            CreateAttachedEmitter(self, bone, army, v):ScaleEmitter(1.5)
        end
    end,
}

TypeClass = URL4032
