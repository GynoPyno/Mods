-- Inietta SIFCommanderDeathWeapon nel modulo seraphimweapons.
-- La versione FAF installata non esporta questa classe nel modulo,
-- causando il crash di GSMB319_script.lua riga 3 (SWeapons.SIFCommanderDeathWeapon nil -> global checker).
-- Replica fedele della definizione in /faforever/lua/seraphimweapons.lua.
local BareBonesWeapon = import('/lua/sim/DefaultWeapons.lua').BareBonesWeapon

SIFCommanderDeathWeapon = Class(BareBonesWeapon) {
    OnCreate = function(self)
        BareBonesWeapon.OnCreate(self)
        local myBlueprint = self:GetBlueprint()
        self.Data = {
            NukeOuterRingDamage    = myBlueprint.NukeOuterRingDamage    or 10,
            NukeOuterRingRadius    = myBlueprint.NukeOuterRingRadius    or 40,
            NukeOuterRingTicks     = myBlueprint.NukeOuterRingTicks     or 20,
            NukeOuterRingTotalTime = myBlueprint.NukeOuterRingTotalTime or 10,
            NukeInnerRingDamage    = myBlueprint.NukeInnerRingDamage    or 2000,
            NukeInnerRingRadius    = myBlueprint.NukeInnerRingRadius    or 30,
            NukeInnerRingTicks     = myBlueprint.NukeInnerRingTicks     or 24,
            NukeInnerRingTotalTime = myBlueprint.NukeInnerRingTotalTime or 24,
        }
    end,
    OnFire = function(self) end,
    Fire = function(self)
        local myBlueprint = self:GetBlueprint()
        local myProjectile = self.unit:CreateProjectile(myBlueprint.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        myProjectile:PassDamageData(self:GetDamageTable())
        if self.Data then
            myProjectile:PassData(self.Data)
        end
    end,
}
