
/*
  to place in combat.ws, in `protected final function InteralCombatComboUpdate( timeDelta : float )`
  right after `GetAssistHeading();` like so:

  // modImprovedAttackBending - BEGIN
  if (IAB_tryApplyingHeadingFromLeftStick(comboAttackA_Id, comboAttackA_Target, parent, comboPlayer, timeDelta)) {
    return;
  }
  // modImprovedAttackBending - END

*/

function IAB_tryApplyingHeadingFromLeftStick(attack_id: int, attack_target: CGameplayEntity, player: CR4Player, combo_player: CComboPlayer, delta: float): bool {
  var heading_from_left_stick: float;

  // the player is currently not attacking
  if (attack_id == -1 || !player.IsInCombatAction() || player.GetBehaviorVariable( 'combatActionType' ) != 0.f) {
    return false;
  }

  // the player is not touching the left stick
  if (theInput.GetActionValue('GI_AxisLeftX') == 0 || theInput.GetActionValue('GI_AxisLeftY') == 0) {
    return false;
  }
  
  heading_from_left_stick = IAB_getHeadingFromLeftStick(delta, attack_target);

  combo_player.UpdateTarget(
    attack_id,
    player.GetWorldPosition() + VecFromHeading(heading_from_left_stick) * 3,
    heading_from_left_stick,
    true,
    true
  );

  if(combo_player) {
    combo_player.Update(delta);
  }

  return true;
}

function IAB_getHeadingFromLeftStick(delta: float, target: CGameplayEntity): float {
  var left_stick_vector: Vector;
  var left_stick_heading: float;
  var camera_heading: float;

  left_stick_vector = Vector(theInput.GetActionValue( 'GI_AxisLeftX' ), theInput.GetActionValue( 'GI_AxisLeftY' ), 0);
  left_stick_heading = VecHeading(left_stick_vector);
  camera_heading = theCamera.GetCameraHeading();

  return AngleNormalize(camera_heading + left_stick_heading);

  // return LerpAngleF(
  //   delta * 20,
  //   thePlayer.GetHeading(),
  //   AngleNormalize(camera_heading + left_stick_heading)
  // );
}