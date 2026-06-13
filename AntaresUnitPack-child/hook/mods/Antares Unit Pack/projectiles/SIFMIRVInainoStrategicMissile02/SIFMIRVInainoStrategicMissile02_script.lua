-- Hook SIFMIRVInainoStrategicMissile02: child warhead GSMB319 Seraphim MIRV.
-- Fix 1: OnCreate imposta effectEntityPath richiesto da NukeProjectile.OnImpact in FAF moderno.
--   InainoEffectController01.PassData(self.Data) gestisce: visual (MainBlast, fingers, plume),
--   ring damage (InnerRingDamage + OuterRingDamage), camera shake e decal principale.
-- Fix 2: OnImpact rimuove la creazione manuale di InainoEffectController01 (ora via effectEntityPath
--   nella catena NukeProjectile.OnImpact → PassData). Corregge la chiave audio Explosion → NukeExplosion.
-- Fix 3: GetDistanceToTarget nil guard (i figli creati con CreateChildProjectile non hanno
--   target assegnato → GetCurrentTargetPosition() restituisce nil).
-- Fix 4: SetTurnRateByDist aggiunge TrackTarget(true) per il dive terminale.

local OriginalClass = SIFMIRVInainoStrategicMissile02
local SIFInainoStrategicMissile = import('/lua/seraphimprojectiles.lua').SIFInainoStrategicMissile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

SIFMIRVInainoStrategicMissile02 = Class(OriginalClass) {

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
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

    OnCreate = function(self)
        OriginalClass.OnCreate(self)
        self.effectEntityPath = '/effects/entities/InainoEffectController01/InainoEffectController01_proj.bp'
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE, TargetEntity) then
            local myBlueprint = self:GetBlueprint()
            if myBlueprint.Audio.NukeExplosion then
                self:PlaySound(myBlueprint.Audio.NukeExplosion)
            end
            local rotation = RandomFloat(0, 2*math.pi)
            CreateDecal(self:GetPosition(), rotation, 'scorch_004_albedo', '', 'Albedo', 13, 13, 300, 15, self:GetArmy())
        end
        SIFInainoStrategicMissile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = SIFMIRVInainoStrategicMissile02
