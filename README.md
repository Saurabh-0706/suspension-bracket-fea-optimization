# Automated FEA-Driven Lightweighting of a Vehicle Suspension Mounting Bracket

A self-contained, computational engineering project combining parametric CAD, scripted mesh generation and FEA, MATLAB/Simulink-derived dynamic loading, and constrained mass optimization. No lab access, no proprietary company standards, and no physical test rig are required — verification comes from analytical hand calculations, a mesh-convergence study, and cross-checking two independent dynamic models against each other.

## Problem Statement

Structural brackets that connect suspension components (control arms, dampers) to a vehicle frame carry static and dynamic loads from braking, cornering, and road inputs. Removing unnecessary mass improves ride and efficiency, but only if the remaining structure is verified against realistic loading — not just an assumed static g-factor. This project builds a small, automated pipeline that: (1) generates a physically-derived dynamic load history from a quarter-car model instead of a guessed static load, (2) runs that load through an automated CAD-to-FEA workflow, (3) cross-checks the result analytically, and (4) optimizes the bracket geometry to minimize mass under a stress/fatigue constraint.

## Why MATLAB/Simulink Is In This Project (Not Just Bolted On)

Every version of this idea needs a load case for the FEA. The weak version of that is "assume 3g and move on." The stronger version — and the reason Simulink belongs here rather than being decorative — is to derive that load from an actual dynamic model:

- A **quarter-car model** (sprung mass, unsprung mass, suspension spring/damper, tire stiffness) is simulated in **Simulink**, driven by a road input (a bump profile or an ISO 8608 random road profile).
- The force transmitted through the suspension mount over time is extracted — this is the load *history* at the bracket, not a single static number.
- The same quarter-car system is independently solved as a plain **MATLAB** ODE (`ode45`), and the two results are cross-checked against each other. This mirrors the FEA-vs-analytical-hand-calculation verification step later in the pipeline, so the whole project has one consistent theme: never trust a single model without an independent check.
- The peak load feeds the static FEA boundary condition; the full load history feeds a basic **rainflow-counting + Miner's-rule fatigue estimate in MATLAB**, using an openly published S-N curve (not a lab-measured one) — giving the project a genuine durability/fatigue angle, which is the piece most CAE-focused job postings ask for and a one-off static FEA project doesn't cover.

## Tools Used

| Purpose | Tool |
|---|---|
| Parametric CAD | PTC Creo Parametric (or CATIA V5) |
| Mesh generation | Altair HyperMesh (TCL/Python batch scripting) |
| FEA solver | ANSYS Mechanical / APDL (PyMAPDL optional) |
| Dynamic load generation | **MATLAB + Simulink** (quarter-car model), cross-checked against a MATLAB ODE solution |
| Fatigue estimate | MATLAB (rainflow counting + Miner's rule) |
| Automation & orchestration | Python (NumPy, Pandas, Matplotlib) |
| Optimization | MATLAB (`fmincon`/`ga`) or Python (`scipy.optimize`) |
| Documentation | Markdown/LaTeX, Git |

## Methodology

1. **Baseline CAD model** — parametric bracket in PTC Creo/CATIA (thickness, rib/fillet dimensions, hole pattern exposed via a design table).
2. **Dynamic load generation (MATLAB/Simulink)** — quarter-car model in Simulink driven by a road-bump input; independently solved via a MATLAB ODE script; peak force and full load history extracted from both, compared for agreement.
3. **Automated meshing** — export each CAD configuration, batch-mesh in HyperMesh via TCL/Python script.
4. **Automated FEA** — ANSYS APDL/PyMAPDL macro applies the Step-2 peak load, solves, extracts max stress, mass, and (optionally) first natural frequency.
5. **Analytical cross-check + convergence study** — independent beam/plate-theory hand calculation at the critical section, plus a mesh-convergence sweep.
6. **Fatigue estimate (MATLAB)** — rainflow-count the Step-2 load history, apply Miner's rule with a published S-N curve, estimate a fatigue life/damage ratio for the baseline design.
7. **Design space exploration & optimization** — sweep CAD parameters through Steps 3–4, then minimize mass subject to a stress/fatigue-damage constraint (MATLAB or Python), reporting the optimized geometry and % mass saved.
8. **Reporting** — methodology, assumptions, convergence study, dynamic-model cross-check, fatigue result, and optimization trade-off, with plots.

## Repository Structure

```
suspension-bracket-fea-optimization/
├── README.md
├── cad/                      # parametric CAD files + design table (add your .prt/.catpart here)
├── dynamics_matlab/          # Simulink quarter-car model builder + MATLAB ODE cross-check + fatigue
├── mesh_scripts/             # HyperMesh TCL/Python batch-meshing scripts
├── fea_scripts/              # ANSYS APDL / PyMAPDL solve macros
├── postprocessing/           # analytical hand-calc cross-check, result parsing, plotting
├── optimization/              # mass-minimization driver script
├── report/                   # final write-up and figures
└── results/                   # raw result data (CSV), stress-contour images
```

## What This Demonstrates

- **CAD & parametric design** (PTC Creo/CATIA)
- **Mesh generation & FEA** (HyperMesh + ANSYS) as real, documented experience
- **MATLAB/Simulink dynamic modeling** — a skill not otherwise represented in your current CV
- **Automation/scripting** (Python + MATLAB) extending your existing FRASCAL automation work
- **Structural verification methodology** — two independent dynamic models cross-checked, plus analytical FEA benchmarking and mesh convergence
- **Fatigue/durability assessment** — the recurring gap across the postings you've targeted this session
- **Optimization/lightweighting** — directly maps to "optimizing components for weight, cost, and robustness"

## Feasibility Note

Every step is achievable with a student/academic license (FAU typically provides MATLAB/Simulink and ANSYS access, and HyperMesh/CATIA may be available through the university) and requires no physical test rig, lab booking, or confidential company data. Verification comes from analytical hand calculations, a mesh-convergence study, and independent dynamic-model cross-checking — not physical-test correlation.

## Status

This repository is scaffolded with a working structure and skeleton scripts (see each folder). Fill in the CAD file, run the Simulink/MATLAB dynamics, and connect the mesh/FEA scripts to your local HyperMesh/ANSYS installation to produce results.
