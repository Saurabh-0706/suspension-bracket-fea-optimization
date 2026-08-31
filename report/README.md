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
| Parametric CAD | Autodesk Fusion 360 |
| Mesh generation & FEA solver | **ANSYS Mechanical** (native meshing + static solve, Workbench GUI) |
| Supplementary meshing practice | Altair HyperMesh Student Edition (OptiStruct/RADIOSS export only — see note below) |
| Dynamic load generation | **MATLAB + Simulink** (quarter-car model), cross-checked against a MATLAB ODE solution |
| Fatigue estimate | MATLAB (rainflow counting + Miner's rule) |
| Automation & orchestration | Python (NumPy, Pandas, Matplotlib) |
| Optimization | MATLAB (`fmincon`/`ga`) or Python (`scipy.optimize`) |
| Documentation | Markdown/LaTeX, Git |

**Note on HyperMesh vs. ANSYS Mechanical:** the original plan was to mesh in HyperMesh and solve in ANSYS via an exported `.cdb` deck. HyperMesh Student Edition, however, only exports to OptiStruct/RADIOSS (`.fem`) — ANSYS export requires a full commercial license. Rather than fight that limitation, the mesh generation and FEA solve for this project both happen natively inside **ANSYS Mechanical** (Workbench), which is free with ANSYS Student and needs no format conversion. HyperMesh is still used and kept in the repo (`mesh_scripts/`, and any `.fem` files you produce) as separate, genuine evidence of HyperMesh meshing skill — it's just not on the critical path that produces this project's FEA results.

## Methodology

1. **Baseline CAD model** — parametric bracket modeled in Fusion 360 (thickness, hole pattern, fillets), exported as a STEP file.
2. **Dynamic load generation (MATLAB/Simulink)** — quarter-car model in Simulink driven by a road-bump input; independently solved via a MATLAB ODE script; peak force and full load history extracted from both, compared for agreement.
3. **Meshing (ANSYS Mechanical, native)** — import the STEP geometry directly into ANSYS Mechanical and generate the mesh there at 2–3 element sizes for the convergence study (see `fea_scripts/ANSYS_MECHANICAL_WORKFLOW.md`). HyperMesh meshing of the same geometry is also kept in the repo as supplementary, documented skill evidence, exported to OptiStruct format.
4. **FEA solve (ANSYS Mechanical, native)** — apply the Step-2 peak load and the chassis-hole fixed supports, solve, and record max equivalent (von Mises) stress, part mass, and (optionally) first natural frequency for each mesh density and geometry configuration.
5. **Analytical cross-check + convergence study** — independent beam/plate-theory hand calculation at the critical section, plus the mesh-convergence sweep from Step 3–4.
6. **Fatigue estimate (MATLAB)** — rainflow-count the Step-2 load history, apply Miner's rule with a published S-N curve, estimate a fatigue life/damage ratio for the baseline design.
7. **Design space exploration & optimization** — sweep geometry parameters through Steps 3–4, then minimize mass subject to a stress/fatigue-damage constraint (MATLAB or Python), reporting the optimized geometry and % mass saved.
8. **Reporting** — methodology, assumptions, convergence study, dynamic-model cross-check, fatigue result, and optimization trade-off, with plots.

## Repository Structure

```
suspension-bracket-fea-optimization/
├── README.md
├── cad/                      # Fusion 360 files + STEP exports (flat-plate baseline + redesigned channel)
├── dynamics_matlab/          # Simulink quarter-car model builder + MATLAB ODE cross-check + fatigue
│                              # + export_load_table_for_ansys.m (downsamples the load history for a
│                              #   Transient Structural tabular load, guaranteeing the true peak survives)
├── mesh_scripts/             # HyperMesh TCL/Python batch-meshing scripts (supplementary skill evidence)
├── fea_scripts/              # ANSYS Mechanical workflow notes + results; APDL/PyMAPDL scripts kept as an optional scripted-automation path
├── postprocessing/           # analytical hand-calc cross-check, result parsing, plotting
├── optimization/              # mass-minimization driver script
├── report/                   # final write-up and figures
└── results/                   # raw result data (CSV), stress-contour images, transient stress animation
```

## Phase 2: Transient Dynamic Loading on a Redesigned Channel-Section Part

The pipeline above applies the quarter-car model's *peak* load as a static design load. A second phase pushes further: a **U-channel redesign** of the bracket (motivated by the optimization step's finding that a flat plate is a mass-inefficient way to add stiffness), analyzed with a genuine **Transient Structural** solve driven by the *full* time-varying mount-force history (not just its peak), including its own temporal-convergence check, a clean same-mesh static-vs-transient comparison (finding no significant dynamic amplification once the comparison is done correctly), an animated stress-contour video export, and a properly-anchored analytical cross-check that demonstrates *where* beam theory does and doesn't apply. Full details and results are in `report/technical_report.md`, Section 7.

## What This Demonstrates

- **CAD & parametric design** (Fusion 360)
- **Meshing & FEA in ANSYS Mechanical** as real, documented, hands-on experience, plus supplementary HyperMesh meshing evidence
- **MATLAB/Simulink dynamic modeling** — a skill not otherwise represented in your current CV
- **Automation/scripting** (Python + MATLAB) extending your existing FRASCAL automation work
- **Structural verification methodology** — two independent dynamic models cross-checked, plus analytical FEA benchmarking and mesh convergence
- **Fatigue/durability assessment** — the recurring gap across the postings you've targeted this session
- **Optimization/lightweighting** — directly maps to "optimizing components for weight, cost, and robustness"
- **Working around real license constraints** — recognizing a tooling limitation (HyperMesh Student's OptiStruct-only export) and adapting the pipeline instead of forcing an unreliable workaround, which is itself a realistic piece of engineering judgment worth being able to talk about

## Feasibility Note

Every step is achievable with student/academic licenses (ANSYS Student, MATLAB/Simulink via FAU's TAH license, HyperMesh Student Edition, Fusion 360's free personal/education license) and requires no physical test rig, lab booking, or confidential company data. Verification comes from analytical hand calculations, a mesh-convergence study, and independent dynamic-model cross-checking — not physical-test correlation.

## Status

CAD baseline modeled in Fusion 360; Simulink/MATLAB quarter-car dynamics built and cross-checked (1.4% agreement between the two models); HyperMesh meshes exported at 3 element sizes (OptiStruct format, supplementary). Next: mesh and solve in ANSYS Mechanical directly (see `fea_scripts/ANSYS_MECHANICAL_WORKFLOW.md`), then the analytical cross-check, fatigue estimate, and optimization steps.
