local version = tonumber( (string.gsub(string.gsub(GetVersion(), '1.5.', ''), '1.6.', '')) )

if version < 3636 then
	LOG('OrbitalWarsMod: [Blueprints.lua '..debug.getinfo(1).currentline..'] - Gameversion '..GetVersion()..' detected. Hooking function "ModBlueprints". Downgrading orbital factories.')
------------------------------------------------- Hook Start --------------------------------------------------

local OldModBlueprints = ModBlueprints
function ModBlueprints(all_blueprints)
	OldModBlueprints(all_blueprints)
	for id,bp in all_blueprints.Unit do
		PatchFactories(bp)
	end
end

function PatchFactories(uBP)
	local Categories = {}
	for _, cat in uBP.Categories do
		Categories[cat] = true
	end
	if Categories.FACTORY and Categories.ORBITAL and not Categories.TECH1 then -- Orbital factory TECH2 or TECH3
		uBP.Categories = RemoveItemFromArray('BUILTBYTIER2ENGINEER',uBP.Categories) -- only TECH1 Factories can be build, so removing build by higher tier
		uBP.Categories = RemoveItemFromArray('BUILTBYTIER3ENGINEER',uBP.Categories)
		uBP.Categories = RemoveItemFromArray('BUILTBYTIER2COMMANDER',uBP.Categories)
		uBP.Categories = RemoveItemFromArray('BUILTBYTIER3COMMANDER',uBP.Categories)
		uBP.Categories = RemoveItemFromArray('BUILTBYTIER4COMMANDER',uBP.Categories)
		if Categories.TECH2 then
			table.insert(uBP.Categories, 'BUILTBYTIER1ORBITALFACTORY') -- Upgrading from TECH1
		elseif Categories.TECH3 then
			table.insert(uBP.Categories, 'BUILTBYTIER2ORBITALFACTORY') -- Upgrading from TECH2
		end
	end
end

function RemoveItemFromArray(REMOVEME,ARRAY)
	zold = 1
	while ARRAY[zold] do
		if ARRAY[zold] == REMOVEME then
			table.remove(ARRAY, zold)
		else
			zold = zold + 1
		end
	end
	return ARRAY
end

-------------------------------------------------  Hook End ---------------------------------------------------
else
	LOG('OrbitalWarsMod: [Blueprints.lua '..debug.getinfo(1).currentline..'] - Gameversion is newer then 3636. No Patch needed.')
end
