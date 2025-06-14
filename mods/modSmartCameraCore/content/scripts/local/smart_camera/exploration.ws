function SC_onGameCameraTick_outOfCombat(player: CR4Player, out moveData: SCameraMovementData, delta: float): bool {
  var absolute_angle_distance: float;
  var player_velocity: Vector;
  var position_offset: Vector;
  var rotation: EulerAngles;
  var feet_distance: float;
  var feet_offset: Vector;
  var player_speed: float;
  var angle_distance: float;
  var rotation_tendency_curved: float;
  var camera: CCustomCamera;


  if (!player.smart_camera_data.settings.is_enabled_in_exploration) {
    return false;
  }

  // change the pivots only if there is something to do with the camera.
  camera = theGame.GetGameCamera();
  camera.ChangePivotDistanceController( 'Default' );
  camera.ChangePivotRotationController( 'Exploration' );
  camera.fov = thePlayer.smart_camera_data.settings.camera_fov;
  moveData.pivotRotationController = camera.GetActivePivotRotationController();
  moveData.pivotDistanceController = camera.GetActivePivotDistanceController();
  moveData.pivotPositionController = camera.GetActivePivotPositionController();
  moveData.pivotPositionController.SetDesiredPosition( thePlayer.GetWorldPosition() );
  moveData.pivotDistanceController.SetDesiredDistance( 3.5f /* - player.GetMovingAgentComponent().GetSpeed() * 0.1 */ );

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

  SC_updateCursor(
    delta,
    player.smart_camera_data.yaw_correction_cursor,
    player_speed > 0
  );

  // two LERPs, one that increases it quickly if the player is moving, the other
  // that LERPs the tendency towards zero.
  //
  // The value is in the [-1;1] range
  player.smart_camera_data.exploration_rotation_tendency = ClampF(
    0,
    1,
    LerpAngleF(
      delta * player_speed * player_speed,
      player.smart_camera_data.exploration_rotation_tendency,
      absolute_angle_distance / 120
    )
  );
  player.smart_camera_data.exploration_rotation_tendency = LerpAngleF(
    delta * 25,
    player.smart_camera_data.exploration_rotation_tendency,
    0
  );

  rotation_tendency_curved = LogF(AbsF(player.smart_camera_data.exploration_rotation_tendency) + 2)
                           * AbsF(player.smart_camera_data.exploration_rotation_tendency);

  //////////////////////
  // Pitch correction //
  //////////////////////
  //#region pitch correction
  if (player.smart_camera_data.settings.exploration_shake_intensity > 0) {

    feet_offset = VecNormalize(
      thePlayer.GetBoneWorldPositionByIndex(player.smart_camera_data.player_bone_index_lfoot)
      - thePlayer.GetBoneWorldPositionByIndex(player.smart_camera_data.player_bone_index_rfoot)
    );

    feet_distance = VecDistance2D(
      thePlayer.GetBoneWorldPositionByIndex(player.smart_camera_data.player_bone_index_lfoot),
      thePlayer.GetBoneWorldPositionByIndex(player.smart_camera_data.player_bone_index_rfoot)
    );

    // the cursor goes up faster than it goes down. Over time this cursor will
    // store the highest distance then slowly go back to lower values and quickly
    // back to higher ones.
    player.smart_camera_data.feet_distance_cursor = LerpF(
      delta
          * (
            1
            // 1 if current value is < than cursor, 0 if greater
            - (float)(feet_distance < player.smart_camera_data.feet_distance_cursor)
            * 0.7
          ),
      player.smart_camera_data.feet_distance_cursor,
      feet_distance
    );

    moveData.pivotRotationValue.Pitch = LerpAngleF(
      delta
        * player.smart_camera_data.settings.overall_speed,

      moveData.pivotRotationValue.Pitch,
      moveData.pivotRotationValue.Pitch
      + (feet_distance / player.smart_camera_data.feet_distance_cursor - 0.84)
      // * (player.smart_camera_data.feet_distance_cursor / feet_distance)
      * 0.25
      * player_speed
      * 2
      * player.smart_camera_data.settings.exploration_shake_intensity
    );
  }

  //#endregion pitch correction

  ////////////////////
  // Yaw correction //
  ///////////////////
  //#region Yaw correction
  // when the player turns around, moves the camera if the player heading is
  // different than the camera heading. But only after a 90 degrees difference.
  // Acts the same way as the Elden Ring camera.
  if (player_speed > 0 && player.smart_camera_data.settings.exploration_autocenter_enabled) {
    // while the player is handling the right axis stick, the yaw correction is
    // progressively disabled
    if (theInput.GetActionValue('GI_AxisRightX') + theInput.GetActionValue('GI_AxisRightY') != 0) {
      player.smart_camera_data.yaw_correction_cursor = -2;
    }
    
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta
      * player_speed
      // * player_speed // squared value on purpose
      * (1 + rotation_tendency_curved * 0.5)
      // the value of the cursor also controls the strength of the correction,
      // the cursor's value is also updated if the player is manually tweaking
      // the camera.
      * MaxF(player.smart_camera_data.yaw_correction_cursor, 0)
      // a number that reaches zero once the angle distance reaches 120, this
      // disables the autocenter the closer Geralt goes towards the camera.
      // For example when you do a 180 degrees turn the camera should not auto
      // center.
      //
      // the -0.15 adds a 10% dead angle where the camera doesn't move when in
      // the center.
      * MaxF(absolute_angle_distance / 120 - 0.15, 0)
      // then the opposite, reaches 0 when the camera is at max angle
      * MaxF(1 - absolute_angle_distance / 120 - 0.1, 0),
      

      moveData.pivotRotationValue.Yaw,

      player.GetHeading()
      // + (
      //   angle_distance
      //   * rotation_tendency_curved
      //   * -5
      // )
    );

    // LogChannel('SC', player.smart_camera_data.exploration_rotation_tendency);

  }

  moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
  //#endregion Yaw correction

  ////////////////////
  // Roll correction //
  ///////////////////
  //#region roll correction
  moveData.pivotRotationValue.Roll = LerpAngleF(
    delta * player.smart_camera_data.settings.overall_speed,
    moveData.pivotRotationValue.Roll,
    0
  );
  //#endregion roll correction

  // the value is lerped as it can quickly change when the player walks towards
  // the camera and goes from left to right.
  if (player.smart_camera_data.settings.exploration_autocenter_enabled) {
    player.smart_camera_data.exploration_local_x_offset = LerpF(
      delta,
      player.smart_camera_data.exploration_local_x_offset,
      // x axis: horizontal position, left to right
      // the values were originally designed for a 2560 ultrawide,
      // going down to 75% brings it to a 1920 regular screen. 
      // Multiplying it again by 1.33 will bring it back to regular values
      0.75
      * ClampF(angle_distance, -60, 60)
      * (1 - 180 / (absolute_angle_distance + 0.001))

      * 0.125
      * MinF(player_speed, 3.0)
      * AbsF(player.smart_camera_data.exploration_rotation_tendency)
      * 0.5
    );

    player.smart_camera_data.exploration_local_y_offset = LerpF(
      delta,
      player.smart_camera_data.exploration_local_y_offset,
      // y axis: horizontal position, front to back
      absolute_angle_distance * -0.005 * player_speed
    );
  }

  DampVectorSpring(
    moveData.cameraLocalSpaceOffset,
    moveData.cameraLocalSpaceOffsetVel,
    Vector(
      // x axis: horizontal position, left to right
      player.smart_camera_data.exploration_local_x_offset
        * player.smart_camera_data.settings.exploration_offset_intensity,

      // y axis: horizontal position, front to back
      player.smart_camera_data.exploration_local_y_offset
        // cannot go higher than 1, otherwise the camera goes way too far
        * MinF(1.0, player.smart_camera_data.settings.exploration_offset_intensity),

      // z axis: vertical position, bottom to top
      feet_offset.Y
      * (feet_distance / player.smart_camera_data.feet_distance_cursor - 0.84)
      * 0.025
      * player_speed
    ),
    0.5f,
    delta
  );

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
      0.30 / (1 + player_speed) * MaxF(player.smart_camera_data.interaction_focus_cursor, 0),
      rotation.Yaw,
      rotation_to_target.Yaw
    );

    rotation.Pitch = LerpAngleF(
      0.30 / (1 + player_speed) * MaxF(player.smart_camera_data.interaction_focus_cursor, 0),
      rotation.Pitch,
      -rotation_to_target.Pitch
    );
  }
  
  return rotation;
}

function SC_shouldDisableExplorationPosTick(player: CR4Player): bool {
  return player.smart_camera_data.settings.is_enabled_in_combat && !player.IsCameraLockedToTarget();
}