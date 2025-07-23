call variables.cmd

set releasemods=%modpath%\release\mods
set bundleddir=%modpath%\release.bundled
set bundledmod=%bundleddir%\mods\modSmartCamera
set bundledout=%bundledmod%\content\scripts

rmdir "%modpath%\release" /s /q
mkdir "%modpath%\release"

rmdir "%modpath%\release.bundled" /s /q
mkdir "%modpath%\release.bundled"

call :movetorelease modSmartCameraCore true
call :movetorelease modSmartCameraHorse true

:: add strings
XCOPY "%modpath%\strings" "%modpath%\release\mods\modSmartCameraCore\content\" /e /s /y
XCOPY "%modpath%\strings" "%bundledmod%\content\" /e /s /y

:: add mod menu
set binfolder=bin\config\r4game\user_config_matrix\pc

mkdir "%modpath%\release\%binfolder%\"
copy "%modpath%\mod-menu.xml" "%modpath%\release\%binfolder%\%modname%.xml" /y

mkdir "%bundleddir%\%binfolder%\"
copy "%modpath%\mod-menu.xml" "%bundleddir%\%binfolder%\%modname%.xml" /y

@REM call compileblob.bat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::FUNCTIONS::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto:eof

:: moves the provided module to the normal release
::
:: the second parameters defines whether it should also be added to the bundled
:: release, which is a single mod folder with all local files in the same place
:movetorelease
  XCOPY "%modpath%\mods\%~1\" "%releasemods%\%~1\" /e /s /y

  set shouldmovetobundled=%~2
  if "%shouldmovetobundled%" == "true" (
    call :movetobundled %~1
  )
goto:eof


:: moves the provided module to the bundled release
:movetobundled
  echo Moving %~1 to bundled release
  ::echo "%releasemods%\%~1\%localpath%"
  ::echo "%bundledout%"
  XCOPY "%releasemods%\%~1\content\scripts\" "%bundledout%\"  /e /s /y
goto:eof