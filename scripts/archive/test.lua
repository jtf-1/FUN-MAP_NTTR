texacosouth=SQUADRON:New("Texaco South", 4, "22ARS") --Ops.Squadron#SQUADRON
texacosouth:SetCallsign(CALLSIGN.Tanker.Texaco, 3)
texacosouth:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
texacosouth:SetMissionRange(500)

shellsouth=SQUADRON:New("Shell South", 4, "23ARS") --Ops.Squadron#SQUADRON
shellsouth:SetCallsign(CALLSIGN.Tanker.Shell,2)
shellsouth:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
shellsouth:SetMissionRange(500)

Magic=SQUADRON:New("Magic", 2, "Magic AWACS")
Magic:SetCallsign(CALLSIGN.AWACS.Magic, 5)
Magic:AddMissionCapability({AUFTRAG.Type.AWACS}, 100) 
Magic:SetMissionRange(500)

Kobuleti=AIRWING:New("Kobuleti Warehouse", "Kobuleti Airwing") --Ops.AirWing#AIRWING
Kobuleti:SetNumberTankerBoom(1)
Kobuleti:SetNumberTankerProbe(1)
Kobuleti:SetNumberAWACS(1)
Kobuleti:AddPatrolPointTANKER(ZONE:New("Tanker South"):GetCoordinate(), 20000, 250, 15, 25)
Kobuleti:AddPatrolPointTANKER(ZONE:New("Tanker South-West"):GetCoordinate(), 18000, 250, 15, 25)
Kobuleti:AddPatrolPointAWACS(ZONE:New("AWACs Zone"):GetCoordinate(), 25000, 250, 15, 25)
Kobuleti:SetAirbase(AIRBASE:FindByName("Kobuleti"))
Kobuleti:Start()
Kobuleti:AddSquadron(texacosouth)
Kobuleti:NewPayload("Texaco South",-1,{AUFTRAG.Type.TANKER},100)
Kobuleti:AddSquadron(Magic)
Kobuleti:NewPayload("Magic",-1,{AUFTRAG.Type.AWACS},100)
Kobuleti:AddSquadron(shellsouth)
Kobuleti:NewPayload("Shell South",-1,{AUFTRAG.Type.TANKER},100)