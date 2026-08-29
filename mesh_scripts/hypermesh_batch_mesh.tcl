# hypermesh_batch_mesh.tcl
#
# NOTE: kept as supplementary, documented HyperMesh meshing skill evidence.
# HyperMesh Student Edition can only export to OptiStruct/RADIOSS format
# (.fem), not the ANSYS .cdb this script originally targeted, so the
# project's actual mesh+solve pipeline now runs natively in ANSYS
# Mechanical instead (see fea_scripts/ANSYS_MECHANICAL_WORKFLOW.md).
# This script still works for meshing the same geometry in HyperMesh and
# exporting an OptiStruct deck -- change the *exportfewithdata line's
# solver string from "ANSYS" to "OptiStruct" to match the Student Edition.
#
# HyperMesh batch-meshing skeleton: imports a CAD geometry file, applies a
# target element size, generates a 2D/3D mesh, and exports a solver-ready
# deck. Intended to be called once per parameter configuration from a
# Python driver script.
#
# Usage (from HyperMesh -batch or hw_tcl shell):
#   hm_tcl_script hypermesh_batch_mesh.tcl <input_geom.stp> <element_size_mm> <output_deck>

*createmark components 1 "all"
*loadfromtemplate "mesh_only"

# --- 1. Import CAD geometry (STEP/Parasolid export from PTC Creo/CATIA) ---
# TODO: set $geom_file from argv when run non-interactively
set geom_file [lindex $argv 0]
*feinputwithdata "geom" "$geom_file" 0 0 0 0 0 0 0

# --- 2. Set target element size and mesh ---
# TODO: set $elem_size from argv (default 3 mm for a first pass)
set elem_size [lindex $argv 1]
*setvalue elementorder ELEMENT_ORDER=0
*meshset elemsize $elem_size
*surfacemesh 1 3 $elem_size 0 0

# NOTE: For the mesh-convergence study referenced in the README, run this
# script multiple times with decreasing $elem_size (e.g. 5, 3, 1.5, 1 mm)
# and confirm the FEA max-stress result stabilizes before trusting it.

# --- 3. Export solver deck for ANSYS ---
set out_file [lindex $argv 2]
*createstringarray 1 "ANSYS"
*exportfewithdata "$out_file" 1 0 0 0 0

puts "Meshed $geom_file at element size $elem_size mm -> $out_file"
