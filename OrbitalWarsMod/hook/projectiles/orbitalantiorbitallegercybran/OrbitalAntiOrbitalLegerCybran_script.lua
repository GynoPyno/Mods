#
# CDFProtonCannon01
#
local CDFBolterLegerCannonProjectile = import('/Mods/OrbitalWarsMod/hook/lua/modprojectiles.lua').CDFBolterLegerCannonProjectile
CDFProtonCannon01 = Class(CDFBolterLegerCannonProjectile) {
    
    OnCreate = function(self)
        CDFBolterLegerCannonProjectile.OnCreate(self)
        self:ForkThread(self.ImpactWaterThread)
    end,
    
    ImpactWaterThread = function(self)
        WaitSeconds(0.3)
        self:SetDestroyOnWater(true)
    end,
    

}
TypeClass = CDFProtonCannon01

