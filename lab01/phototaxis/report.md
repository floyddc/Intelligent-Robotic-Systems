# Phototaxis

## *phototaxis.argos* — structure
- **XML header:** declares an ARGoS configuration file.
- `<framework>`: sets the system (threads), the experiment length, and
  `ticks_per_second`.
- `<controllers>`: registers the Lua controller and the actuators/sensors used
  by the robots. In this configuration the controller uses a
  `differential_steering` actuator (differential drive) and the `footbot_light`
  sensor (rotation about Z only, with noise).
- `<arena>`: defines the physical environment — perimeter walls (boxes), a single
  light source (`<light>` with position and intensity), and entity distribution
  (`<distribute>`). Here 20 foot-bots are distributed uniformly with random
  orientations.
- `<physics_engines>`, `<media>`, `<visualization>`: select the physics engine
  (`dynamics2d`), media (LEDs) and the Qt/OpenGL visualizer with a default
  camera placement.

**General role:** this file configures the experiment — how many robots, where the
light is placed, which sensors/actuators they have, and how simulation and
visualization are set up.

## *phototaxis.lua* — controller behavior
- **Global constants:** `MAX_VELOCITY`, `BASE_SPEED`, `TURN_GAIN`, `LIGHT_THRESHOLD`.
  These control the maximum velocity, forward speed fraction, steering gain,
  and a small threshold to avoid division by zero.
- **Lifecycle functions:** `init()`, `step()`, `reset()`, `destroy()`.
  - `init()`: sets initial wheel velocities and sets LEDs to green if available.
  - `step()`: runs each tick; reads light sensors, computes steering response,
    and updates wheel velocities.
  - `reset()` and `destroy()`: restore or clean up controller state.
- **Control logic** (in `step()`):
  1. Sum light values from the robot's light sensors and split them into left
     and right groups (half of the sensors each).
  2. Compute `diff = (sum_right - sum_left) / (total + LIGHT_THRESHOLD)`, a
     normalized difference indicating the side with stronger light.
  3. Compute `turn = TURN_GAIN * diff * MAX_VELOCITY` and convert it into
     wheel velocities around a fixed forward speed.
  4. Apply velocities with `robot.wheels.set_velocity(left_v, right_v)`.
  5. Update LEDs as feedback: if total light exceeds a threshold, LEDs are
     set to yellow, otherwise green.

**Emergent behavior:** robots keep a constant forward bias and steer based on the
left/right light imbalance, producing positive phototaxis (movement toward the
light source).

**Notes and tuning**
- Parameters such as `BASE_SPEED` and `TURN_GAIN` determine whether robots reach
  the light smoothly or oscillate; `LIGHT_THRESHOLD` prevents numerical issues
  when light is very low.
- The `.argos` file controls robot density and light placement—changing these
  parameters creates different scenarios (stronger/weaker light, more robots,
  obstacles, etc.).

## Conclusion
- `phototaxis.argos` defines the experiment and virtual hardware;
- `phototaxis.lua` implements a simple, robust controller that uses the left/right
  light intensity difference to steer foot-bots toward the light. Together they
  form a clear educational experiment to study emergent phototaxis in multi-robot systems.
