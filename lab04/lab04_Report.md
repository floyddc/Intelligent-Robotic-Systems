# Lab 04 - Motor Schemas
**Author:** Diego Colì - diego.coli@studio.unibo.it<br>

## Idea
Each behavior is modeled as a **potential field** producing a force vector. All vectors are summed into a single resultant, converted to differential wheel velocities.

## Controller architecture
The controller (`controller-ms.lua`) uses `vector.lua` for polar/cartesian operations and implements four perceptual schemas:

- **Phototaxis (attractive)**: sums all 24 light sensor readings as polar vectors. The result points toward the brightest region, scaled by `LIGHT_GAIN = 80`.
- **Obstacle avoidance (repulsive)**: each proximity sensor produces a vector in the opposite direction (`angle + π`), scaled by `OBSTACLE_GAIN = 12`.
- **Uniform forward drive**: constant vector `{length = 8, angle = 0}` to keep the robot moving when no stimulus is perceived.
- **Halt on black spot**: when a ground sensor reads below `HALT_THRESHOLD = 0.1`, a strong backward vector (`HALT_GAIN = 101`) overrides motion, stopping the robot on the target.
- **LED feedback**: red when halted, yellow when light is perceived, green otherwise.

All schema vectors are summed with `vec2_polar_sum()`. The resultant is converted to wheel speeds via the differential drive model:
- $v = \text{clamp}(|\vec{r}|,\, 0,\, 15)$
- $\omega = 1.5 \cdot \angle\vec{r}$
- $v_{l,r} = v \mp \omega \cdot L/2$.

## Expected behavior
- The robot steers toward the light (phototaxis) while the uniform drive ensures continuous forward motion.
- Obstacles are avoided via the repulsive field without stopping forward progress.
- On reaching the black spot under the light, the halt schema dominates and the robot stops.
