-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- TEST LUA
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

JTFTEST = {}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- TEST CODE BLOCK
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function JTFTEST.testRadioTextDefault()

    local msgText = "Radio test with text only. Defaults."
    MISSIONSRS:SendRadio(msgText)

end

function JTFTEST.testRadioSoundTextDefault()

    local msgText = "Radio test with soundtext only. Defaults."
    msgText = SOUNDTEXT:New(msgText)
    MISSIONSRS:SendRadio(msgText)

end

function JTFTEST.testRadioTextFreqsNoMod()

    local msgText = "Radio test with text and frequnecies, no modulations."
    local msgFreqs = "355"
    MISSIONSRS:SendRadio(msgText, msgFreqs)

end

function JTFTEST.testRadioSoundTextFreqsNoMod()

    local msgText = "Radio test with soundtext and frequencies, no modulations."
    msgText = SOUNDTEXT:New(msgText)
    local msgFreqs = "355"
    MISSIONSRS:SendRadio(msgText, msgFreqs)
    
end

function JTFTEST.testRadioTextFreqsAndMod()

    local msgText = "Radio test with text and frequnecies, AM and FM modulation."
    local msgFreqs = "355,31"
    local msgMods = "AM,FM"
    MISSIONSRS:SendRadio(msgText, msgFreqs,msgMods)

end

function JTFTEST.testRadioSoundTextFreqsAndMod()

    local msgText = "Radio test with text and frequencies, AM and FM modulation."
    msgText = SOUNDTEXT:New(msgText)
    local msgFreqs = "355,31"
    local msgMods = "AM,FM"
    MISSIONSRS:SendRadio(msgText, msgFreqs,msgMods)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- TEST MENU BLOCK
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

JTFTEST.Menu = MENU_MISSION:New("TEST", DEV_MENU.topmenu)
MENU_MISSION_COMMAND:New("Mission Restart", JTFTEST.Menu, MISSIONTIMER.Restart, MISSIONTIMER )
MENU_MISSION_COMMAND:New("Radio Text DEFAULTS", JTFTEST.Menu, JTFTEST.testRadioTextDefault, MISSIONSRS )
MENU_MISSION_COMMAND:New("Radio SoundText DEFAULTS", JTFTEST.Menu, JTFTEST.testRadioSoundTextDefault, MISSIONSRS )
MENU_MISSION_COMMAND:New("Radio Text Freqs default mods", JTFTEST.Menu, JTFTEST.testRadioTextFreqsNoMod, MISSIONSRS )
MENU_MISSION_COMMAND:New("Radio SoundText freqs no mods", JTFTEST.Menu, JTFTEST.testRadioSoundTextFreqsNoMod, MISSIONSRS )
MENU_MISSION_COMMAND:New("Radio Text freqs and mods", JTFTEST.Menu, JTFTEST.testRadioTextFreqsAndMod, MISSIONSRS )
MENU_MISSION_COMMAND:New("Radio SoundText freqs and mods", JTFTEST.Menu, JTFTEST.testRadioSoundTextFreqsAndMod, MISSIONSRS )
