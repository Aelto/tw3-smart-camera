
function SC_reloadSettings(out settings: SC_settings) {
  settings.is_enabled_in_combat = SC_isEnabledInCombat();
  settings.is_enabled_in_exploration = SC_isEnabledInExploration();
  settings.camera_zoom = SC_getCameraZoom();
  settings.horizontal_sensitivity = SC_getHorizontalSensitivity();
  settings.overall_speed = SC_getOverallSpeed();
  settings.camera_fov = SC_getCameraFov();
  settings.camera_height = SC_getCameraHeight();
  settings.camera_horizontal_position = SC_getCameraHorizontalPosition();
}

function SC_isEnabledInCombat(): bool {
  return theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCmodEnabledInCombat');
}

function SC_isEnabledInExploration(): bool {
  return theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCmodEnabledInExploration');
}

function SC_getCameraZoom(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCcameraZoom')
  );
}

function SC_getHorizontalSensitivity(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SChorizontalSensitivity')
  );
}

function SC_getOverallSpeed(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCoverallSpeed')
  );
}

function SC_getCameraFov(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCcameraFov')
  );
}

function SC_getCameraHeight(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCcameraHeight')
  );
}

function SC_getCameraHorizontalPosition(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SC_getCameraHorizontalPosition')
  );
}