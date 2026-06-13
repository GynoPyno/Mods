local EmitterProjectile = import('/lua/sim/DefaultProjectiles.lua').EmitterProjectile

GatArtprojFix = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/gauss_cannon_munition_trail_03_emit.bp'},
}
TypeClass = GatArtprojFix
