-- OWPlus experimental units — registra template per fazione
-- Indice fazioni: [1]=UEF, [2]=Aeon, [3]=Cybran, [4]=Seraphim
--
-- Fonte: Antares Unit Pack (tutti BUILTBYTIER3ENGINEER + MOBILE + EXPERIMENTAL verificati)
-- Se una fazione non ha entry per uno slot, il builder fallisce silenziosamente
-- e il BuilderManager passa al successivo — nessun crash.

-- Slot 1: sperimentale Antares terra — tutti e 4 le fazioni
table.insert(BuildingTemplates[1], { 'OWPlusExp1', 'oel0401' })   -- UEF
table.insert(BuildingTemplates[2], { 'OWPlusExp1', 'gmal0401' })  -- Aeon: Improved Experimental Assault Bot
table.insert(BuildingTemplates[3], { 'OWPlusExp1', 'wrl0404' })   -- Cybran
table.insert(BuildingTemplates[4], { 'OWPlusExp1', 'zxl0401' })   -- Seraphim

-- Slot 2: sperimentale Antares terra — UEF, Aeon, Cybran
table.insert(BuildingTemplates[1], { 'OWPlusExp2', 'oel0402' })   -- UEF
table.insert(BuildingTemplates[2], { 'OWPlusExp2', 'wza7401' })   -- Aeon: Intergalactic Colossus
table.insert(BuildingTemplates[3], { 'OWPlusExp2', 'wrl04044' })  -- Cybran

-- Slot 3: sperimentale Antares terra — UEF, Aeon
table.insert(BuildingTemplates[1], { 'OWPlusExp3', 'uelb0401' })  -- UEF
table.insert(BuildingTemplates[2], { 'OWPlusExp3', 'ual0402' })   -- Aeon

-- Slot 4: Planetary Colossus — Aeon only
table.insert(BuildingTemplates[2], { 'OWPlusExp4', 'lduc11' })    -- Aeon: Planetary Colossus

-- Aria: sperimentale Antares aria — UEF only (unica fazione con air experimental in Antares)
table.insert(BuildingTemplates[1], { 'OWPlusAirExp1', 'oea0401' }) -- UEF

-- ============================================================
-- TotalMayhem Land Experimentals — 8 slot
-- Tutti verificati: EXPERIMENTAL + MOBILE + LAND + BUILTBYTIER3ENGINEER, senza TECH1/TECH2/TECH3
-- Cybran[3]=BRM*, UEF[1]=BRN*, Aeon[2]=BRO*, Seraphim[4]=BRP*
-- ============================================================

-- TMExpLand1: mega T4 (mass 400k+) — tutti e 4
table.insert(BuildingTemplates[3], { 'TMExpLand1', 'brmt3ava' })       -- Cybran: AVA (HP200k/M400k)
table.insert(BuildingTemplates[1], { 'TMExpLand1', 'brnt3doomsday' })  -- UEF: Doomsday (HP430k/M430k)
table.insert(BuildingTemplates[2], { 'TMExpLand1', 'brot3hades' })     -- Aeon: Hades (HP100k/M120k)
table.insert(BuildingTemplates[4], { 'TMExpLand1', 'brpt3shbm' })      -- Seraphim: SHBM (HP120k/M75k)

-- TMExpLand2: T4 grandi (mass 100k+)
table.insert(BuildingTemplates[3], { 'TMExpLand2', 'brmt3snake' })     -- Cybran: Snake (HP135k/M110k)
table.insert(BuildingTemplates[1], { 'TMExpLand2', 'brnt3shbm2' })     -- UEF: SHBM2 (HP150k/M110k)
table.insert(BuildingTemplates[2], { 'TMExpLand2', 'brot3ncm2' })      -- Aeon: NCM2 (HP93k/M34k)

-- TMExpLand3: T4 medi (mass 40k-85k)
table.insert(BuildingTemplates[3], { 'TMExpLand3', 'brmt3mcm4' })      -- Cybran: MCM4 (HP80k/M52k)
table.insert(BuildingTemplates[1], { 'TMExpLand3', 'brnt3shbm' })      -- UEF: SHBM (HP105k/M40k)
table.insert(BuildingTemplates[2], { 'TMExpLand3', 'brot3ncm' })       -- Aeon: NCM (HP85k/M26k)

-- TMExpLand4: T4 medi (mass 22k-85k)
table.insert(BuildingTemplates[3], { 'TMExpLand4', 'brmt3exbm' })      -- Cybran: EXBM (HP50k/M40k)
table.insert(BuildingTemplates[1], { 'TMExpLand4', 'brnt3bat' })       -- UEF: BAT (HP96k/M85k)
table.insert(BuildingTemplates[2], { 'TMExpLand4', 'brot3btbot' })     -- Aeon: BTBOT (HP75k/M22k)

-- TMExpLand5: T4 medi (mass 26k-34k)
table.insert(BuildingTemplates[3], { 'TMExpLand5', 'brmt3mcm2' })      -- Cybran: MCM2 (HP67k/M25k)
table.insert(BuildingTemplates[1], { 'TMExpLand5', 'brnt3blasp' })     -- UEF: BLASP (HP71k/M34k)
table.insert(BuildingTemplates[2], { 'TMExpLand5', 'brot3shbm' })      -- Aeon: SHBM (HP70k/M26k)

-- TMExpLand6: T4 piccoli (mass 16k-25k)
table.insert(BuildingTemplates[3], { 'TMExpLand6', 'brmt3mcm' })       -- Cybran: MCM (HP58k/M20.5k)
table.insert(BuildingTemplates[1], { 'TMExpLand6', 'brnt3argus' })     -- UEF: Argus (HP61k/M25k)
table.insert(BuildingTemplates[2], { 'TMExpLand6', 'brot3ham' })       -- Aeon: HAM (HP34k/M16.5k)

-- TMExpLand7: Cybran + Aeon (UEF esaurito dopo slot 6 — fail silenzioso)
table.insert(BuildingTemplates[3], { 'TMExpLand7', 'brmt3cloaker' })   -- Cybran: Cloaker (HP35k/M25k)
table.insert(BuildingTemplates[2], { 'TMExpLand7', 'brot3coug' })      -- Aeon: Cougar (HP31k/M15k)

-- TMExpLand8: solo Cybran (Aeon esaurito dopo slot 7)
table.insert(BuildingTemplates[3], { 'TMExpLand8', 'brmt3vul' })       -- Cybran: VUL (HP45k/M15k)

-- TotalMayhem Air Experimentals
table.insert(BuildingTemplates[2], { 'TMAirExp1', 'broat3pride' })     -- Aeon: PRIDE air exp

-- ============================================================
-- Wyvern Battle Pack Land Experimentals — 4 slot
-- Tutti verificati: EXPERIMENTAL + MOBILE + LAND + BUILTBYTIER3ENGINEER
-- WEL0401/WEL0416 hanno anche STRUCTURE (normale, come Colossus vanilla)
-- ============================================================

-- WyvernExpLand1: bot/tank base — tutti e 4
table.insert(BuildingTemplates[1], { 'WyvernExpLand1', 'wel0401' })   -- UEF: Experimental Assault Tank
table.insert(BuildingTemplates[2], { 'WyvernExpLand1', 'wal0401' })   -- Aeon: Experimental Assault Bot
table.insert(BuildingTemplates[3], { 'WyvernExpLand1', 'wrl0402' })   -- Cybran: Experimental Assault Vehicle
table.insert(BuildingTemplates[4], { 'WyvernExpLand1', 'wsl0403' })   -- Seraphim: Experimental Tank

-- WyvernExpLand2: bot/hover secondario — tutti e 4
table.insert(BuildingTemplates[1], { 'WyvernExpLand2', 'wel0416' })   -- UEF: Ultimate Assault Bot
table.insert(BuildingTemplates[2], { 'WyvernExpLand2', 'wal4404' })   -- Aeon: Experimental Siege Bot
table.insert(BuildingTemplates[3], { 'WyvernExpLand2', 'wrl0404' })   -- Cybran: Experimental Prototype Spiderbot
table.insert(BuildingTemplates[4], { 'WyvernExpLand2', 'wsl0404' })   -- Seraphim: Experimental Tank (alt)

-- WyvernExpLand3: UEF + Cybran (Aeon/Seraphim esauriti dopo slot 2)
table.insert(BuildingTemplates[1], { 'WyvernExpLand3', 'wel1409' })   -- UEF: Experimental Assault Vehicle
table.insert(BuildingTemplates[3], { 'WyvernExpLand3', 'wrl1466' })   -- Cybran: Storm Spider

-- WyvernExpLand4: UEF + Cybran (slot 3 e 4 identici per copertura)
table.insert(BuildingTemplates[1], { 'WyvernExpLand4', 'wel4404' })   -- UEF: Experimental Heavy Mech
table.insert(BuildingTemplates[3], { 'WyvernExpLand4', 'wrl2466' })   -- Cybran: Storm Strider

-- Wyvern Battle Pack Air Experimentals
-- Solo Cybran ha un sperimentale aria: WRA0401 Experimental Gunship
table.insert(BuildingTemplates[3], { 'WyvernExpAir1', 'wra0401' })    -- Cybran: Experimental Gunship
