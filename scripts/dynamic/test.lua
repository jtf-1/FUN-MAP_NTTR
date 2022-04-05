-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --- Default SRS Text-to-Speech
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --
-- -- Send messages through SRS using STTS
-- -- Script will try to load the file specified with LocalServerConfigFile [name of settings file] 
-- -- and LocalServerConfigPath [path to file]. This file should define the path to the SRS installation 
-- -- directory and the port used by the DCS server instance running the mission. 
-- --
-- -- If the settings file is not found, the defaults for srs_path and srs_port will be used.

-- JTFMSRS = {
--   fileName = "ServerLocalSettings.lua", -- name of file containing local server settings
--   LocalServerConfigPath = nil, --"C:/Users/rober/Saved Games/DCS.openbeta_server/Scripts", -- path to server srs settings
--   LocalServerConfigFile = "LocalServerSettings.txt", -- srs server settings file name
--   defaultSrsPath = "C:/Program Files/DCS-SimpleRadio-Standalone", -- default path to SRS install directory if setting file is not avaialable "C:/Program Files/DCS-SimpleRadio-Standalone"
--   defaultSrsPort = 5002, -- default SRS port to use if settings file is not available
--   defaultText = "No Message Defined!",
--   defaultFreqs = "243,251,327,377.8", -- transmit on guard, CTAF, NTTR TWR and NTTR BLACKJACK as default frequencies
--   defaultModulation = "AM,AM,AM,AM", -- default modulation
--   defaultVol = "1.0", -- default to full volume
--   defaultName = "Server", -- default to server as sender
--   defaultCoalition = 0, -- default to spectators
--   defaultVec3 = nil, -- point from which transmission originates
--   defaultSpeed = 2, -- speed at which message should be played
--   defaultGender = "female", -- default gender of sender
--   defaultCulture = "en-US", -- default culture of sender
--   defaultVoice = "", -- default voice to use
-- }

-- function JTFMSRS:LoadSettings()
--   local loadFile  = JTFMSRS.LocalServerConfigFile
--   if UTILS.CheckFileExists(JTFMSRS.LocalServerConfigPath, JTFMSRS.LocalServerConfigFile) then
--     local loadFile, serverSettings = UTILS.LoadFromFile(JTFMSRS.LocalServerConfigPath, JTFMSRS.LocalServerConfigFile)
--     BASE:T({serverSettings})
--     if not loadFile then
--       BASE:E(string.format("[JTFMSRS] ERROR: Could not load %s", loadFile))
--     else
--       JTFMSRS.SRS_DIRECTORY = serverSettings[1] or JTFMSRS.defaultSrsPath
--       JTFMSRS.SRS_PORT = serverSettings[2] or JTFMSRS.defaultSrsPort
--       JTFMSRS:AddDefaultRadio()
--       BASE:T({JTFMSRS})
--     end
--   else
--     BASE:E(string.format("[JTFMSRS] ERROR: Could not find %s", loadFile))
--   end
-- end

-- function JTFMSRS:AddDefaultRadio()
--   JTFMSRS.DefaultRadio = MSRS:New(JTFMSRS.SRS_DIRECTORY, JTFMSRS.defaultFreqs, JTFMSRS.defaultModulation)
--   JTFMSRS.DefaultRadio:SetPort(JTFMSRS.SRS_PORT)
--   JTFMSRS.DefaultRadio:SetGender(JTFMSRS.defaultGender)
--   JTFMSRS.DefaultRadio:SetCulture(JTFMSRS.defaultCulture)
--   JTFMSRS.DefaultRadio.name = JTFMSRS.defaultName
-- end

-- function JTFMSRS.SendDefaultRadio(msgText)
--   BASE:T("[JTFMSRS] SendDefaultRadio")
--   BASE:T("msgText = " .. msgText )
--   local text = SOUNDTEXT:New(msgText)
--   JTFMSRS.DefaultRadio:PlaySoundText(text)
  
--   --STTS.DIRECTORY = JTFMSRS.SRS_DIRECTORY
--   --STTS.SRS_PORT = JTFMSRS.SRS_PORT
--   --STTS.TextToSpeech(msgText,JTFMSRS.defaultFreqs, JTFMSRS.defaultModulation, JTFMSRS.defaultVol, JTFMSRS.defaultName, 2)
--   --BASE:T({STTS})
-- end

-- JTFMSRS:LoadSettings()

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- TEST BLOCK
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

JTFTEST = {}
JTFTEST.Menu = MENU_MISSION:New("TEST", DEV_MENU.topmenu)
MENU_MISSION_COMMAND:New("STTS test 1.", JTFTEST.Menu, JTFMSRS.SendDefaultRadio, "99 all players, mission will restart in 10 minutes!")