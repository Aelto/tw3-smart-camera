function SC_boatOnCameraTickPostTick(player: CR4Player, boat: CBoatComponent, camera: CCustomCamera, out moveData: SCameraMovementData, delta: float): bool {
  var rotation: EulerAngles;
  var angle_distance: float;
  var boat_speed: float;
  var absolute_angle_distance: float;

  rotation = moveData.pivotRotationValue;
  boat_speed = boat.GetLinearVelocityXY() / boat.GetMaxSpeed() * 4;

  angle_distance = AngleDistance(rotation.Yaw, boat.GetHeading());
  absolute_angle_distance = AbsF(angle_distance);
  rotation.Yaw = boat.GetHeading();

  if (angle_distance * angle_distance < (4 + boat_speed) * (4 + boat_speed)) {
    player.smart_camera_data.horse_auto_center_enabled = true;
  }

  if (theInput.GetActionValue('GI_AxisRightX') != 0) {
    player.smart_camera_data.horse_auto_center_enabled = false;
  }

  ////////////////////
  // Yaw correction //
  ///////////////////
  //#region yaw correction
  if (boat_speed > 0 && player.smart_camera_data.horse_auto_center_enabled) {
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * boat_speed * 1 * absolute_angle_distance * 0.03,
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
  if (boat_speed > 0 && player.smart_camera_data.horse_auto_center_enabled) {
    moveData.pivotRotationValue.Roll = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed,
      moveData.pivotRotationValue.Roll,
      angle_distance * 0.3 * boat_speed
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
      0 + absolute_angle_distance * boat_speed * 0.02 * (float)player.smart_camera_data.horse_auto_center_enabled,
      // z axis: vertical position, bottom to top
      player.smart_camera_data.settings.camera_height + 1
    ),
    0.5f,
    delta
  );
  //#endregion zoom correction

  return true;
}