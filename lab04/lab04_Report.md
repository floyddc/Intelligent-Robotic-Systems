# Lab 04 - Motor Schemas
**Author:** Diego Colì - 0001172691<br><br>
This lab exercise requires that the robot finds a light source and reaches it as fast as possible while avoiding collisions with walls, boxes and other robots, using a motor schemas architecture.

## Idea
Each behavior is modeled as a **potential field** that produces a force vector on the robot. All vectors are summed to obtain a single resultant, which is then converted into differential wheel velocities.<br>
The key behaviors are: phototaxis (attractive field toward light), obstacle avoidance (repulsive field away from obstacles), and a uniform forward drive for exploration.

## Controller architecture - Motor Schemas
The controller is implemented in `controller-ms.lua` and uses the `vector.lua` module for polar/cartesian vector operations. It includes the following components:

- **Perceptual Schema 1 – Phototaxis (attractive field)**: sums all 24 light sensor readings as polar vectors `{length = value, angle = sensor_angle}`. The resulting vector points toward the brightest region and is scaled by `LIGHT_GAIN`.
- **Perceptual Schema 2 – Obstacle avoidance (repulsive field)**: each of the 24 proximity sensors produces a repulsive vector in the opposite direction (`angle + π`) with magnitude proportional to the reading. The sum is scaled by `OBSTACLE_GAIN`.
- **Perceptual Schema 3 – Uniform forward drive**: a constant vector `{length = UNIFORM_GAIN, angle = 0}` pointing straight ahead, ensuring the robot keeps moving even when no stimulus is perceived.
- **Vector summation**: all three schema vectors are summed pairwise using `vector.vec2_polar_sum()` to obtain a single resultant vector.
- **Velocity conversion**: the resultant vector is converted to wheel velocities using the differential drive model:
  - Translational velocity: `v = clamp(resultant.length, 0, MAX_VELOCITY)`
  - Angular velocity: `ω = ANGULAR_GAIN * resultant.angle`
  - Wheel velocities: `vl = v - ω·L/2`, `vr = v + ω·L/2` (where `L = robot.wheels.axis_length ≈ 14 cm`)
- **Halt on black spot**: when at least one ground sensor reads below `HALT_THRESHOLD`, the robot stops (both wheels set to 0). This addresses the challenge of stopping at the target using a pure MS approach — the ground sensor effectively acts as a zero-velocity stop field.
- **LED feedback**: red when halted on spot, yellow when perceiving significant light, green otherwise.

## Key parameters
- `MAX_VELOCITY = 15`: hard physical wheel speed limit (15 cm/s).
- `LIGHT_GAIN = 80`: high gain to amplify the very small light sensor values at distance.
- `OBSTACLE_GAIN = 12`: repulsive field strength.
- `UNIFORM_GAIN = 8`: base forward speed for exploration.
- `ANGULAR_GAIN = 1.5`: kept low because the inter-wheel distance L ≈ 14 cm amplifies the differential; a high value causes the robot to spin in place.
- `HALT_THRESHOLD = 0.1`: ground sensor threshold for black spot detection.

## Expected behavior
- From any starting position, the robot moves forward (uniform drive) and steers toward the light (phototaxis) as soon as it perceives it.
- When approaching obstacles, the repulsive field deflects the robot away while maintaining forward progress.
- The balance between attractive and repulsive fields allows the robot to navigate around boxes and walls without getting stuck.
- Once the robot reaches the black spot under the light, it halts and turns its LEDs red.
- Performance can be evaluated by logging the distance to the light at each step via the positioning sensor (used only for evaluation, not for control).
