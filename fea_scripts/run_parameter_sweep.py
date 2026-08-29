"""
run_parameter_sweep.py

SUPERSEDED for now: see ANSYS_MECHANICAL_WORKFLOW.md, which meshes and
solves directly in ANSYS Mechanical (Workbench) rather than exporting a
HyperMesh mesh for this script to batch-process -- HyperMesh Student
Edition can only export OptiStruct/RADIOSS decks, not the ANSYS .cdb this
script's pipeline expects. Kept as a reference for automating the sweep
via command-line batch runs later, once a mesh/solve path that produces
ANSYS-readable decks is available.

Orchestrates the full pipeline for a batch of bracket geometry
configurations:

  1. For each configuration, regenerate CAD geometry (via a Creo/CATIA
     design-table update -- left as a TODO/manual step or driven through
     the CAD tool's own scripting API if available).
  2. Batch-mesh the exported geometry with HyperMesh
     (mesh_scripts/hypermesh_batch_mesh.tcl).
  3. Run the ANSYS APDL static solve (fea_scripts/ansys_apdl_template.mac)
     using the peak load from the quarter-car dynamics model.
  4. Collect mass + max-stress results into a single CSV for the
     optimization step (optimization/optimize_mass.m or .py).

This script defines the orchestration logic and expected subprocess
calls; fill in the TODOs with your local HyperMesh/ANSYS installation
paths before running.
"""

import csv
import subprocess
from pathlib import Path

HYPERMESH_EXE = "TODO: path to hmbatch or hw_tcl executable"
ANSYS_EXE = "TODO: path to ansys batch executable, e.g. ansys232"

RESULTS_CSV = Path("../results/parameter_sweep_results.csv")


def mesh_configuration(geom_file: str, elem_size_mm: float, out_cdb: str) -> None:
    """Batch-mesh one CAD configuration via HyperMesh."""
    cmd = [
        HYPERMESH_EXE,
        "-tcl", "../mesh_scripts/hypermesh_batch_mesh.tcl",
        geom_file, str(elem_size_mm), out_cdb,
    ]
    print("TODO: run ->", " ".join(cmd))
    # subprocess.run(cmd, check=True)


def solve_configuration(mesh_cdb: str, peak_load_n: float) -> None:
    """Run the ANSYS APDL static solve for one meshed configuration."""
    cmd = [
        ANSYS_EXE, "-b", "-i", "ansys_apdl_template.mac", "-o", "run.out",
        f"-p_mesh={mesh_cdb}", f"-p_load={peak_load_n}",
    ]
    print("TODO: run ->", " ".join(cmd))
    # subprocess.run(cmd, check=True)


def main():
    # TODO: replace with the actual parameter grid (thickness, rib height,
    # fillet radius, hole spacing) exported from the CAD design table.
    configurations = [
        {"name": "baseline", "thickness_mm": 6.0, "elem_size_mm": 3.0},
        {"name": "thin_4mm", "thickness_mm": 4.0, "elem_size_mm": 3.0},
        {"name": "thick_8mm", "thickness_mm": 8.0, "elem_size_mm": 3.0},
    ]

    # TODO: read the peak mount force from the MATLAB dynamics output
    # (e.g. exported as peak_force.csv by quarter_car_ode.m)
    peak_load_n = 2500.0

    for cfg in configurations:
        geom_file = f"../cad/bracket_{cfg['name']}.stp"  # TODO: export from CAD
        mesh_cdb = f"../results/{cfg['name']}_mesh.cdb"
        mesh_configuration(geom_file, cfg["elem_size_mm"], mesh_cdb)
        solve_configuration(mesh_cdb, peak_load_n)

    print(f"TODO: aggregate ../results/results_summary.csv into {RESULTS_CSV}")


if __name__ == "__main__":
    main()
