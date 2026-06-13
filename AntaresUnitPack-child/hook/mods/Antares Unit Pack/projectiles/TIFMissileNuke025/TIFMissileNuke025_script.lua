local TIFMissileNuke = import('/lua/terranprojectiles.lua').TIFMissileNuke
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

-- FIX: lo script originale Antares chiamava TIFMissileNuke.OnImpact DOPO self:Destroy() (riga 72),
-- causando crash in NukeProjectile.OnImpact(118) perché self.effectEntityPath è nil per il parent.
-- FIX traiettoria: TrackTarget=true + TrackTargetGround=true nel blueprint causano al motore C++
-- di reintrodurre vy negativo durante la crociera anche con SetTurnRate(0).
-- Soluzione: velocity leveling + TrackTarget(false) dopo SetTurnRate(0), riabilitato a dist<15.
-- Velocità di crociera: InitialSpeed(6) + Acceleration(3) × 9.5s = 34.5 u/s
TIFMissileNuke025 = Class(TIFMissileNuke) {

    OnCreate = function(self)
        TIFMissileNuke.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.MoveThread = self:ForkThread(self.MovementThread)
    end,

    PassDamageData = function(self, damageData)
        TIFMissileNuke.PassDamageData(self, damageData)
        local launcherbp = self:GetLauncher():GetBlueprint()
        self.ChildDamageData = table.copy(self.DamageData)
    end,

    InitialEffects = {'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',},
    LaunchEffects = {
        '/effects/emitters/nuke_munition_launch_trail_03_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_05_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_07_emit.bp',
    },
    ThrustEffects = {
        '/effects/emitters/nuke_munition_launch_trail_04_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_06_emit.bp',
    },

    OnImpact = function(self, TargetType, TargetEntity)
        local FxFragEffect = EffectTemplate.TFragmentationSensorShellFrag
        local ChildProjectileBP = '/mods/Antares Unit Pack/projectiles/TIFMissileNuke12/TIFMissileNuke12_proj.bp'

        for k, v in FxFragEffect do
            CreateEmitterAtEntity(self, self:GetArmy(), v)
        end

        -- FIX: DamageArea diretto PRIMA di Destroy(). Non chiamiamo TIFMissileNuke.OnImpact perché
        -- risalirebbe a NukeProjectile.OnImpact che usa self.effectEntityPath (nil per il parent MIRV).
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

        -- 6 proiettili in schema a ventaglio (7 totali)
        local numProjectiles = 6
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
        local launcher = self:GetLauncher()
        self.CreateEffects(self, self.InitialEffects, army, 1)
        self:TrackTarget(false)
        WaitSeconds(2.5)
        self:SetCollision(true)
        self.CreateEffects(self, self.LaunchEffects, army, 1)
        WaitSeconds(2.5)
        self.CreateEffects(self, self.ThrustEffects, army, 3)
        WaitSeconds(2.5)
        self:TrackTarget(true)
        self:SetDestroyOnWater(true)
        self:SetTurnRate(47.36)
        WaitSeconds(2)
        self:SetTurnRate(0)
        self:SetAcceleration(0.001)
        -- GetVelocity() restituisce direzione normalizzata: dopo SetVelocity(dir) serve SetVelocity(speed).
        -- Velocità di crociera: InitialSpeed(6) + Acceleration(3) × 9.5s = 34.5 u/s
        local vx, vy, vz = self:GetVelocity()
        local hDist = math.sqrt(vx*vx + vz*vz)
        if hDist > 0.01 then
            self:SetVelocity(vx / hDist, 0, vz / hDist)
            self:SetVelocity(34.5)
        end
        -- FIX: disabilita tracking durante la crociera per impedire al motore di reintrodurre vy.
        -- TrackTarget=true + TrackTargetGround=true nel blueprint farebbero puntare il missile verso
        -- il target a terra anche con SetTurnRate(0), rompendo la crociera orizzontale (vy=0).
        -- Cache posizione prima di disabilitare: GetCurrentTargetPosition() potrebbe restituire
        -- nil dopo TrackTarget(false) per alcune classi base.
        -- Viene riabilitato in SetTurnRateByDist quando dist < 15 per il dive terminale.
        local tpos = self:GetCurrentTargetPosition()
        if tpos then self.CachedTargetPos = tpos end
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

    -- FIX: usa CachedTargetPos se disponibile — GetCurrentTargetPosition() puo' restituire nil
    -- dopo TrackTarget(false) per alcune classi base. La cache viene popolata appena prima
    -- di disabilitare il tracking nel MovementThread.
    GetDistanceToTarget = function(self)
        local tpos = self.CachedTargetPos or self:GetCurrentTargetPosition()
        if not tpos then return 9999 end
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
    end,
}

TypeClass = TIFMissileNuke025
