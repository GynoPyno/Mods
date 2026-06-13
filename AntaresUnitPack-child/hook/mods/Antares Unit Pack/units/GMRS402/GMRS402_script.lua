local CSeaUnit = import('/lua/cybranunits.lua').CSeaUnit
local BareBonesWeapon = import('/lua/sim/defaultweapons.lua').BareBonesWeapon
local CybranWeapons = import('/lua/cybranweapons.lua')

local CAAMissileNaniteWeapon = CybranWeapons.CAAMissileNaniteWeapon
local CANNaniteTorpedoWeapon = CybranWeapons.CANNaniteTorpedoWeapon
local CAMZapperWeapon = CybranWeapons.CAMZapperWeapon
local CIFMissileLoaWeapon = CybranWeapons.CIFMissileLoaWeapon

local SCUStyleDeathWeapon = ClassWeapon(BareBonesWeapon) {
    OnFire = function(self) end,
    Fire = function(self)
        local bp = self:GetBlueprint()
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:PassDamageData(self:GetDamageTable())
    end,
}

GMRS402 = Class(CSeaUnit) {
    DestructionTicks = 200,

    Weapons = {
        DeathWeapon = ClassWeapon(SCUStyleDeathWeapon) {},
        AAGun       = ClassWeapon(CAAMissileNaniteWeapon) {},
        LeftZapper  = ClassWeapon(CAMZapperWeapon) {},
        RightZapper = ClassWeapon(CAMZapperWeapon) {},
        Torpedo     = ClassWeapon(CANNaniteTorpedoWeapon) {},
        MissileRack = ClassWeapon(CIFMissileLoaWeapon) {},
    },

    RadarThread = function(self)
        local spinner1 = CreateRotator(self, 'Spinner01', 'y', nil, 180, 0, 180)
        local spinner6 = CreateRotator(self, 'Spinner06', 'y', nil, 180, 0, 180)
        while true do
            WaitFor(spinner6)
            spinner6:SetTargetSpeed(-35)
            WaitFor(spinner6)
            spinner6:SetTargetSpeed(35)
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CSeaUnit.OnStopBeingBuilt(self, builder, layer)
        self:ForkThread(self.RadarThread)
        self.Trash:Add(CreateRotator(self, 'Spinner02', 'y', nil, 180, 0, 180))
        self.Trash:Add(CreateRotator(self, 'Spinner03', 'y', nil, 180, 0, 180))
        self.Trash:Add(CreateRotator(self, 'Spinner04', 'y', nil, 180, 0, 180))
        self.Trash:Add(CreateRotator(self, 'Spinner05', 'y', nil, 180, 0, 180))
        self.Trash:Add(CreateRotator(self, 'Spinner07', 'y', nil, 180, 0, 180))
        self.Trash:Add(CreateRotator(self, 'Spinner08', 'y', nil, 180, 0, 180))
    end,
}

TypeClass = GMRS402
