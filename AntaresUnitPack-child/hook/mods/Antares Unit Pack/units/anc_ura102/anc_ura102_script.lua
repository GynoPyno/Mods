-- Fix: OnKilled chiama CreateAttachedEmitter(...):ScaleEmitter(2.5) in catena.
-- Se il blueprint flamethrower_emit.bp non esiste (AlienNationsUnitAdditions non installato o
-- path invalido), CreateAttachedEmitter ritorna nil → ScaleEmitter su nil → crash.
-- Re-importiamo CAirUnit perché nel file originale è una local non accessibile dal hook.
local CAirUnit = import('/lua/cybranunits.lua').CAirUnit

ANC_URA102.OnKilled = function(self, instigator, type, overkillRatio)
    CAirUnit.OnKilled(self, instigator, type, overkillRatio)
    local emitter = CreateAttachedEmitter(self, 'Exhaust', self:GetArmy(), '/mods/AlienNationsUnitAdditions/effects/emitters/flamethrower_emit.bp')
    if emitter then emitter:ScaleEmitter(2.5) end
end
