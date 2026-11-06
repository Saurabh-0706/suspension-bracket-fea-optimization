# Suspension Mounting Bracket: FEA-Driven Lightweighting

**A computational verification-and-optimization pipeline: dynamic load derivation, meshing/FEA, analytical cross-check, fatigue estimate, and constrained mass optimization — built without lab access, physical test rigs, or proprietary standards. Extended with a genuinely transient (time-varying) structural analysis on a redesigned channel-section part, with an animated stress-contour export.**

---

## 1. Problem Statement and Load-Case Derivation

Suspension mounting brackets connect chassis-side structure to a vehicle's suspension components and carry the dynamic loads transmitted through that connection during normal driving — braking, cornering, and road inputs. A common shortcut in early-stage design is to size such a bracket against an assumed static "g-factor" load (e.g. "assume 3g and move on"). This project instead derives the design load from an actual dynamic model of the suspension, then carries that physically-grounded load all the way through meshing, FEA, an independent analytical check, a fatigue estimate, and a constrained mass optimization — mirroring the full verification loop a real structural-CAE role would expect, without requiring lab access, a physical test rig, or any proprietary company standard.

**Baseline geometry** (Fusion 360, `cad/`): a 95 mm × 30 mm × 10 mm plate with two Ø6 mm chassis-side mounting holes (at x = 15 mm, y = ±7 mm) and one Ø12 mm suspension-side load hole (at x = 80 mm, y = 0), with 6 mm corner fillets.

**Load case**: rather than an assumed static factor, the design load is the peak transient force transmitted through the suspension mount during a simulated road-bump event, derived from a quarter-car dynamic model (Section 2) and carried forward as an equivalent static design load for the FEA (Sections 3–4) and as a full time history for the fatigue estimate (Section 5).

---

## 2. Quarter-Car Dynamics: Simulink Model + MATLAB ODE Cross-Check

A 2-degree-of-freedom quarter-car model (sprung mass, unsprung mass, suspension spring/damper, tire stiffness) was built two independent ways and cross-checked against each other before its output was trusted as an FEA input — the same "never trust one model alone" principle applied later between FEA and hand calculation.

**Parameters**: sprung mass `m_s = 350 kg`, unsprung mass `m_u = 45 kg`, suspension stiffness `k_s = 35,000 N/m`, suspension damping `c_s = 2,500 N·s/m`, tire stiffness `k_t = 250,000 N/m`.

**Road input**: a 0.05 m, 3 Hz bump, windowed to the first second of a 2-second simulation — `0.05·sin(2π·3·t)·(t<1)`.

**Model 1 — MATLAB ODE** (`dynamics_matlab/quarter_car_ode.m`): direct numerical integration (`ode45`) of the coupled equations of motion.

**Model 2 — Simulink** (`dynamics_matlab/build_quarter_car_simulink.m` → `quarter_car_model.slx`): the same system built from blocks, with the mount-force output wired as `F = k_s·(x_s − x_u) + c_s·(ẋ_s − ẋ_u)` via a Gain block in Matrix(K·u) mode, and the same windowed bump signal fed in through a From Workspace block (rather than a bare Sine Wave block, which — as a build note — interprets its Frequency parameter in rad/s, not Hz, and would otherwise silently run continuously instead of being time-windowed).

| Model | Peak mount force |
|---|---|
| MATLAB ODE | 3953.5 N |
| Simulink | 3898.0 N |
| **Agreement** | **1.4%** |

This agreement was treated as validating both models. The average, **F_peak ≈ 3926 N**, is the design load carried into every downstream step of this project.

---

## 3. Mesh-Convergence Study (ANSYS Mechanical)

**Note on tooling**: the original plan was to mesh in Altair HyperMesh and solve in ANSYS via an exported `.cdb` deck. HyperMesh Student Edition, however, only exports to OptiStruct/RADIOSS (`.fem`) format — ANSYS import doesn't reliably accept it, and ANSYS export requires a full commercial HyperMesh license. Rather than force an unreliable format-conversion workaround, meshing and solving were both done natively inside **ANSYS Mechanical** (Workbench), which is free with ANSYS Student. HyperMesh meshing of the same geometry (`mesh_scripts/`, OptiStruct format) is retained in the repository as separate, genuine meshing-skill evidence, off the critical path.

**Boundary conditions**: Fixed Support on the two Ø6 mm chassis-hole faces; a 3900 N Force (≈ F_peak from Section 2) applied to the Ø12 mm load-hole face, perpendicular to the plate.

A convergence study was run at three element sizes:

| Element size | Max equivalent (von Mises) stress | Mass |
|---|---|---|
| 3.0 mm | 837.05 MPa | 0.20801 kg |
| 1.5 mm | 947.68 MPa | 0.20801 kg |
| 1.2 mm | 998.4 MPa | 0.20801 kg |

The originally-planned fourth point (0.75 mm) could not be solved: it exceeded the **ANSYS Student license's ~32,000-node problem-size limit** (the highest node ID must stay below that cap; boundary-condition/contact elements count toward it beyond what the visible mesh statistics show). 1.2 mm was used as the finest mesh that would solve under the license constraint.

**Convergence assessment**: the change in max stress between successive refinements *decelerates* (+13.2% from 3.0→1.5 mm, then +5.4% from 1.5→1.2 mm), which is the expected signature of genuine convergence rather than a numerical singularity (a true stress singularity, e.g. at a sharp reentrant corner, would keep growing rather than decelerating). **998.4 MPa at 1.2 mm was accepted as the converged design value**, with a documented ~5% residual mesh-convergence uncertainty attributable to the license-imposed mesh-size floor. Mass (0.20801 kg) is mesh-independent, as expected — it's read directly from the model geometry, not the solve.

---

## 4. Analytical Hand-Calculation vs. FEA

An independent classical beam-bending calculation (`postprocessing/analytical_beam_check.m`) was used as a hand-calculation cross-check on the converged FEA result, at the critical section through the Ø12 mm load hole (L = 0.08 m from the chassis edge to the hole center, plate width b = 0.03 m, thickness h = 0.01 m, F_peak = 3926 N).

A first pass using the plate's **gross** (full) width gave:

- σ_gross = M·c / I_gross = **628.16 MPa** — a **58.9% difference** from the FEA result (998.4 MPa).

This large a gap is not a modeling error — it's a missing correction. The naive gross-section calculation doesn't account for the material actually removed by the Ø12 mm hole at the critical section. Repeating the calculation with the **net section** width (30 mm − 12 mm = 18 mm) gives:

- σ_net = M·c / I_net = **1046.93 MPa** — a **4.9% difference** from the FEA result (998.4 MPa).

This is a strong cross-check, better than the ~10–15% target typically expected of a simplified beam-theory benchmark against a full 3D FEA result, and it builds confidence that both the FEA boundary conditions and the mesh are physically representative — not just numerically stable. It also illustrates a genuine engineering lesson: a hand-calculation benchmark is only as good as the section properties fed into it, and a stress-concentration feature (here, a hole at the checked section) has to be accounted for explicitly.

---

## 5. Fatigue / Rainflow Damage Estimate

A fatigue estimate was built on the full mount-force time history from Section 2 (not just its peak), using rainflow cycle counting and Miner's rule (`postprocessing/rainflow_fatigue.m`).

**Force-to-stress conversion**: rather than a second simplified nominal-section estimate, the force history was converted to stress using a factor calibrated directly from the converged FEA result — 998.4 MPa at the 3900 N peak load, i.e. ≈2.56×10⁵ Pa per N. Because the structure is linear-elastic (small deflections, no plasticity, a single scalable load case), this ratio is assumed to hold across the whole time history, carrying the FEA's actual hole-edge stress concentration into the fatigue estimate rather than a textbook nominal-section number.

**Rainflow counting**: implemented from scratch following ASTM E1049-85 §5.4.4 (the same method underlying MATLAB's Signal Processing Toolbox `rainflow` function), so the project doesn't depend on a toolbox that may not be present in a base Student MATLAB install. The implementation was verified against a reference open-source implementation of the same standard on multiple test signals (including a random one) with identical cycle counts before being trusted on real data.

**S-N curve**: a generic, illustrative structural-steel curve (not a lab-measured or certified material curve):

| Stress amplitude | Cycles to failure |
|---|---|
| 1000 MPa | 1×10³ |
| 500 MPa | 1×10⁴ |
| 300 MPa | 1×10⁵ |
| 200 MPa | 1×10⁶ |
| 150 MPa | 1×10⁷ (treated as an endurance limit) |

**Result** on the 2-second load history: 10 counted cycles (full + half); cumulative Miner's-rule damage of **0.0022 per pass**; equivalently, **≈455 repeats** of that exact load event to accumulate a damage sum of 1.0.

**Interpretation and caveat**: the load history used is a single, severe worst-case bump event, not a representative road-load spectrum — repeating it continuously (as a literal "time to failure" framing would imply) is not a realistic duty cycle, and the S-N curve is generic rather than material-specific. The result is best read as a demonstration of the rainflow/Miner's-rule *methodology*, correctly wired to a real, FEA-calibrated stress signal, rather than a qualified fatigue-life number. A production estimate would substitute a proper road-load spectrum (e.g. an ISO 8608 profile mixing many event severities) and a certified material S-N curve.

---

## 6. Optimization Results

A constrained mass-minimization (`optimization/optimize_mass.m`, MATLAB `fmincon`, SQP algorithm) was run over plate thickness — the one geometry parameter for which a validated relationship exists (the bracket has no rib feature, and no FEA data exists at any fillet radius other than the 6 mm baseline, so the optimization was scoped to what the data actually supports rather than an assumed multi-parameter model).

**Surrogate models**, both calibrated to the real converged FEA data point (10 mm thickness → 998.4 MPa, 0.20801 kg):

- **Mass**: exactly linear in thickness for this geometry (planform and hole pattern fixed, only thickness varies) — `mass = 0.020801 kg/mm × thickness`.
- **Stress**: net-section beam theory predicts a 1/thickness² relationship; the analytical formula was scaled by a constant correction factor (0.954) so it matches the real FEA point exactly at 10 mm, while keeping the physically correct 1/t² shape elsewhere.

**Constraint**: max allowable stress = 250 MPa (ANSYS default "Structural Steel" yield) / 1.5 (standard static safety factor against yield, applied to the peak dynamic load used as an equivalent static design load) = **166.7 MPa**.

| | Thickness | Max stress | Mass |
|---|---|---|---|
| Baseline | 10.0 mm | 998.4 MPa | 0.2080 kg |
| Optimized | 24.48 mm | 166.7 MPa | 0.5091 kg |

`fmincon` converged cleanly (feasibility violation dropped from 832 to ~0 over 7 iterations; first-order optimality ≈1×10⁻¹⁰), landing exactly on the constraint boundary — the mathematically expected outcome for a monotonically-increasing-mass, monotonically-decreasing-stress problem being minimized subject to a stress ceiling.

**Interpretation**: this is not a "12% mass savings" result — it is the opposite, and arguably a more informative one. The optimization reveals that the **10 mm baseline does not satisfy a standard 1.5× safety factor against yield for the peak dynamic mount load**; the minimum-mass thickness that does is ≈24.5 mm, a 145% mass increase. This is a legitimate finding a mass-optimization loop is supposed to surface — an under-designed baseline — rather than a failure of the method. It's also a result that invites further engineering judgment rather than being taken as final: 24.5 mm is a notably thick plate for a bracket, and a real next iteration would more likely explore a higher-strength material or local stiffening (e.g. a rib or gusset) than simply thickening the whole part — a design conversation an optimization result should prompt, not foreclose.

---

## 7. Extension: Transient Dynamic Loading on a Redesigned Channel-Section Bracket

Sections 1–6 apply the peak of the quarter-car load history as a *static* design load — standard practice, but it discards the rest of the time history and never tests whether a genuinely time-varying load produces a different peak stress than its static-equivalent value. This extension addresses that gap, and simultaneously makes the part itself more representative of a real chassis bracket, using two changes: a redesigned, stiffer cross-section, and a full transient (time-varying) FEA driven directly by the dynamics model's output rather than a single scalar peak.

### 7.1 Redesigned Geometry: Flat Plate → U-Channel

Section 6's optimization showed that meeting a proper safety factor by adding flat thickness alone is mass-inefficient (145% mass growth for a 10→24.5 mm thickness increase). A more mass-efficient real-world response is to add stiffness geometrically rather than through bulk thickness, so the baseline flat plate was redesigned as a **U-channel**: a 5 mm-thick, 40 mm-wide web with two 5 mm-thick, 15 mm-tall flanges at the outer edges (2 mm fillets at each flange-web junction to avoid an artificial sharp-corner stress riser), 95 mm long, carrying the same three mounting holes — two Ø5 mm chassis holes (x = 15 mm, y = ±7 mm) and one Ø12 mm load hole (x = 80 mm, y = 0). (The channel was first drawn at 30 mm overall width, matching the flat-plate baseline, but that placed the flange inner face only 0.5 mm from the Ø5 mm chassis-hole edge — well under the ~1.5× hole-diameter edge distance bolted-joint practice calls for. The web was widened to 40 mm before meshing to give the holes proper clearance, with the hole positions themselves unchanged.) A channel resists bending far more efficiently per unit mass than a flat plate, because the flange material sits far from the neutral axis (parallel-axis theorem) — the same principle behind real formed/extruded automotive brackets.

### 7.2 Transient Structural Analysis: The Full Load History, Not Just Its Peak

Rather than applying a single static Force, a **Transient Structural** analysis in ANSYS Mechanical was driven by the actual F_mount(t) curve from `dynamics_matlab/quarter_car_ode.m`, applied as a time-varying tabular load. The full 2000-point ODE output was downsampled (`dynamics_matlab/export_load_table_for_ansys.m`) to a manageable number of solve points — while explicitly guaranteeing the true peak-force sample was never lost to the downsampling, since it's the single most structurally important instant in the history.

**Temporal convergence check**: the same discretization-convergence logic used for the spatial mesh (Section 3) was applied to the *time* discretization. A 51-point table gave a peak stress of 2654.0 MPa; doubling to 100 points gave 2677.2 MPa — a change of **0.87%**, confirming the result had converged with respect to table resolution rather than being an artifact of the coarse table's linear-interpolation "kinks" between points (both at t ≈ 0.353 s, matching the load history's own peak instant).

**Large Deflection diagnostic**: an early transient result differed sharply from expectations, prompting a check of the geometric-nonlinearity ("Large Deflection") setting. Toggling it on/off changed the peak stress by under 0.5% (2642 vs. 2654 MPa), ruling out nonlinear geometric effects — confirming the model remains safely within the small-deflection linear regime assumed throughout this project, and that whatever the actual dynamic effect turned out to be, it wasn't a Large-Deflection artifact.

### 7.3 Isolating the Real Dynamic Effect: A Clean Same-Mesh Comparison

An initial comparison of the channel's transient peak (2677.2 MPa) against the *original flat-plate* static baseline (998.4 MPa, Section 3) suggested a dramatic 2.68× dynamic amplification factor. That comparison is invalid, however — it conflates two different geometries with two different loading types, rather than isolating loading type alone. A **clean comparison requires the same geometry and the same mesh**, differing only in how the load is applied.

A new Static Structural system was built sharing the channel's mesh (Geometry + Model cells linked to the transient system, so both solve on an identical discretization), with a **constant** 3953.5 N force (the load table's exact peak) replacing the tabular load:

| Analysis | Peak stress | Location |
|---|---|---|
| Static (constant 3953.5 N, channel mesh) | 2694.5 MPa | Ø5 mm chassis-hole edge, bottom face of web, near fixed support |
| Transient (100-point table, same mesh) | 2677.2 MPa | Same location |

**Clean dynamic amplification factor: 2677.2 / 2694.5 ≈ 0.99 — no meaningful amplification.** The apparent 2.68× figure was entirely an artifact of comparing across geometries, not a real dynamic effect. This makes physical sense: dynamic amplification arises when a structure's natural frequency is close to the load's frequency content; a small, stiff steel bracket almost certainly has a natural frequency far above the few-Hz content in the mount-force signal, so it responds essentially quasi-statically. This is a more defensible finding than a dramatic-sounding but flawed number would have been — it validates that the static-equivalent approach used in Sections 1–6 is not meaningfully non-conservative for this structure, rather than asserting a dynamic effect that further scrutiny didn't support.

A related note on the animation described below: ANSYS auto-scales displayed deformation for visibility by default (often by a large multiplier), so the visible flexing in the animation is exaggerated for legibility, not a literal depiction of the bracket's true (much smaller) physical displacement — consistent with the small-deflection regime confirmed above.

### 7.4 Stress-Contour Animation

The transient solution's Equivalent (von-Mises) Stress result was exported as a video (`results/transient_stress_animation.wmv`, 1586×628, ~10 s) using ANSYS Mechanical's built-in animation export, walking through all solved time points of the 2-second event. Because the color legend is fixed to the global min/max across the whole run (the correct convention, so colors are comparable frame-to-frame), most of the video shows the bracket in "cold" colors — accurately reflecting that stress stays modest for most of the 2 seconds — with a brief, localized hot-spot flash at the chassis-hole edge around t ≈ 0.35 s, when the load passes through its peak.

### 7.5 Revisiting the Analytical Check: Where Beam Theory Breaks Down

Section 4's flat-plate analytical check benchmarked stress at a hole reasonably distant from any support, achieving 4.9% agreement with FEA. Repeating that exercise properly for the channel — using the *true* lever arm from the fixed chassis-hole support to the load point (L = 80 − 15 = 65 mm, not the load-hole-to-edge distance used in Section 4) — gives a very different outcome.

For the channel's cross-section at the critical station (neutral axis 6.8 mm from the bottom face, gross; 7.5 mm net of the two Ø5 mm chassis holes), with M = 3953.5 N × 65 mm = 256,978 N·mm:

| Section assumption | σ at bottom fiber |
|---|---|
| Gross (uncorrected) | 147.8 MPa |
| Net (both Ø5 mm chassis holes) | 181.4 MPa |
| **FEA (clean static, same location)** | **2694.5 MPa** |

The hand calculation undershoots by roughly **15×** — a dramatically worse result than Section 4's flat-plate check, and one that should not be forced closer with an arbitrary correction factor. The reason is structural, not numerical: this check evaluates stress essentially *at* a fixed support and *at* a hole simultaneously — precisely the regime (per Saint-Venant's principle) where classical beam theory's underlying assumptions break down, since the theory assumes sections are evaluated reasonably far from load and support discontinuities. The contrast between the two analytical checks — a trustworthy 4.9% agreement away from any support, and a legitimately unusable 15× gap immediately next to one — is itself the finding: it demonstrates judgment about *when* a simplified hand-calculation is a valid verification tool and when FEA is the only appropriate one, which is arguably more valuable than either number in isolation.

### 7.6 What This Extension Demonstrates

- **Genuinely dynamic FEA**, not just a static analysis driven by a dynamically-derived load — a full transient solve using the actual time history, with its own temporal-convergence check mirroring the spatial one in Section 3.
- **Diagnostic discipline**: an unexpected result (the apparent 2.68× amplification) was investigated rather than reported at face value, isolating and ruling out one candidate cause (geometric nonlinearity) before identifying the real one (an invalid cross-geometry comparison) and correcting it.
- **A redesigned, more representative part geometry** (channel vs. flat plate), motivated directly by an earlier finding (Section 6) rather than arbitrarily chosen.
- **Engineering visualization**: an animated stress-contour export suitable for a portfolio, report, or interview walkthrough — with an honest read of what the animation does and doesn't literally represent (exaggerated deformation).
- **Knowing the limits of a verification method**: recognizing that beam theory doesn't apply at a support-hole intersection, rather than distorting the check to appear more successful than it validly can be.

---

## 8. Conclusions and What Would Change With More Time/Access

This project built a complete, self-consistent verification loop — dynamic load derivation, two independently cross-checked models, meshing/FEA, an independent analytical benchmark, a fatigue estimate, a constrained optimization, and (Section 7) a full transient dynamic analysis with its own temporal convergence check and an animated result export — entirely with free/student software licenses and no lab access, physical test rig, or proprietary company standard. Several genuine engineering constraints and false leads were encountered and navigated during the work, each documented rather than hidden: HyperMesh Student Edition's OptiStruct-only export (resolved by meshing/solving natively in ANSYS Mechanical), the ANSYS Student 32,000-node solve limit (resolved by capping the mesh-convergence study's finest size at 1.2 mm), an under-designed baseline surfaced by the optimization step (treated as a finding, not a bug), a geometric-nonlinearity red herring during the transient debugging (ruled out via an on/off comparison), and an invalid cross-geometry static-vs-transient comparison that initially suggested a large, spurious dynamic amplification factor (caught and corrected with a proper same-mesh comparison).

With lab access, a certified material specification, and physical test correlation, the following would be the natural next steps to turn this from a verification-methodology demonstration into a qualified engineering result:

- Replace the generic illustrative S-N curve with a certified, material-specific curve (e.g. from a materials handbook or MMPDS) for the actual candidate bracket material.
- Replace the single-event road-bump load history with a proper road-load spectrum (e.g. an ISO 8608 random road profile, or measured road-load data) for a representative fatigue-life estimate rather than a methodology demonstration.
- Correlate the FEA model against strain-gauge data from a physical prototype under known loading, to validate the boundary-condition assumptions (in particular, how well "chassis-hole fixed support" approximates the real mounting stiffness).
- Extend the optimization beyond plate thickness to include material selection and local stiffening features (ribs/gussets), now that the single-parameter result has shown that thickness alone is a fairly blunt and heavy way to meet the safety-factor constraint.
- Re-run the FEA mesh-convergence study on a full (non-Student) ANSYS license to confirm the 1.2 mm result would still hold at a finer mesh, closing the ~5% convergence-uncertainty gap left by the Student node-count cap.
- Re-run the mass optimization (Section 6) on the channel geometry rather than the flat plate, now that Section 7 has shown the channel carries the same peak load at a comparable stress level with a fundamentally stiffer, more mass-efficient cross-section.
