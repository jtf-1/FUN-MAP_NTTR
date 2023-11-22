env.info( "[JTF-1] activeranges_data" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- ACTIVE RANGES SETTINGS FOR MIZ
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER activeranges.lua
--
-- These values are specific to the miz and will override the default values in MISSIONRANGES.default
--

-- Error prevention. Create empty container if module core lua not loaded.
if not MISSIONRANGES then 
	_msg = "[JTF-1 MISSIONRANGES] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	MISSIONRANGES = {}
end


MISSIONRANGES.activeatstart = false -- if true, spawn targets with AI inactive
MISSIONRANGES.useSRS = true -- set to false to disable use of SRS for this module in this miz
--MISSIONRANGES.rangeRadio = "377.8" -- radio frequency over which to broadcast Active Range messages


-- start the mission timer
if MISSIONRANGES.Start then
	MISSIONRANGES:Start()
end