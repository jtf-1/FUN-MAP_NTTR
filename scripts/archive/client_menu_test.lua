ClientSet = SET_CLIENT:New()
                      :FilterStart()

function SetEventHandler()
    ClientBirth = ClientSet:HandleEvent(EVENTS.Birth)
end

function ClientSet:OnEventBirth(EventData)
    local name = EventData.IniUnitName
    env.info("Client connected!")
    env.info(name)
    local client = CLIENT:FindByName(name)

    MESSAGE:New("Welcome, " .. name):ToClient(client)
end

SetEventHandler()



TopMenu = {}
TopMenu[1] = MENU_MISSION:New( "Northern Support Menu" )
TopMenu[2] = MENU_MISSION:New( "Southern Support Menu" )
TopMenu[3] = MENU_MISSION:New( "CVN-71/CVW-17 Carrier Menu" )
TopMenu[4] = MENU_MISSION:New( "CVN-72/CVW-9 Carrier Menu" )
-- Now you can 
for i=1,4 do 
  TopMenu[i]:remove()
end