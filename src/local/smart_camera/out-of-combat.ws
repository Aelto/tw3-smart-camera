function SC_onGameCameraTick_outOfCombat(player: CR4Player, out moveData: SCameraMovementData, delta: float): bool {
  var absolute_angle_distance: float;
  var player_velocity: Vector;
  var position_offset: Vector;
  var rotation: EulerAngles;
  var player_speed: float;
  var angle_distance: float;

  if (!player.smart_camera_data.settings.is_enabled_in_exploration) {
    return false;
  }

  rotation = moveData.pivotRotationValue;
  angle_distance = AngleDistance(rotation.Yaw, player.GetHeading());
  absolute_angle_distance = AbsF(angle_distance);
  rotation.Yaw = player.GetHeading();


  if (player.GetPlayerAction() == PEA_ExamineGround) {
    SC_applyClueInteractionOffset(rotation, position_offset, player);
  }

  rotation = SC_getUpdatedRotationToLookAtTarget(rotation, player, delta);

  player_velocity = VecNormalize(player.GetMovingAgentComponent().GetVelocity());
  player_speed = player.GetMovingAgentComponent().GetSpeed();

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

  SC_updateCursor(
    delta,
    player.smart_camera_data.yaw_correction_cursor,
    1,
    player_speed > 0
  );

  if (player.smart_camera_data.yaw_correction_cursor > 0) {
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.exploration_start_smoothing * player.smart_camera_data.yaw_correction_cursor,
      moveData.pivotRotationValue.Yaw,
      rotation.Yaw
    );

    moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
  }
  //#endregion yaw correction

  //////////////////////
  // Pitch correction //
  //////////////////////
  //#region pitch correction

  // pitch correction when the player is going up or down
  if (AbsF(player_velocity.Z) > 0.25) {
    if (player.smart_camera_data.pitch_correction_delay <= 0) {
      player.smart_camera_data.corrected_y_direction = LerpF(
        0.80,
        moveData.pivotRotationValue.Pitch,
        90 * player_velocity.Z
      );
    }

    player.smart_camera_data.pitch_correction_delay = LerpF(
      delta,
      player.smart_camera_data.pitch_correction_delay,
      2
    );
  }
  // pitch correction if the rotation.Pitch value is different than the current
  // pitch of the camera. The rotation.Pitch can be changed by many things
  else if (rotation.Pitch != moveData.pivotRotationValue.Pitch) {
    if (player.smart_camera_data.pitch_correction_delay <= 0) {
      player.smart_camera_data.corrected_y_direction = LerpF(
        0.80,
        moveData.pivotRotationValue.Pitch,
        rotation.Pitch
      );
    }

    player.smart_camera_data.pitch_correction_delay = LerpF(
      delta * 5,
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
  }
  //#endregion pitch correction

  ////////////////////
  // Roll correction //
  ///////////////////
  //#region roll correction
  if (player_speed > 0) {
    moveData.pivotRotationValue.Roll = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed,
      moveData.pivotRotationValue.Roll,
      angle_distance * 0.001 * player_speed
    );

    // moveData.pivotRotationController.SetDesiredHeading(angle_distance * 0.1);
  }
  else {
    moveData.pivotRotationValue.Roll = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed,
      moveData.pivotRotationValue.Roll,
      0
    );
  }
  //#endregion roll correction

  /////////////////////
  // Zoom correction //
  /////////////////////
  //#region zoom correction
  moveData.pivotPositionController.offsetZ = 0.0f;

  DampVectorSpring(
    moveData.cameraLocalSpaceOffset,
    moveData.cameraLocalSpaceOffsetVel,
    Vector(
      // x axis: horizontal position, left to right
      player.smart_camera_data.settings.camera_horizontal_position + position_offset.X,
      // y axis: horizontal position, front to back
      4 - player.smart_camera_data.settings.camera_zoom + position_offset.Y,
      // z axis: vertical position, bottom to top
      player.smart_camera_data.settings.camera_height + position_offset.Z
    ),
    0.5f,
    delta * player.smart_camera_data.exploration_start_smoothing
  );
  //#endregion zoom correction

  return true;
}

function SC_applyClueInteractionOffset(out rotation: EulerAngles, out position_offset: Vector, player: CR4Player) {
  var rotation_to_target: EulerAngles;

  rotation_to_target = VecToRotation(player.GetWorldPosition() - theCamera.GetCameraPosition());
  rotation.Yaw = LerpAngleF(
    0.8,
    rotation.Yaw,
    rotation_to_target.Yaw
  );

  rotation.Pitch = LerpAngleF(
    0.5,
    rotation.Pitch,
    -rotation_to_target.Pitch
  );

  position_offset.X += 0.2;
  position_offset.Y += 1;
  position_offset.Z += -1;
}

function SC_getUpdatedRotationToLookAtTarget(rotation: EulerAngles, player: CR4Player, delta: float): EulerAngles {
  var interaction_target: CInteractionComponent;
  var interaction_entity: CGameplayEntity;
  var rotation_to_target: EulerAngles;
  var target_position: Vector;

  interaction_target = theGame.GetInteractionsManager().GetActiveInteraction();
  if (!interaction_target) {
    SC_updateCursor(
      delta * 2,
      player.smart_camera_data.interaction_focus_cursor,
      1,
      false
    );

    return rotation;
  }

  SC_updateCursor(
    delta,
    player.smart_camera_data.interaction_focus_cursor,
    1,
    true
  );

  if (player.smart_camera_data.interaction_focus_cursor > 0) {
    interaction_entity = (CGameplayEntity)interaction_target.GetEntity();

    target_position = interaction_entity.GetWorldPosition();
    rotation_to_target = VecToRotation(target_position - theCamera.GetCameraPosition());

    rotation.Yaw = LerpAngleF(
      0.15,
      rotation.Yaw,
      rotation_to_target.Yaw
    );

    rotation.Pitch = LerpAngleF(
      0.15,
      rotation.Pitch,
      -rotation_to_target.Pitch
    );
  }
  
  return rotation;
}