::
:: Copy Mission Files from dynmic to static
::

@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

:: name of this file for message output
SET me=%~n0
:: folder in which this file is being executed
SET parent=%~dp0
:: log file to output build results
SET log=%parent%logs\%me%.log

SET destination_path=%parent%static\
ECHO Static file output path:    %destination_path%

:: path to dynamic files to be concatenated
SET source_path=%parent%dynamic\
SET source_path_core=%parent%dynamic\core\

ECHO.

:: Initialise build file & log
ECHO STATIC FILE COPY STARTED: %DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%T%TIME% > %log%
ECHO. >> %log%

ECHO.

:: Dynamic local files
copy %source_path%disableai.lua %destination_path%disableai.lua
copy %source_path%missionsrs_data.lua %destination_path%missionsrs_data.lua
copy %source_path%missiontimer_data.lua %destination_path%missiontimer_data.lua
copy %source_path%missiletrainer_data.lua %destination_path%missiletrainer_data.lua
copy %source_path%supportaircraft_data.lua %destination_path%supportaircraft_data.lua
copy %source_path%staticranges_data.lua %destination_path%staticranges_data.lua
copy %source_path%movingtargets.lua %destination_path%movingtargets.lua
copy %source_path%ecs.lua %destination_path%ecs.lua
copy %source_path%bfmacm_data.lua %destination_path%bfmacm_data.lua
copy %source_path%bvrgci.lua %destination_path%bvrgci.lua
copy %source_path%markspawn.lua %destination_path%markspawn.lua
copy %source_path%activeranges_data.lua %destination_path%activeranges_data.lua

:: Dynamic core files
copy %source_path_core%mission_init.lua %destination_path%mission_init.lua
copy %source_path_core%devcheck.lua %destination_path%devcheck.lua
copy %source_path_core%adminmenu.lua %destination_path%adminmenu.lua
copy %source_path_core%missiontimer.lua %destination_path%missiontimer.lua
copy %source_path_core%Hercules_Cargo.lua %destination_path%Hercules_Cargo.lua
copy %source_path_core%missionsrs.lua %destination_path%missionsrs.lua
copy %source_path_core%supportaircraft.lua %destination_path%supportaircraft.lua
copy %source_path_core%staticranges.lua %destination_path%staticranges.lua
copy %source_path_core%activeranges.lua %destination_path%activeranges.lua
copy %source_path_core%mission_end.lua %destination_path%mission_end.lua
copy %source_path_core%missiletrainer.lua %destination_path%missiletrainer.lua
copy %source_path_core%bfmacm.lua %destination_path%bfmacm.lua

ECHO.

:: Close log
ECHO. >> %log%
ECHO STATIC FILE COPY FINISHED: %DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%T%TIME% >> %log%
ECHO Copy complete.

PAUSE
EXIT /B %ERRORLEVEL%