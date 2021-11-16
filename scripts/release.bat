call variables.cmd

rmdir "%modpath%\release" /s /q
mkdir "%modpath%\release"

mkdir "%modpath%\release\mods\%modname%\content\scripts\"
rmdir "%modpath%\release\mods\%modName%\content\" /s /q
XCOPY "%modpath%\src" "%modpath%\release\mods\%modName%\content\scripts\" /e /s /y
XCOPY "%modpath%\strings" "%modpath%\release\mods\%modName%\content\" /e /s /y

mkdir "%modpath%\release\bin\config\r4game\user_config_matrix\pc\"
copy "%modpath%\mod-menu.xml" "%modpath%\release\bin\config\r4game\user_config_matrix\pc\%modname%.xml" /y
