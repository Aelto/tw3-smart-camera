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
  output.mean_position = SC_getMeanPosition(positions, this) + Vector(0.0, 0.0, -1.0);

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
    this,
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
