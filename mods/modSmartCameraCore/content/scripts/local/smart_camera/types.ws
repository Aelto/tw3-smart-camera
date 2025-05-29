
struct SC_data {

  /**
   * Whether the settings were fetched already
   */
  var settings_fetched: bool;

  /**
   * The time before settings are updated, in seconds
   */
  var time_before_bone_fetch: float;

  /**
   * Set to the previously run camera mode
   */
  var previous_camera_mode: SC_cameraMode;

  /**
   * The user can tell the camera to move a little left and right. This value
   * stores the desired direction on the X axis.
   */
  var desired_x_direction: float;

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
   * a LERPed offset for the left to right position in exploration mode
   */
  var exploration_local_x_offset: float;

  /**
   * a LERPed offset for the front to back position in exploration mode
   */
  var exploration_local_y_offset: float;

  /**
   * a cursor that is constantly LERPed towards 0 and that indicates recent
   * sudden rotations
   */
  var exploration_rotation_tendency: float;

  /**
   * Tracks the look_at position of the camera, it is used to LERP the
   * translations in order to avoid having a fast moving camera going from left
   * to right constantly.
   */
  var combat_look_at_position: Vector;

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
  var pitch_correction_cursor: float;
  var feet_distance_cursor: float;

  var interaction_focus_cursor: float;

  var camera_disable_cursor: float;

  var player_bone_index_lfoot: int;
  default player_bone_index_lfoot = -999;

  var player_bone_index_rfoot: int;
  default player_bone_index_rfoot = -999;

  var horse_bone_index_torso: int;
  var horse_bone_index_pelvis: int;
  default horse_bone_index_pelvis = -999;
}

struct SC_settings {
  /**
   * Whether or not the mod is enabled
   */
  var is_enabled_in_combat: bool;
  var is_enabled_in_exploration: bool;
  var is_enabled_on_horse: bool;
  var is_enabled_on_boat: bool;
  var is_enabled_with_mouse: bool;

  var camera_zoom: float;
  var camera_zoom_max: float;

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
  var camera_height_max: float;

  var camera_horizontal_position: float;

  var horse_camera_zoom: float;
  var camera_tilt_intensity: float;

  var exploration_autocenter_enabled: bool;
  var exploration_shake_intensity: float;
  var exploration_offset_intensity: float;
}

enum SC_cameraMode {
  SCCM_Exploration,
  SCCM_Horse
}