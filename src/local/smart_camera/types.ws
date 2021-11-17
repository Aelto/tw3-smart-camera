
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
}

struct SC_settings {
  /**
   * Whether or not the mod is enabled
   */
  var is_enabled: bool;

  /**
   * Multiplier controlling zoom outs of the camera
   */
  var zoom_out_multiplier: float;

  /**
   * Multiplier control the horizontal sensitivity
   */
  var horizontal_sensitivity: float;
}