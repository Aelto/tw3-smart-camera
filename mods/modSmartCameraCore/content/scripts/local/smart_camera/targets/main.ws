// use annotations to add method right in the player class in order to access
// internal arrays directly, thus saving us from copying arrays around every
// tick.

struct SC_CombatTargetData {
  var hostile_enemies_count: int;
  var mean_position: Vector;

  var should_lower_pitch: bool;
  var lower_pitch_amount: float;

  var offset_from_targets_in_back: float;
}

@addMethod(CR4Player)
function SC_computeCombatTargetData(
  player_position: Vector
): SC_CombatTargetData {
  var output: SC_CombatTargetData;

  var positions: array<Vector>;

  SC_getEntitiesPositions(this.hostileEnemies, positions);
  output.hostile_enemies_count = this.hostileEnemies.Size();
  output.mean_position = SC_getMeanPosition(positions) + Vector(0.0, 0.0, -1.0);

  // LERP the mean position to smooth out the movements
  if (output.hostile_enemies_count > 0) {
    if (
      this.smart_camera_data.combat_look_at_position.X == 0
      && this.smart_camera_data.combat_look_at_position.Y == 0
    ) {
      this.smart_camera_data.combat_look_at_position = output.mean_position;
    }
    else {
      this.smart_camera_data.combat_look_at_position.X = LerpF(
        delta * this.smart_camera_data.settings.overall_speed,
        this.smart_camera_data.combat_look_at_position.X,
        output.mean_position.X
      );
  
      this.smart_camera_data.combat_look_at_position.Y = LerpF(
        delta * this.smart_camera_data.settings.overall_speed,
        this.smart_camera_data.combat_look_at_position.Y,
        output.mean_position.Y
      );
  
      this.smart_camera_data.combat_look_at_position.Z = LerpF(
        delta * this.smart_camera_data.settings.overall_speed,
        this.smart_camera_data.combat_look_at_position.Z,
        output.mean_position.Z
      );
    }
  }
  output.mean_position = this.smart_camera_data.combat_look_at_position;

  output.should_lower_pitch = SC_shouldLowerPitch(
    positions,
    output.lower_pitch_amount
  );

  output.offset_from_targets_in_back = SC_getHeightOffsetFromTargetsInBack(
    this,
    player_position,
    positions
  );


  return output;
}


function SC_getEntitiesPositions(
  out entities: array<CActor>,
  out positions: array<Vector>
) {
  var size: int;
  var i: int;

  size = entities.Size();
  positions.Resize(size);

  for (i = 0; i < size; i += 1) {
    positions[i] = entities[i].GetWorldPosition();
  }
}

function SC_getMeanPosition(out positions: array<Vector>): Vector {
  var mean_position: Vector;
  var i: int;

  for (i = 0; i < positions.Size(); i += 1) {
    mean_position += positions[i];
  }

  mean_position /= i;

  // when the camera is locked on a target, put a much greater importance to the
  // target.
  if (thePlayer.IsCameraLockedToTarget()) {
    i = positions.Size();

    mean_position += i * thePlayer.GetTarget().GetWorldPosition();
    mean_position /= i;
  }

  return mean_position;
}


function SC_getHeightOffsetFromTargetsInBack(
  player: CR4Player,
  player_position: Vector,
  out positions: array<Vector>
): float {
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

/**
 * Returns a value between 0 and 1, where 1 means the pitch should be lowered
 * by 100% of the pitch correction.
 */
function SC_shouldLowerPitch(
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

      // use ^2 to make the curve somewhat exponential with an increase near
      // the end.
      lower_pitch_amount_local *= lower_pitch_amount_local;

      // take the highest value possible from all targets.
      if (lower_pitch_amount_local > lower_pitch_amount) {
        lower_pitch_amount = lower_pitch_amount_local;
      }
    }
  }

  if (lower_pitch_amount_local > 0.0) {
    // finally, the more targets there are the less intense it is:
    // i == positions.Size() here since the loop is over
    lower_pitch_amount = MaxF(0, lower_pitch_amount - 0.1 * i);

    return true;
  }

  lower_pitch_amount = 0.0;
  return false;
}