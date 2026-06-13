local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local WeaponsFile = import('/lua/terranweapons.lua')
local TAMPhalanxWeapon = WeaponsFile.TAMPhalanxWeapon
local TIFArtilleryWeapon = WeaponsFile.TIFArtilleryWeapon
local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon

UEB2210 = Class(TStructureUnit) {
    Weapons = {
        Gatling01 = ClassWeapon(TIFArtilleryWeapon) {
            FxMuzzleFlashScale = 3,

            PlayFxWeaponUnpackSequence = function(self)
                if not self.SpinManip then
                    self.SpinManip = CreateRotator(self.unit, 'AxeGatling', 'z', nil, 130, 180, 60)
                    self.unit.Trash:Add(self.SpinManip)
                end
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(130)
                end
                TAMPhalanxWeapon.PlayFxWeaponUnpackSequence(self)
            end,

            PlayFxWeaponPackSequence = function(self)
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(0)
                end
                TAMPhalanxWeapon.PlayFxWeaponPackSequence(self)
            end,

            -- Override del WeaponPackingState per evitare snap-back istantaneo.
            -- La versione base chiama AimManipulatorSetEnabled(false) che forza le ossa
            -- alla posizione di riposo istantaneamente. Omettendola, l'aim manipulator
            -- resta attivo e il turret torna al centro a TurretYawSpeed (fluido).
            WeaponPackingState = State(DefaultProjectileWeapon.WeaponPackingState) {
                Main = function(self)
                    self.unit:SetBusy(true)
                    local bp = self:GetBlueprint()
                    WaitSeconds(bp.WeaponRepackTimeout)
                    self:PlayFxWeaponPackSequence()
                    if bp.WeaponUnpackLocksMotion then
                        self.unit:SetImmobile(false)
                    end
                    ChangeState(self, self.IdleState)
                end,
            },
        },
    },
}

TypeClass = UEB2210
