call variables.cmd

rmdir "%modpath%\release" /s /q
mkdir "%modpath%\release"

rmdir "%modpath%\release\mods\%modName%\content\" /s /q
XCOPY "%modpath%\mods" "%modpath%\release\mods\" /e /s /y
XCOPY "%modpath%\strings" "%modpath%\release\mods\%modName%Core\content\" /e /s /y

mkdir "%modpath%\release\bin\config\r4game\user_config_matrix\pc\"
copy "%modpath%\mod-menu.xml" "%modpath%\release\bin\config\r4game\user_config_matrix\pc\%modname%.xml" /y
