@wrapMethod(CR4Player)
function OnGameCameraTick(out moveData : SCameraMovementData, dt : float) {
  var res: bool;

  res =  wrappedMethod(moveData, dt);
  SC_onGameCameraTick(this, moveData, dt);

  return res;
}