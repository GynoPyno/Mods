-- Hook sul child MIRV Aeon. Il file originale (Antares) viene eseguito prima.
-- Questo hook eredita da OriginalClass e sovrascrive solo i metodi difettosi.
local OriginalClass = AIFQuantumWarhead13

-- Necessario per chiamare AQuantumWarheadProjectile.OnImpact direttamente,
-- bypassando la versione Antares che usa PassData(self.Data) — rotto in FAF moderno.
local AQuantumWarheadProjectile = import('/lua/aeonprojectiles.lua').AQuantumWarheadProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AIFQuantumWarhead13 = Class(OriginalClass) {

    -- FIX: nil guard — CreateChildProjectile non passa il target al figlio
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        if not tpos then return 9999 end
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
    end,

    -- FIX: imposta effectEntityPath richiesto da NukeProjectile.OnImpact in FAF moderno.
    --      La versione vanilla di AIFQuantumWarhead02 (path /projectiles/) ha EffectThread.
    --      La versione FAF (/faforever/projectiles/) usa PassData ma NON ha EffectThread.
    --      CreateProjectile('/projectiles/...') carica la versione vanilla → EffectThread OK.
    OnCreate = function(self)
        OriginalClass.OnCreate(self)
        self.effectEntityPath = '/projectiles/AIFQuantumWarhead02/AIFQuantumWarhead02_proj.bp'
    end,

    -- FIX: velocity leveling a 34.5 u/s + TrackTarget(false) dopo leveling
    -- v0=6 (da SetVelocity nel parent), Acceleration=3, t=9.5s → 34.5 u/s
    MovementThread = function(self)
        local army = self:GetArmy()
        local launcher = self:GetLauncher()
        self:TrackTarget(false)
        WaitSeconds(2.5)
        self:SetCollision(true)
        self:SetDestroyOnWater(true)
        WaitSeconds(2.5)
        WaitSeconds(2.5)
        self:TrackTarget(true)
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

    -- FIX: delega ad AQuantumWarheadProjectile.OnImpact (bypassa la versione Antares rotta).
    --      AQuantumWarheadProjectile.OnImpact → NukeProjectile.OnImpact:
    --        1. Crea l'entity effect via effectEntityPath → fork EffectThread (visuale esplosione)
    --        2. NullShell.OnImpact → DoDamage (danno diretto dell'impatto) → Destroy
    --      FIX: Audio.NukeExplosion (la chiave Explosion non esiste nel blueprint child)
    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE, TargetEntity) then
            local myBlueprint = self:GetBlueprint()
            if myBlueprint.Audio.NukeExplosion then
                self:PlaySound(myBlueprint.Audio.NukeExplosion)
            end
            local rotation = RandomFloat(0, 2*math.pi)
            CreateDecal(self:GetPosition(), rotation, 'scorch_004_albedo', '', 'Albedo', 13, 13, 300, 15, self:GetArmy())
        end
        AQuantumWarheadProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}

TypeClass = AIFQuantumWarhead13
