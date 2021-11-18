
function SC_reloadSettings(out settings: SC_settings) {
  settings.is_enabled = SC_isEnabled();
  settings.zoom_out_multiplier = SC_getZoomOutMultiplier();
  settings.horizontal_sensitivity = SC_getHorizontalSensitivity();
  settings.overall_speed = SC_getOverallSpeed();
}

function SC_isEnabled(): bool {
  return theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCmodEnabled');
}

function SC_getZoomOutMultiplier(): float {
  return StringToFloat(
    theGame
    .GetInGameConfigWrapper()
    .GetVarValue('SCgeneral', 'SCzoomOutMultiplier')
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