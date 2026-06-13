local EmitterProjectile = import('/lua/sim/DefaultProjectiles.lua').EmitterProjectile

TDFGauss25fix = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/gauss_cannon_munition_trail_03_emit.bp'},
    FxLandHitScale = 2.5,
}
TypeClass = TDFGauss25fix
