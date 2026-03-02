# Collision Avoidance

## *collisions_avoidance.argos* — structure 
- **XML header**: configures ARGoS for the experiment.
- `<framework>`: sets threads, experiment length (here infinite with `length="0"`),
  and `ticks_per_second`.
- `<controllers>`: declares the `lua_controller` with actuators (`differential_steering`,
  `leds`) and sensors (`footbot_proximity`, `footbot_light`, `positioning`). The
  controller runs the script `collisions_avoidance.lua`.
- `<arena>`: defines the boundary walls and two `<distribute>` blocks:
  - 5 static obstacle boxes distributed uniformly.
  - 2 foot-bots using the Lua controller, placed with random positions and orientations.
- `<physics_engines>`, `<media>`, `<visualization>`: select `dynamics2d`, the LED medium,
  and several camera placements for visualization.

**General role:** the .argos file builds the scenario (how many obstacles and robots,
their placement), the available sensors/actuators, and the visualization settings.

## *collisions_avoidance.lua* — controller behavior
- **Key global parameters:**
  - `MOVE_STEPS = 15`: interval for changing random velocities;
  - `MAX_VELOCITY = 10`: reference maximum velocity;
  - `LIGHT_THRESHOLD = 1.5`: threshold to detect significant light;
  - `PROX_THRESHOLD = 0.3`: threshold to consider a proximity reading as an obstacle.
- **State variables:** `n_steps`, `left_v`, `right_v`, initialized in `init()`.
- **Lifecycle functions:** `init()`, `step()`, `reset()`, `destroy()`.
  - `init()`: sets initial velocities (0.5 * MAX) and turns LEDs off (black).
  - `reset()`: picks random initial velocities and resets the `n_steps` counter.
  - `destroy()`: empty hook for cleanup.
- **Control logic** (in `step()`):
  1. Increment `n_steps` and read proximity with `prox_sides()` which returns
     `sum_left`, `sum_right`, and `max_prox`.
  2. Compute forward speed `forward` reduced proportionally to `max_prox`
     (robots slow when an obstacle is near).
  3. If `max_prox > PROX_THRESHOLD` then perform avoidance:
     - if `sum_left > sum_right` (obstacle on the left) -> turn right by
       setting `right_v` negative and `left_v = forward`.
     - vice versa for an obstacle on the right.
  4. If no critical obstacle, every `MOVE_STEPS` steps choose random wheel
     velocities to implement a small random-walk.
  5. Apply velocities via `robot.wheels.set_velocity(left_v, right_v)`.
  6. Handle additional sensors: ground (spot) detection using `robot.motor_ground`
     (spot detected if any ground sensor value is 0) and sum light sensors to
     detect light presence (`LIGHT_THRESHOLD`).
  7. LEDs: `red` if a spot is detected, `yellow` if significant light is present,
     otherwise `black`.

**Helper:** `prox_sides()` splits proximity sensors into left and right halves, sums
their readings, and returns the maximum proximity value (used to modulate speed
and trigger avoidance).

**Emergent behavior and practical notes**
- Robots move forward, slow down when an obstacle is near, and steer away from
  the closer obstacle side; this produces effective local avoidance without
  global mapping.
- Tunable parameters: `PROX_THRESHOLD` (sensitivity), `MAX_VELOCITY`, and the
  turning coefficients (currently -0.6 on the reversed wheel) affect avoidance
  aggressiveness and stability.
- The .argos environment (number/position of boxes and robots) strongly affects
  collective behavior; try different densities to test robustness.

## Conclusion
- `collisions_avoidance.argos` sets up the environment and available devices;
- `collisions_avoidance.lua` implements a simple but effective proximity-based
  avoidance controller with added random-walk and LED feedback for debugging/visualization.
