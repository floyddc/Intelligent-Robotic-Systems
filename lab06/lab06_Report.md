# Lab 06 - Aggregation
**Author:** Diego Colì - diego.coli@studio.unibo.it

## Idea
The goal is to make a swarm of robots aggregate into a single cluster using only local interactions, without any centralised control.<br>
Each robot runs a stochastic two-state FSM (moving/stopped). Transition probabilities are modulated by the number of stopped neighbours perceived via the range-and-bearing (RAB) sensor: the more stopped robots nearby, the more likely a moving robot stops, and the less likely a stopped robot resumes walking. This positive feedback drives the swarm toward a single large cluster.

## Controller architecture
The controller (`aggregation.lua`) implements the following components:
- **State machine**: two states, `STATE_MOVING` and `STATE_STOPPED`.
- **Neighbour counting (`CountRAB`)**: counts robots within `MAXRANGE = 30 cm` that broadcast data byte `1` (stopped). Moving robots broadcast `0`.
- **Stopping probability**: `Ps = min(PSmax, S + alpha·N)` increases with `N`, base value `S = 0.01`, `alpha = 0.4`, cap `PSmax = 0.99`.
- **Walking probability**: `Pw = max(PWmin, W - beta·N)` decreases with `N`, base value `W = 0.1`, `beta = 0.05`, floor `PWmin = 0.005`.
- **Obstacle avoidance**: active only when moving. It detects the strongest front proximity reading (`|angle| < π/2`, threshold `0.1`) and turns away from it. If no obstacle, the robot moves straight at `SPEED = 10`.
- **LED feedback**: green when moving, red when stopped.

Each step, `N` is sampled, `Ps` and `Pw` are recomputed, and a uniform random draw decides the state transition.

## Expected behavior
- Isolated moving robots rarely stop (low `Ps` with `N = 0`) and keep exploring.
- A robot near a stopped cluster perceives high `N`, so `Ps` rises sharply and it is likely to stop and join the cluster.
- Stopped robots in small groups (low `N`) have a relatively high `Pw` and may resume walking, dissolving small clusters. The algorithm naturally favours larger, stable aggregates.
- Over time the swarm converges to one dominant cluster through this self-reinforcing local feedback.