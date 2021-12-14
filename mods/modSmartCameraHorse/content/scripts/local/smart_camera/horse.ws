function SC_horseOnCameraTickPostTick(player: CR4Player, horse: W3HorseComponent, camera: CCustomCamera, out moveData: SCameraMovementData, delta: float): bool {
  var rotation: EulerAngles;
  var angle_distance: float;
  var horse_speed: float;
  var absolute_angle_distance: float;

  rotation = moveData.pivotRotationValue;
  horse_speed = horse.InternalGetSpeed();

  angle_distance = AngleDistance(rotation.Yaw, horse.GetHeading());
  absolute_angle_distance = AbsF(angle_distance);
  rotation.Yaw = horse.GetHeading();

  if (angle_distance * angle_distance < (4 + horse_speed) * (4 + horse_speed)) {
    player.smart_camera_data.horse_auto_center_enabled = true;
  }

  if (theInput.GetActionValue('GI_AxisRightX') != 0) {
    player.smart_camera_data.horse_auto_center_enabled = false;
  }

  ////////////////////
  // Yaw correction //
  ///////////////////
  //#region yaw correction
  if (horse_speed > 0 && player.smart_camera_data.horse_auto_center_enabled) {
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * horse_speed * 0.5 * absolute_angle_distance * 0.03,
      moveData.pivotRotationValue.Yaw,
      rotation.Yaw
    );

    moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
  }
  //#endregion yaw correction

  ////////////////////
  // Roll correction //
  ///////////////////
  //#region roll correction
  if (horse_speed > 0 && player.smart_camera_data.horse_auto_center_enabled) {
    moveData.pivotRotationValue.Roll = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed,
      moveData.pivotRotationValue.Roll,
      angle_distance * 0.03 * horse_speed
    );

    // moveData.pivotRotationController.SetDesiredHeading(angle_distance * 0.1);
  }
  else {
    moveData.pivotRotationValue.Roll = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * absolute_angle_distance * 0.01,
      moveData.pivotRotationValue.Roll,
      0
    );
  }
  //#endregion roll correction


  /////////////////////
  // Zoom correction //
  /////////////////////
  //#region zoom correction
  DampVectorSpring(
    moveData.cameraLocalSpaceOffset,
    moveData.cameraLocalSpaceOffsetVel,
    Vector(
      // x axis: horizontal position, left to right
      0,
      // y axis: horizontal position, front to back
      -2 + absolute_angle_distance * horse_speed * 0.02 * (float)player.smart_camera_data.horse_auto_center_enabled,
      // z axis: vertical position, bottom to top
      0.25
    ),
    0.5f,
    delta
  );
  //#endregion zoom correction

  return true;
}