
precompiled_mod := "release/precompiled/mods/modsmartcamera_precompiled"

[working-directory: ".."]
release-precompiled:
  @ echo generating release: precompile

  @ echo - purge the precompiled release
  @ rm -rf release/precompiled
  @ mkdir -p release/precompiled

  @ echo - copy scripts to precompile release
  @ mkdir -p {{precompiled_mod}}/content/scripts/
  @ cp -r mods/**/content/scripts/smart_camera {{precompiled_mod}}/content/scripts/

  @ echo - copy metadata to precompile release
  @ cp mods/modsmartcameracore/content/info.json {{precompiled_mod}}/content

  @ echo - generating precompile blob
  @ just scripts/generate-blob-on-windows
  @ mv {{precompiled_mod}}/content/scripts/blob.rsblob {{precompiled_mod}}/content/precompiled.rsblob

  @ just scripts/release-precompiled-zip
  @ echo generating release: precompile <~ [DONE]

[working-directory: "../release/precompiled"]
release-precompiled-zip:
  @ echo - zipping precompiled release
  @ zip -r modsmartcamera_precompiled mods

[working-directory: ".."]
[private]
generate-blob-on-windows:
  @ cmd.exe /c "just scripts/generate-blob"

gamescripts := "D:/dev/github/tw3-shared-utils/dev-scripts"
modtocompile := "D:/dev/github/tw3-smart-camera" / precompiled_mod
[working-directory: "D:/programs/Steam/steamapps/common/The Witcher 3 REDkit/bin/x64_RedKit"]
[windows]
[private]
generate-blob:
  @ wcc_lite.exe compilescripts "{{gamescripts}}" -patch="{{modtocompile}}/content/scripts" -out "{{modtocompile}}/content"

[windows]
set shell := ["nu", "-c"]
