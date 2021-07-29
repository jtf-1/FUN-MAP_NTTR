-- BEGIN ATIS SECTION

atisCreech=ATIS:New(AIRBASE.Nevada.Creech_AFB, 290.450)
:SetRadioRelayUnitName("Radio Relay Creech")
:SetTowerFrequencies({360.6, 118.3, 38.55})
:SetTACAN(87)
:Start()

atisGroom=ATIS:New(AIRBASE.Nevada.Groom_Lake_AFB, 123.500)
:SetRadioRelayUnitName("Radio Relay Groom")
:SetTowerFrequencies({250.050, 118.0, 38.6})
:SetTACAN(18)
:AddILS(109.3, "32R")
:Start()

atisHenderson=ATIS:New(AIRBASE.Nevada.Henderson_Executive_Airport, 120.775)
:SetRadioRelayUnitName("Radio Relay Henderson")
:SetTowerFrequencies({250.1, 125.1, 38.75})
:Start()

atisLaughlin=ATIS:New(AIRBASE.Nevada.Laughlin_Airport, 119.825)
:SetRadioRelayUnitName("Radio Relay Laughlin")
:SetTowerFrequencies({250.0, 123.9, 38.4})
:Start()

atisMcCarran=ATIS:New(AIRBASE.Nevada.McCarran_International_Airport, 132.400)
:SetRadioRelayUnitName("Radio Relay McCarran")
:SetTowerFrequencies({257.8, 119.9, 118.750, 38.65})
:SetTACAN(116)
:AddILS(111.8, "25L")
:AddILS(110.3, "25R")
:Start()

atisNellis=ATIS:New(AIRBASE.Nevada.Nellis_AFB, 270.100)
:SetRadioRelayUnitName("Radio Relay Nellis")
--:SetActiveRunway("21L")
:SetActiveRunway("03L")
:SetTowerFrequencies({327.0, 132.550, 38.7})
:SetTACAN(12)
:AddILS(109.1, "21L")
:Start()

atisNLV=ATIS:New(AIRBASE.Nevada.North_Las_Vegas, 118.050)
:SetRadioRelayUnitName("Radio Relay NLV")
:SetTowerFrequencies({360.750, 125.700, 38.45})
:AddILS(110.7, "12")
:Start()

atisTonopahT=ATIS:New(AIRBASE.Nevada.Tonopah_Test_Range_Airfield, 113.000)
:SetRadioRelayUnitName("Radio Relay Tonopah")
:SetTowerFrequencies({257.950, 124.750, 38.5})
:SetTACAN(77)
:AddILS(108.3, "14")
:AddILS(111.7, "32")
:Start()

-- END ATIS SECTION