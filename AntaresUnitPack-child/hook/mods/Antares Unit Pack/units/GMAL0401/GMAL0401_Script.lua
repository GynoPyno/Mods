-- Fix GMAL0401 (Improved Experimental Assault Bot):
-- LeftArmCannon.PlayFxWeaponPackSequence usa 'EffectUtil' come global (typo: e' importato come 'EffectUtils')
-- FAF's closed env blocca l'accesso a globali non definite → crash ad ogni sparo.
local EffectUtil = import('/lua/effectutilities.lua')
local Effects = import('/lua/effecttemplates.lua')
local ADFCannonOblivionWeapon = import('/lua/aeonweapons.lua').ADFCannonOblivionWeapon

GMAL0401.Weapons.LeftArmCannon.PlayFxWeaponPackSequence = function(self)
    if self.SpinManip then
        self.SpinManip:SetTargetSpeed(0)
    end
    if self.SpinManip2 then
        self.SpinManip2:SetTargetSpeed(0)
    end
    self.ExhaustEffects = EffectUtil.CreateBoneEffects(self.unit, 'Left_Arm_Muzzle01', self.unit:GetArmy(), Effects.WeaponSteam01)
    self.ExhaustEffects = EffectUtil.CreateBoneEffects(self.unit, 'Right_Arm_Muzzle01', self.unit:GetArmy(), Effects.WeaponSteam01)
    ADFCannonOblivionWeapon.PlayFxWeaponPackSequence(self)
end
