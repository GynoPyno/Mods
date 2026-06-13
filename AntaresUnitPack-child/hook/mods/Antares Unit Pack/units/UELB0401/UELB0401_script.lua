-- Hook FAF-compatible — gira DOPO l'originale (che ora non crasha grazie al hook terranweapons)
-- Ridefinisce UELB0401 con ClassWeapon() (pattern FAF corretto)
local TLandUnit = import('/lua/terranunits.lua').TLandUnit

local WeaponsFile = import('/lua/terranweapons.lua')
local TDFGaussCannonWeapon = WeaponsFile.TDFLandGaussCannonWeapon
local TDFRiotWeapon = WeaponsFile.TDFRiotWeapon
local TAALinkedRailgun = WeaponsFile.TAALinkedRailgun
local TANTorpedoAngler = WeaponsFile.TANTorpedoAngler
local TIFFragLauncherWeapon = WeaponsFile.TDFFragmentationGrenadeLauncherWeapon
local TSAMLauncher = WeaponsFile.TSAMLauncher

local BareBonesWeapon = import('/lua/sim/defaultweapons.lua').BareBonesWeapon
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- Death weapon SCU-style: crea SCUDeath01 e passa DamageTable dal blueprint (Damage=12750, DamageRadius=8)
local SCUStyleDeathWeapon = ClassWeapon(BareBonesWeapon) {
    OnFire = function(self) end,
    Fire = function(self)
        local bp = self:GetBlueprint()
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:PassDamageData(self:GetDamageTable())
    end,
}

UELB0401 = Class(TLandUnit) {
    OnCreate = function(self)
        TLandUnit.OnCreate(self)
    end,

    Weapons = {
        RightTurret01  = ClassWeapon(TDFGaussCannonWeapon) {},
        RightTurret02  = ClassWeapon(TDFGaussCannonWeapon) {},
        LeftTurret01   = ClassWeapon(TDFGaussCannonWeapon) {},
        LeftTurret02   = ClassWeapon(TDFGaussCannonWeapon) {},
        RightRiotgun   = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        LeftRiotgun    = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        RightAAGun     = ClassWeapon(TAALinkedRailgun) {},
        LeftAAGun      = ClassWeapon(TAALinkedRailgun) {},
        Torpedo        = ClassWeapon(TANTorpedoAngler) {},
        CenterTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        CenterTurret02 = ClassWeapon(TDFGaussCannonWeapon) {},
        FrontRiotgun01 = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        FrontRiotgun02 = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        FrontRiotgun03 = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        FrontRiotgun04 = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        FrontRiotgun05 = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        FrontRiotgun06 = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        FrontRiotgun07 = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        FrontRiotgun08 = ClassWeapon(TDFRiotWeapon) { FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank },
        HeavyGrenade01 = ClassWeapon(TIFFragLauncherWeapon) {},
        HeavyGrenade02 = ClassWeapon(TIFFragLauncherWeapon) {},
        -- Toggled
        MissileRack01  = ClassWeapon(TSAMLauncher) {},
        MissileRack02  = ClassWeapon(TSAMLauncher) {},
        DeathWeapon    = ClassWeapon(SCUStyleDeathWeapon) {},
    },

    CreateRollOffEffects = function(self)
        local army = self:GetArmy()
        local unitB = self.UnitBeingBuilt
        for k, v in self.RollOffBones do
            local fx = AttachBeamEntityToEntity(self, v, unitB, -1, army, EffectTemplate.TTransportBeam01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
            fx = AttachBeamEntityToEntity(unitB, -1, self, v, army, EffectTemplate.TTransportBeam02)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
            fx = CreateEmitterAtBone(self, v, army, EffectTemplate.TTransportGlow01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
        end
    end,

    DestroyRollOffEffects = function(self)
        for k, v in self.ReleaseEffectsBag do
            v:Destroy()
        end
        self.ReleaseEffectsBag = {}
    end,
}

TypeClass = UELB0401
