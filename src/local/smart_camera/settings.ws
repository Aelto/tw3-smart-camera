
function SC_reloadSettings(out settings: SC_settings) {
  settings.is_enabled = SC_isEnabled();
  settings.camera_zoom = SC_getCameraZoom();
  settings.horizontal_sensitivity = SC_getHorizontalSensitivity();
  settings.overall_speed = SC_getOverallSpeed();
}

function SC_isEnabled(): bool {
  return theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCmodEnabled');
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
    .GetVarValue('SCgeneral', 'SChorizontalSensitivity')
  );
}

function SC_getMinZoomOut(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCminZoomOut')
  );
}

function SC_getMaxZoomOut(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCmaxZoomOut')
  );
}