-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ATIS SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- NELLIS 270.100
-- CREECH 290.450
-- GROOM LAKE 123.500
-- TONOPAH TEST RANGE 113.000

MISSIONATIS = {
    defaultSrsPath = "C:/Program Files/DCS-SimpleRadio-Standalone",
    defaultSrsPort = 5002,
    defaultSex = "male",
    defaultNationality = "en-US",
    defaultSubtitleDuration = 0, --disable subtitles
    defaultTransmitOnlyWithPlayers = true,
    atis = {},
    airfields = {
        {
            name = "Nellis",
            frequency = 327.3,
            modulation = 0,
            sex = "male",
            nationality = "en-US",
            activeRunwayTakeoff = "03L",
            activeRunwayTakeoffPreferLeft = true,
            activeRunwayLanding = "21L",
            activeRunwayLandingPreferLeft = true,
            ILSFreq = 109.10,
            ILSName = "21L",
            TACAN = 12,
            towerFrequencies = 327.3,
            metricUnits = false,
            reportmBar = true,
            additionalInformation = "Takeoff from runway zero three Left.",
        },
    },
}

MISSIONATIS.SRSPath = MISSIONSRS.SRS_DIRECTORY or MISSIONATIS.defaultSrsPath
MISSIONATIS.SRSPort = MISSIONSRS.SRS_PORT or MISSIONATIS.defaultSrsPort

BASE:I(string.format("[MISSIONATIS] SRS Config:\nPath: %s\nPort: %d\n",MISSIONATIS.SRSPath, MISSIONATIS.SRSPort))


function MISSIONATIS:AddAtis(_airfields)

    self.atis[_airfields.name] = ATIS:New(_airfields.name, _airfields.frequency, _airfields.modulation)
    self.atis[_airfields.name]:SetSRS(self.SRSPath,(_airfields.sex or self.defaultSex),(_airfields.nationality or self.defaultnationality),nil,self.STSPort)
    if _airfields.activeRunwayTakeoff then
        self.atis[_airfields.name]:SetActiveRunwayTakeoff(_airfields.activeRunwayTakeoff, (_airfields.activeRunwayTakeoffPreferLeft or nil))
    end
    if _airfields.activeRunwayLanding then
        self.atis[_airfields.name]:SetActiveRunwayLanding(_airfields.activeRunwayLanding, (_airfields.activeRunwayLandingPreferleft or nil))
    end
    if _airfields.ILS then
        self.atis[_airfields.name]:AddILS(_airfields.ILSFreq, (_airfields.ILSName or nil))
    end
    self.atis[_airfields.name]:SetSubtitleDuration((_airfields.subtitleDuration or self.defaultSubtitleDuration))
    if _airfields.TACAN then
        self.atis[_airfields.name]:SetTACAN(_airfields.TACAN)
    end
    self.atis[_airfields.name]:SetTowerFrequencies(_airfields.towerFrequencies)
    if _airfields.metricUnits then
        self.atis[_airfields.name]:SetMetricUnits()
    else
        self.atis[_airfields.name]:SetReportmBar()
    end
    if _airfields.additionalInformation then
        self.atis[_airfields.name]:SetAdditionalInformation(_airfields.additionalInformation)
    end
    self.atis[_airfields.name]:SetTransmitOnlyWithPlayers((_airfields.transmitOnlyWithPlayers or self.defaultTransmitOnlyWithPlayers))
    self.atis[_airfields.name]:SetSubtitleDuration((_airfields.subtitleDuration or self.defaultSubtitleDuration))
    self.atis[_airfields.name]:Start()

end

MISSIONATIS:AddAtis(MISSIONATIS.airfields[1])

-- nttrAtis = ATIS:New("Nellis", 327.3, 0)
-- nttrAtis:SetSRS(MISSIONATIS.SRSPath,"male","en-GB",nil,MISSIONATIS.SRSPort)
-- nttrAtis:SetActiveRunwayTakeoff("03L",true)
-- nttrAtis:SetActiveRunwayLanding("21L",true)
-- nttrAtis:AddILS(109.10,"21L")
-- nttrAtis:SetSubtitleDuration(20)
-- nttrAtis:SetTACAN(12)
-- nttrAtis:SetTowerFrequencies({327.0, 132.6, 38.7})
-- nttrAtis:SetImperialUnits()
-- nttrAtis:SetReportmBar()
-- nttrAtis:SetAdditionalInformation("Takeoff from runway zero three Lima.")
-- nttrAtis:Start()   


