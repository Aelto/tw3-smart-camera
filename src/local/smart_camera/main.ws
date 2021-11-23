
function SC_onGameCameraTick(player: CR4Player, out moveData: SCameraMovementData, delta: float): bool {
  var new_entities: array<CGameplayEntity>;
  var is_mean_position_too_high: bool;
  var rotation_to_target: EulerAngles;
  var positions: array<Vector>;
  var player_position: Vector;
  var target_position: Vector;
  var mean_position: Vector;
  var rotation: EulerAngles;
  var camera: CCustomCamera;
  var back_offset: float;
  var target: CActor;

  player.smart_camera_data.time_before_settings_fetch -= delta;
  if (player.smart_camera_data.time_before_settings_fetch <= 0) {
    player.smart_camera_data.time_before_settings_fetch = 10;
    SC_reloadSettings(player.smart_camera_data.settings);
  }

  if (!player.smart_camera_data.settings.is_enabled_in_combat && !player.smart_camera_data.settings.is_enabled_in_exploration) {
    player.smart_camera_data.time_before_target_fetch = -1;

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

  if (!player.IsInCombat()) {
    player.smart_camera_data.time_before_target_fetch = -1;
    player.smart_camera_data.combat_start_smoothing = 0;

    return SC_onGameCameraTick_outOfCombat(player, moveData, delta);
  }

  if (!player.smart_camera_data.settings.is_enabled_in_combat) {
    return false;
  }

  player_position = player.GetWorldPosition();
  // 3 seconds 
  player.smart_camera_data.combat_start_smoothing = LerpF(0.33 * delta, player.smart_camera_data.combat_start_smoothing, 1);

  player.smart_camera_data.time_before_target_fetch -= delta;
  if (player.smart_camera_data.time_before_target_fetch <= 0) {
    player.smart_camera_data.time_before_target_fetch = 5;

    new_entities = SC_fetchNearbyTargets(player);

    if (new_entities.Size() > 0) {
      player.smart_camera_data.nearby_targets = new_entities;
    }
  }

  SC_removeDeadEntities(player.smart_camera_data.nearby_targets);
  positions = SC_getEntitiesPositions(player.smart_camera_data.nearby_targets);
  target = player.GetTarget();
  target_position = target.GetWorldPosition();

  mean_position = SC_getMeanPosition(positions, player);
  is_mean_position_too_high = mean_position.Z - player_position.Z > 1.5;

  rotation = SC_getRotationToLookAtPosition(
    mean_position,
    player
  );

  player.smart_camera_data.desired_x_direction += theInput.GetActionValue('GI_AxisRightX')
    * delta
    * player.smart_camera_data.settings.horizontal_sensitivity;

  player.smart_camera_data.desired_x_direction *= 1 - (1 - 0.99 * delta);

  ////////////////////
  // Yaw correction //
  ///////////////////
  //#region yaw correction

  if (player.smart_camera_data.desired_x_direction != 0) {
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing,
      moveData.pivotRotationValue.Yaw,
      moveData.pivotRotationValue.Yaw
      + player.smart_camera_data.desired_x_direction
    );

    moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
  }
  else if (PowF(AngleDistance(moveData.pivotRotationValue.Yaw, rotation.Yaw), 2) > 4) {
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing,
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

  // some pitch correction if the mean position is too high compared to the
  // player, which means the target is probably off camera.
  if (is_mean_position_too_high) {
    if (player.smart_camera_data.update_y_direction_duration <= 0) {
      player.smart_camera_data.update_y_direction_duration = 1;
    }

    moveData.pivotRotationController.SetDesiredPitch( rotation.Pitch );
    moveData.pivotRotationValue.Pitch	= LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing,
      moveData.pivotRotationValue.Pitch,
      rotation.Pitch
    );
  }
  // do pitch correction if the target is blocked by Geralt, but only if the 
  // pitch is not lower than it current one.
  // As pitch goes down, camera looks further down.
  else if (!player.IsInCombatAction() && SC_shouldLowerPitch(player, target)) {
    rotation_to_target = VecToRotation(target_position - player_position);

    // only if the creature is near the player
    if (VecDistanceSquared2D(target_position, player_position) < 3 * 3
    // only if the creature is not already higher than the player
    && target_position.Z < player_position.Z + 1
    // only if the camera is not already looking down
    &&  rotation_to_target.Pitch - 30 < moveData.pivotRotationValue.Pitch) {

      if (player.smart_camera_data.update_y_direction_duration <= 0) {
        player.smart_camera_data.update_y_direction_duration = 1;
        player.smart_camera_data.corrected_y_direction = moveData.pivotRotationValue.Pitch - 10;
      }

      moveData.pivotRotationController.SetDesiredPitch( player.smart_camera_data.corrected_y_direction );
      moveData.pivotRotationValue.Pitch	= LerpAngleF(
        delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing,
        moveData.pivotRotationValue.Pitch,
        player.smart_camera_data.corrected_y_direction
      );
    }

  }
  else if (player.smart_camera_data.update_y_direction_duration > 0) {
    player.smart_camera_data.update_y_direction_duration -= delta * player.smart_camera_data.settings.overall_speed;

    // player.smart_camera_data.desired_y_direction = LerpF(
    //   delta * 0.1,
    //   player.smart_camera_data.desired_y_direction,
    //   moveData.pivotRotationValue.Pitch
    // );

    moveData.pivotRotationController.SetDesiredPitch( player.smart_camera_data.desired_y_direction );
    moveData.pivotRotationValue.Pitch	= LerpAngleF(
      delta * player.smart_camera_data.settings.overall_speed,
      moveData.pivotRotationValue.Pitch,
      player.smart_camera_data.desired_y_direction
    );
  }
  else {
    player.smart_camera_data.desired_y_direction = moveData.pivotRotationValue.Pitch;
  }
  //#endregion pitch correction

  /////////////////////
  // Zoom correction //
  /////////////////////
  //#region zoom correction

  // offset coming from the creatures behind the Camera's back.
  back_offset = SC_getHeightOffsetFromTargetsInBack(player, player_position, positions);

  moveData.cameraLocalSpaceOffset.Y = LerpF(
    delta * player.smart_camera_data.settings.overall_speed * 0.2 * player.smart_camera_data.combat_start_smoothing,
    moveData.cameraLocalSpaceOffset.Y,
    back_offset
  );

  // some hardcoded values to avoid the camera flying up for no reason
  moveData.cameraLocalSpaceOffset.Z = LerpF(delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing, moveData.cameraLocalSpaceOffset.Z, 0);
  moveData.pivotPositionController.offsetZ = LerpF(delta * player.smart_camera_data.settings.overall_speed * player.smart_camera_data.combat_start_smoothing, moveData.pivotPositionController.offsetZ, 1.3f);
  //#endregion zoom correction

  return true;
}

/**
 * Returns a value between 0 and 1, where 1 means the pitch should be lowered
 * by 100% of the pitch correction.
 */
function SC_shouldLowerPitch(player: CR4Player, target: CActor): bool {
  var heading_to_target: float;
  var heading_to_player: float;
  var camera_position: Vector;
  var distance: float;

  camera_position = theCamera.GetCameraPosition();
  heading_to_target = VecHeading(target.GetWorldPosition() - camera_position);
  heading_to_player = VecHeading(player.GetWorldPosition() - camera_position);

  distance = AngleDistance(heading_to_player, heading_to_target);

  return distance * distance < 10 * 10;
}

function SC_getVelocityOffset(player: CR4Player): Vector {
  var player_to_camera_heading: float;
  var player_velocity: Vector;
  var angle_distance: float;
  var multiplier: float;

  player_to_camera_heading = VecHeading(
    theCamera.GetCameraPosition() - player.GetWorldPosition()
  );

  player_velocity = player.GetMovingAgentComponent().GetVelocity();

  angle_distance = AngleDistance(
    VecHeading(player_velocity),
    player_to_camera_heading
  );

  // slowly decreases the velocity offset as the velocity gets closer towards the
  // camera.
  multiplier = MinF(angle_distance, 180) / 180;

  if (player.IsInCombatAction()) {
    return player_velocity * 0.5 * multiplier * 0.2;
  }

  return player_velocity * 0.5 * multiplier;
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

  for (i = 0; i < positions.Size(); i += 1) {
    current_angle = VecHeading(positions[i] - player_position);
    current_angle = AngleDistance(player_back_heading, current_angle);

    // the entity is not in the Camera's back
    if (current_angle * current_angle > 120 * 120) {
      continue;
    }

    entities_count_in_back += 1;
    mean_position += positions[i];

    // if the creature in right behind the camera then we add the position one
    // more, but we don't increase the entities count so that it has a bigger
    // impact on the mean vlaue.
    // if (current_angle * current_angle > 60 * 60) {
    //   continue;
    // }

    // mean_position += positions[i];
  }

  // no entities in the back, so there is no bonus offset
  if (entities_count_in_back == 0) {
    return 0;
  }

  mean_position /= entities_count_in_back;

  return ClampF(
    VecDistance2D(mean_position, player_position) * -1,
    -player.smart_camera_data.settings.camera_zoom,
    player.smart_camera_data.settings.camera_zoom * -5,
  );;
}

function SC_getMeanPosition(positions: array<Vector>, player: CR4Player): Vector {
  var mean_position: Vector;
  var i: int;

  for (i = 0; i < positions.Size(); i += 1) {
    mean_position += positions[i];
  }

  mean_position /= i;
  mean_position += SC_getVelocityOffset(player);

  return mean_position;
}

function SC_getRotationToLookAtPosition(mean_position: Vector, player: CR4Player): EulerAngles {
  return VecToRotation(mean_position - player.GetWorldPosition());
}

function SC_fetchNearbyTargets(player: CR4Player): array<CGameplayEntity> {
  var entities: array<CGameplayEntity>;

  FindGameplayEntitiesInRange(
    entities,
    player,
    20,
    10,,
    FLAG_OnlyAliveActors | FLAG_ExcludePlayer | FLAG_Attitude_Hostile,
    player
  );

  return entities;
}

function SC_getEntitiesPositions(entities: array<CGameplayEntity>): array<Vector> {
  var output: array<Vector>;
  var size: int;
  var i: int;

  size = entities.Size();
  output.Resize(size);

  for (i = 0; i < size; i += 1) {
    output[i] =entities[i].GetWorldPosition();
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

function SC_removeDeadEntities(out entities: array<CGameplayEntity>): int {
  var i: int;
  var max: int;
  var removed_count: int;

  max = entities.Size();

  for (i = 0; i < max; i += 1) {
    if (!((CActor)entities[i]).IsAlive() || ((CActor)entities[i]).GetHealthPercents() <= 0.01) {
      entities.Remove(entities[i]);

      max -= 1;
      i -= 1;
      removed_count += 1;
    }
  }

  return removed_count;
}