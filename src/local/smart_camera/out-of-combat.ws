function SC_onGameCameraTick_outOfCombat(player: CR4Player, out moveData: SCameraMovementData, delta: float): bool {
  var player_velocity: Vector;

  if (!player.smart_camera_data.settings.is_enabled_in_exploration) {
    return false;
  }

  player_velocity = VecNormalize(player.GetMovingAgentComponent().GetVelocity());
  LogChannel('SC', VecToString(player_velocity));

  player.smart_camera_data.desired_x_direction += theInput.GetActionValue('GI_AxisRightX')
    * delta
    * player.smart_camera_data.settings.horizontal_sensitivity;

  player.smart_camera_data.desired_x_direction *= 1 - (1 - 0.99 * delta);

  player.smart_camera_data.exploration_start_smoothing = LerpF(0.33 * delta, player.smart_camera_data.exploration_start_smoothing, 1);
  player.smart_camera_data.combat_start_smoothing = 0;

  ////////////////////
  // Yaw correction //
  ///////////////////
  //#region yaw correction

  if (player.smart_camera_data.desired_x_direction != 0) {
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.exploration_start_smoothing,
      moveData.pivotRotationValue.Yaw,
      moveData.pivotRotationValue.Yaw
      + player.smart_camera_data.desired_x_direction
    );

    moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
  }
  else if (player_velocity.X != 0 || player_velocity.Y != 0) {
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.exploration_start_smoothing * 2,
      moveData.pivotRotationValue.Yaw,
      player.GetHeading()
    );

    moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
  }
  //#endregion yaw correction

  //////////////////////
  // Pitch correction //
  //////////////////////
  //#region pitch correction
  LogChannel('SC', "Z = " + player_velocity.Z);
  
  if (AbsF(player_velocity.Z) > 0.25) {
    if (player.smart_camera_data.pitch_correction_delay <= 0) {
      // player.smart_camera_data.desired_y_direction = moveData.pivotRotationValue.Pitch;

      player.smart_camera_data.corrected_y_direction = LerpF(
        0.80,
        moveData.pivotRotationValue.Pitch,
        90 * player_velocity.Z
      );
    }

    if (player.smart_camera_data.pitch_correction_delay <= 1) {
      // player.smart_camera_data.desired_y_direction = moveData.pivotRotationValue.Pitch;
    }

    player.smart_camera_data.pitch_correction_delay = LerpF(
      delta,
      player.smart_camera_data.pitch_correction_delay,
      2
    );
  }
  else {
    player.smart_camera_data.pitch_correction_delay = LerpF(
      delta,
      player.smart_camera_data.pitch_correction_delay,
      -2
    );


    if (player.smart_camera_data.pitch_correction_delay <= -1) {
      player.smart_camera_data.update_y_direction_duration = 0;
      player.smart_camera_data.desired_y_direction = moveData.pivotRotationValue.Pitch;
    }
  }

  if (player.smart_camera_data.pitch_correction_delay >= 1) {
    player.smart_camera_data.update_y_direction_duration = 1;

    moveData.pivotRotationController.SetDesiredPitch( player.smart_camera_data.corrected_y_direction );
    moveData.pivotRotationValue.Pitch	= LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.exploration_start_smoothing * 0.2 * (player.smart_camera_data.pitch_correction_delay - 1),
      moveData.pivotRotationValue.Pitch,
      player.smart_camera_data.corrected_y_direction
    );
  }
  else {
    if (player.smart_camera_data.pitch_correction_delay >= -1 && player.smart_camera_data.pitch_correction_delay <= 0 && player.smart_camera_data.update_y_direction_duration == 1) {
      moveData.pivotRotationController.SetDesiredPitch( player.smart_camera_data.desired_y_direction );
      moveData.pivotRotationValue.Pitch	= LerpAngleF(
        delta * player.smart_camera_data.settings.overall_speed,
        moveData.pivotRotationValue.Pitch,
        player.smart_camera_data.desired_y_direction
      );
    }
    else if (player.smart_camera_data.pitch_correction_delay < -1) {
      // player.smart_camera_data.desired_y_direction = moveData.pivotRotationValue.Pitch;
    }
  }
  //#endregion pitch correction

  /////////////////////
  // Zoom correction //
  /////////////////////
  //#region zoom correction
  DampVectorSpring(
    moveData.cameraLocalSpaceOffset,
    moveData.cameraLocalSpaceOffsetVel,
    Vector(
      // x axis: horizontal position, left to right
      player.smart_camera_data.settings.camera_horizontal_position,
      // y axis: horizontal position, front to back
      4 - player.smart_camera_data.settings.camera_zoom,
      // z axis: vertical position, bottom to top
      player.smart_camera_data.settings.camera_height
    ),
    0.5f,
    delta * player.smart_camera_data.exploration_start_smoothing
  );
  //#endregion zoom correction

  return true;
}