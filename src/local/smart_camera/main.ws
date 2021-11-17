
function SC_onGameCameraTick(player: CR4Player, out moveData: SCameraMovementData, delta: float): bool {
  var new_entities: array<CGameplayEntity>;
  var positions: array<Vector>;
  var player_position: Vector;
  var rotation: EulerAngles;
  var back_offset: float;
  var target: CActor;

  if (!player.IsInCombat()) {
    return false;

  }

  player.smart_camera_data.time_before_settings_fetch = -10;
  if (player.smart_camera_data.time_before_settings_fetch <= 0) {
    player.smart_camera_data.time_before_settings_fetch = 10;
    SC_reloadSettings(player.smart_camera_data.settings);
  }

  if (!player.smart_camera_data.settings.is_enabled) {
    return false;
  }

  theGame.GetGameCamera().ChangePivotDistanceController( 'Default' );
  theGame.GetGameCamera().ChangePivotRotationController( 'Exploration' );
  moveData.pivotRotationController = theGame.GetGameCamera().GetActivePivotRotationController();
  moveData.pivotDistanceController = theGame.GetGameCamera().GetActivePivotDistanceController();
  moveData.pivotPositionController = theGame.GetGameCamera().GetActivePivotPositionController();

  player_position = player.GetWorldPosition();

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

  rotation = SC_getRotationToLookAtPositionsAroundPoint(
    player_position,
    positions
  );

  player.smart_camera_data.desired_x_direction += theInput.GetActionValue('GI_AxisRightX') * delta;
  player.smart_camera_data.desired_x_direction *= (1 - 0.9) * delta;

  if (PowF(AngleDistance(moveData.pivotRotationValue.Yaw, rotation.Yaw), 2) > 4) {
    moveData.pivotRotationValue.Yaw = LerpAngleF(
      delta,
      moveData.pivotRotationValue.Yaw,
      rotation.Yaw
      + player.smart_camera_data.desired_x_direction
      * player.smart_camera_data.settings.horizontal_sensitivity
    );

    moveData.pivotRotationController.SetDesiredHeading(moveData.pivotRotationValue.Yaw);
  }

  // offset coming from the creatures behind the Camera's back.
  back_offset = SC_getHeightOffsetFromTargetsInBack(player, player_position, positions)
              * player.smart_camera_data.settings.zoom_out_multiplier;

  moveData.cameraLocalSpaceOffset.Y = LerpF(delta * 0.2, moveData.cameraLocalSpaceOffset.Y, back_offset);

  // some hardcoded values to avoid the camera flying up for no reason
  moveData.cameraLocalSpaceOffset.Z = 0;
  moveData.pivotPositionController.offsetZ = 1.3f;

  return true;
}

function SC_getHeightOffsetFromTargetsInBack(player: CR4Player, player_position: Vector, positions: array<Vector>): float {
  var entities_count_in_back: int;
  var player_back_heading: float;
  var mean_position: Vector;
  var current_angle: float;
  var i: int;

  player_back_heading = player.GetHeading() + 180;
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

  return MinF(VecDistance2D(mean_position, player_position) * -1, 10);
}

function SC_getRotationToLookAtPositionsAroundPoint(point: Vector, positions_around_point: array<Vector>): EulerAngles {
  var rotation: EulerAngles;
  var mean_position: Vector;
  var i: int;

  for (i = 0; i < positions_around_point.Size(); i += 1) {
    mean_position += positions_around_point[i];
  }

  mean_position /= i;

  // rotation = VecToRotation(mean_position - theCamera.GetCameraPosition());
  rotation = VecToRotation(mean_position - thePlayer.GetWorldPosition());

  return rotation;
}

function SC_fetchNearbyTargets(player: CR4Player): array<CGameplayEntity> {
  var entities: array<CGameplayEntity>;

  FindGameplayEntitiesInRange(
    entities,
    player,
    25,
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