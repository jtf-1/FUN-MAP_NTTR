-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Default SRS Text-to-Speech
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Send messages through SRS using STTS
-- Script will try to load the file specified with LocalServerConfigFile [name of settings file] 
-- and LocalServerConfigPath [path to file]. This file should define the path to the SRS installation 
-- directory and the port used by the DCS server instance running the mission. 
--
-- If the settings file is not found, the defaults for srs_path and srs_port will be used.
--
-- Message text will be formatted as a SOUNDTEXT object.
-- 


MISSIONSRS = {
  fileName = "ServerLocalSettings.lua", -- name of file containing local server settings
  LocalServerConfigPath = nil, --"C:/Users/rober/Saved Games/DCS.openbeta_server/Scripts", -- path to server srs settings
  LocalServerConfigFile = "LocalServerSettings.txt", -- srs server settings file name
  defaultSrsPath = "C:/Program Files/DCS-SimpleRadio-Standalone", -- default path to SRS install directory if setting file is not avaialable "C:/Program Files/DCS-SimpleRadio-Standalone"
  defaultSrsPort = 5002, -- default SRS port to use if settings file is not available
  defaultText = "No Message Defined!",
  defaultFreqs = "243,251,327,377.8", -- transmit on guard, CTAF, NTTR TWR and NTTR BLACKJACK as default frequencies
  defaultModulation = "AM,AM,AM,AM", -- default modulation (count *must* match qty of freqs)
  defaultVol = "1.0", -- default to full volume
  defaultName = "Server", -- default to server as sender
  defaultCoalition = 0, -- default to spectators
  defaultVec3 = nil, -- point from which transmission originates
  defaultSpeed = 2, -- speed at which message should be played
  defaultGender = "female", -- default gender of sender
  defaultCulture = "en-US", -- default culture of sender
  defaultVoice = "", -- default voice to use
}

function MISSIONSRS:LoadSettings()
  local loadFile  = MISSIONSRS.LocalServerConfigFile
  if UTILS.CheckFileExists(MISSIONSRS.LocalServerConfigPath, MISSIONSRS.LocalServerConfigFile) then
    local loadFile, serverSettings = UTILS.LoadFromFile(MISSIONSRS.LocalServerConfigPath, MISSIONSRS.LocalServerConfigFile)
    BASE:T({"[MISSIONSRS] Load Server Settings",{serverSettings}})
    if not loadFile then
      BASE:E(string.format("[MISSIONSRS] ERROR: Could not load %s", loadFile))
    else
      MISSIONSRS.SRS_DIRECTORY = serverSettings[1] or MISSIONSRS.defaultSrsPath
      MISSIONSRS.SRS_PORT = serverSettings[2] or MISSIONSRS.defaultSrsPort
      MISSIONSRS:AddRadio()
      BASE:T({"[MISSIONSRS]",{MISSIONSRS}})
    end
  else
    BASE:E(string.format("[MISSIONSRS] ERROR: Could not find %s", loadFile))
  end
end

function MISSIONSRS:AddRadio()
  MISSIONSRS.Radio = MSRS:New(MISSIONSRS.SRS_DIRECTORY, MISSIONSRS.defaultFreqs, MISSIONSRS.defaultModulation)
  MISSIONSRS.Radio:SetPort(MISSIONSRS.SRS_PORT)
  MISSIONSRS.Radio:SetGender(MISSIONSRS.defaultGender)
  MISSIONSRS.Radio:SetCulture(MISSIONSRS.defaultCulture)
  MISSIONSRS.Radio.name = MISSIONSRS.defaultName
end

function MISSIONSRS.SendRadio(msgText)
  BASE:T({"[MISSIONSRS] SendRadio", {msgText, msgFreqs, msgModulations}})
  local text = SOUNDTEXT:New(msgText)
  MISSIONSRS.Radio:PlaySoundText(text)
end


MISSIONSRS:LoadSettings()
