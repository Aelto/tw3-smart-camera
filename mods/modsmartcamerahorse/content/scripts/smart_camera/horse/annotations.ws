@addMethod(W3VehicleCombatManager)
function SC_isAiming(): bool {
  return false;
}

@addMethod(W3VehicleCombatManagerStateRangedAttack)
function SC_isAiming(): bool {
  return aiming;
}

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
  if (!parent.smart_camera_data.settings.is_enabled_on_horse || vehicleCombatMgr.SC_isAiming()) {
    return wrappedMethod(moveData, dt);
  }

  return true;
}