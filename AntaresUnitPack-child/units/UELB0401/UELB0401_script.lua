local TLandUnit = import('/lua/terranunits.lua').TLandUnit

local WeaponsFile = import('/lua/terranweapons.lua')

local TDFGaussCannonWeapon = WeaponsFile.TDFLandGaussCannonWeapon
local TDFRiotWeapon = WeaponsFile.TDFRiotWeapon
local TAALinkedRailgun = WeaponsFile.TAALinkedRailgun
local TANTorpedoAngler = WeaponsFile.TANTorpedoAngler
local TIFCommanderDeathWeapon = import('/lua/terranweapons.lua').TIFCommanderDeathWeapon
local TSAMLauncher = import('/lua/terranweapons.lua').TSAMLauncher

local EffectTemplate = import('/lua/EffectTemplates.lua')

WARN('*AntaresChild* UELB0401 script caricato')
WARN('*AntaresChild* TLandUnit           = ' .. tostring(TLandUnit))
WARN('*AntaresChild* TDFGaussCannonWeapon= ' .. tostring(TDFGaussCannonWeapon))
WARN('*AntaresChild* TDFRiotWeapon       = ' .. tostring(TDFRiotWeapon))
WARN('*AntaresChild* TAALinkedRailgun    = ' .. tostring(TAALinkedRailgun))
WARN('*AntaresChild* TANTorpedoAngler    = ' .. tostring(TANTorpedoAngler))
WARN('*AntaresChild* TIFCommanderDeathWeapon = ' .. tostring(TIFCommanderDeathWeapon))
WARN('*AntaresChild* TSAMLauncher        = ' .. tostring(TSAMLauncher))

UELB0401 = Class(TLandUnit) {
    OnCreate = function(self)
        TLandUnit.OnCreate(self)
        WARN('*AntaresChild* UELB0401 OnCreate - TypeClass attivo, unita spawned')
    end,

    Weapons = {
        DeathWeapon = Class(TIFCommanderDeathWeapon) {},
        RightTurret01 = Class(TDFGaussCannonWeapon) {},
        RightTurret02 = Class(TDFGaussCannonWeapon) {},
        LeftTurret01 = Class(TDFGaussCannonWeapon) {},
        LeftTurret02 = Class(TDFGaussCannonWeapon) {},
        RightRiotgun = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        LeftRiotgun = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        RightAAGun = Class(TAALinkedRailgun) {},
        LeftAAGun = Class(TAALinkedRailgun) {},
        Torpedo = Class(TANTorpedoAngler) {},
        CenterTurret01 = Class(TDFGaussCannonWeapon) {},
        CenterTurret02 = Class(TDFGaussCannonWeapon) {},
        FrontRiotgun01 = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        FrontRiotgun02 = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        FrontRiotgun03 = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        FrontRiotgun04 = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        FrontRiotgun05 = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        FrontRiotgun06 = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        FrontRiotgun07 = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        FrontRiotgun08 = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        HeavyGrenade01 = Class(TSAMLauncher) {},
        HeavyGrenade02 = Class(TSAMLauncher) {},
        MissileRack01 = Class(TSAMLauncher) {},
        MissileRack02 = Class(TSAMLauncher) {},
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
