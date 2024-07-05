function SC_horseOnCameraTickPostTick(player: CR4Player, horse: W3HorseComponent, camera: CCustomCamera, out moveData: SCameraMovementData, delta: float): bool {
  var rotation: EulerAngles;
  var angle_distance: float;
  var horse_speed: float;
  var horse_zoom_offset: float;
  var absolute_angle_distance: float;
  var pelvis_torso_angle: EulerAngles;

  if (!player.smart_camera_data.settings.is_enabled_on_horse) {
    return false;
  }

  player.smart_camera_data.time_before_settings_fetch -= delta;
  if (player.smart_camera_data.time_before_settings_fetch <= 0 || player.smart_camera_data.horse_bone_index_pelvis < -999 || player.smart_camera_data.previous_camera_mode != SCCM_Horse) {
    player.smart_camera_data.time_before_settings_fetch = 10;
    SC_reloadSettings(player.smart_camera_data.settings);

    player.smart_camera_data.horse_bone_index_torso = horse.GetEntity().GetBoneIndex('head');
    player.smart_camera_data.horse_bone_index_pelvis = horse.GetEntity().GetBoneIndex('pelvis');
  }

  player.smart_camera_data.previous_camera_mode = SCCM_Horse;


  if (!theInput.LastUsedGamepad()) {
    if (!player.smart_camera_data.settings.is_enabled_with_mouse) {
      return false;
    }

    if (theInput.GetActionValue('GI_MouseDampX') != 0
     || theInput.GetActionValue('GI_MouseDampY') != 0) {
      player.smart_camera_data.camera_disable_cursor = 1;
    }
  }

  player.smart_camera_data.camera_disable_cursor = SC_updateCursor(
    delta * 0.5,
    player.smart_camera_data.camera_disable_cursor,
    player.IsInCombat()
  );

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

  //////////////////////
  // Pitch correction //
  //////////////////////
  //#region pitch correction
  if (player.smart_camera_data.camera_disable_cursor < 0 && horse_speed > 0 && player.smart_camera_data.horse_auto_center_enabled && player.smart_camera_data.horse_bone_index_pelvis > 0) {
    pelvis_torso_angle = VecToRotation(
      horse.GetEntity().GetBoneWorldPositionByIndex(player.smart_camera_data.horse_bone_index_pelvis)
      - horse.GetEntity().GetBoneWorldPositionByIndex(player.smart_camera_data.horse_bone_index_torso)
    );

    moveData.pivotRotationValue.Pitch = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed / (MaxF(horse_speed, 3) + 0.01),
      moveData.pivotRotationValue.Pitch,
      pelvis_torso_angle.Pitch - 15
    );
  }
  //#endregion pitch correction

  ////////////////////
  // Yaw correction //
  ///////////////////
  //#region yaw correction
  if (player.smart_camera_data.camera_disable_cursor < 0 && horse_speed > 0 && player.smart_camera_data.horse_auto_center_enabled) {
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
  //#endregion roll correction


  /////////////////////
  // Zoom correction //
  /////////////////////
  //#region zoom correction

  // an offset users can set from the menus, the default value is 1, below
  // 1 and the camera gets closer, higher than 1 and its goes further away
  horse_zoom_offset = (-1 * player.smart_camera_data.settings.horse_camera_zoom)
                      // the + makes the camera go closer to the horse during angles
                      + MinF(absolute_angle_distance, 90)
                      * horse_speed
                      * 0.002
                      * (float)player.smart_camera_data.horse_auto_center_enabled
                      * player.smart_camera_data.settings.horse_camera_zoom;

  LogChannel('SmartCamera', "horse_zoom_offset = " + horse_zoom_offset);

  moveData.pivotDistanceController.SetDesiredDistance(horse_zoom_offset);
  DampVectorSpring(
    moveData.cameraLocalSpaceOffset,
    moveData.cameraLocalSpaceOffsetVel,
    Vector(
      // x axis: horizontal position, left to right
      // we place the camera based on the horse's head position.
      pelvis_torso_angle.Yaw * 0.002,

      // y axis: horizontal position, front to back
      horse_zoom_offset,
      // z axis: vertical position, bottom to top
      0
    ),
    0.5f,
    delta
  );
  //#endregion zoom correction

  return true;
}