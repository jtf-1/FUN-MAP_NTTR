Welcome to the JTF-1 NTTR Fun Map!
Range template from 476th vFG


Radio presets are per NELLISAFBI-11-250

- 01 - SQUADRON COMMON
- 02 - 289.400 - Nellis Clearance Delivery
- 03 - 275.800 - Nellis Ground
- 04 - 327.000 - Nellis Tower
- 05 - 385.400 - Nellis App/Dep WEST
- 06 - 273.550 - Nellis App/Dep EAST
- 07 - 317.525 - Nellis Control SALLY
- 08 - 254.400 - Nellis Control LEE
- 09 - 305.600 - SOF (BULLSEYE SOF)
- 10 - 251.000 - Emergeency Single Frequency App
- 11 - 270.100 - ATIS
- 12 - 360.625 - Creech AFB Tower
- 13 - UNUSED
- 14 - 377.800 - BLACKJACK
- 15 - 295.400 - Unit Option / AR-641A HI
- 16 - 276.100 - Unit Option / AR-641A LO
- 17 - 352.600 - Unit Option / AR-635 HI
- 18 - 317.775 - Unit Option / AR-635 LO
- 19 - 343.600 - Unit Option / AR-230V
- 20 - 282.025 - AWACS

Default waypoints for all aircraft are;

- 1: FLEX
- 2: JUNNO
- 3: DREAM
- 4: STUDENT GAP
- 5: BELTED PK
- 6: GARTH
- 7: FLUSH
- 8: JAYSN
- 9: STRYK
- 10: GASS PK
- 11: APEX

See mission kneeboard for comms, navigation and range info.


ATIS
====

- Nellis AFB 270.100
- Creech AFB 290.450
- MCCarran Int 132.400
- Groom Lake AFB 123.500
- Henderson Executive 120.775
- Laughlin 119.825
- North Las Vegas 118.050
- Tonopah Test Range 131.000 


AWACS
=====

DARKSTAR 1-1, 344.025


TANKERS
=======

Track R-641A
- HI, TEXACO 1-1 [KC-135] 31Y, 295.400, FL230-250
- LO, SHELL 1-1 [KC-135MPRS] 35Y, 276.100, FL180-210

AR-635 
- HI, TEXACO 2-1 [KC-135] 52Y, 352.600, FL230-250
- LO, SHELL 2-1 [KC-135MPRS] 34Y, 317.775, F180-210

ARLNS 
- HI, TEXACO 3-1 [KC-135] 51Y, 324.050, FL240-330
- LO, SHELL 3-1 [KC-135MPRS] 33Y, 319.800, F210-260

AR-230V
- ARCO 1-1 [KC-135] 30Y, 343.600, FL150 [215kts IAS]
- ARCO 3-1 [KC-130] 29Y, 323.200, FL100


MISSILE TRAINER
===============

A missile trainer is available to assist training in A/S and A/A missile evasion without being destroyed. By default, the missile trainer is disabled, but may be enabled for your aircraft via the F10 menu

While enabled, the missile trainer will;

- Alert on missile launch
- Provide evasion advice
- Destroy incoming missiles prior to impact

NOTE: At very high closure rates it may not be possible to destroy the incoming missile without causing (potentially catastrophic) damage to your aircraft. The missile trainer will not protect against cannon rounds or other balistic weapons.


STATIC RANGES
=============

The following ranges are populated with multiple static targets; 61B, 62A, 62B, 63B, 64A, 64B, 64C, 65C, 65D and 74C. Each target contains one or more DMPI. See the in-game kneeboard for target data.

Static targets are script scored and have an F10 menu system you can use to manage them. A range instructor is available at each range to provide hit assessment. 

Bomb targets are scored on the proximity of the last round to the target. Smoke will be used to mark the round's impact.

Strafe Pits, where available (R63B, R64C), are configured with three targets per lane. Aircraft must be below 3000ft AGL and within 500ft either side of the inbound heading to the target to avoid a foul pass. Rounds fired after the foul line will not count.


ACTIVE RANGES
=============

Active Targets are available in the following ranges and can be activated or reset from the F10 menu; 

R74C
- 74-01, 74-06, 74-25, 74-26, 74-27, 74-29, 74-30, 74-36, 74-39

R75W
- 75-16, 75-20

R76
- 76-10, 76-20

Two activation options are available for each Active Target that also has a separate SAM defence; Activate or Active with SAM. Activated targets will engage with firearms, AAA. If the SAM option is selected, SAM and MANPAD assets at or IVO the target will also engage. Dedicated SAM targets will become active when the Activate option is selected. 

Notifications relating to target activation, reset and deactivation will be broadcast on BLACKJACK.


ELECTRONIC COMBAT SIMULATION RANGE
==================================

Electronic Combat simulations are available in EC South and can be activated, or reset, from the F10 menu.

The following SAM threats can be activated IVO target 77-69;

- SA-2
- SA-3
- SA-6
- SA-8
- SA-15


AI BFM/ACM
==========

On-demand single or pair adversary spawns are available via the F10 menu while aircraft are within ranges Coyote Alpha, Bravo and Charlie. Adversaries will be spawned ahead of you at the selected distance (5NM, 10NM, 20NM). 

Notifications relating to target activation, reset and deactivation will be broadcast on BLACKJACK.


AI BVR/GCI
==========

On-demand pair or four-ship BVR adversary spawns are available via the F10 menu in an 80NM wide BVR training corridor. The corridor runs from BEATTY VORTAC [BTY] to MINA VORTAC [MVA], approx 140NM, along the Western edge of the MOA. Adversaries will be spawned IVO MVA, and will flow towards BTY.

The menu is structured to allow selection of Altitude [High: 30k, Medium: 20k, Low: 10k], Formation/Spacing, and Adversary Aircraft Type. Adversaries will spawn in Line Abreast, then manoeuvre into the selected formation. ROE is set to Return Fire, although adversaries should engage any training aircraft passing North-West of BTY. Adversary spawns can be removed via the F10 menu. They will also despawn if they are outside the BVR training corridor. The F10 menu is also available in GameMaster, Observer and JTAC slots.

Notifications relating to target activation, reset and deactivation will be broadcast on BLACKJACK.


MAP MARK SPAWNING
=================

WIP - Use F10 map marks to spawn BVR opponents or ground threats anywhere on the map. Add mark to map then type the CMD syntax below in the map mark text field. The command will execute on mouse-clicking out of the text box.

NOTE: currently no syntax error feedback if you get it wrong.


Airspawn syntax
---------------

CMD ASPAWN: [type][, [option]: [value]][...]


Airspawn Types
--------------

- F4
- SU27
- MIG29
- SU25
- MIG23


Airspawn Options
----------------

- HDG: [degrees] - default 000
- ALT: [flight level] - default 280 (28,000ft)
- DIST:[nm] - default 0 (spawn on mark point)
- NUM: [1-4] - default 1
- SPD: [knots] - default 425
- SKILL: [AVERAGE, GOOD, HIGH, EXCELLENT, RANDOM] - default AVERAGE
- TASK: [CAP] - default NOTHING


Example
-------

CMD ASPAWN: MIG29, NUM: 2, HDG: 180, SKILL: GOOD

Will spawn 2x MiG29 at the default speed of 425 knots, with heading 180 and skill level GOOD.


Groundspawn Syntax
------------------

CMD GSPAWN: [groundspawn type][, [option]: [value]][...]


Groundspawn Types
-----------------

- SA2
- SA6
- SA10
- SA11
- SA15


Groundspawn Options
----------------

- ALERT: [GREEN, AUTO, RED] - default RED 
- SKILL: [AVERAGE, GOOD, HIGH, EXCELLENT, RANDOM] - default AVERAGE


Example
-------

CMD GSPAWN: SA6, ALERT: GREEN, SKILL: HIGH

Will spawn an SA6 Battery on the location of the map mark, in alert state GREEN and with skill level HIGH.


Delete Spawn Syntax
-------------------

CMD DELETE: [object type] [group name from F10 map]


Delete Spawn Object Types
-------------------------

- GROUP


Example
-------

CMD DELETE: GROUP MIG29A#001

Will remove the spawned group named MIG29A#001


Cut-n-Paste Command Examples
----------------------------

CMD GSPAWN: SA8, ALERT: RED, SKILL: HIGH

CMD GSPAWN: SA15, ALERT: RED, SKILL: HIGH

CMD ASPAWN: MIG29, NUM: 2, HDG: 90, SKILL: GOOD, ALT: 280, TASK: CAP

CMD DELETE: GROUP BVR_MIG29A#001
