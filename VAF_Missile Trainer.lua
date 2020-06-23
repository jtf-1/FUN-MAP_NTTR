-- Only use Include.File when developing new MOOSE classes.
-- When using Moose.lua in the DO SCIPTS FILE initialization box, 
-- these Include.File statements are not needed, because all classes within Moose will be loaded.


-- This is an example of a global
local Trainer = MISSILETRAINER
  :New( 200, "Trainer: Welcome to the VAF AIR-TO-SURFACE (AS) training, trainee! Surface to air threats will engage you but will not destroy you. Registered Missiles kills will be graded against you. Try to evade them. Good luck!" )
  :InitMessagesOnOff(false)
  :InitAlertsToAll(false) 
  :InitAlertsHitsOnOff(true)
  :InitAlertsLaunchesOnOff(false) -- I'll put it on below ...
  :InitBearingOnOff(false)
  :InitRangeOnOff(false)
  :InitTrackingOnOff(false)
  :InitTrackingToAll(false)
  :InitMenusOnOff(false)

Trainer:InitAlertsToAll(false) -- Now alerts are also on