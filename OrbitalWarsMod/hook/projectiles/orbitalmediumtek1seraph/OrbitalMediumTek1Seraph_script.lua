#****************************************************************************
#**
#**  File     :  /data/projectiles/SIFThunthoArtilleryShell01/SIFThunthoArtilleryShell01_script.lua
#**  Author(s):  Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Thuntho Artillery Shell Projectile script, XSL0103
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local EffectTemplate = import('/lua/EffectTemplates.lua')
local SThunthoOrbitalShell = import('/Mods/OrbitalWarsMod/hook/lua/modprojectiles.lua').SThunthoOrbitalShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

SIFThunthoArtilleryShell01 = Class(SThunthoOrbitalShell) {}

TypeClass = SIFThunthoArtilleryShell01