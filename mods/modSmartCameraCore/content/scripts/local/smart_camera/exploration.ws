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

  if (player.GetPlayerAction() == PEA_ExamineGround) {
    SC_applyClueInteractionOffset(rotation, position_offset, player);
  }

  player_velocity = VecNormalize(player.GetMovingAgentComponent().GetVelocity());
  player_speed = player.GetMovingAgentComponent().GetSpeed();

  rotation = SC_getUpdatedRotationToLookAtTarget(rotation, player, delta, player_speed);
  player.smart_camera_data.exploration_start_smoothing = LerpF(0.33 * delta, player.smart_camera_data.exploration_start_smoothing, 1);
  player.smart_camera_data.combat_start_smoothing = 0;

  ////////////////////
  // Yaw correction //
  ///////////////////
  //#region yaw correction
  SC_updateCursor(
    delta,
    player.smart_camera_data.yaw_correction_cursor,
    player_speed > 0
  );

  if (player.smart_camera_data.yaw_correction_cursor > 0) {
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta
        * player.smart_camera_data.settings.overall_speed
        * player.smart_camera_data.exploration_start_smoothing
        * player.smart_camera_data.yaw_correction_cursor
        * 1.5
        / MaxF(player_speed, 1.0),
      moveData.pivotRotationValue.Yaw,
      rotation.Yaw
    );

    moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
  }
  //#endregion yaw correction

  ////////////////////
  // Yaw correction //
  ///////////////////
  //#region Yaw correction
  // when the player turns around, moves the camera if the player heading is
  // different than the camera heading. But only after a 90 degrees difference.
  // Acts the same way as the Elden Ring camera.
  if (player_speed > 0 && player.smart_camera_data.settings.exploration_autocenter_enabled) {
    
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta
        * MaxF(AbsF(angle_distance) / 90 - 0.3, 0)
        * player_speed
        * 0.25
        // we divide by the right axis values so that using the right stick
        // reduces the auto-center speed
        / (1 + AbsF(theInput.GetActionValue('GI_AxisRightX')) + AbsF(theInput.GetActionValue('GI_AxisRightY')))
        + 0.05 * delta * player_speed,
      moveData.pivotRotationValue.Yaw,
      player.GetHeading()
    );

    moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
  }
  //#endregion roll correction

  return false;
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

function SC_getUpdatedRotationToLookAtTarget(rotation: EulerAngles, player: CR4Player, delta: float, player_speed: float): EulerAngles {
  var interaction_target: CInteractionComponent;
  var interaction_entity: CGameplayEntity;
  var rotation_to_target: EulerAngles;
  var target_position: Vector;

  interaction_target = theGame.GetInteractionsManager().GetActiveInteraction();
  if (!interaction_target) {
    SC_updateCursor(
      delta * 2,
      player.smart_camera_data.interaction_focus_cursor,
      false
    );

    return rotation;
  }

  SC_updateCursor(
    delta,
    player.smart_camera_data.interaction_focus_cursor,
    true
  );

  if (player.smart_camera_data.interaction_focus_cursor > 0) {
    interaction_entity = (CGameplayEntity)interaction_target.GetEntity();

    target_position = interaction_entity.GetWorldPosition();
    rotation_to_target = VecToRotation(target_position - theCamera.GetCameraPosition());

    rotation.Yaw = LerpAngleF(
      0.30 / (1 + player_speed),
      rotation.Yaw,
      rotation_to_target.Yaw
    );

    rotation.Pitch = LerpAngleF(
      0.30 / (1 + player_speed),
      rotation.Pitch,
      -rotation_to_target.Pitch
    );
  }
  
  return rotation;
}

function SC_shouldDisableExplorationPosTick(player: CR4Player): bool {
  return player.smart_camera_data.settings.is_enabled_in_combat && !player.IsCameraLockedToTarget()
}