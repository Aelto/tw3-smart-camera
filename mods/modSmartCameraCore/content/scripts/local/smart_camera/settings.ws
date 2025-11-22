
function SC_reloadSettings(out settings: SC_settings) {
  LogChannel('SmartCamera', "has mod menu = " + SC_hasModMenu());

  if (SC_hasModMenu()) {
    settings.is_enabled_in_combat = SC_isEnabledInCombat();
    settings.is_enabled_in_exploration = SC_isEnabledInExploration();
    settings.is_enabled_on_horse = SC_isEnabledOnHorse();
    settings.is_enabled_on_boat = SC_isEnabledOnBoat();
    settings.is_enabled_with_mouse = SC_isEnabledWithMouse();
    settings.camera_zoom = SC_getCameraZoom();
    settings.camera_zoom_max = SC_getCameraZoomMax();
    settings.horizontal_sensitivity = SC_getHorizontalSensitivity();
    settings.overall_speed = SC_getOverallSpeed();
    settings.camera_fov = SC_getCameraFov();
    settings.camera_height = SC_getCameraHeight();
    settings.camera_height_max = SC_getCameraHeightMax();
    settings.camera_horizontal_position = SC_getCameraHorizontalPosition();
    settings.horse_camera_zoom = SC_getHorseCameraZoom();
    settings.camera_tilt_intensity = SC_getHorseCameraTiltIntensity();
    settings.exploration_autocenter_enabled = SC_isExplorationAutocenterEnabled();
    settings.exploration_shake_intensity = SC_getExplorationShakeIntensity();
    settings.exploration_offset_intensity = SC_getExplorationOffsetIntensity();
  }
  else {
    settings.is_enabled_in_combat = true;
    settings.is_enabled_in_exploration = true;
    settings.is_enabled_on_horse = true;
    settings.is_enabled_on_boat = true;
    settings.is_enabled_with_mouse = true;
    settings.camera_zoom = 3.5;
    settings.camera_zoom_max = 10;
    settings.horizontal_sensitivity = 1;
    settings.overall_speed = 1;
    settings.camera_fov = 60;
    settings.camera_height = 0.8;
    settings.camera_height_max = 5.0;
    settings.camera_horizontal_position = 0;
    settings.horse_camera_zoom = 1;
    settings.camera_tilt_intensity = 1;
    settings.exploration_autocenter_enabled = 1;
    settings.exploration_shake_intensity = 1;
    settings.exploration_offset_intensity = 1;
  }
}

function SC_hasModMenu(): bool {
  return GetLocStringByKey("panel_sc_name") != "";
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

function SC_isEnabledOnHorse(): bool {
  return theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCmodEnabledOnHorse');
}

function SC_isEnabledOnBoat(): bool {
  return theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCmodEnabledOnBoat');
}

function SC_isEnabledWithMouse(): bool {
  return theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCmodEnabledWithMouse');
}

function SC_getCameraZoom(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCcameraZoom')
  );
}

function SC_getCameraZoomMax(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCcameraZoomMax')
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

function SC_getCameraHeightMax(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCcameraHeightMax')
  );
}

function SC_getCameraHorizontalPosition(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCcameraHorizontalPosition')
  );
}

function SC_getHorseCameraZoom(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SChorseCameraZoom')
  );
}

function SC_getHorseCameraTiltIntensity(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCcameraTiltIntensity')
  );
}

function SC_isExplorationAutocenterEnabled(): bool {
  return theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCexplorationAutoCenterEnabled');
}

function SC_getExplorationShakeIntensity(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCexplorationShakeIntensity')
  );
}

function SC_getExplorationOffsetIntensity(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCexplorationOffsetIntensity')
  );
}