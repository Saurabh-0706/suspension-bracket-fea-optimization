# Automated FEA-Driven Lightweighting of a Vehicle Suspension Mounting Bracket

A self-contained computational engineering project: a design load derived from a quarter-car dynamics model, carried through ANSYS Mechanical FEA, an analytical cross-check, a rainflow/Miner fatigue estimate and a constrained mass optimization, then extended with a transient (time-varying) analysis of a redesigned U-channel bracket. No lab access, proprietary standards or physical test rig were used. Verification comes from an analytical hand calculation, a mesh-convergence study, a temporal-convergence check and two independent dynamic models cross-checked against each other. It is not physical-test correlation.

The full write-up is in [`report/technical_report.md`](report/technical_report.md).

## Results at a Glance

| Step | Result |
|---|---|
| Design load (quarter-car, 0.05 m / 3 Hz bump) | MATLAB ODE 3953.5 N vs. Simulink 3898.0 N, 1.4% apart; design load ≈ 3926 N |
| Mesh convergence (flat plate, ANSYS Mechanical) | 837.05 / 947.68 / 998.40 MPa at 3.0 / 1.5 / 1.2 mm; 0.75 mm exceeded the ANSYS Student ~32,000-node limit |
| Analytical cross-check (net-section beam theory) | 1046.9 MPa vs. 998.4 MPa FEA (4.9%); the gross-section first pass was 628.2 MPa, 58.9% off |
| Fatigue estimate (rainflow + Miner, generic S-N curve) | 10 counted cycles, damage 0.0022 per pass, about 455 repeats of the event to reach 1.0 |
| Mass optimization (`fmincon`, thickness only) | Baseline 10 mm fails a 1.5x safety factor on yield; minimum feasible thickness 24.48 mm, mass 0.2080 → 0.5091 kg |
| Channel redesign, transient vs. static (same mesh) | 2677.2 MPa vs. 2694.5 MPa, dynamic amplification ≈ 0.99 |
| Temporal convergence (51 vs. 100 table points) | 2654.0 vs. 2677.2 MPa, 0.87% change |

![Quarter-car suspension mount force from the MATLAB ODE model](results/peak%20mount%20force.png)

*Mount-force history for the 2-second bump event (MATLAB ODE). The peak of about 3953 N at t ≈ 0.35 s is the design load; the full curve drives the fatigue estimate and the transient FEA.*

## Problem Statement

Structural brackets that connect suspension components (control arms, dampers) to a vehicle frame carry static and dynamic loads from road inputs and other events. Removing unnecessary mass improves ride and efficiency, but only if the remaining structure is verified against a realistic load rather than an assumed static g-factor. This project builds a small pipeline that (1) derives a load history from a quarter-car model instead of a guessed static load, (2) runs that load through meshing and FEA, (3) cross-checks the result analytically, and (4) optimizes the bracket under a stress constraint.

## Why MATLAB/Simulink Is In This Project

Every version of this idea needs a load case for the FEA. The weak version is "assume 3g and move on." The stronger version is to derive the load from a dynamic model:

- A **2-DOF quarter-car model** (sprung mass 350 kg, unsprung mass 45 kg, suspension 35 kN/m and 2.5 kN·s/m, tire stiffness 250 kN/m) is built in **Simulink**, driven by a 0.05 m, 3 Hz bump windowed to the first second of a 2-second run.
- The same system is solved independently as a MATLAB ODE (`ode45`), and the two peak forces are compared (1.4% apart).
- The peak load feeds the static FEA boundary condition. The full load history feeds the rainflow-counting + Miner's-rule fatigue estimate and the transient FEA.
- An ISO 8608 random road profile is not used in this version; it is listed under next steps.

## Tools Used

| Purpose | Tool |
|---|---|
| Parametric CAD | Autodesk Fusion 360 |
| Meshing and FEA solver | **ANSYS Mechanical** (native meshing, Static and Transient Structural, Workbench GUI) |
| Supplementary meshing practice | Altair HyperMesh Student Edition (OptiStruct/RADIOSS export only, see note below) |
| Dynamic load generation | **MATLAB + Simulink** (quarter-car), cross-checked against a MATLAB ODE solution |
| Fatigue estimate | MATLAB (rainflow counting written from scratch per ASTM E1049-85, Miner's rule) |
| Optimization | MATLAB `fmincon` (SQP) |
| Optional scripted path | APDL / Python scripts in `fea_scripts/`, written for the original HyperMesh plan and **not used** for any reported result |

**Note on HyperMesh vs. ANSYS Mechanical:** the original plan was to mesh in HyperMesh and solve in ANSYS via an exported `.cdb` deck. HyperMesh Student Edition only exports OptiStruct/RADIOSS (`.fem`), so meshing and solving were both done natively in ANSYS Mechanical. The HyperMesh meshes are kept in `mesh_scripts_old/` and `command1.tcl` as supplementary evidence, off the critical path.

## Methodology

1. **Baseline CAD**: a 95 × 30 × 10 mm flat plate with two Ø6 mm chassis holes and one Ø12 mm load hole, modeled in Fusion 360 and exported as STEP.
2. **Dynamic load generation**: quarter-car model in Simulink and as a MATLAB ODE; peak force and full history extracted and compared.
3. **Meshing and FEA**: STEP imported into ANSYS Mechanical; fixed supports on the chassis-hole faces, 3900 N on the load-hole face; mesh-convergence sweep at 3.0, 1.5 and 1.2 mm (see `fea_scripts/ANSYS_MECHANICAL_WORKFLOW.md`).
4. **Analytical cross-check**: net-section beam bending at the critical section (`postprocessing/analytical_beam_check.m`).
5. **Fatigue estimate**: rainflow counting of the load history, Miner's rule with a generic illustrative S-N curve (not a certified material curve), stress scaled from the converged FEA result.
6. **Optimization**: constrained mass minimization over plate thickness only, using surrogate models calibrated to the converged FEA point (allowable stress 250 MPa / 1.5 = 166.7 MPa).
7. **Phase 2**: U-channel redesign and a Transient Structural solve driven by the full mount-force history (below).
8. **Reporting**: `report/technical_report.md`.

## Phase 2: Transient Dynamic Loading on a Redesigned Channel-Section Part

The optimization showed that thickening a flat plate is a mass-inefficient way to meet the safety factor (+145% mass), so the bracket was redesigned as a U-channel (5 mm web and flanges, 40 mm wide web, 15 mm flanges). A **Transient Structural** solve was driven by the full time-varying mount force. It includes a temporal-convergence check, a same-mesh static-vs-transient comparison (amplification ≈ 0.99, after an earlier cross-geometry comparison suggesting 2.68x was found to be invalid), an animated stress-contour export (`results/transient_stress_animation.wmv`), and an analytical check showing where beam theory stops being valid (next to a support and a hole). Details are in Section 7 of the technical report.

## Repository Structure

```
suspension-bracket-fea-optimization/
├── README.md
├── cad/                  # STEP exports: flat-plate baseline + redesigned channel
├── dynamics_matlab/      # Simulink quarter-car builder + MATLAB ODE cross-check
│                         # + export_load_table_for_ansys.m (downsamples the load history for the
│                         #   Transient Structural tabular load, keeping the true peak sample)
├── mesh_scripts/         # ANSYS Workbench projects per element size (flat plate and channel)
├── mesh_scripts_old/     # HyperMesh OptiStruct meshes (supplementary, not on the critical path)
├── fea_scripts/          # ANSYS Mechanical workflow notes; APDL/Python scripts kept as an unused optional path
├── postprocessing/       # analytical hand check, rainflow/Miner fatigue
├── optimization/         # fmincon mass-minimization script
├── report/               # technical_report.md
└── results/              # convergence CSVs, load table, mount-force plot, transient stress animation
```

## Known Limitations

- The analyses are **linear-elastic**. Peak local stresses (998 MPa flat plate, about 2.7 GPa channel) are far above the 250 MPa yield used for the constraint, so they are best read as relative indices, not predictions of real stress. Plasticity and local strain-life methods would be needed for a qualified result.
- The mesh study stops at 1.2 mm because of the ANSYS Student ~32,000-node limit, leaving roughly 5% residual convergence uncertainty by the report's own estimate.
- The fatigue result demonstrates the method on a single severe bump with a generic S-N curve. It is not a qualified life estimate.
- Only a vertical bump input is modeled. Braking and cornering load cases are not.
- No physical-test correlation: fixed-support boundary conditions are idealized.

## Status

Complete through Phase 2: load derivation, mesh convergence, analytical cross-check, fatigue estimate, thickness optimization, channel redesign, transient analysis and animation. Next steps are listed in Section 8 of the technical report (certified S-N data, a road-load spectrum, strain-gauge correlation, optimization on the channel geometry, and a finer mesh on a full ANSYS license).

## Feasibility Note

Every step uses student/academic licenses (ANSYS Student, MATLAB/Simulink, HyperMesh Student Edition, Fusion 360 education) and requires no physical test rig, lab booking or confidential data.
