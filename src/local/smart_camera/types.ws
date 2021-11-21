
struct SC_data {
  /**
   * The time before a new fetch in seconds
   */
  var time_before_target_fetch: float;

  /**
   * Cached nearby targets
   */
  var nearby_targets: array<CGameplayEntity>;

  /**
   * The user can tell the camera to move a little left and right. This value
   * stores the desired direction on the X axis.
   */
  var desired_x_direction: float;

  /**
   * The time before settings are updated, in seconds
   */
  var time_before_settings_fetch: float;

  /**
   * The cached settings data
   */
  var settings: SC_settings;

  /**
   * a percentage going from 0 to 1 representing how much the movements of the
   * camera should be smoothen at the start of the camera.
   */
  var combat_start_smoothing: float;

  var exploration_start_smoothing: float;

  var desired_y_direction: float;

  var update_y_direction_duration: float;

  var corrected_y_direction: float;

  var pitch_correction_delay: float;
}

struct SC_settings {
  /**
   * Whether or not the mod is enabled
   */
  var is_enabled_in_combat: bool;
  var is_enabled_in_exploration: bool;

  var camera_zoom: float;

  /**
   * Multiplier control the horizontal sensitivity
   */
  var horizontal_sensitivity: float;

  /**
   * The overall speed of the camera
   */
  var overall_speed: float;

  var camera_fov: float;

  var camera_height: float;

  var camera_horizontal_position: float;
}