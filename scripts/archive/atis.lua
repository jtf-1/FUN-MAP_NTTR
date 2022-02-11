env.info( '[JTF-1] *** JTF-1 ATIS START ***' )

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ATIS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Load SRS config


local srsConfigFile = {}
srsConfigFile.open, srsConfigFile.data = UTILS.LoadFromFile(nil, "server_config.lua")
if srsConfigFile.open then
    BASE:I("[SERVERCONFIG] SRS Config file loaded")
else  
    BASE:E("[SERVERCONFIG] SRS Config file load failed!")
end
--]]

-- Configure SRS
local srsPath =  srsConfigFile.data[1]--"C:\\PROGRA~1\\DCS-SI~1" --Path to SRS install. No spaces 
local srsPort =  srsConfigFile.data[2] -- 5002 --SRS server port

-- Nellis AFB
atisNellis = ATIS:New("Nellis", 270.1)
    :SetSRS(srsPath, "male", "en-US", nil, srsPort)
    :SetActiveRunway("21L")
    :SetTowerFrequencies({327.000, 132.550})
    :SetTACAN(12)
    :AddILS(109.1, "21")
    :Start()

--[[
atisCreech=ATIS:New(AIRBASE.Nevada.Creech_AFB, 290.450, radio.modulation.AM)
    :SetSRS(SRSPath, "male", "en-US", nil, nil, SRSPort)
    :SetTowerFrequencies({360.6, 118.3, 38.55})
    :SetTACAN(87)
    :Start()

atisGroom=ATIS:New(AIRBASE.Nevada.Groom_Lake_AFB, 123.500, radio.modulation.AM)
    :SetSRS(SRSPath, "male", "en-US", nil, nil, SRSPort)
    :SetTowerFrequencies({250.050, 118.0, 38.6})
    :SetTACAN(18)
    :AddILS(109.3, "32R")
    :Start()

atisHenderson=ATIS:New(AIRBASE.Nevada.Henderson_Executive_Airport, 120.775, radio.modulation.AM)
    :SetSRS(SRSPath, "female", "en-US", nil, nil, SRSPort)
    :SetTowerFrequencies({250.1, 125.1, 38.75})
    :Start()

atisLaughlin=ATIS:New(AIRBASE.Nevada.Laughlin_Airport, 119.825, radio.modulation.AM)
    :SetSRS(SRSPath, "female", "en-US", nil, nil, SRSPort)
    :SetTowerFrequencies({250.0, 123.9, 38.4})
    :Start()

atisMcCarran=ATIS:New(AIRBASE.Nevada.McCarran_International_Airport, 132.400, radio.modulation.AM)
    :SetSRS(SRSPath, "female", "en-US", nil, nil, SRSPort)
    :SetTowerFrequencies({257.8, 119.9, 118.750, 38.65})
    :SetTACAN(116)
    :AddILS(111.8, "25L")
    :AddILS(110.3, "25R")
    :Start()

atisNLV=ATIS:New(AIRBASE.Nevada.North_Las_Vegas, 118.050, radio.modulation.AM)
    :SetSRS(SRSPath, "female", "en-US", nil, nil, SRSPort)
    :SetTowerFrequencies({360.750, 125.700, 38.45})
    :AddILS(110.7, "12")
    :Start()

atisTonopahT=ATIS:New(AIRBASE.Nevada.Tonopah_Test_Range_Airfield, 113.000, radio.modulation.AM)
    :SetSRS(SRSPath, "male", "en-US", nil, nil, SRSPort)
    :SetTowerFrequencies({257.950, 124.750, 38.5})
    :SetTACAN(77)
    :AddILS(108.3, "14")
    :AddILS(111.7, "32")
    :Start()

--]]

env.info( '[JTF-1] *** JTF-1 ATIS END ***' )
