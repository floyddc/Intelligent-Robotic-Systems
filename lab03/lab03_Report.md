# Lab 03 - Subsumption architecture
**Author:** Diego Colì - diego.coli@studio.unibo.it<br>
## Idea
Behaviors are organized in a strict priority hierarchy. Each layer receives wheel velocities from lower layers and can modify them (the halt layer may completely override them). The final command is set by the highest-priority layer whose condition is active.

## Controller architecture - Possible solution
The controller (`subsumption.lua`) defines four layers from lowest to highest priority:

- **Layer 0 — Random Walk**: both wheels are set to a base speed of 10 with a small random noise (±1.5). Keeps the robot moving and exploring when no other behavior is triggered.
- **Layer 1 — Phototaxis**: sums light sensor readings as a 2D vector and extracts the resultant angle. Steers proportionally to `angle * MAX_VELOCITY`. Transparent if no light is detected (`total_light < 0.001`).
- **Layer 2 — Obstacle Avoidance**: computes a **`front`** signal (`Σ value·cos(angle)`) and a **`turn`** signal (`Σ value·sin(angle)`) from proximity sensors. An **`obstacle_intensity`** factor (clamped to `[0,1]`) gates the correction. `gain_turn = 30` is much larger than `gain_front = 8` to prioritize steering away over braking.
- **Layer 3 — Halt**: reads motor ground sensors. If any value falls below `GROUND_THRESHOLD = 0.5`, returns `(0, 0)` immediately, overriding all other layers. Transparent otherwise.

## Expected behavior
- Open space with light: the robot tends to move toward the light source, aided by the random walk forward bias.
- Obstacle nearby: avoidance overrides phototaxis steering; intensity scaling ensures a smooth response.
- Dark ground detected: robot stops immediately regardless of other inputs.
- No stimuli: random walk drives exploration.
