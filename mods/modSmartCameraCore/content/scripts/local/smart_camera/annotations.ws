@wrapMethod(CR4Player)
function OnGameCameraTick(out moveData : SCameraMovementData, dt : float) {
  var res: bool;

  res =  wrappedMethod(moveData, dt);
  SC_onGameCameraTick(this, moveData, dt);

  return res;
}

@wrapMethod(CR4CommonMainMenuBase)
function OnConfigUI() {
  var player: CR4Player;
  wrappedMethod();

  player = thePlayer;
  if (player) {
    SC_reloadSettings(player.smart_camera_data.settings);
  }
}

@wrapMethod(CR4IngameMenu)
function SaveChangedSettings() {
  var player: CR4Player;
  wrappedMethod();

  player = thePlayer;
  if (player) {
    SC_reloadSettings(player.smart_camera_data.settings);
  }
}
