@wrapMethod(HorseRiding)
function OnGameCameraPostTick(
  out moveData: SCameraMovementData,
  dt: float
) {
  if (SC_horseOnCameraTickPostTick(
    parent,
    (W3HorseComponent)vehicle,
    (CCustomCamera)theCamera.GetTopmostCameraObject(),
    moveData,
    dt
  )) {
    return true;
  }

  return wrappedMethod(moveData, dt);
}

@wrapMethod(HorseRiding)
function OnGameCameraTick(out moveData: SCameraMovementData, dt: float ) {
  if (false) {
    wrappedMethod(moveData, dt);
  }

  return true;
}