local EmitterProjectile = import('/lua/sim/DefaultProjectiles.lua').EmitterProjectile

local FxLandHit = {
    '/mods/AntaresUnitPack-child/effects/emitters/napalm_hvy_01_emit.bp',
    '/effects/emitters/antimatter_hit_01_emit.bp',   -- glow
    '/effects/emitters/antimatter_hit_02_emit.bp',   -- flash
    '/effects/emitters/antimatter_hit_03_emit.bp',   -- sparks
    '/effects/emitters/antimatter_hit_06_emit.bp',   -- base fire
    '/effects/emitters/antimatter_hit_07_emit.bp',   -- base dark
    '/effects/emitters/antimatter_hit_09_emit.bp',   -- base smoke
    '/effects/emitters/antimatter_hit_11_emit.bp',   -- base highlights
    '/effects/emitters/antimatter_ring_01_emit.bp',  -- anello esterno
    '/effects/emitters/antimatter_ring_02_emit.bp',  -- anello interno
    '/effects/emitters/destruction_explosion_fire_plume_02_emit.bp',
    '/effects/emitters/destruction_explosion_fire_plume_03_emit.bp',
    '/effects/emitters/destruction_explosion_fire_plume_04_emit.bp',
    '/effects/emitters/fire_cloud_02_emit.bp',
    '/effects/emitters/destruction_explosion_fire_02_emit.bp',
    '/effects/emitters/destruction_land_hit_dirt_01_emit.bp',
    '/effects/emitters/destruction_explosion_smoke_03_emit.bp',
    '/effects/emitters/destruction_explosion_smoke_07_emit.bp',
}

-- Su unità: antimatter hit senza emitter plume (04/05/08/10) che formano il fungo
local FxUnitHit = {
    '/effects/emitters/antimatter_hit_01_emit.bp',   -- glow
    '/effects/emitters/antimatter_hit_02_emit.bp',   -- flash
    '/effects/emitters/antimatter_hit_03_emit.bp',   -- sparks
    '/effects/emitters/antimatter_hit_06_emit.bp',   -- base fire
    '/effects/emitters/antimatter_hit_07_emit.bp',   -- base dark
    '/effects/emitters/antimatter_hit_09_emit.bp',   -- base smoke
    '/effects/emitters/antimatter_hit_11_emit.bp',   -- base highlights
    '/effects/emitters/antimatter_ring_01_emit.bp',  -- anello esterno
    '/effects/emitters/destruction_unit_hit_flash_01_emit.bp',
    '/effects/emitters/destruction_unit_hit_shrapnel_01_emit.bp',
}

EQCAIARTprojFix = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/gauss_cannon_munition_trail_03_emit.bp'},

    FxImpactLand  = FxLandHit,
    FxImpactUnit  = FxUnitHit,
    FxImpactProp  = FxLandHit,
    FxLandHitScale = 1.3,
    FxUnitHitScale = 1.0,

    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local launcher = self:GetLauncher()
        local px, py, pz = pos[1], pos[2], pos[3]

        -- DoT incendiario: 5 tick × 1s × 364 = 1820 ≈ 8% danno impatto, 5s totali
        local instigator = launcher
        local dotPos = {px, py, pz}
        ForkThread(function()
            for i = 1, 5 do
                WaitSeconds(1)
                if instigator and not instigator.Dead then
                    DamageArea(instigator, dotPos, 10, 364, 'Normal', false)
                end
            end
        end)

        EmitterProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = EQCAIARTprojFix
