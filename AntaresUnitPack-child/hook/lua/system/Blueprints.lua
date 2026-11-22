local BaseModBlueprints = ModBlueprints

function ModBlueprints(all_bps)
    BaseModBlueprints(all_bps)
    for id, bp in pairs(all_bps.Unit) do
        if string.lower(id) == 'ueb2310' then        -- UEF T4 Imperator (quad cannon arty)
            if bp.Economy then
                bp.Economy.BuildTime = 445000
                bp.Economy.MaintenanceConsumptionPerSecondEnergy = 300
            end
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'MainGun' then
                        weapon.Turreted = true
                        weapon.MuzzleVelocity = 100
                        weapon.MuzzleVelocityReduceDistance = 1
                        weapon.BallisticArc = 'RULEUBA_LowArc'
                        weapon.MaxRadius = 2000
                        weapon.MinRadius = 240
                        weapon.FiringRandomness = 0.45
                        weapon.DamageRadius = 7
                        weapon.RateOfFire = 1/60
                        weapon.EnergyRequired = 140000
                        weapon.EnergyDrainPerSecond = 7000
                        weapon.TurretYawSpeed = 2.4
                        weapon.TurretPitchSpeed = 2.4
                    end
                    if weapon.ProjectileId then
                        if string.find(weapon.ProjectileId, 'EQCAIARTproj', 1, true) then
                            weapon.ProjectileId = '/mods/AntaresUnitPack-child/projectiles/EQCAIARTprojFix/EQCAIARTprojFix_proj.bp'
                        end
                    end
                end
            end

        elseif string.lower(id) == 'uelb0401' then    -- UEF T4 Fatboy MkII (walker)
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.ProjectileId and string.find(string.lower(weapon.ProjectileId), 'tdfgauss25', 1, true) then
                        weapon.ProjectileId = '/mods/AntaresUnitPack-child/projectiles/TDFGauss25fix/TDFGauss25fix_proj.bp'
                    end
                end
            end

            bp.CollisionOffsetY = 0
            bp.CollisionOffsetZ = 0
            bp.SizeX = 9
            bp.SizeY = 2
            bp.SizeZ = 10

            if bp.AI then
                bp.AI.TargetBones = {
                    'Bay_Cover',
                    'Front_Core',
                    'Rear_Core',
                    'Ramp',
                    'UEL0401',
                }
            end

        elseif string.lower(id) == 'url4032' then      -- Cybran T4 Thicklord (walker)
            bp.CollisionOffsetY = 3
            bp.CollisionOffsetZ = 0
            bp.SizeX = 10
            bp.SizeY = 6.5
            bp.SizeZ = 13
            if bp.AI then
                bp.AI.TargetBones = {
                    'BolterLegerBunker03',
                    'BolterLegerBunker05',
                    'BolterLegerBunker07',
                    'BolterLegerBunker08',
                    'Left_Leg04_B01',
                    'Right_Leg04_B01',
                    'Left_Leg01_B01',
                    'Right_Leg01_B01',
                    'URLEW0005',
                }
            end

        elseif string.lower(id) == 'gmrs402' then      -- Cybran T4 Archer Class MkII (cruiser)
            -- Collider originale Antares (editabile)
            bp.CollisionOffsetY = -0.29
            bp.CollisionOffsetZ = 0
            bp.SizeX = 9
            bp.SizeY = 3
            bp.SizeZ = 15
            -- Fix: bone 'URS0202' copiato dal blueprint vanilla Siren, non esiste nel modello GMRS402
            if bp.Display then
                bp.Display.IdleEffects = {
                    Water = {
                        Effects = {
                            {
                                Bones = { 'GMRS402' },
                                Scale = 3.1,
                                Type = 'SeaIdle01',
                            },
                        },
                    },
                }
            end

        elseif string.lower(id) == 'gmrs302' then      -- Cybran T4 Ennui (sommergibile)
            bp.CollisionOffsetY = -0.25
            bp.CollisionOffsetZ = 0.25
            bp.SizeX = 2.5
            bp.SizeY = 1
            bp.SizeZ = 9

        elseif string.lower(id) == 'xrs0402' then      -- Cybran T4 Sea Dragon (nave)
            bp.CollisionOffsetY = -0.375
            bp.CollisionOffsetZ = 0
            bp.SizeX = 4
            bp.SizeY = 2.5
            bp.SizeZ = 20

        elseif string.lower(id) == 'wrs0401' then      -- Cybran T4 Odysseus Class (nave)
            bp.CollisionOffsetY = -0.375
            bp.CollisionOffsetZ = 0
            bp.SizeX = 2.8
            bp.SizeY = 2.3
            bp.SizeZ = 16

        elseif string.lower(id) == 'ct4bs' then        -- Cybran T4 Harbinger Class (nave)
            bp.CollisionOffsetY = -0.375
            bp.CollisionOffsetZ = 0.8
            bp.SizeX = 6
            bp.SizeY = 4
            bp.SizeZ = 30

        elseif string.lower(id) == 'gmrs401' then      -- Cybran T4 Typhoon MkII (MIRV sommergibile)
            bp.CollisionOffsetY = -2.25
            bp.CollisionOffsetZ = 1
            bp.SizeX = 4
            bp.SizeY = 3
            bp.SizeZ = 26
            -- Riduce beccheggio in immersione/emersione: sub vanilla usano -1.5, originale era -4
            if bp.Physics then
                bp.Physics.Elevation = -2
            end

        elseif string.lower(id) == 'anc_urs404' then   -- Cybran T4 Krakken Class (nave)
            bp.CollisionOffsetY = -0.375
            bp.CollisionOffsetZ = 0
            bp.SizeX = 5
            bp.SizeY = 2.5
            bp.SizeZ = 22

        elseif string.lower(id) == 'ueb2210' then
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.ProjectileId then
                        if string.find(weapon.ProjectileId, 'GatArtproj', 1, true) then
                            weapon.ProjectileId = '/mods/AntaresUnitPack-child/projectiles/GatArtprojFix/GatArtprojFix_proj.bp'
                        end
                    end
                    -- FAF vieta RackRecoilDistance != 0 + MuzzleSalvoDelay != 0
                    -- MuzzleSalvoSize=1 rende il delay inutile -> azzerarlo ripristina il recoil visivo
                    if weapon.RackRecoilDistance and weapon.RackRecoilDistance ~= 0 then
                        weapon.MuzzleSalvoDelay = 0
                    end
                    -- Fuoco sequenziale canna per canna invece di simultaneo
                    if weapon.RackFireTogether ~= nil then
                        weapon.RackFireTogether = false
                    end
                    -- Spin-up: canne girano per 1.5s prima di sparare (RackSalvoChargeState)
                    -- Spin-down: canne rallentano 2s dopo l'ultimo colpo prima di fermarsi
                    if weapon.WeaponUnpacks then
                        weapon.RackSalvoChargeTime = 1.5
                        weapon.WeaponRepackTimeout = 2
                    end
                end
            end
        -- Silo nuke T3 vanilla â€” collision box di riferimento (valori identici all'originale, centralizzati qui per tuning rapido)
        elseif string.lower(id) == 'ueb2305' then      -- UEF T3 Strategic Missile Launcher (Stonager)
            bp.CollisionOffsetY = -0.25
            bp.SizeX = 2.9
            bp.SizeY = 0.9
            bp.SizeZ = 2.9

        elseif string.lower(id) == 'uab2305' then      -- Aeon T3 Strategic Missile Launcher (Apocalypse)
            bp.CollisionOffsetY = -0.25
            bp.SizeX = 2.0
            bp.SizeY = 1.0
            bp.SizeZ = 2.0

        elseif string.lower(id) == 'urb2305' then      -- Cybran T3 Strategic Missile Launcher (Liberator)
            bp.CollisionOffsetY = -0.25
            bp.SizeX = 2.5
            bp.SizeY = 1.75
            bp.SizeZ = 2.5

        elseif string.lower(id) == 'xsb2305' then      -- Seraphim T3 Strategic Missile Launcher (Hastue)
            bp.CollisionOffsetY = -0.25
            bp.SizeX = 2.0
            bp.SizeY = 1.0
            bp.SizeZ = 2.0

        elseif string.lower(id) == 'urb23051' then     -- Cybran T4 MIRV Structure "Last Judgment" (Antares)
            bp.CollisionOffsetY = -0.25
            bp.SizeX = 4.5
            bp.SizeY = 3
            bp.SizeZ = 4.5
            -- Fix FAF ACUDeathWeapon: vecchia API usava Damage/DamageRadius, nuova usa NukeRing*
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'DeathWeapon' then
                        weapon.NukeInnerRingDamage = weapon.Damage or 1
                        weapon.NukeInnerRingRadius = weapon.DamageRadius or 1
                        weapon.NukeOuterRingDamage = 1
                        weapon.NukeOuterRingRadius = (weapon.DamageRadius or 1) + 5
                    end
                end
            end

        elseif string.lower(id) == 'gmab407' then      -- Aeon T4 MIRV Structure "Nuclear Kitty" (Antares)
            bp.CollisionOffsetY = -0.25
            bp.SizeX = 3.5     -- originale: 3 * 5
            bp.SizeY = 2     -- originale: 1 * 5
            bp.SizeZ = 3.5      -- originale: 3 * 5
            -- Fix FAF ACUDeathWeapon: vecchia API usava Damage/DamageRadius, nuova usa NukeRing*
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'DeathWeapon' then
                        weapon.NukeInnerRingDamage = weapon.Damage or 1
                        weapon.NukeInnerRingRadius = weapon.DamageRadius or 1
                        weapon.NukeOuterRingDamage = 1
                        weapon.NukeOuterRingRadius = (weapon.DamageRadius or 1) + 5
                    end
                end
            end

        elseif string.lower(id) == 'gmeb420' then      -- UEF T4 MIRV Structure "Ares Soul" (Antares)
            bp.SizeX = 2.7
            bp.SizeY = 1.5
            bp.SizeZ = 2.7
            bp.StrategicIconName = 'icon_experimental_generic'
            -- Fix FAF ACUDeathWeapon: vecchia API usava Damage/DamageRadius, nuova usa NukeRing*
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'DeathWeapon' then
                        weapon.NukeInnerRingDamage = weapon.Damage or 1
                        weapon.NukeInnerRingRadius = weapon.DamageRadius or 1
                        weapon.NukeOuterRingDamage = 1
                        weapon.NukeOuterRingRadius = (weapon.DamageRadius or 1) + 5
                    end
                end
            end

        elseif string.lower(id) == 'gsmb319' then      -- Seraphim T4 MIRV Structure "Hust Lett" (Antares)
            bp.CollisionOffsetY = -0.25
            bp.SizeX = 4
            bp.SizeY = 3.5
            bp.SizeZ = 4
            bp.StrategicIconName = 'icon_experimental_generic'
            -- Fix FAF ACUDeathWeapon: vecchia API usava Damage/DamageRadius, nuova usa NukeRing*
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'DeathWeapon' then
                        weapon.NukeInnerRingDamage = weapon.Damage or 1
                        weapon.NukeInnerRingRadius = weapon.DamageRadius or 1
                        weapon.NukeOuterRingDamage = 1
                        weapon.NukeOuterRingRadius = (weapon.DamageRadius or 1) + 5
                    end
                end
            end

        elseif string.lower(id) == 'swab03' or string.lower(id) == 'sweb03' or string.lower(id) == 'swrb03' or string.lower(id) == 'swsb03' then  -- Aeon/UEF/Cybran/Seraphim Spacedock (Antares)
            -- Rimuovi BUILTBY* e ORBITAL per nascondere le fabbriche dal menu build e impedire il match 'FACTORY TECH3 UEF STRUCTURE ORBITAL' della fabbrica T2 OW
            if bp.Categories then
                local filtered = {}
                for _, cat in ipairs(bp.Categories) do
                    if not string.find(cat, 'BUILTBY') and cat ~= 'ORBITAL' then
                        table.insert(filtered, cat)
                    end
                end
                bp.Categories = filtered
            end

        elseif string.lower(id) == 'gmes405' then      -- UEF T4 Senator Class MKII (nave sperimentale)
            -- Fix bone IdleEffect: 'UES0202' non esiste nel modello GMES405, copiato per errore da vanilla Siren
            if bp.Display then
                bp.Display.IdleEffects = {
                    Water = {
                        Effects = {
                            {
                                Bones = { 'GMES405' },
                                Scale = 2.5,
                                Type = 'SeaIdle01',
                            },
                        },
                    },
                }
            end
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'DeathWeapon' then
                        -- Fix FAF ACUDeathWeapon: vecchia API usava Damage/DamageRadius, nuova usa NukeRing*
                        weapon.NukeInnerRingDamage = weapon.Damage or 1
                        weapon.NukeInnerRingRadius = weapon.DamageRadius or 1
                        weapon.NukeOuterRingDamage = 1
                        weapon.NukeOuterRingRadius = (weapon.DamageRadius or 1) + 5
                    elseif weapon.Label == 'MissileRack' then
                        -- Fix Flayer SAM: (6-1)*0.1=0.5s > 1/2.5=0.4s -> errore weapon setup
                        weapon.MuzzleSalvoDelay = 0.06
                    end
                end
            end

        elseif string.lower(id) == 'lduc11' or string.lower(id) == 'wza7401' then   -- Colossi Aeon Antares (Planetary/Intergalactic)
            -- TargetRestrictDisallow: filtra il targeting AI automatico (insufficiente per il beam grab C++,
            -- ma utile come prima barriera). Il fix effettivo e' in hook/lua/aeonweapons.lua (ADFTractorClaw.OnFire).
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'RightArmTractor' or weapon.Label == 'LeftArmTractor' then
                        weapon.TargetRestrictDisallow = 'UNTARGETABLE STRUCTURE COMMAND EXPERIMENTAL NAVAL SUBCOMMANDER'
                    end
                end
            end

        elseif string.lower(id) == 'sab2304' then      -- Aeon T4 Mortymer (SAM Launcher)
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'DeathWeapon' then
                        -- Fix FAF ACUDeathWeapon: vecchia API usava Damage/DamageRadius, nuova usa NukeRing*
                        weapon.NukeInnerRingDamage = weapon.Damage or 1
                        weapon.NukeInnerRingRadius = weapon.DamageRadius or 1
                        weapon.NukeOuterRingDamage = 1
                        weapon.NukeOuterRingRadius = (weapon.DamageRadius or 1) + 5
                    elseif weapon.Label == 'AntiAirMissiles' then
                        -- Fix Zealot AA: (8-1)*0.2=1.4s > 1/1.2=0.833s -> errore weapon setup -> unita' non spara
                        weapon.MuzzleSalvoDelay = 0.1
                    end
                end
            end

        elseif string.lower(id) == 'gmas308' then      -- Aeon T4 Deramath Class (corazzata sperimentale)
            -- Collider originale: SizeX=16, SizeY=12, SizeZ=32 — troppo grande rispetto al modello.
            -- UAS0302 (nave base usata come mesh) ha SizeX=3.3/SizeZ=12.8 a scale=0.13.
            -- GMAS308 usa scale=0.32 → ratio 2.46×. Partenza: X≈8, Z≈22 (conservativo vs 31.5 scala pura).
            -- SizeY=4 standard per corazzate (CT4BS usa la stessa). Da tweakare in gioco.
            bp.CollisionOffsetY = -0.375
            bp.CollisionOffsetZ = 0.8
            bp.SizeX = 7
            bp.SizeY = 4
            bp.SizeZ = 22
            -- Fix MidTurret04: RackBones mancante nel blueprint originale → weapon setup abort.
            -- I bone Turret_Front_Muzzle100 / Turret_Front_Barrel100 sono custom del modello GMAS308.
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'MidTurret04' then
                        weapon.RackBones = {
                            {
                                MuzzleBones = { 'Turret_Front_Muzzle100' },
                                RackBone    = 'Turret_Front_Barrel100',
                            },
                        }
                    end
                end
            end

        elseif string.lower(id) == 'tbu1000' then   -- Dragon Slayer (SAM sperimentale UEF)
            -- Fix fuoco sequenziale: MuzzleSalvoDelay=0 fa sparare tutti e 6 i tubi del rack
            -- in un singolo tick. MuzzleSalvoSize=6 + MuzzleSalvoDelay=0.1 → burst rapido
            -- un missile alla volta per rack (stesso pattern di UEB2304 Flayer SAM vanilla).
            -- RateOfFire abbassato: 6*0.1+0.5=1.1s > 1/3=0.333s → weapon setup abortito.
            -- Con 0.7: ciclo=1.43s > 1.1s → validazione OK.
            if bp.Weapon then
                for i, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'MissileRack01' then
                        weapon.MuzzleSalvoSize  = 6
                        weapon.MuzzleSalvoDelay = 0.1
                        weapon.RateOfFire       = 0.7
                    end
                end
            end

        end
    end

    -- Fix proiettili MIRV (GMRS401 Typhoon MkII + URB23051 MIRV Structure)
    for id, bp in pairs(all_bps.Projectile) do
        if string.find(string.lower(id), 'mirvcifempfluxwarhead01', 1, true) then
            if bp.Physics then
                -- Split piÃ¹ in alto: a quota ~290 (crociera) il missile inizia il dive a dist<15,
                -- raggiunge quota 150 con velocitÃ  quasi verticale â†’ i figli ereditano direzione verso il basso
                bp.Physics.DetonateBelowHeight = 150
            end
        end
        if string.find(string.lower(id), 'cifempfluxwarhead025', 1, true) then
            if bp.Physics then
                -- Stesso pattern submarine MIRV: split a quota 150 con missile in picchiata
                bp.Physics.DetonateBelowHeight = 150
            end
        end
        if string.find(string.lower(id), 'cifempfluxwarhead14', 1, true) then
            if bp.Physics then
                bp.Physics.CollideSurface = true   -- abilita collisione col terreno â†’ triggera OnImpact
                bp.Physics.UseGravity = true        -- caduta naturale garantisce impatto anche se velocitÃ  split Ã¨ orizzontale
            end
        end
        if string.find(string.lower(id), 'aifquantumwarhead025', 1, true) then
            if bp.Physics then
                -- 150 e' sicuro: la quota di crociera e' ora ~288u (MovementThread 4+4+4=12s)
                -- I figli partono a ~150u e hanno piu' altitudine per manovrare rispetto al valore originale 90
                bp.Physics.DetonateBelowHeight = 150
            end
        end
        if string.find(string.lower(id), 'aifquantumwarhead13', 1, true) then
            if bp.Physics then
                bp.Physics.CollideSurface = true   -- originale=false: i figli passavano attraverso il terreno
                bp.Physics.UseGravity = true        -- caduta naturale verso il basso dopo lo split
            end
        end
        if string.find(string.lower(id), 'sifinainostrategicmissile011', 1, true) then
            if bp.Physics then
                -- Split a quota 150u: sicuro con quota crociera ~288u (MovementThread 4+4+4=12s)
                bp.Physics.DetonateBelowHeight = 150
            end
        end
        if string.find(string.lower(id), 'sifmirvinainostrategicmissile02', 1, true) then
            if bp.Physics then
                bp.Physics.CollideSurface = true   -- originale=false: i figli non colpivano il terreno
                bp.Physics.UseGravity = true        -- caduta naturale verso il basso dopo lo split
            end
        end
    end

    -- Sess.104 (2026-11-22): vita dei soli MIRV strategici moddati al livello del missile dei lanciamissili strategici T3 di FAF.
    -- Vanilla FAF: missile nucleare 25.000 di vita, anti-nuke vanilla 30.000 di danno (un colpo). Molti missili
    -- moddati avevano 1-60 di vita e cadevano al primo colpo della Rezta-ueo (GMSB402, 100 di danno, 2 colpi/s).
    -- Solo i 5 MIRV strategici (vettori lanciati da un'unita'). NON toccati: V6 Marlos (tifmissilenukemk), Mobile Nuke Launcher
    -- XSL0310 (sifinainostrategicmissile03), Purifier (mirvserpentine01, missile tattico), i figli dei MIRV (tifmissilenuke12, cifempfluxwarhead14,
    -- aifquantumwarhead13, sifmirvinainostrategicmissile02, mirvserpentinevchild01, ...), le nuke tattiche, le nuke
    -- dell'ACU e il B-52 Marlos (tifmissilenukemk2, 1.000.000: scelta dell'utente). Mai alzare il valore se e' gia' piu' alto.
    -- Flag di ripristino: OWPlusMirvHealthEnabled = false riporta i valori originali delle mod.
    local OWPlusMirvHealthEnabled = true
    local OWPlusMirvHealthTarget = 25000
    local OWPlusMirvHealthIds = {
        tifmissilenuke025 = true,                  -- Ares Soul (Antares GMEB420), era 60
        sifinainostrategicmissile011 = true,       -- Hust Lett (Antares GSMB319), era 60
        cifempfluxwarhead025 = true,               -- Last Judgment (Antares URB23051), era 50
        aifquantumwarhead025 = true,               -- Nuclear Kitty (Antares GMAB407), era 50
        mirvcifempfluxwarhead01 = true,            -- Typhoon MkII (Antares GMRS401), era 25
    }
    if OWPlusMirvHealthEnabled then
        LOG('[AntaresUnitPack-child] ModBlueprints: OK, adeguamento della vita dei missili nucleari a ' .. OWPlusMirvHealthTarget)
        local changed, checked = 0, 0
        for id, bp in pairs(all_bps.Projectile) do
            local base = string.lower(id)
            base = string.gsub(base, '^.*/', '')
            base = string.gsub(base, '_proj%.bp$', '')
            if OWPlusMirvHealthIds[base] then
                checked = checked + 1
                if not bp.Defense then
                    bp.Defense = {}
                end
                local old = bp.Defense.MaxHealth or bp.Defense.Health or 0
                if old < OWPlusMirvHealthTarget then
                    bp.Defense.Health = OWPlusMirvHealthTarget
                    bp.Defense.MaxHealth = OWPlusMirvHealthTarget
                    changed = changed + 1
                    LOG('[AntaresUnitPack-child] ModBlueprints: missile ' .. base .. ' vita ' .. old .. ' -> ' .. OWPlusMirvHealthTarget)
                else
                    LOG('[AntaresUnitPack-child] ModBlueprints: missile ' .. base .. ' gia a ' .. old .. ', invariato')
                end
            end
        end
        LOG('[AntaresUnitPack-child] ModBlueprints: vita missili nucleari, trovati ' .. checked .. ' di 5, modificati ' .. changed)
    else
        LOG('[AntaresUnitPack-child] ModBlueprints: OWPlusMirvHealthEnabled=false, vita dei missili originale')
    end

    -- Sess.104 (2026-11-22): Rezta-ueo (GMSB402, anti-nuke sperimentale Seraphim di Antares) a RAFFICA.
    -- Prima: 100 di danno, 2 colpi/s, scorte infinite, raggio 225. Con i MIRV a 25.000 di vita (blocco sopra) non
    -- abbatteva piu' nulla (250 colpi per missile). Ora: una raffica concentrata su UN missile, poi ricarica lunga.
    -- Come funziona il motore (DefaultProjectileWeapon.lua di FAF): MuzzleSalvoSize colpi allo stesso bersaglio, uno ogni
    -- MuzzleSalvoDelay (passo minimo 1 tick = 0,1 s); poi RackSalvoReloadTime di attesa; il bersaglio si rilegge a ogni
    -- raffica. Un colpo collide solo con il missile a cui era destinato alla nascita (Projectile.OnCollisionCheck), quindi
    -- il danno di UNA raffica deve bastare da solo: colpi x danno >= vita del missile (25.000), con margine per i mancati.
    -- Vincolo di timing (Conoscenze_acquisite_15/20): colpi x delay + ricarica <= 1/RateOfFire, altrimenti l'arma viene
    -- abortita in silenzio ('aborting weapon setup'): RateOfFire = 1/(colpi x delay + ricarica + 0,5).
    -- MODALITA' (e' il flag di ripristino):
    --   'raffica'   = nuova arma a raffica (parametri sotto)
    --   'colpo'     = ripiego: un colpo da 30.000 (come l'anti-nuke vanilla) ogni ~3 s, scorte infinite
    --   'originale' = nessuna modifica, blueprint Antares com'e'
    local OWPlusRezta = {
        Mode = 'raffica',
        Raffica = {
            Shots = 10,        -- colpi per raffica
            ShotDelay = 0.1,   -- secondi tra due colpi (minimo 0,1 = 1 tick)
            Damage = 3000,     -- danno per colpo: 10 x 3000 = 30.000 per raffica (come un colpo anti-nuke vanilla)
            Reload = 15,       -- secondi di ricarica dopo ogni raffica
        },
        Colpo = {
            Damage = 30000,
            RateOfFire = 0.3,
        },
    }
    for id, bp in pairs(all_bps.Unit) do
        if string.lower(id) == 'gmsb402' and bp.Weapon then
            local mode = OWPlusRezta.Mode
            if mode ~= 'raffica' and mode ~= 'colpo' and mode ~= 'originale' then
                LOG('[AntaresUnitPack-child] ModBlueprints: Rezta-ueo, modalita non valida "' .. tostring(mode) .. '", uso "originale"')
                mode = 'originale'
            end
            LOG('[AntaresUnitPack-child] ModBlueprints: Rezta-ueo (GMSB402) modalita "' .. mode .. '"')
            for i, weapon in ipairs(bp.Weapon) do
                if weapon.Label == 'MissileRack' then
                    local oldDamage, oldRof = weapon.Damage, weapon.RateOfFire
                    if mode == 'raffica' then
                        local r = OWPlusRezta.Raffica
                        local volley = r.Shots * r.ShotDelay
                        local rof = 1 / (volley + r.Reload + 0.5)
                        weapon.MuzzleSalvoSize = r.Shots
                        weapon.MuzzleSalvoDelay = r.ShotDelay
                        weapon.Damage = r.Damage
                        weapon.RackSalvoReloadTime = r.Reload
                        weapon.RateOfFire = rof
                        LOG('[AntaresUnitPack-child] ModBlueprints: Rezta-ueo raffica OK: ' .. r.Shots .. ' colpi x ' .. r.Damage
                            .. ' = ' .. (r.Shots * r.Damage) .. ' di danno in ' .. string.format('%.1f', volley) .. ' s, ricarica ' .. r.Reload
                            .. ' s, RateOfFire ' .. string.format('%.4f', rof) .. ' (prima: danno ' .. tostring(oldDamage) .. ', RateOfFire ' .. tostring(oldRof) .. ')')
                        if volley + r.Reload > 1 / rof then
                            WARN('[AntaresUnitPack-child] ModBlueprints: Rezta-ueo, vincolo di timing violato (colpi x delay + ricarica > 1/RateOfFire): l\'arma verrebbe abortita')
                        end
                        if r.Shots * r.Damage < 25000 then
                            WARN('[AntaresUnitPack-child] ModBlueprints: Rezta-ueo, il danno di una raffica (' .. (r.Shots * r.Damage) .. ') non uccide un missile da 25.000')
                        end
                    elseif mode == 'colpo' then
                        local c = OWPlusRezta.Colpo
                        weapon.MuzzleSalvoSize = 1
                        weapon.MuzzleSalvoDelay = 0
                        weapon.Damage = c.Damage
                        weapon.RackSalvoReloadTime = 0
                        weapon.RateOfFire = c.RateOfFire
                        LOG('[AntaresUnitPack-child] ModBlueprints: Rezta-ueo colpo singolo OK: danno ' .. c.Damage .. ', RateOfFire ' .. c.RateOfFire
                            .. ' (prima: danno ' .. tostring(oldDamage) .. ', RateOfFire ' .. tostring(oldRof) .. ')')
                    else
                        LOG('[AntaresUnitPack-child] ModBlueprints: Rezta-ueo, valori originali Antares invariati (danno ' .. tostring(oldDamage)
                            .. ', RateOfFire ' .. tostring(oldRof) .. ')')
                    end
                end
            end
        end
    end
end

