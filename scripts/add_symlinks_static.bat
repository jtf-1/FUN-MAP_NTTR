::
:: Create Symlinks for library source files
:: Files will be added to MIZ when calling build_miz.bat
::

@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

:: name of this file for message output
SET me=%~n0
:: folder in which this file is being executed
SET parent=%~dp0

CD %parent%

:: path to static scripts
SET staticscriptpath=%parent%static\
ECHO Static path:           %staticscriptpath%

:: Move to folder containing library files
CD %staticscriptpath%
DIR  %staticscriptpath%*.*
ECHO --------------------------------------------------------
ECHO:

:: Create symlinks to library files
:: MOOSE
MKLINK %staticscriptpath%Moose_.lua "d:\GitHub\MOOSE_INCLUDE\Moose_Include_Static\Moose_.lua"
:: MIST
MKLINK %staticscriptpath%mist.lua "D:\GitHub\Skynet-IADS\demo-missions\mist_4_5_107.lua"
:: SKYNET
MKLINK %staticscriptpath%skynet-iads-compiled.lua "D:\GitHub\Skynet-IADS\demo-missions\skynet-iads-compiled.lua"

ECHO:
ECHO --------------------------------------------------------

DIR  %staticscriptpath%*.*

PAUSE
EXIT /B %ERRORLEVEL%