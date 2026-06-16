-- Compat globali per Antares Unit Pack (GMAB407) — richiesti dallo script originale
-- AIFCommanderDeathWeapon: rimosso da FAF, ora e' ACUDeathWeapon in /lua/sim/defaultweapons.lua
AIFCommanderDeathWeapon = import('/lua/sim/defaultweapons.lua').ACUDeathWeapon

-- Fix LDUC11 (Planetary Colossus) + WZA7401 (Intergalactic Colossus):
-- Nel FAF corrente il grab e' gestito da ADFTractorClaw.OnFire, che:
--   1. valida il target (GetUnitBehindTarget, Tractored check)
--   2. imposta RunningTractorThread = true e target.Tractored = true
--   3. forka TractorThread(self, target, muzzle)
-- Reimplementiamo OnFire aggiungendo il check categorie prima dell'avvio del thread.
-- TargetRestrictDisallow nel blueprint e' insufficiente per il beam grab (opera lato C++).
local _OnInvalidTargetThread = ADFTractorClaw.OnInvalidTargetThread
local _GetUnitBehindTarget   = ADFTractorClaw.GetUnitBehindTarget
ADFTractorClaw.OnFire = function(self)
    if self.RunningTractorThread then
        self.Trash:Add(ForkThread(_OnInvalidTargetThread, self))
        return
    end

    local blipOrUnit = self:GetCurrentTarget()
    if not blipOrUnit then return end

    local target = _GetUnitBehindTarget(self, blipOrUnit)
    if not target then
        self.Trash:Add(ForkThread(_OnInvalidTargetThread, self))
        return
    end

    if target.Tractored then
        self.Trash:Add(ForkThread(_OnInvalidTargetThread, self))
        return
    end

    if EntityCategoryContains(categories.EXPERIMENTAL,  target) or
       EntityCategoryContains(categories.STRUCTURE,     target) or
       EntityCategoryContains(categories.COMMAND,       target) or
       EntityCategoryContains(categories.NAVAL,         target) or
       EntityCategoryContains(categories.SUBCOMMANDER,  target) or
       not EntityCategoryContains(categories.ALLUNITS,  target) then
        self.Trash:Add(ForkThread(_OnInvalidTargetThread, self))
        return
    end

    target.Tractored = true
    self.RunningTractorThread = true
    local muzzle = self.Blueprint.MuzzleSpecial
    self.TractorThreadInstance = ForkThread(self.TractorThread, self, target, muzzle)
end
