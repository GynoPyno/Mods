local CEMPFluxWarheadProjectile = import('/lua/cybranprojectiles.lua').CEMPFluxWarheadProjectile

CIFEMPFluxWarhead14 = Class(CEMPFluxWarheadProjectile) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_06_emit.bp',
    FxSplashScale = 0.5,
    FxTrails = {},

    LaunchSound = 'Nuke_Launch',
    ExplodeSound = 'Nuke_Impact',
    AmbientSound = 'Nuke_Flight',

    InitialEffects = {'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',},
    LaunchEffects  = {'/effects/emitters/nuke_munition_launch_trail_03_emit.bp',},
    ThrustEffects  = {'/effects/emitters/nuke_munition_launch_trail_04_emit.bp',},

    -- FIX: CEMPFluxWarheadProjectile.OnImpact → NukeProjectile.OnImpact (FAF packed) usa
    -- self.effectEntityPath per CreateProjectile, non NukeInnerRingProjectile. Senza il campo
    -- il crash era CreateProjectile(nil). La delega gestisce: fungo atomico (CIFEMPFluxWarhead02),
    -- suono NukeExplosion, DoDamage via NullShell.OnImpact, e Destroy del proiettile.
    OnImpact = function(self, TargetType, TargetEntity)
        CEMPFluxWarheadProjectile.OnImpact(self, TargetType, TargetEntity)
    end,

    OnCreate = function(self)
        CEMPFluxWarheadProjectile.OnCreate(self)
        -- effectEntityPath richiesto da NukeProjectile.OnImpact per il proiettile visivo dell'esplosione
        self.effectEntityPath = '/projectiles/CIFEMPFluxWarhead02/CIFEMPFluxWarhead02_proj.bp'
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
        self.CreateEffects(self, self.InitialEffects, army, 1)
        self:TrackTarget(false)
        WaitSeconds(2.5)
        self:SetCollision(true)
        self:SetDestroyOnWater(true)
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

    -- FIX: GetCurrentTargetPosition() ritorna nil per i proiettili figlio (orphan, creati
    -- con CreateChildProjectile senza target). Restituire distanza grande per congelare
    -- il turn rate a 0 e fermare il loop spam nel log.
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        if not tpos then return 9999 end
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
    end,
}

TypeClass = CIFEMPFluxWarhead14
