# Lab 02 - Composite behaviors
**Author:** Diego Colì - diego.coli@studio.unibo.it<br><br>
This lab exercise requires that the robot goes in the direction of the light while avoiding obstacles.

## Idea
The robot should have two main behaviors (collision avoidance + phototaxis) and an extra behavior (random walk when light is not visible).<br>
My idea is to combine the two main behaviors (phototaxis and collision avoidance)through continuous behavior blending.
Each behavior produces a steering contribution, and the final wheel velocities are obtained by combining these contributions into a single continuous motor command.

## Controller architecture - Possible solution
The controller is implemented in `composite_behaviors.lua` and includes the following components:
- **Sensors**: arrays of light sensors (`robot.light`) and proximity sensors (`robot.proximity`).
- **Phototaxis**: computes the normalized difference between right and left light sides (`light_diff`) and produces a steering command proportional to `LIGHT_GAIN * light_diff * MAX_VELOCITY`.
- **Collision avoidance**: sums proximity values on the left and right sides to compute `prox_diff` and calculates `obstacle_turn = OBSTACLE_GAIN * prox_diff * MAX_VELOCITY`.
- **Speed reduction**: the base speed is scaled by `speed_factor = 1 - (max_prox * SPEED_REDUCTION)` to slow down near obstacles.
- **Gap detection**: if the average of front sensors is low while side sensors report high values, the controller increases `speed_factor` and attenuates steering to safely traverse a narrow passage.
- **Gap detection**: the controller uses a threshold‑free continuous measure of gapness computed from front and side proximity readings. A `gap_weight` (0...1) is derived from the relative difference between side and front signals and smoothly increases `speed_factor` while attenuating steering commands. This avoids binary decisions and produces graceful behavior when entering narrow passages.
- **Random walk**: when neither light nor obstacles are significantly perceived, the controller injects a small random perturbation into the steering signal to promote
exploration and avoid deadlocks.
- **Continuous steering**: instead of using discrete left/right turning states,
  the controller computes wheel velocities continuously as `left_v  = base_speed + total_turn` and `right_v = base_speed - total_turn`,
  where `total_turn` is obtained by combining phototaxis and obstacle avoidance steering contributions. This produces smoother trajectories and reduces oscillatory behavior.

## Expected behavior
- With a dominant light source and open space, the robot converges towards the light.
- When approaching an obstacle the robot steers away using `obstacle_turn` and reduces speed via `speed_factor`.
- In narrow passages (gaps) the controller detects a clear center with close sides, reduces steering and temporarily increases relative speed to cross the gap smoothly.
- When no significant objects are present and no light is visible, the robot performs a simple exploratory random walk to avoid getting stuck.
