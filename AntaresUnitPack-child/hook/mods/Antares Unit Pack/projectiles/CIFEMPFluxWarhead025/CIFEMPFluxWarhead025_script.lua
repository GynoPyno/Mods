local CEMPFluxWarheadProjectile = import('/lua/cybranprojectiles.lua').CEMPFluxWarheadProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

-- FIX: lo script originale Antares usava Class() invece di ClassProjectile (pattern vanilla),
-- chiamava CEMPFluxWarheadProjectile.OnImpact DOPO self:Destroy() (entity invalida),
-- e aveva la classe nominata MirvCIFEMPFluxWarhead01 invece di CIFEMPFluxWarhead025.
-- Causa dell'esplosione prematura: DetonateBelowHeight=95 su quota crociera ~129u (margine 34u)
-- → qualsiasi deriva verso il basso durante la crociera triggera lo split.
-- Fix traiettoria identico a MirvCIFEMPFluxWarhead01: timing 3/3/6, velocity leveling, SetVelocity(48).
CIFEMPFluxWarhead025 = Class(CEMPFluxWarheadProjectile) {
    FxSplashScale = 0.5,
    FxTrails = {},

    LaunchSound = 'Nuke_Launch',
    ExplodeSound = 'Nuke_Impact',
    AmbientSound = 'Nuke_Flight',

    InitialEffects = {'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',},
    LaunchEffects  = {'/effects/emitters/nuke_munition_launch_trail_03_emit.bp',},
    ThrustEffects  = {'/effects/emitters/nuke_munition_launch_trail_04_emit.bp',},

    OnCreate = function(self)
        CEMPFluxWarheadProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.MoveThread = self:ForkThread(self.MovementThread)
    end,

    PassDamageData = function(self, damageData)
        CEMPFluxWarheadProjectile.PassDamageData(self, damageData)
        local launcherbp = self:GetLauncher():GetBlueprint()
        self.ChildDamageData = table.copy(self.DamageData)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        local FxFragEffect = EffectTemplate.TFragmentationSensorShellFrag
        local ChildProjectileBP = '/mods/Antares Unit Pack/projectiles/CIFEMPFluxWarhead14/CIFEMPFluxWarhead14_proj.bp'

        for k, v in FxFragEffect do
            CreateEmitterAtEntity(self, self:GetArmy(), v)
        end

        -- FIX: DamageArea diretto PRIMA di Destroy(). Non chiamiamo CEMPFluxWarheadProjectile.OnImpact
        -- perché risalirebbe a NukeProjectile.OnImpact che usa self.effectEntityPath (nil per il parent).
        if self.DamageData then
            DamageArea(self, self:GetPosition(),
                self.DamageData.DamageRadius   or 0,
                self.DamageData.DamageAmount   or 0,
                self.DamageData.DamageType     or 'Normal',
                self.DamageData.DamageFriendly or false)
        end

        local vx, vy, vz = self:GetVelocity()
        local velocity = 6

        -- Un proiettile iniziale nella stessa direzione del parent
        self:CreateChildProjectile(ChildProjectileBP):SetVelocity(vx, vy, vz):SetVelocity(velocity):PassDamageData(self.DamageData)

        -- 8 proiettili in schema a ventaglio (9 totali)
        local numProjectiles = 8
        local angle = (2*math.pi) / numProjectiles
        local angleInitial = RandomFloat(0, angle)
        local angleVariation = angle * 0.35
        local spreadMul = 2.5
        local xVec = 0
        local yVec = vy
        local zVec = 0

        for i = 0, (numProjectiles - 1) do
            xVec = vx + (math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            local proj = self:CreateChildProjectile(ChildProjectileBP)
            proj:SetVelocity(xVec, yVec, zVec)
            proj:SetVelocity(velocity)
            proj:PassDamageData(self.DamageData)
        end

        self:Destroy()
    end,

    CreateEffects = function(self, EffectTable, army, scale)
        for k, v in EffectTable do
            self.Trash:Add(CreateAttachedEmitter(self, -1, army, v):ScaleEmitter(scale))
        end
    end,

    MovementThread = function(self)
        local army = self:GetArmy()
        self.CreateEffects(self, self.InitialEffects, army, 1)
        self:TrackTarget(false)
        WaitSeconds(3)
        self:SetCollision(true)
        self.CreateEffects(self, self.LaunchEffects, army, 1)
        WaitSeconds(3)
        self.CreateEffects(self, self.ThrustEffects, army, 3)
        WaitSeconds(6)
        self:TrackTarget(true)
        self:SetDestroyOnWater(true)
        self:SetTurnRate(47.36)
        WaitSeconds(2)
        self:SetTurnRate(0)
        self:SetAcceleration(0.001)
        -- GetVelocity() restituisce direzione normalizzata: dopo SetVelocity(dir) serve SetVelocity(speed).
        -- Velocità di crociera: InitialSpeed(6) + Acceleration(3) × 14s = 48 u/s
        local vx, vy, vz = self:GetVelocity()
        local hDist = math.sqrt(vx*vx + vz*vz)
        if hDist > 0.01 then
            self:SetVelocity(vx / hDist, 0, vz / hDist)
            self:SetVelocity(48)
        end
        -- FIX: disabilita tracking durante la crociera per impedire al motore di reintrodurre vy.
        -- TrackTarget=true + TrackTargetGround=true nel blueprint farebbero puntare il missile verso
        -- il target a terra anche con SetTurnRate(0), rompendo la crociera orizzontale (vy=0).
        -- Viene riabilitato in SetTurnRateByDist quando dist < 15 per il dive terminale.
        self:TrackTarget(false)
        self.WaitTime = 0.5
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > 150 then
            self:SetTurnRate(0)
        elseif dist > 75 and dist <= 150 then
            self.WaitTime = 0.3
        elseif dist > 32 and dist <= 75 then
            self.WaitTime = 0.1
        elseif dist < 15 then
            self:TrackTarget(true)
            self:SetTurnRate(95)
        end
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        if not tpos then return 9999 end
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
    end,
}

TypeClass = CIFEMPFluxWarhead025
