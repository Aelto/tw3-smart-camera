@wrapMethod(CR4PlayerStateHorseRiding)
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

@wrapMethod(CR4PlayerStateHorseRiding)
function OnGameCameraTick(out moveData: SCameraMovementData, dt: float ) {
  if (!parent.smart_camera_data.settings.is_enabled_on_horse) {
    return wrappedMethod(moveData, dt);
  }

  return true;
}