-- OWPlusDispersedBuilder: template per gli ingegneri che costruiscono nelle sub-location
-- BASE_NE/SE/SW/NW. Usa OWPlusDispersedBuildAI (hook/lua/platoon.lua) come Plan,
-- che passa le coordinate del manager target come 'reference' tabella ad AIExecuteBuildStructure.

PlatoonTemplate {
    Name = 'OWPlusDispersedBuilder',
    Plan = 'OWPlusDispersedBuildAI',
    GlobalSquads = {
        { categories.ENGINEER * (categories.TECH1 + categories.TECH2 + categories.TECH3) - categories.ENGINEERSTATION - categories.COMMAND, 1, 1, 'support', 'none' },
    },
}
