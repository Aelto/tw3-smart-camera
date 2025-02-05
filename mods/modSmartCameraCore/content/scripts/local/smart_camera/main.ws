
function SC_onGameCameraTick(player: CR4Player, out moveData: SCameraMovementData, delta: float): bool {
  var player_to_camera_heading_distance: float;
  var is_mean_position_too_high: bool;
  var rotation_to_target: EulerAngles;
  var hostile_enemies: array<CActor>;
  var lower_pitch_amount: float;
  var positions: array<Vector>;
  var player_position: Vector;
  var player_heading: float;
  var mean_position: Vector;
  var rotation: EulerAngles;
  var camera: CCustomCamera;
  var back_offset: float;
  var target: CActor;

  player.smart_camera_data.time_before_settings_fetch -= delta;
  if (player.smart_camera_data.time_before_settings_fetch <= 0) {
    player.smart_camera_data.time_before_settings_fetch = 10;
    SC_reloadSettings(player.smart_camera_data.settings);

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

  hostile_enemies = player.GetHostileEnemies();
  positions = SC_getEntitiesPositions(hostile_enemies);
  target = player.GetTarget();

  mean_position = SC_getMeanPosition(positions, player) + Vector(0.0, 0.0, 1.0);
  is_mean_position_too_high = mean_position.Z - player_position.Z > 3.5;

  // LERP the mean position to smooth out the movements
  if (
    player.smart_camera_data.combat_look_at_position.X == 0
    && player.smart_camera_data.combat_look_at_position.Y == 0
  ) {
    player.smart_camera_data.combat_look_at_position = mean_position;
  }
  else {
    player.smart_camera_data.combat_look_at_position.X = LerpF(
      delta * (player.smart_camera_data.settings.overall_speed * 0.5),
      player.smart_camera_data.combat_look_at_position.X,
      mean_position.X
    );

    player.smart_camera_data.combat_look_at_position.Y = LerpF(
      delta * (player.smart_camera_data.settings.overall_speed * 0.5),
      player.smart_camera_data.combat_look_at_position.Y,
      mean_position.Y
    );

    player.smart_camera_data.combat_look_at_position.Z = LerpF(
      delta * (player.smart_camera_data.settings.overall_speed * 0.5),
      player.smart_camera_data.combat_look_at_position.Z,
      mean_position.Z
    );
  }

  rotation = SC_getRotationToLookAtPosition(
    mean_position,
    player
  );

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
    if (hostile_enemies.Size() > 0) {
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
  rotation_to_target = VecToRotation(mean_position - player_position);


  // some pitch correction if the mean position is too high compared to the
  // player, which means the target is probably off camera.
  if (thePlayer.IsCameraLockedToTarget()) {
    moveData.pivotRotationController.SetDesiredPitch( rotation_to_target.Pitch - 15 );
    moveData.pivotRotationValue.Pitch	= LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing,
      moveData.pivotRotationValue.Pitch,
      rotation_to_target.Pitch - 15
    );
  }
  else if (is_mean_position_too_high) {
    SC_updateCursor(
      delta,
      player.smart_camera_data.pitch_correction_cursor,
      true
    );

    rotation.Pitch = LerpAngleF(
      0.2,
      moveData.pivotRotationValue.Pitch,
      rotation.Pitch
    );

    moveData.pivotRotationController.SetDesiredPitch( rotation.Pitch );
    moveData.pivotRotationValue.Pitch	= LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing,
      moveData.pivotRotationValue.Pitch,
      -rotation.Pitch
    );
  }
  // do pitch correction if the target is blocked by Geralt, but only if the 
  // pitch is not lower than the current one.
  // As pitch goes down, camera looks further down.
  else if (
    // !player.IsInCombatAction() &&
    // only if the camera is not already looking down
    moveData.pivotRotationValue.Pitch > rotation_to_target.Pitch - 30 &&
    SC_shouldLowerPitch(player, positions, lower_pitch_amount)
  ) {

      SC_updateCursor(
        delta * lower_pitch_amount,
        player.smart_camera_data.pitch_correction_cursor,
        true
      );

      moveData.pivotRotationController.SetDesiredPitch(
        rotation_to_target.Pitch - 30 * lower_pitch_amount
      );
      moveData.pivotRotationValue.Pitch	= LerpAngleF(
        delta
          * player.smart_camera_data.settings.overall_speed
          * player.smart_camera_data.combat_start_smoothing
          * MaxF(player.smart_camera_data.pitch_correction_cursor, 0),
        moveData.pivotRotationValue.Pitch,
        rotation_to_target.Pitch - 30 * lower_pitch_amount
      );

  }
  else if (player.smart_camera_data.pitch_correction_cursor > 0) {
    SC_updateCursor(
      delta,
      player.smart_camera_data.pitch_correction_cursor,
      false
    );

    moveData.pivotRotationController.SetDesiredPitch( player.smart_camera_data.desired_y_direction );
    moveData.pivotRotationValue.Pitch	= LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed,
      moveData.pivotRotationValue.Pitch,
      player.smart_camera_data.desired_y_direction
    );
  }
  // during the first few seconds where the start_smoothing is still below 1,
  // lowers the pitch of the camera so that it looks towards the ground.
  else if (player.smart_camera_data.combat_start_smoothing < 1 && positions.Size() > 0) {
    moveData.pivotRotationController.SetDesiredPitch( rotation_to_target.Pitch - 15 );
    moveData.pivotRotationValue.Pitch	= LerpAngleF(
      delta
        * player.smart_camera_data.settings.overall_speed
        * player.smart_camera_data.combat_start_smoothing
        * 0.5,
      moveData.pivotRotationValue.Pitch,
      rotation_to_target.Pitch - 15
    );
  }
  else {
    SC_updateCursor(
      delta,
      player.smart_camera_data.pitch_correction_cursor,
      false
    );

    player.smart_camera_data.desired_y_direction = moveData.pivotRotationValue.Pitch;
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
      * 0.05
  );
  //#endregion roll correction

  /////////////////////
  // Zoom correction //
  /////////////////////
  //#region zoom correction

  // offset coming from the creatures behind the Camera's back.
  back_offset = SC_getHeightOffsetFromTargetsInBack(player, player_position, positions);
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
        + back_offset + ((int)is_mean_position_too_high * -1)
        + lower_pitch_amount * 0.5,

        -player.smart_camera_data.settings.camera_zoom_max,
        player.smart_camera_data.settings.camera_zoom_max
      ),

      // z axis: vertical position, bottom to top
      ClampF(
        player.smart_camera_data.settings.camera_height
        + ((int)is_mean_position_too_high * 0.2)
        + lower_pitch_amount * 0.5,
        -player.smart_camera_data.settings.camera_height_max,
        player.smart_camera_data.settings.camera_height_max
      )
    ),
    0.5f,
    delta * player.smart_camera_data.settings.overall_speed * 0.2 * player.smart_camera_data.combat_start_smoothing
  );

  return true;
}

/**
 * Returns a value between 0 and 1, where 1 means the pitch should be lowered
 * by 100% of the pitch correction.
 */
function SC_shouldLowerPitch(
  player: CR4Player,
  out positions: array<Vector>,
  out lower_pitch_amount: float
): bool {
  var lower_pitch_amount_local: float;
  var heading_to_target: float;
  var heading_to_player: float;
  var camera_position: Vector;
  var target_position: Vector;
  var player_position: Vector;
  var distance_angle: float;
  var distance: float;
  var i: int;

  camera_position = theCamera.GetCameraPosition();
  player_position = thePlayer.GetWorldPosition();

  for (i = 0; i < positions.Size(); i += 1) {
    target_position = positions[i];
    distance = VecDistanceSquared2D(player_position, target_position);

    // target is far away, lowered pitch is probably not needed
    if (distance >= 10 * 10) {
      continue;
    }

    // target has the high ground!
    if (target_position.Z >= player_position.Z + 0.2) {
      continue;
    }

    heading_to_target = VecHeading(target_position - camera_position);
    heading_to_player = VecHeading(player_position - camera_position);

    // squared values because angle may otherwise be a negative value in some
    // cases
    distance_angle = AngleDistance(heading_to_player, heading_to_target);
    distance_angle *= distance_angle;

    // 100 because it's 10*10
    if (distance_angle < 100) {
      // the closer the creature, the lower distance is, and the closer it gets
      // to 100 thanks to the (100 - distance) which is then divided by 100 and
      // again the closer the distance is the closer to 1.0 the result will get.
      //
      // NOTE: distance could in theory be higher than 100 which would lead the
      // first SUB to negatives but we're in a if case that checks it so it's
      // fine.
      lower_pitch_amount_local = (100 - distance) / 100;

      // then multiply it based on how close to the center the target is as well
      //
      // the value starts from 0 and reaches 1 as the target reaches the center,
      // this means the multiplication will almost always decrease the intensity
      lower_pitch_amount_local *= (100 - distance_angle) / 100;

      // take the highest value possible from all targets.
      if (lower_pitch_amount_local > lower_pitch_amount) {
        lower_pitch_amount = lower_pitch_amount_local;
      }
    }
  }

  // finally, the more targets there are the less intense it is:
  if (lower_pitch_amount_local > 0.0) {
    lower_pitch_amount = MaxF(0, lower_pitch_amount - 0.1 * positions.Size());

    return true;
  }

  lower_pitch_amount = 0.0;
  return false;
}

function SC_getHeightOffsetFromTargetsInBack(player: CR4Player, player_position: Vector, positions: array<Vector>): float {
  var entities_count_in_back: float;
  var player_back_heading: float;
  var camera_position: Vector;
  var mean_position: Vector;
  var current_angle: float;
  var i: int;

  camera_position = theCamera.GetCameraPosition();
  player_back_heading = VecHeading(
    camera_position - player_position
  );

  if (positions.Size() == 0) {
    return 0;
  }

  for (i = 0; i < positions.Size(); i += 1) {
    current_angle = VecHeading(positions[i] - player_position);
    current_angle = AngleDistance(player_back_heading, current_angle);

    // the entity is not in the Camera's back
    if (current_angle * current_angle > 120 * 120) {
      continue;
    }

    entities_count_in_back += 1;
    mean_position += positions[i];
  }

  // no entities in the back, so there is no bonus offset
  if (entities_count_in_back == 0) {
    return 0;
  }

  mean_position /= entities_count_in_back;

  return ClampF(
    VecDistance2D(mean_position, player_position) * -1,
    0,
    (10 - MinF(player.smart_camera_data.settings.camera_zoom, 5)) * -0.75,
  );
}

function SC_getMeanPosition(positions: array<Vector>, player: CR4Player): Vector {
  var mean_position: Vector;
  var i: int;

  for (i = 0; i < positions.Size(); i += 1) {
    mean_position += positions[i];
  }

  mean_position /= i;
  // mean_position += SC_getVelocityOffset(player);

  // when the camera is locked on a target, put a much greater importance to the
  // target.
  if (thePlayer.IsCameraLockedToTarget()) {
    i = positions.Size();

    mean_position += i * thePlayer.GetTarget().GetWorldPosition();
    mean_position /= i;
  }

  return mean_position;
}

function SC_getRotationToLookAtPosition(mean_position: Vector, player: CR4Player): EulerAngles {
  return VecToRotation(mean_position - player.GetWorldPosition());
}

function SC_getEntitiesPositions(entities: array<CActor>): array<Vector> {
  var output: array<Vector>;
  var size: int;
  var i: int;

  size = entities.Size();
  output.Resize(size);

  for (i = 0; i < size; i += 1) {
    output[i] = entities[i].GetWorldPosition();
  }

  return output;
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
