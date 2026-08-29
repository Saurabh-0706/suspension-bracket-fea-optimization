# ANSYS Mechanical Workflow (Native Meshing + Solve)

This replaces the original "mesh in HyperMesh, solve in ANSYS via an exported `.cdb`" plan. HyperMesh Student Edition only exports to OptiStruct/RADIOSS, so meshing and solving both happen directly inside ANSYS Mechanical instead — no format conversion needed, and it's free with ANSYS Student.

Load values referenced below come from `dynamics_matlab/quarter_car_ode.m` and the cross-checked Simulink model: peak mount force ≈ 3900 N (average of the two models' ~3953 N and ~3898 N results).

Geometry values referenced below come from `cad/` (Fusion 360 baseline): 95 mm × 30 mm × 10 mm plate, two Ø6 mm chassis-end holes at x = 15 mm (y = ±7 mm), one Ø12 mm load-end hole at x = 80 mm (y = 0) — matching `postprocessing/analytical_beam_check.m`'s `L = 0.08`, `b = 0.03`, `h = 0.01`.

## Steps

1. **Start a Static Structural analysis.** Open ANSYS Workbench, drag a *Static Structural* system into the project schematic.

2. **Import geometry.** Right-click the Geometry cell → Import Geometry → browse to `cad/bracket_baseline.stp` (or whatever you named the STEP export from Fusion 360).

3. **Open Mechanical.** Double-click the Model cell. This opens the Mechanical window with your geometry loaded under the Geometry branch.

4. **Assign material.** Under the Geometry branch, select the body, and in Details set a structural steel (or whatever material you intend — note this in `report/` once decided, since `postprocessing/analytical_beam_check.m`'s hand calculation needs the same modulus to be a fair comparison).

5. **Mesh — pass 1 (coarse).** Right-click the Mesh branch → Insert → Sizing, select the whole body, set Element Size to **3 mm**, then right-click Mesh → Generate Mesh. Save this as your first convergence-study data point.

6. **Apply boundary conditions.**
   - **Fixed Support:** select the two Ø6 mm chassis-end holes (the cylindrical faces), right-click → Insert → Fixed Support.
   - **Force:** select the Ø12 mm load-hole's cylindrical face, right-click → Insert → Force. Set magnitude to **3900 N**, direction perpendicular to the plate (matching the transverse bending load direction assumed in the analytical beam check) — check the arrow preview in the viewport before solving so you're confident the direction is right, not just the magnitude.

7. **Request results.** Right-click the Solution branch → Insert → Stress → Equivalent (von-Mises), and separately check the body's mass (Geometry branch → select body → Details panel shows Mass directly, no solve needed for this one).

8. **Solve.** Click Solve. Once finished, click on the Equivalent Stress result to see the max value and the stress contour plot.

9. **Repeat meshing at finer sizes.** Change the Sizing element size to **1.5 mm**, regenerate the mesh, re-solve, and record the new max stress. Do this once more at **0.75 mm**. Plot max stress vs. element size — if the value has stopped changing much between the last two sizes, the mesh has converged and that result is trustworthy.

10. **Save results.** For each mesh size, record: element size, max equivalent stress, part mass, solve time. Put this into a small CSV in `results/` (e.g. `results/mesh_convergence.csv`) so it's available for the report and for `postprocessing/analytical_beam_check.m`'s comparison.

## What this feeds into next

- The converged max-stress value is what you compare against `postprocessing/analytical_beam_check.m`'s hand-calculated stress.
- The mass value (from the Geometry branch, no solve required) is your baseline mass for `optimization/optimize_mass.m`.
- Re-running steps 2–9 for different plate thicknesses (per the parameter sweep idea in `fea_scripts/run_parameter_sweep.py`) is how you'd build the small stress-vs-thickness dataset the optimization step needs, if you want real data rather than the current placeholder curves.

## On the APDL/PyMAPDL scripts in this folder

`ansys_apdl_template.mac` and `run_parameter_sweep.py` were written for the original HyperMesh-mesh-export-then-script-the-solve plan. They're kept in the repo as a documented alternate path — useful if you later want to automate the parameter sweep via command-line ANSYS batch runs instead of clicking through Workbench each time — but they are not required for the workflow above, and the `%p_mesh%` `.cdb` input they expect won't come from HyperMesh Student Edition. Treat them as a "next level of automation" reference rather than something to run right now.
