#
# Aeon Very Fast Anti-Missile Missile
#
local AIMFlare01Projectile = import('/Mods/OrbitalWarsMod/hook/lua/modprojectiles.lua').AIMFlare01Projectile

AIMAntiMissile01 = Class(AIMFlare01Projectile) {
    OnCreate = function(self)
        AIMFlare01Projectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,
}

TypeClass = AIMAntiMissile01

