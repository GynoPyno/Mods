local CSubUnit = import('/lua/cybranunits.lua').CSubUnit
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CIFMissileStrategicWeapon = CybranWeaponsFile.CIFMissileStrategicWeapon
local CIFMissileLoaTacticalWeapon = CybranWeaponsFile.CIFMissileLoaTacticalWeapon
local CANTorpedoLauncherWeapon = CybranWeaponsFile.CANTorpedoLauncherWeapon

-- FIX: originale usava Class() per tutte le armi. Con Class() i callback FAF del ciclo di vita
-- (OnFire, OnProjectileFired, CountedProjectile decrement) non vengono registrati:
-- i missili vengono creati ma il contatore dell'inventario non scala mai.
-- ClassWeapon() aggancia correttamente tutti i callback.
GMRS401 = Class(CSubUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(CybranWeaponsFile.CIFCommanderDeathWeapon) {},

        NukeMissile = ClassWeapon(CIFMissileStrategicWeapon) {
            CurrentRack = 1,

            PlayFxMuzzleSequence = function(self, muzzle)
                local bp = self:GetBlueprint()
                self.Rotator = CreateRotator(self.unit, bp.RackBones[self.CurrentRack].RackBone, 'y', nil, 90, 90, 90)
                muzzle = bp.RackBones[self.CurrentRack].MuzzleBones[1]
                self.Rotator:SetGoal(90)
                CIFMissileStrategicWeapon.PlayFxMuzzleSequence(self, muzzle)
                WaitFor(self.Rotator)
                WaitSeconds(1)
            end,

            CreateProjectileAtMuzzle = function(self, muzzle)
                muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
                if self.CurrentRack >= 12 then
                    self.CurrentRack = 1
                else
                    self.CurrentRack = self.CurrentRack + 1
                end
                return CIFMissileStrategicWeapon.CreateProjectileAtMuzzle(self, muzzle)
            end,

            PlayFxRackReloadSequence = function(self)
                WaitSeconds(1)
                self.Rotator:SetGoal(0)
                WaitFor(self.Rotator)
                self.Rotator:Destroy()
                self.Rotator = nil
            end,
        },

        CruiseMissile = ClassWeapon(CIFMissileLoaTacticalWeapon) {},
        Torpedo01 = ClassWeapon(CANTorpedoLauncherWeapon) {},
        Torpedo02 = ClassWeapon(CANTorpedoLauncherWeapon) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CSubUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
        self:RequestRefreshUI()
    end,
}

TypeClass = GMRS401
