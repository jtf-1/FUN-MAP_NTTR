env.info( "[JTF-1] bfmacm_data" )
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- ACM/BFM
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER missiletrainer.lua
--
-- These values are specific to the miz and will override the default values in missiletrainer.lua
--

-- Error prevention. Create empty container if module core lua not loaded.
if not BFMACM then 
	_msg = "[JTF-1 BFMACM] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	BFMACM = {}
end

BFMACM.zoneBfmAcmName = "COYOTEABC" -- The BFM/ACM Zone
BFMACM.zonesNoSpawnName = { -- zones inside BFM/ACM zone within which adversaries may NOT be spawned.
	"zone_box",
} 

BFMACM.adversary = {
	menu = { -- Adversary menu
		{template = "ADV_F4", menuText = "Adversary A-4"},
		{template = "ADV_MiG28", menuText = "Adversary MiG-28"},
		{template = "ADV_Su27", menuText = "Adversary MiG-23"},
		{template = "ADV_MiG23", menuText = "Adversary Su-27"},
		{template = "ADV_F16", menuText = "Adversary F-16"},
		{template = "ADV_F18", menuText = "Adversary F-18"},
	},
	range = {5, 10, 20}, -- ranges at which to spawn adversaries in nautical miles
	spawn = {}, -- container for aversary spawn objects
	defaultRadio = "377.8",
}


if BFMACM.Start then
	BFMACM:Start()
end