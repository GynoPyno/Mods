local TIFMissileNuke = import('/lua/terranprojectiles.lua').TIFMissileNuke
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- FIX: lo script originale chiamava TIFMissileNuke.OnImpact senza impostare self.effectEntityPath,
-- causando crash in NukeProjectile.OnImpact(118): CreateProjectile(nil) → "string expected but got nil".
-- Il crash impediva self:Destroy() → il child restava vivo e triggerava OnImpact ogni tick (loop nel log).
-- Soluzione: impostare self.effectEntityPath in OnCreate, poi delegare a TIFMissileNuke.OnImpact.
-- FIX traiettoria: GetDistanceToTarget() ritorna nil quando il child non ha target assegnato.
-- Nil in SetTurnRateByDist causava deviazioni. Restituire 9999 congela SetTurnRate(0) → linea retta.
TIFMissileNuke12 = Class(TIFMissileNuke) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_06_emit.bp',
    InitialEffects = {'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',},
    LaunchEffects = {
        '/effects/emitters/nuke_munition_launch_trail_03_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_05_emit.bp',
    },
    ThrustEffects = {'/effects/emitters/nuke_munition_launch_trail_04_emit.bp',},

    OnImpact = function(self, TargetType, TargetEntity)
        -- effectEntityPath impostato in OnCreate: NukeProjectile.OnImpact può creare il controller UEF
        TIFMissileNuke.OnImpact(self, TargetType, TargetEntity)
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        if self.ProjectileDamaged then
            for k, v in self.ProjectileDamaged do
                v(self)
            end
        end
        TIFMissileNuke.DoTakeDamage(self, instigator, amount, vector, damageType)
    end,

    OnCreate = function(self)
        TIFMissileNuke.OnCreate(self)
        -- effectEntityPath richiesto da NukeProjectile.OnImpact per il controller dell'esplosione UEF
        self.effectEntityPath = '/effects/Entities/UEFNukeEffectController01/UEFNukeEffectController01_proj.bp'
        local launcher = self:GetLauncher()
        if launcher and not launcher:IsDead() and launcher.EventCallbacks and launcher.EventCallbacks.ProjectileDamaged then
            self.ProjectileDamaged = {}
            for k, v in launcher.EventCallbacks.ProjectileDamaged do
                table.insert(self.ProjectileDamaged, v)
            end
        end
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.MovementTurnLevel = 1
        self:ForkThread(self.MovementThread)
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
        self:SetTurnRate(47.36)
        WaitSeconds(2)
        self:SetTurnRate(0)
        self:SetAcceleration(0.001)
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
        elseif dist < 32 then
            self:SetTurnRate(50)
        end
    end,

    -- FIX: GetCurrentTargetPosition() ritorna nil per i figli creati con CreateChildProjectile
    -- senza target assegnato. Restituire 9999 congela SetTurnRate(0) → il child vola in linea retta.
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        if not tpos then return 9999 end
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
    end,
}

TypeClass = TIFMissileNuke12
