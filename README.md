# Autonomous Guidance and Control for Spacecraft in Low-Gravity Proximity Operations

MATLAB/Simulink code of my MSc thesis in Space Engineering at Politecnico di Milano (advisors: Prof. A. Colagrossi, Prof. S. Soldini).

<!--- 📄 Thesis: [link to the thesis PDF] --->

## What it does

- **Real-time gravity model.** The polyhedral gravity field of an asteroid is sampled offline on concentric spherical grids with logarithmically spaced radii, then interpolated online with index caching for constant-time lookups (about 0.63 µs per query). It matches the full polyhedral model to within 0.04% mean acceleration error on Bennu and Kleopatra, and it is compatible with automatic code generation.
- **Event-triggered waypoint guidance.** The spacecraft coasts between waypoints and fires a single corrective burn on entering each waypoint's proximity radius. The Δv comes from the arc's state transition matrix, refined with a quasi-Newton correction. Around Bennu it reaches a 7.5 m mean arrival error, with a 9.85% propellant penalty against a continuous sliding-mode controller in exchange for no continuous thrusting.
- **Monte Carlo verification.** A 500-run campaign with dispersed initial conditions gave a 100% success rate, with no divergence, ejection or surface impact.

The thesis also includes a Hardware-in-the-Loop campaign at the University of Liverpool's Zero-G AstroLab. That code belongs to the facility and is **not** part of this repository.

## Repository structure

| Folder | Contents |
|---|---|
| `GravityFieldGeneration/` | Offline sampling of the polyhedral gravity field (`mainGravFieldGeneration.m`) and interpolation tests |
| `Simulation/` | ARIES (Asteroid-centered Relative Inertial and Environmental Simulator): Simulink model, waypoint generation, single runs and Monte Carlo |
| `AsteroidModels/` | Shape models in STL format |
| `utils/` | Mesh handling, reference-frame conversions, plotting |

## How to run

Requires MATLAB and Simulink ([version]). The Monte Carlo script also needs the Parallel Computing Toolbox. Paths use Windows separators.

1. **Generate the gravity grid:** set the asteroid in `GravityFieldGeneration/mainGravFieldGeneration.m` and run it. Output goes to `GravityData/`, which is not tracked.
2. **Generate waypoints:** run `Simulation/mainWaypointGenerator.m`. It opens the `ARIES.prj` project.
3. **Simulate:** run `Simulation/mainSimulator.m` for a single run, or `Simulation/mainMontecarlo.m` for the Monte Carlo campaign.
