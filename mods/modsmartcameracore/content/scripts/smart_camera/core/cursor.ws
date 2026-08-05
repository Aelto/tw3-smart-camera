/**
 * utilities for cursor management
 */

/**
 * update the cursor value, if the condition is true thne it increases the value
 * if the condition is false then it decreases it towards the negative limit.
 */
function SC_updateCursor(delta: float, out cursor: float, should_increase: bool): float {
  cursor = LerpF(
    delta, 
    cursor,
    1 + (-2 * ((float)!should_increase))
  );

  return cursor;
}