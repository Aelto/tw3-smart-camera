
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

  var horse_auto_center_enabled: bool;

  /**
   * a cursor is a float value that can be positive as well as negative and is
   * changed based on multiple factors.
   * Then depending on the value of the cursor actions are applied, for example
   * if the cursor is a positive value then it will apply yaw correction. But
   * it won't if it's negative.
   *
   * Cursors are great with LerpF to add some delays on corrections with a
   * smooth transition.
   */
  var yaw_correction_cursor: float;

  var interaction_focus_cursor: float;

  var camera_disable_cursor: float;
}

struct SC_settings {
  /**
   * Whether or not the mod is enabled
   */
  var is_enabled_in_combat: bool;
  var is_enabled_in_exploration: bool;
  var is_enabled_on_horse: bool;
  var is_enabled_with_mouse: bool;

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