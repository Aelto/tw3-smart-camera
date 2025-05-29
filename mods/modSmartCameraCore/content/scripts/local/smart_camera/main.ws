
function SC_onGameCameraTick(player: CR4Player, out moveData: SCameraMovementData, delta: float): bool {
  var player_to_camera_heading_distance: float;
  var is_mean_position_too_high: bool;
  var player_position: Vector;
  var player_heading: float;
  var rotation: EulerAngles;
  var camera: CCustomCamera;
  var back_offset: float;
  var target: CActor;

  var target_data: SC_CombatTargetData;

  player.smart_camera_data.time_before_bone_fetch -= delta;
  if (player.smart_camera_data.time_before_bone_fetch <= 0) {
    player.smart_camera_data.time_before_bone_fetch = 10;

    if (!player.smart_camera_data.settings_fetched) {
      player.smart_camera_data.settings_fetched = true;
      SC_reloadSettings(player.smart_camera_data.settings);
    }

    player.smart_camera_data.player_bone_index_rfoot = player.GetBoneIndex('r_foot');
    player.smart_camera_data.player_bone_index_lfoot = player.GetBoneIndex('l_foot');
  }

  /////////////////////
  // Roll correction //
  /////////////////////
  //#region roll correction (left to right rotation)

  // slowly bring back the rotation to 0 if it's not the case, for example if
  // someone dismount from the horse camera while it had a roll angle.
  if (player.smart_camera_data.previous_camera_mode == SCCM_Horse) {
    moveData.pivotRotationValue.Roll = 0;
  }
  //#endregion roll correction

  if (!player.smart_camera_data.settings.is_enabled_in_combat && !player.smart_camera_data.settings.is_enabled_in_exploration) {
    return false;
  }

  if (thePlayer.IsCameraLockedToTarget() || thePlayer.IsCurrentSignChanneled() && thePlayer.GetCurrentlyCastSign() == ST_Igni) {
    return false;
  }

  if (!theInput.LastUsedGamepad()) {
    if (!player.smart_camera_data.settings.is_enabled_with_mouse) {
      return false;
    }

    if (theInput.GetActionValue('GI_MouseDampX') != 0
     || theInput.GetActionValue('GI_MouseDampY') != 0) {
      player.smart_camera_data.camera_disable_cursor = 1;
    }
  }

  player.smart_camera_data.previous_camera_mode = SCCM_Exploration;

  if (!player.IsInCombat()) {
    player.smart_camera_data.combat_look_at_position.X = 0;
    player.smart_camera_data.combat_look_at_position.Y = 0;

    return SC_onGameCameraTick_outOfCombat(player, moveData, delta);
  }

  if (!player.smart_camera_data.settings.is_enabled_in_combat) {
    return false;
  }

  camera = theGame.GetGameCamera();
  camera.ChangePivotDistanceController( 'Default' );
  camera.ChangePivotRotationController( 'Exploration' );
  camera.fov = thePlayer.smart_camera_data.settings.camera_fov;
  moveData.pivotRotationController = camera.GetActivePivotRotationController();
  moveData.pivotDistanceController = camera.GetActivePivotDistanceController();
  moveData.pivotPositionController = camera.GetActivePivotPositionController();
  moveData.pivotPositionController.SetDesiredPosition( thePlayer.GetWorldPosition() );
  moveData.pivotDistanceController.SetDesiredDistance( 3.5f /* - player.GetMovingAgentComponent().GetSpeed() * 0.1 */ );

  player_position = player.GetWorldPosition();
  player_heading = player.GetHeading();
  // 3 seconds 
  player.smart_camera_data.combat_start_smoothing = LerpF(0.33 * delta, player.smart_camera_data.combat_start_smoothing, 1);

  target_data = player.SC_computeCombatTargetData(player_position, delta);
  target = player.GetTarget();

  is_mean_position_too_high = target_data.mean_position.Z - player_position.Z > 3.5;

  if (target_data.should_lower_pitch) {
    // lower the position so the camera looks down
    target_data.mean_position.Z -= 1.5 * target_data.lower_pitch_amount;

    SC_updateCursor(
      delta,
      player.smart_camera_data.pitch_correction_cursor,
      true
    );
  }
  else if (player.smart_camera_data.combat_start_smoothing < 1 && target_data.hostile_enemies_count > 0) {
    target_data.mean_position.Z -= 1;

    SC_updateCursor(
      delta,
      player.smart_camera_data.pitch_correction_cursor,
      true
    );
  }
  else {
    SC_updateCursor(
      // the slighly slower decrease means the camera will always take a few
      // extra milliseconds to aim back at the mean_position before stopping
      // all corrections
      delta * 0.8,
      player.smart_camera_data.pitch_correction_cursor,
      false
    );
  }

  rotation = VecToRotation(target_data.mean_position - theCamera.GetCameraPosition());
  rotation.Pitch *= -1;

  player.smart_camera_data.desired_x_direction += theInput.GetActionValue('GI_AxisRightX')
    * delta
    * player.smart_camera_data.settings.horizontal_sensitivity;

  player.smart_camera_data.desired_x_direction = LerpF(delta * 0.3, player.smart_camera_data.desired_x_direction, 0);

  ////////////////////
  // Yaw correction //
  ///////////////////
  //#region yaw correction
  player.smart_camera_data.camera_disable_cursor = SC_updateCursor(
    delta * 0.25,
    player.smart_camera_data.camera_disable_cursor,
    player.GetIsSprinting()
  );


  if (AbsF(player.smart_camera_data.desired_x_direction) > 0.25) {
    player.smart_camera_data.camera_disable_cursor = 1;
  }

  if (player.smart_camera_data.camera_disable_cursor < 0) {
    if (target_data.hostile_enemies_count > 0) {
      moveData.pivotRotationValue.Yaw = LerpAngleF(
        delta
          * player.smart_camera_data.settings.overall_speed
          * player.smart_camera_data.combat_start_smoothing
          * 2,
        moveData.pivotRotationValue.Yaw,
        rotation.Yaw
      );

      moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
    }
    // that's for when you're in combat but there are no enemies targetting Geralt
    // or if the camera is disabled because the player is sprinting for a few
    // seconds
    else {
      rotation.Yaw = player_heading;

      moveData.pivotRotationValue.Yaw = LerpAngleF(
        delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing,
        moveData.pivotRotationValue.Yaw,
        rotation.Yaw
      );

      moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
    }
  }
  //#endregion yaw correction


  //////////////////////
  // Pitch correction //
  //////////////////////
  //#region pitch correction
  // some pitch correction if the mean position is too high compared to the
  // player, which means the target is probably off camera.
  if (thePlayer.IsCameraLockedToTarget()) {
    moveData.pivotRotationController.SetDesiredPitch( rotation.Pitch - 15 );
    moveData.pivotRotationValue.Pitch	= LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing,
      moveData.pivotRotationValue.Pitch,
      rotation.Pitch - 15
    );
  }
  else if (player.smart_camera_data.pitch_correction_cursor > 0) {
    moveData.pivotRotationController.SetDesiredPitch(rotation.Pitch);
    moveData.pivotRotationValue.Pitch	= LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed,
      moveData.pivotRotationValue.Pitch,
      MaxF(rotation.Pitch, -30)
    );
  }
  //#endregion pitch correction

  ////////////////////
  // Roll correction //
  ///////////////////
  //#region roll correction
  moveData.pivotRotationValue.Roll = LerpAngleF(
    delta * player.smart_camera_data.settings.overall_speed,
    moveData.pivotRotationValue.Roll,
    player.smart_camera_data.settings.camera_tilt_intensity
      * AngleDistance(moveData.pivotRotationValue.Yaw, rotation.Yaw)
      * 0.03
  );
  //#endregion roll correction

  /////////////////////
  // Zoom correction //
  /////////////////////
  //#region zoom correction
  //#endregion zoom correction

  player_to_camera_heading_distance = AngleDistance(
    player_heading,
    moveData.pivotRotationValue.Yaw
  );

  DampVectorSpring(
    moveData.cameraLocalSpaceOffset,
    moveData.cameraLocalSpaceOffsetVel,
    Vector(
      // x axis: horizontal position, left to right
      player.smart_camera_data.settings.camera_horizontal_position,

      // y axis: horizontal position, front to back
      ClampF(
        4 
        - player.smart_camera_data.settings.camera_zoom
        + target_data.offset_from_targets_in_back
        + ((int)is_mean_position_too_high * -1),

        -player.smart_camera_data.settings.camera_zoom_max,
        player.smart_camera_data.settings.camera_zoom_max
      ),

      // z axis: vertical position, bottom to top
      ClampF(
        player.smart_camera_data.settings.camera_height
        + ((int)is_mean_position_too_high * 0.2)
        + target_data.lower_pitch_amount * 1.5 * player.smart_camera_data.pitch_correction_cursor,
        -player.smart_camera_data.settings.camera_height_max,
        player.smart_camera_data.settings.camera_height_max
      )
    ),
    0.5f,
    delta * player.smart_camera_data.settings.overall_speed * 0.2 * player.smart_camera_data.combat_start_smoothing
  );

  return true;
}

function SC_getClosestPosition(origin: Vector, positions: array<Vector>): Vector {
  var closest_distance: float;
  var current_distance: float;
  var position: Vector;
  var i: int;

  if (positions.Size() == 0) {
    return origin;
  }

  closest_distance = VecDistanceSquared2D(origin, positions[0]);

  for (i = 0; i < positions.Size(); i += 1) {
    current_distance = VecDistanceSquared2D(origin, positions[i]);

    if (current_distance < closest_distance) {
      closest_distance = current_distance;
      position = positions[i];
    }
  }

  return position;
}

function SC_getPositionsAroundOrigin(origin: Vector, positions: array<Vector>, radius: float): array<Vector> {
  var output: array<Vector>;
  var i: int;

  radius *= radius;

  for (i = 0; i < positions.Size(); i += 1) {
    if (VecDistanceSquared2D(origin, positions[i]) <= radius) {
      output.PushBack(positions[i]);
    }
  }

  return output;
}
