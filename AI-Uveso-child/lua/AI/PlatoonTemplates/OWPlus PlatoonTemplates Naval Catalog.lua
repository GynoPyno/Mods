-- OWPlus PlatoonTemplates Naval Catalog.lua
--
-- Sess.102: un PlatoonTemplate di FABBRICA per ogni nave del catalogo (OWPlusNavalCatalog.lua,
-- 62 candidati), una sola fazione in FactionSquads (stesso schema del catalogo aereo). Nessun
-- Plan: le navi finiscono nell'ArmyPool e da li' nei plotoni d'attacco qui sotto.
--
-- Plotoni d'attacco navali (decisione utente 2026-10-15): a lotti, superficie 10-30 e
-- sottomarini 6-20, piano nativo HeroFightPlatoon (bersagli in OWPlus Naval Production.lua).
-- Le categorie sono quelle di OWPlusNavalCatalog.lua: ogni nave del catalogo entra in una delle due.

local OWPlusNavalCatalogMod = import('/mods/AI-Uveso-child/lua/AI/OWPlusNavalCatalog.lua')

local owplusNavalTemplates = 0
for _, c in ipairs(OWPlusNavalCatalogMod.OWPLUS_NAVAL_CATALOG) do
    local squads = {}
    squads[c[2]] = { { c[3], 1, 1, 'Attack', 'none' } }
    PlatoonTemplate {
        Name = OWPlusNavalCatalogMod.OWPlusNavalTemplateName(c),
        FactionSquads = squads,
    }
    owplusNavalTemplates = owplusNavalTemplates + 1
end

PlatoonTemplate {
    Name = 'OWPlus Naval Surface 10 30',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { OWPlusNavalCatalogMod.OWPlusNavalSurfaceCategory, 10, 30, 'Attack', 'none' },
    },
}

-- Sess.103 (feedback utente: navi un po' piu' aggressive): plotoni di superficie da 6 navi, usato
-- da 'OWPlus Naval Surface Attack' quando OWPlusNavalAggressionDisabled = false.
PlatoonTemplate {
    Name = 'OWPlus Naval Surface 6 30',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { OWPlusNavalCatalogMod.OWPlusNavalSurfaceCategory, 6, 30, 'Attack', 'none' },
    },
}

PlatoonTemplate {
    Name = 'OWPlus Naval Sub 6 20',
    Plan = 'HeroFightPlatoon',
    GlobalSquads = {
        { OWPlusNavalCatalogMod.OWPlusNavalSubCategory, 6, 20, 'Attack', 'none' },
    },
}

LOG('[OWPlus-NAVAL] PlatoonTemplates Naval Catalog: OK, registrati ' .. owplusNavalTemplates
    .. ' template navali (attesi 62) + 3 template d\'attacco (superficie 10-30 e 6-30, sottomarini 6-20)')
