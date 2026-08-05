@addField(CR4Player)
var smart_camera_data: SC_data;

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


// disable vanilla sprint camera if SC is enabled
@wrapMethod(CPlayer)
function EnableRunCamera(flag: bool) {
  if (!thePlayer.smart_camera_data.settings.is_enabled_in_exploration) {
    wrappedMethod(flag);
  }
}

@wrapMethod(CPlayer)
function EnableSprintingCamera(flag: bool) {
  if (!thePlayer.smart_camera_data.settings.is_enabled_in_exploration) {
    wrappedMethod(flag);
  }
}

@wrapMethod(CR4Player)
function EnableSprintingCamera(flag: bool) {
  if (!thePlayer.smart_camera_data.settings.is_enabled_in_exploration) {
    wrappedMethod(flag);
  }
}

// This wrapper was once used, but now removed as it
// can conflict with mods having a Combat state.
// The removal of this wrapper does not seem to 
// change anything either, which is odd.
//
// leaving it commented in case it causes issues

// @wrapMethod(Combat)
// function OnGameCameraPostTick(out moveData: SCameraMovementData, dt: float) {
//   if (SC_shouldDisableExplorationPosTick(parent)) {
//     return true;
//   }

//   return wrappedMethod(moveData, dt);
// }