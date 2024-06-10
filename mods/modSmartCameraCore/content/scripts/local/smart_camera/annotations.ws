@wrapMethod(CR4Player)
function OnGameCameraTick(out moveData : SCameraMovementData, dt : float) {
  if (!SC_onGameCameraTickCheck(this, moveData, dt)) {
    wrappedMethod(moveData, dt);
  }
  else {
    if(this.substateManager.UpdateCameraIfNeeded(moveData, dt)) {
      return true;
		}

    return SC_onGameCameraTick(this, moveData, dt);
  }
}

// @wrapMethod(CR4PlayerStateCombat)
// function OnGameCameraPostTick(out moveData: SCameraMovementData, dt: float) {
//   if (SC_shouldDisableExplorationPosTick(parent)) {
//     return true;
//   }
//   else {
//     return wrappedMethod(moveData, dt);
//   }
// }