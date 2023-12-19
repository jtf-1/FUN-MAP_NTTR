env.info( "[JTF-1] missionatis_data.lua" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- MISSIONATIS SETTINGS FOR MIZ
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER missionatis.lua
--
-- These values are specific to the miz and will override the default values in MISSIONATIS.default
--
--
-- NELLIS 270.100
-- CREECH 290.450
-- GROOM LAKE 123.500
-- TONOPAH TEST RANGE 113.000

-- Error prevention. Create empty container if module core lua not loaded.
if not MISSIONATIS then 
	_msg = "[JTF-1 MISSIONATIS] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	MISSIONATIS = {}
end

-- only transmit ATIS if players are present
MISSIONATIS.transmitOnlyWithPlayers = false -- default value is false
MISSIONATIS.transmitInterval = 55 -- interval, in seconds, between ATIS transmissions. From start of transmission to start of next

MISSIONATIS.airfields = {
    {
        name = AIRBASE.Nevada.Nellis_AFB,
        frequency = 270.1,
        modulation = radio.modulation.AM,
        sex = "male",
        nationality = "en-US",
        transmitInterval = 55,
        activeRunwayTakeoff = "03",
        activeRunwayTakeoffPreferLeft = true,
        activeRunwayLanding = "21",
        activeRunwayLandingPreferLeft = true,
        ILSFreq = 109.10,
        ILSName = "21L",
        TACAN = 12,
        towerFrequencies = 327, -- table of freqs. A single freq MUST be given as a plain number, NOT a atable.
        metricUnits = false,
        reportmBar = false,
        additionalInformation = "All aircraft report hold-short.",
    },
    {
        name = AIRBASE.Nevada.Creech_AFB,
        frequency = 290.45,
        modulation = radio.modulation.AM,
        sex = "female",
        nationality = "en-US",
        TACAN = 87,
        towerFrequencies = 360.6, -- table of freqs. A single freq MUST be given as a plain number, NOT a atable.
        metricUnits = false,
        reportmBar = false,
        transmitInterval = 50,
    },
    {
        name = AIRBASE.Nevada.Tonopah_Test_Range_Airfield,
        frequency = 113,
        modulation = radio.modulation.AM,
        sex = "female",
        nationality = "en-US",
        TACAN = 77,
        towerFrequencies = 257.95, -- table of freqs. A single freq MUST be given as a plain number, NOT a atable.
        metricUnits = false,
        reportmBar = false,
        transmitInterval = 50,
    },
    {
        name = AIRBASE.Nevada.Groom_Lake_AFB,
        frequency = 123,
        modulation = radio.modulation.AM,
        sex = "male",
        nationality = "en-US",
        TACAN = 18,
        towerFrequencies = 120.1, -- table of freqs. A single freq MUST be given as a plain number, NOT a atable.
        metricUnits = false,
        reportmBar = false,
        transmitInterval = 50,
    },
    -- EXAMPLE AIRFIELD CONFIG
    -- {
    --     name = AIRBASE.Nevada.Nellis_AFB,
    --     frequency = 327.3,
    --     modulation = radio.modulation.AM,
    --     sex = "male",
    --     nationality = "en-US",
    --     transmitInterval = 55,
    --     activeRunwayTakeoff = "03",
    --     activeRunwayTakeoffPreferLeft = true,
    --     activeRunwayLanding = "21",
    --     activeRunwayLandingPreferLeft = true,
    --     ILSFreq = 109.10,
    --     ILSName = "21L",
    --     TACAN = 12,
    --     towerFrequencies = 327.3, -- table of freqs. A single freq MUST be given as a plain number, NOT a atable.
    --     metricUnits = false,
    --     reportmBar = false,
    --     additionalInformation = "All aircraft report hold-short.",
    -- },
}

-- start the misison ATIS
if MISSIONATIS.Start then
	MISSIONATIS:Start()
end