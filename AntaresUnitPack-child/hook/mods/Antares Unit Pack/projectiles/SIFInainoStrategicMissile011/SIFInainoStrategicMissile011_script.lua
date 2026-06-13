-- Hook SIFInainoStrategicMissile011: GSMB319 Seraphim MIRV parent.
-- Fix 1: MovementThread esteso a 4+4+4 = 12s → quota ~288u (era 2.5+2.5+2.5=7.5s → ~129u).
--   Con DetonateBelowHeight=150 il margine di sicurezza e' ora 138u.
-- Fix 2: OnImpact originale chiamava SExperimentalStrategicMissile.OnImpact dopo
--   self:Destroy() → NukeProjectile.OnImpact crash (effectEntityPath=nil).
--   La catena parent non e' necessaria: i figli gestiscono il danno tramite InainoEffectController01.
-- Fix 3: GetDistanceToTarget nil guard (GetCurrentTargetPosition puo' restituire nil).
-- Fix 4: TrackTarget(false) durante la crociera (come UEF/Cybran/Aeon) per impedire al motore
--   di reintrodurre vy con TrackTarget=true + TurnRate=0. La posizione target viene cachata
--   appena prima di disabilitare il tracking per garantire che GetDistanceToTarget() la trovi
--   anche se GetCurrentTargetPosition() restituisce nil dopo TrackTarget(false).
--   Riabilitato a dist<15 per il dive terminale.

local OriginalClass = SIFInainoStrategicMissile011
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

SIFInainoStrategicMissile011 = Class(OriginalClass) {

    GetDistanceToTarget = function(self)
        local tpos = self.CachedTargetPos or self:GetCurrentTargetPosition()
        if not tpos then return 9999 end
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
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

    -- h = 6*12 + 0.5*3*144 = 288u | velocity leveling orizzontale a 34.5 u/s dopo l'arco
    MovementThread = function(self)
        local army = self:GetArmy()
        local launcher = self:GetLauncher()
        self.CreateEffects(self, self.InitialEffects, army, 1)
        self:TrackTarget(false)
        WaitSeconds(4)
        self:SetCollision(true)
        self.CreateEffects(self, self.LaunchEffects, army, 1)
        WaitSeconds(4)
        self.CreateEffects(self, self.ThrustEffects, army, 3)
        WaitSeconds(4)
        self:TrackTarget(true)
        self:SetDestroyOnWater(true)
        self:SetTurnRate(47.36)
        WaitSeconds(2)
        self:SetTurnRate(0)
        self:SetAcceleration(0.001)
        local vx, vy, vz = self:GetVelocity()
        local hDist = math.sqrt(vx*vx + vz*vz)
        if hDist > 0.01 then
            self:SetVelocity(vx / hDist, 0, vz / hDist)
            self:SetVelocity(34.5)
        end
        -- Cache posizione target prima di disabilitare tracking: GetCurrentTargetPosition()
        -- potrebbe restituire nil dopo TrackTarget(false) per alcune classi base Seraphim.
        local tpos = self:GetCurrentTargetPosition()
        if tpos then self.CachedTargetPos = tpos end
        self:TrackTarget(false)
        self.WaitTime = 0.5
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        local FxFragEffect = EffectTemplate.TFragmentationSensorShellFrag
        local ChildProjectileBP = '/mods/Antares Unit Pack/projectiles/SIFMIRVInainoStrategicMissile02/SIFMIRVInainoStrategicMissile02_proj.bp'

        for k, v in FxFragEffect do
            CreateEmitterAtEntity(self, self:GetArmy(), v)
        end

        local vx, vy, vz = self:GetVelocity()
        local velocity = 6

        self:CreateChildProjectile(ChildProjectileBP):SetVelocity(vx, vy, vz):SetVelocity(velocity):PassDamageData(self.DamageData)

        local numProjectiles = 10
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
}
TypeClass = SIFInainoStrategicMissile011
