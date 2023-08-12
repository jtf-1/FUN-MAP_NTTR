env.info( "[JTF-1] supportaircraft_data" )
--------------------------------------------
--- Support Aircraft Defined in this file
--------------------------------------------
--
-- **NOTE**: SUPPORTAIRCRAFT.LUA MUST BE LOADED BEFORE THIS FILE IS LOADED!
--
-- This file contains the config data specific to the miz in which it will be used.
-- All functions and key values are in SUPPORTAIRCRAFT.LUA, which should be loaded first
--
-- Load order in miz MUST be;
--     1. supportaircraft.lua
--     2. supportaircraft_data.lua
--

-- Error prevention. Create empty container if SUPPORTAIRCRAFT.LUA is not loaded or has failed.
if not SUPPORTAC then 
  _msg = "[JTF-1 SUPPORTAC] CORE FILE NOT LOADED!"
  BASE:E(_msg)
  SUPPORTAC = {}
end

SUPPORTAC.useSRS = true

-- Support aircraft missions. Each mission block defines a support aircraft mission. Each block is processed
-- and an aircraft will be spawned for the mission. When the mission is cancelled, eg after RTB or if it is destroyed,
-- a new aircraft will be spawned and a fresh AUFTRAG created.
SUPPORTAC.mission = {
    -- {
    --   name = "ARWK", -- text name for this support mission. Combined with this block's index and the mission type to define the group name on F10 map
    --   category = SUPPORTAC.category.tanker, -- support mission category. Used to determine the auftrag type. Options are listed in SUPPORTAC.category
    --   type = SUPPORTAC.type.tankerBoom, -- type defines the spawn template that will be used
    --   zone = "ARWK", -- ME zone that defines the start waypoint for the spawned aircraft
    --   callsign = CALLSIGN.Tanker.Arco, -- callsign under which the aircraft will operate
    --   callsignNumber = 1, -- primary callsign number that will be used for the aircraft
    --   tacan = 35, -- TACAN channel the ac will use
    --   tacanid = "ARC", -- TACAN ID the ac will use. Also used for the morse ID
    --   radio = 276.5, -- freq the ac will use when on mission
    --   flightLevel = 160, -- flight level at which to spwqan aircraft and at which track will be flown
    --   speed = 315, -- IAS when on mission
    --   heading = 94, -- mission outbound leg in degrees
    --   leg = 40, -- mission leg length in NM
    --   fuelLowThreshold = 30, -- lowest fuel threshold at which RTB is triggered
    --   activateDelay = 5, -- delay, after this aircraft has been despawned, before new aircraft is spawned
    --   despawnDelay = 10, -- delay before this aircraft is despawned
    -- },
    {
    name = "AR641A", -- text name for this support mission. Combined with this block's index and the mission type to define the group name on F10 map
    category = SUPPORTAC.category.tanker, -- support mission category. Used to determine the auftrag type. Options are listed in SUPPORTAC.categories
    type = SUPPORTAC.type.tankerBoom, -- type defines the spawn template that will be used
    zone = "AR641A", -- ME zone that defines the start waypoint for the spawned aircraft
    callsign = CALLSIGN.Tanker.Texaco, -- callsign under which the aircraft will operate
    callsignNumber = 1, -- primary callsign number that will be used for the aircraft
    tacan = 31, -- TACAN channel the ac will use
    tacanid = "TEX", -- TACAN ID the ac will use. Also used for the morse ID
    radio = 295.4, -- freq the ac will use when on mission
    flightLevel = 240,
    speed = 315, -- IAS when on mission
    heading = 71, -- mission outbound leg in degrees
    leg = 30, -- mission leg length in NM
  },
  {
    name = "AR641A",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerProbe,
    zone = "AR641A",
    callsign = CALLSIGN.Tanker.Shell,
    callsignNumber = 1,
    tacan = 35,
    tacanid = "SHL",
    radio = 276.1,
    flightLevel = 200,
    speed = 315,
    heading = 71,
    leg = 30,
  },
  {
    name = "AR635",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerBoom,
    zone = "AR635",
    callsign = CALLSIGN.Tanker.Texaco,
    callsignNumber = 2,
    tacan = 52,
    tacanid = "TEX",
    radio = 352.6,
    flightLevel = 240,
    speed = 315,
    heading = 272,
    leg = 50,
  },
  {
    name = "AR635",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerProbe,
    zone = "AR635",
    callsign = CALLSIGN.Tanker.Shell,
    callsignNumber = 2,
    tacan = 34,
    tacanid = "SHL",
    radio = 317.775,
    flightLevel = 200,
    speed = 315,
    heading = 272,
    leg = 50,
  },
  {
    name = "AR230V",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerBoom,
    zone = "AR230V",
    callsign = CALLSIGN.Tanker.Arco,
    callsignNumber = 1,
    tacan = 30,
    tacanid = "ARC",
    radio = 343.6,
    flightLevel = 150,
    speed = 215,
    heading = 41,
    leg = 30,
  },
  {
    name = "AR230V",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerProbeC130,
    zone = "AR230V",
    callsign = CALLSIGN.Tanker.Arco,
    callsignNumber = 3,
    tacan = 29,
    tacanid = "ARC",
    radio = 323.2,
    flightLevel = 100,
    speed = 315,
    heading = 41,
    leg = 30,
  },
  {
    name = "ARLNS",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerBoom,
    zone = "ARLNS",
    callsign = CALLSIGN.Tanker.Texaco,
    callsignNumber = 3,
    tacan = 51,
    tacanid = "TEX",
    radio = 324.05,
    flightLevel = 240,
    speed = 315,
    heading = 331,
    leg = 20,
  },
  {
    name = "ARLNS",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerProbe,
    zone = "ARLNS",
    callsign = CALLSIGN.Tanker.Shell,
    callsignNumber = 3,
    tacan = 33,
    tacanid = "SHL",
    radio = 319.8,
    flightLevel = 200,
    speed = 315,
    heading = 331,
    leg = 20,
  },
  {
    name = "AWACSEAST",
    category = SUPPORTAC.category.awacs,
    type = SUPPORTAC.type.awacsE3a,
    zone = "AWACS-EAST",
    callsign = CALLSIGN.AWACS.Darkstar,
    callsignNumber = 1,
    tacan = nil,
    tacanid = nil,
    radio = 282.025,
    flightLevel = 300,
    speed = 400,
    heading = 210,
    leg = 43,
    activateDelay = 5,
    despawnDelay = 10,
    fuelLowThreshold = 15,
  },
}

-- call the function that initialises the SUPPORTAC module
if SUPPORTAC.Start ~= nil then
  _msg = "[JTF-1 SUPPORTAC] SUPPORTAIRCRAFT_DATA - call SUPPORTAC:Start()."
  BASE:I(_msg)
  SUPPORTAC:Start()
end


