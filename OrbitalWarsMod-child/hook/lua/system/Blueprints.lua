local function ModBlueprints(all_bps)
    for id, bp in pairs(all_bps.Unit) do

        -- =====================================================================
        -- UEOW1101  "EFOF Infallible"  —  UEF Heavy Spaceship (T3)
        -- =====================================================================
        -- Fix: Death Ray ha TargetRestrictOnlyAllow = 'ORBITAL' → spara solo ad
        -- altre spaceship; cambiato in 'AIR' per renderlo utile contro qualsiasi aereo.
        -- Fix: velocità e quota troppo basse rispetto al modello (scala Antares).
        -- Fix: intel radar/omni completamente assenti nella versione OW.
        -- Fix: buff veterano regen (1/2/3/4/5 → valori proporzionali al ruolo T3).
        if string.lower(id) == 'ueow1101' then
            if bp.Air then
                bp.Air.MaxAirspeed = 4
                bp.Air.MinAirspeed = 2
            end
            if bp.Physics then
                bp.Physics.Elevation = 30
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 72
                bp.Intel.OmniRadius   = 42
                bp.Intel.VisionRadius = 54
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 20
                bp.Buffs.Regen.Level2 = 40
                bp.Buffs.Regen.Level3 = 60
                bp.Buffs.Regen.Level4 = 80
                bp.Buffs.Regen.Level5 = 100
            end
            if bp.Weapon then
                for _, weapon in ipairs(bp.Weapon) do
                    if weapon.Label == 'OrbitalDeathLaserWeapon' then
                        weapon.TargetRestrictOnlyAllow = 'AIR'
                    end
                end
            end

        -- =====================================================================
        -- UEOW1102  "EFOF Protector"  —  UEF Medium Spaceship (T2)
        -- =====================================================================
        -- Fix: velocità e quota troppo basse.
        -- Fix: intel radar/omni assenti.
        -- Fix: buff veterano regen minimi.
        elseif string.lower(id) == 'ueow1102' then
            if bp.Air then
                bp.Air.MaxAirspeed = 3
                bp.Air.MinAirspeed = 2
            end
            if bp.Physics then
                bp.Physics.Elevation = 25
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 48
                bp.Intel.OmniRadius   = 32
                bp.Intel.VisionRadius = 42
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 15
                bp.Buffs.Regen.Level2 = 30
                bp.Buffs.Regen.Level3 = 45
                bp.Buffs.Regen.Level4 = 60
                bp.Buffs.Regen.Level5 = 75
            end

        -- =====================================================================
        -- UEOW1103  "EFOF Cleaner"  —  UEF Light Spaceship (T1)
        -- =====================================================================
        -- Fix: velocità dimezzata rispetto ad Antares.
        -- Fix: RegenRate = 0 nella versione OW (omissione).
        -- Fix: intel radar/omni assenti.
        -- Fix: buff veterano regen minimi.
        elseif string.lower(id) == 'ueow1103' then
            if bp.Air then
                bp.Air.MaxAirspeed = 5
                bp.Air.MinAirspeed = 3
            end
            if bp.Physics then
                bp.Physics.Elevation = 20
            end
            if bp.Defense then
                bp.Defense.RegenRate = 10
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 42
                bp.Intel.OmniRadius   = 24
                bp.Intel.VisionRadius = 36
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 15
                bp.Buffs.Regen.Level2 = 30
                bp.Buffs.Regen.Level3 = 45
                bp.Buffs.Regen.Level4 = 75
                bp.Buffs.Regen.Level5 = 100
            end

        -- =====================================================================
        -- UROW1101  —  Cybran Medium Spaceship
        -- =====================================================================
        -- Fix: velocità 2→4, quota 12→25, intel radar/omni assenti.
        -- Fix: regen 5/25→25/150; un'arma con TargetRestrictOnlyAllow='ORBITAL'→'AIR'.
        elseif string.lower(id) == 'urow1101' then
            if bp.Air then
                bp.Air.MaxAirspeed = 4
                bp.Air.MinAirspeed = 2
            end
            if bp.Physics then
                bp.Physics.Elevation = 25
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 48
                bp.Intel.OmniRadius   = 32
                bp.Intel.VisionRadius = 42
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 25
                bp.Buffs.Regen.Level2 = 50
                bp.Buffs.Regen.Level3 = 75
                bp.Buffs.Regen.Level4 = 100
                bp.Buffs.Regen.Level5 = 150
            end
            if bp.Weapon then
                for _, weapon in ipairs(bp.Weapon) do
                    if weapon.TargetRestrictOnlyAllow == 'ORBITAL' then
                        weapon.TargetRestrictOnlyAllow = 'AIR'
                    end
                end
            end

        -- =====================================================================
        -- UROW1102  —  Cybran Heavy Spaceship (T3)
        -- =====================================================================
        -- Fix: velocità 2→3, quota 12→30, RegenRate 0→10, intel parziale→completo.
        -- Fix: regen 2/10→30/150; 2 armi con TargetRestrictOnlyAllow='ORBITAL'→'AIR'.
        elseif string.lower(id) == 'urow1102' then
            if bp.Air then
                bp.Air.MaxAirspeed = 3
                bp.Air.MinAirspeed = 2
            end
            if bp.Physics then
                bp.Physics.Elevation = 30
            end
            if bp.Defense then
                bp.Defense.RegenRate = 10
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 72
                bp.Intel.OmniRadius   = 42
                bp.Intel.VisionRadius = 54
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 30
                bp.Buffs.Regen.Level2 = 60
                bp.Buffs.Regen.Level3 = 90
                bp.Buffs.Regen.Level4 = 120
                bp.Buffs.Regen.Level5 = 150
            end
            if bp.Weapon then
                for _, weapon in ipairs(bp.Weapon) do
                    if weapon.TargetRestrictOnlyAllow == 'ORBITAL' then
                        weapon.TargetRestrictOnlyAllow = 'AIR'
                    end
                end
            end

        -- =====================================================================
        -- UROW1103  —  Cybran Light Spaceship (T1)
        -- =====================================================================
        -- Fix: velocità 2→5, quota 12→20, RegenRate 0→10, intel radar/omni assenti.
        -- Fix: regen 20/60→20/100 (livelli intermedi corretti verso Antares).
        elseif string.lower(id) == 'urow1103' then
            if bp.Air then
                bp.Air.MaxAirspeed = 5
                bp.Air.MinAirspeed = 3
            end
            if bp.Physics then
                bp.Physics.Elevation = 20
            end
            if bp.Defense then
                bp.Defense.RegenRate = 10
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 42
                bp.Intel.OmniRadius   = 24
                bp.Intel.VisionRadius = 36
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 20
                bp.Buffs.Regen.Level2 = 40
                bp.Buffs.Regen.Level3 = 60
                bp.Buffs.Regen.Level4 = 80
                bp.Buffs.Regen.Level5 = 100
            end

        -- =====================================================================
        -- UAOW1101  —  Aeon Medium Spaceship
        -- =====================================================================
        -- Fix: velocità 2→5, quota 12→25, intel radar/omni assenti.
        -- Fix: regen 3/15→15/75; un'arma con TargetRestrictOnlyAllow='ORBITAL'→'AIR'.
        elseif string.lower(id) == 'uaow1101' then
            if bp.Air then
                bp.Air.MaxAirspeed = 5
                bp.Air.MinAirspeed = 2
            end
            if bp.Physics then
                bp.Physics.Elevation = 25
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 48
                bp.Intel.OmniRadius   = 32
                bp.Intel.VisionRadius = 42
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 15
                bp.Buffs.Regen.Level2 = 25
                bp.Buffs.Regen.Level3 = 35
                bp.Buffs.Regen.Level4 = 50
                bp.Buffs.Regen.Level5 = 75
            end
            if bp.Weapon then
                for _, weapon in ipairs(bp.Weapon) do
                    if weapon.TargetRestrictOnlyAllow == 'ORBITAL' then
                        weapon.TargetRestrictOnlyAllow = 'AIR'
                    end
                end
            end

        -- =====================================================================
        -- UAOW1102  —  Aeon Heavy Spaceship (T3)
        -- =====================================================================
        -- Fix: velocità 2→4, quota 12→30, RegenRate 0→10, intel completamente assente.
        -- Fix: regen 5/25→30/150; 2 armi (EyeWeapon/EyeWeapon02) ORBITAL→AIR.
        elseif string.lower(id) == 'uaow1102' then
            if bp.Air then
                bp.Air.MaxAirspeed = 4
                bp.Air.MinAirspeed = 2
            end
            if bp.Physics then
                bp.Physics.Elevation = 30
            end
            if bp.Defense then
                bp.Defense.RegenRate = 10
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 72
                bp.Intel.OmniRadius   = 42
                bp.Intel.VisionRadius = 54
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 30
                bp.Buffs.Regen.Level2 = 60
                bp.Buffs.Regen.Level3 = 90
                bp.Buffs.Regen.Level4 = 120
                bp.Buffs.Regen.Level5 = 150
            end
            if bp.Weapon then
                for _, weapon in ipairs(bp.Weapon) do
                    if weapon.TargetRestrictOnlyAllow == 'ORBITAL' then
                        weapon.TargetRestrictOnlyAllow = 'AIR'
                    end
                end
            end

        -- =====================================================================
        -- UAOW1103  —  Aeon Light Spaceship (T1)
        -- =====================================================================
        -- Fix: velocità 2→6, quota 12→20, RegenRate 0→10, intel radar/omni assenti.
        -- Fix: regen 1/5→15/75.
        elseif string.lower(id) == 'uaow1103' then
            if bp.Air then
                bp.Air.MaxAirspeed = 6
                bp.Air.MinAirspeed = 3
            end
            if bp.Physics then
                bp.Physics.Elevation = 20
            end
            if bp.Defense then
                bp.Defense.RegenRate = 10
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 42
                bp.Intel.OmniRadius   = 24
                bp.Intel.VisionRadius = 36
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 15
                bp.Buffs.Regen.Level2 = 30
                bp.Buffs.Regen.Level3 = 45
                bp.Buffs.Regen.Level4 = 60
                bp.Buffs.Regen.Level5 = 75
            end

        -- =====================================================================
        -- XSOW1101  —  Seraphim Light Spaceship (T1)
        -- =====================================================================
        -- Fix: velocità 2→6, quota 12→20, RegenRate 0→10, intel radar/omni assenti.
        -- Fix: regen 1/5→20/100.
        elseif string.lower(id) == 'xsow1101' then
            if bp.Air then
                bp.Air.MaxAirspeed = 6
                bp.Air.MinAirspeed = 3
            end
            if bp.Physics then
                bp.Physics.Elevation = 20
            end
            if bp.Defense then
                bp.Defense.RegenRate = 10
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 42
                bp.Intel.OmniRadius   = 24
                bp.Intel.VisionRadius = 36
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 20
                bp.Buffs.Regen.Level2 = 40
                bp.Buffs.Regen.Level3 = 60
                bp.Buffs.Regen.Level4 = 80
                bp.Buffs.Regen.Level5 = 100
            end

        -- =====================================================================
        -- XSOW1102  —  Seraphim Heavy Spaceship (T3)
        -- =====================================================================
        -- Fix: velocità 2→4, quota 12→30, RegenRate 0→10, intel completamente assente.
        -- Fix: regen 1/5→30/150; 4 armi con TargetRestrictOnlyAllow='ORBITAL'→'AIR'.
        elseif string.lower(id) == 'xsow1102' then
            if bp.Air then
                bp.Air.MaxAirspeed = 4
                bp.Air.MinAirspeed = 2
            end
            if bp.Physics then
                bp.Physics.Elevation = 30
            end
            if bp.Defense then
                bp.Defense.RegenRate = 10
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 72
                bp.Intel.OmniRadius   = 42
                bp.Intel.VisionRadius = 54
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 30
                bp.Buffs.Regen.Level2 = 60
                bp.Buffs.Regen.Level3 = 90
                bp.Buffs.Regen.Level4 = 120
                bp.Buffs.Regen.Level5 = 150
            end
            if bp.Weapon then
                for _, weapon in ipairs(bp.Weapon) do
                    if weapon.TargetRestrictOnlyAllow == 'ORBITAL' then
                        weapon.TargetRestrictOnlyAllow = 'AIR'
                    end
                end
            end

        -- =====================================================================
        -- XSOW1103  —  Seraphim Medium Spaceship
        -- =====================================================================
        -- Fix: velocità 2→5, quota 12→25, intel radar/omni assenti.
        -- Fix: regen 1/5→15/75; un'arma con TargetRestrictOnlyAllow='ORBITAL'→'AIR'.
        elseif string.lower(id) == 'xsow1103' then
            if bp.Air then
                bp.Air.MaxAirspeed = 5
                bp.Air.MinAirspeed = 2
            end
            if bp.Physics then
                bp.Physics.Elevation = 25
            end
            if bp.Intel then
                bp.Intel.RadarRadius  = 48
                bp.Intel.OmniRadius   = 32
                bp.Intel.VisionRadius = 42
            end
            if bp.Buffs and bp.Buffs.Regen then
                bp.Buffs.Regen.Level1 = 15
                bp.Buffs.Regen.Level2 = 30
                bp.Buffs.Regen.Level3 = 45
                bp.Buffs.Regen.Level4 = 60
                bp.Buffs.Regen.Level5 = 75
            end
            if bp.Weapon then
                for _, weapon in ipairs(bp.Weapon) do
                    if weapon.TargetRestrictOnlyAllow == 'ORBITAL' then
                        weapon.TargetRestrictOnlyAllow = 'AIR'
                    end
                end
            end

        end
    end
end
