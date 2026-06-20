local version = tonumber( (string.gsub(string.gsub(GetVersion(), '1.5.', ''), '1.6.', '')) )

if version < 3652 then -- All versions below 3652 don't have buildin global icon support, so we need to insert the icons by our own function
	LOG('OrbitalWarsMod: [unitview.lua '..debug.getinfo(1).currentline..'] - Gameversion is older then 3652. Hooking "UpdateWindow" to add our own unit icons')

local MyUnitIdTable = {
   ueb0403=true, -- Vuver - (Spaceships Factory)
   xsow1101=true, -- The Alphiconos - (Spaceship)
   ueow1103=true, -- EFOF Cleaner - (Spaceship)
   uab0403=true, -- Afrolas - (Spaceships Factory)
   uea0202=true, -- EF Tempest - (Interceptor)
   xsb0401=true, -- Acuron - (Spaceships factory)
   urb0401=true, -- Leka - (Spaceships Factory)
   xsow1103=true, -- The Tlacuconos - (Spaceship)
   ueb0402=true, -- Oekoolford - (Spaceships Factory)
   uab0402=true, -- Xeigas - (Spaceships Factory)
   ura0202=true, -- Fast Bat - (Interceptor)
   xsb0403=true, -- Zlestin - (Spaceships Factory)
   urb0403=true, -- Isok - (Spaceships Factory)
   uaow2001=true, -- The Missionary - (Anti Spaceships Defense)
   urb0402=true, -- Tixmond - (Spaceships Factory)
   urow1102=true, -- The Legate - (Spaceships)
   xsow1102=true, -- The Tlacualphos - (Spaceship)
   uab0401=true, -- Phiqey - (Spaceships Factory)
   uob2101=true, -- The Eradicator - (Anti Spaceships Defense)
   uean0303=true, -- Wasp - (Air-Superiority Fighter)
   urow1101=true, -- The Benefactor - (Spaceship)
   ueow1102=true, -- EFOF Protector - (Spaceship)
   uaow1102=true, -- The Essence Of Life - (Spaceships)
   xsbse0001=true, -- The Tlatoanum - (Anti Spaceships Defense)
   urow1103=true, -- The Shadow - (Spaceship)
   ueow1101=true, -- EFOF Infallible - (Spaceship)
   uaow1101=true, -- The Expectancy - (Spaceship)
   xsb0402=true, -- Plance - (Spaceships Factory)
   ueb0401=true, -- Prore - (Spaceships Factory)
   uaow0101=true, -- First Generation Interceptor - (Spaceship)
   uaow1103=true, -- The Falling Star - (Spaceship)
   uro2001=true, -- Phlegyas - (Anti Spaceships Defense)
}

	local IconPath = "/Mods/OrbitalWarsMod"

	local oldUpdateWindow = UpdateWindow
	function UpdateWindow(info)
		oldUpdateWindow(info)
		if MyUnitIdTable[info.blueprintId] then
			controls.icon:SetTexture(IconPath .. '/icons/units/' .. info.blueprintId .. '_icon.dds')
		end
	end

else
	LOG('OrbitalWarsMod: [unitview.lua '..debug.getinfo(1).currentline..'] - Gameversion is 3652 or newer. No need to insert the unit icons by our own function.')
end -- All versions below 3652 don't have buildin global icon support, so we need to insert the icons by our own function