@echo off

call variables.cmd

rem install scripts
rmdir "%gamePath%\mods\%modName%Core\content\scripts" /s /q
rmdir "%gamePath%\mods\%modName%Horse\content\scripts" /s /q

XCOPY "%modPath%\mods" "%gamePath%\mods\" /e /s /y
XCOPY "%modPath%\strings" "%gamepath%\mods\%modname%Core\content\" /e /s /y
copy "%modPath%\mod-menu.xml" "%gamePath%\bin\config\r4game\user_config_matrix\pc\%modname%.xml" /y

if "%1"=="-dlc" (
  echo "copying DLC"
  rmdir "%gamePath%\dlc\dlc%modName%" /s /q
  xcopy "%modPath%\release\dlc" "%gamepath%\dlc" /e /s /y
)
