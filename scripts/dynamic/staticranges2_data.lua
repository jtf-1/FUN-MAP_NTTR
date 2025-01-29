env.info( "[JTF-1] staticranges_data" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- STATIC RANGES SETTINGS FOR MIZ
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER staticranges.lua
--
-- These values are specific to the miz and will override the default values in STATICRANGES.default
--

-- Error prevention. Create empty container if module core lua not loaded.
if not STATICRANGES then 
	_msg = "[JTF-1 STATICRANGES] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	STATICRANGES = {}
end

-- These values will overrides the default values in staticranges.lua
STATICRANGES.strafeMaxAlt             = 1530 -- [5000ft] in metres. Height of strafe box.
STATICRANGES.strafeBoxLength          = 3000 -- [10000ft] in metres. Length of strafe box.
STATICRANGES.strafeBoxWidth           = 300 -- [1000ft] in metres. Width of Strafe pit box (from 1st listed lane).
STATICRANGES.strafeFoullineDistance   = 610 -- [2000ft] in metres. Min distance for from target for rounds to be counted.
STATICRANGES.strafeGoodPass           = 20 -- Min hits for a good pass.

-- Range targets table
STATICRANGES.Ranges = {
    -- { -- SAMPLE RANGE DATA
    --   rangeId               = "R63", -- unique ID for the range
    --   rangeName             = "Range 63", -- text used for messages
    --   rangeZone             = "R63", -- zone object in which range objects are placed
    --   rangeControlFrequency = 361.6, -- TAC radio frequency for the range
    --   groups = { -- group objects used as bombing targets
    --     "63-01", "63-02", "63-03", "63-05", 
    --     "63-10", "63-12", "63-15", "R-63B Class A Range-01", 
    --     "R-63B Class A Range-02",    
    --   },
    --   units = { -- unit objects used as bombing targets
    --     "R63BWC", "R63BEC",
    --   },
    --   strafepits = { -- unit objects used as strafepits 
    --     { --West strafepit -- use sub groups for multiple strafepits
    --       "R63B Strafe Lane L2", 
    --       "R63B Strafe Lane L1", 
    --       "R63B Strafe Lane L3",
    --     },
    --     { --East strafepit 
    --       "R63B Strafe Lane R2", 
    --       "R63B Strafe Lane R1", 
    --       "R63B Strafe Lane R3",
    --     },
    --   },
    -- },
    { --R61
      rangeId               = "R61",
      rangeName             = "Range 61",
      rangeZone             = "R61",
      rangeControlFrequency = 341.925,
      groups = {
        "61-01", "61-03",
      },
      units = {
        "61-01 Aircraft #001", "61-01 Aircraft #002", 
      },
      strafepits = {
      },
    },--R61 END
    { --R62
      rangeId               = "R62",
      rangeName             = "Range 62",
      rangeZone             =  "R62AB", --"R62",
      rangeControlFrequency = 234.250,
      groups = {
        "62-01", "62-02", "62-04",
        "62-03", "62-08", "62-09", "62-11", 
        "62-12", "62-13", "62-14", "62-21", 
        "62-21-01", "62-22", "62-31", "62-32",
        "62-41", "62-42", "62-43", "62-44", 
        "62-45", "62-51", "62-52", "62-53", 
        "62-54", "62-55", "62-56", "62-61", 
        "62-62", "62-63", "62-71", "62-72", 
        "62-73", "62-74", "62-75", "62-76", 
        "62-77", "62-78", "62-79", "62-81", 
        "62-83", "62-91", "62-92", "62-93",
      },
      units = {
        "62-32-01", "62-32-02", "62-32-03", "62-99",  
      },
      strafepits = {
      },
    },--R62 END
    { --R63
      rangeId               = "R63",
      rangeName             = "Range 63",
      rangeZone             = "R63",
      rangeControlFrequency = 361.6,
      groups = {
        "63-01", "63-02", "63-03", "63-05", 
        "63-10", "63-12", "63-15", "R-63B Class A Range-01", 
        "R-63B Class A Range-02",    
      },
      units = {
        "R63BWC", "R63BEC",
      },
      strafepits = {
        { --West strafepit
          "R63B Strafe Lane L2", 
          "R63B Strafe Lane L1", 
          "R63B Strafe Lane L3",
        },
        { --East strafepit 
          "R63B Strafe Lane R2", 
          "R63B Strafe Lane R1", 
          "R63B Strafe Lane R3",
        },
      },
    },--R63 END
    { --R64
      rangeId               = "R64",
      rangeName             = "Range 64",
      rangeZone             = "R64",
      rangeControlFrequency = 288.8,
      groups = {
        "64-10", "64-11", "64-13", "64-14", 
        "64-17", "64-19", "64-15", "64-05", 
        "64-08", "64-09",
      },
      units = {
        "64-12-05", "R64CWC", "R64CEC", "R-64C Class A Range-01", 
        "R-64C Class A Range-02", 
      },
      strafepits = {
        {-- West strafepit
          "R64C Strafe Lane L2", 
          "R64C Strafe Lane L1", 
          "R64C Strafe Lane L3",
        },
        {-- East strafepit
          "R64C Strafe Lane R2", 
          "R64C Strafe Lane R1", 
          "R64C Strafe Lane R3",
        },
      },
    },--R64 END
    { --R65
      rangeId               = "R65",
      rangeName             = "Range 65",
      rangeZone             = "R65",
      rangeControlFrequency = 225.450,
      groups = {
        "65-01", "65-02", "65-03", "65-04", 
        "65-05", "65-06", "65-07", "65-08", 
        "65-11",
      },
      units = {
      },
      strafepits = {
      },
    },--R65 END
}
  
-- Start the STATICRANGES module
if STATICRANGES.Start then
	STATICRANGES:Start()
end