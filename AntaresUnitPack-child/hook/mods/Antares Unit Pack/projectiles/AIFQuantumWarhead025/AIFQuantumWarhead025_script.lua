-- Hook sul parent MIRV Aeon. Il file originale (Antares) viene eseguito prima.
-- Questo hook eredita da OriginalClass e sovrascrive solo i metodi difettosi.
local OriginalClass = AIFQuantumWarhead025

local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AIFQuantumWarhead025 = Class(OriginalClass) {

    -- FIX: usa CachedTargetPos se disponibile — GetCurrentTargetPosition() puo' restituire nil
    -- dopo TrackTarget(false) per alcune classi base. La cache viene popolata appena prima
    -- di disabilitare il tracking nel MovementThread.
    GetDistanceToTarget = function(self)
        local tpos = self.CachedTargetPos or self:GetCurrentTargetPosition()
        if not tpos then return 9999 end
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
    end,

    -- FIX: salita estesa a 12s per quota crociera ~288u (come MIRV UEF/Cybran)
    -- h = 6*12 + 0.5*3*144 = 288u  |  velocity leveling orizzontale a 34.5 u/s dopo l'arco
    MovementThread = function(self)
        local army = self:GetArmy()
        local launcher = self:GetLauncher()
        self:TrackTarget(false)
        WaitSeconds(4)
        self:SetCollision(true)
        WaitSeconds(4)
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
        local tpos = self:GetCurrentTargetPosition()
        if tpos then self.CachedTargetPos = tpos end
        self:TrackTarget(false)
        self.WaitTime = 0.5
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    -- FIX: aggiunto TrackTarget(true) per il dive terminale
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

    -- FIX: rimossa chiamata AQuantumWarheadProjectile.OnImpact dopo Destroy()
    -- Quella catena usa effectEntityPath=nil → NukeProjectile.OnImpact → CreateProjectile(nil) crash
    OnImpact = function(self, TargetType, TargetEntity)
        local FxFragEffect = EffectTemplate.TFragmentationSensorShellFrag
        local ChildProjectileBP = '/mods/Antares Unit Pack/projectiles/AIFQuantumWarhead13/AIFQuantumWarhead13_proj.bp'

        for k, v in FxFragEffect do
            CreateEmitterAtEntity(self, self:GetArmy(), v)
        end

        local vx, vy, vz = self:GetVelocity()
        local velocity = 6

        self:CreateChildProjectile(ChildProjectileBP):SetVelocity(vx, vy, vz):SetVelocity(velocity):PassDamageData(self.DamageData)

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
}

TypeClass = AIFQuantumWarhead025
