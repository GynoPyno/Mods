--****************************************************************************
--**
--**	File:		/lua/CustomUnits/CustomUnits.lua
--**
--**	Description:	For use with the Sorian AI
--**
--**	Copyright © 2009 BrewLAN
--**
--****************************************************************************
	local PRIORITY1 = 40
	local PRIORITY2 = 50
	local PRIORITY3 = 60

UnitList = {

			--Tech 1 Buildings	*********************************************
			T1AirBomber = {
				UEF = {'ueow1103', PRIORITY1},
				Cybran = {'urow1103', PRIORITY1},
				Aeon = {'uaow1103', PRIORITY1},
				Seraphim = {'xsow1101', PRIORITY1},
			},
			
			--Tech 2 Buildings	*********************************************

			T2AirGunship = {
				UEF = {'ueow1102', PRIORITY2},
				Cybran = {'urow1101', PRIORITY2},
				Aeon = {'uaow1101', PRIORITY2},
				Seraphim = {'xsow1103', PRIORITY2},
			},

			--Tech 3 Buildings	*********************************************

			T3AirBomber = {
				UEF = {'ueow1101', PRIORITY3},
				Cybran = {'urow1102', PRIORITY3},
				Aeon = {'uaow1102', PRIORITY3},
				Seraphim = {'xsow1102', PRIORITY3},
			},

			--Tech 4 Buildings	*********************************************


}