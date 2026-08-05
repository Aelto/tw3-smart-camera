import 'release.precompiled.justfile'
import 'strings.justfile'

release:
  @ just release-modular
  @ just release-precompiled


[private]
[working-directory: ".."]
release-modular:
  @ echo generating release: modular

  @ echo - purge the modular release
  @ rm -rf release/modular
  @ mkdir -p release/modular

  @ echo - copy scripts to modular release
  @ mkdir -p release/modular/mods
  @ cp -r mods/modsmartcameracore release/modular/mods
  @ cp -r mods/modsmartcamerahorse release/modular/mods

  @ echo - copy mod menu to modular release
  @ mkdir -p release/modular/bin/config/r4game/user_config_matrix/pc
  @ cp mod-menu.xml release/modular/bin/config/r4game/user_config_matrix/pc/smart-camera.xml

  @ echo - generating strings for modular release
  @ just scripts/encode_w3strings
  @ cp strings/*.w3strings release/modular/mods/modsmartcameracore/content/
  @ cp strings/*.csv release/modular/mods/modsmartcameracore/content/

  just scripts/release-modular-zip

  @ echo generating release: modular <~ [DONE]

[working-directory: "../release/modular"]
release-modular-zip:
  @ echo - zipping modular release
  @ zip -r modsmartcamera_modular mods bin
