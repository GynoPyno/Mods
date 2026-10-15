-- OWPlus PlatoonTemplates Air Catalog.lua
--
-- Sess.101: un PlatoonTemplate di FABBRICA per ogni unita' del catalogo aereo
-- (OWPlusAirCatalog.lua, 57 candidati). Una sola fazione in FactionSquads: per le altre fazioni
-- il template risulta vuoto e il motore scarta il builder (stesso schema dei template
-- 'OWPlus Outpost <tipo> ...' di terra). Nessun Plan: gli aerei finiscono nell'ArmyPool e da li'
-- nei plotoni batch aria (OWPlus Formers.lua), come con i template nativi T1AirFighter & co.
-- Un template per unita' salta anche le sostituzioni casuali di CustomUnits (legate al nome del
-- template nativo).

local OWPlusAirCatalogMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusAirCatalog.lua')

local owplusAirTemplates = 0
for _, c in ipairs(OWPlusAirCatalogMod.OWPLUS_AIR_CATALOG) do
    local squads = {}
    squads[c[3]] = { { c[4], 1, 1, 'Attack', 'none' } }
    PlatoonTemplate {
        Name = OWPlusAirCatalogMod.OWPlusAirTemplateName(c),
        FactionSquads = squads,
    }
    owplusAirTemplates = owplusAirTemplates + 1
end

LOG('[OWPlus-AIR] PlatoonTemplates Air Catalog: OK, registrati ' .. owplusAirTemplates .. ' template aerei (attesi 57)')
