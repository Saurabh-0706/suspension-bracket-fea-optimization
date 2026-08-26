# CAD

Place the parametric bracket CAD file here (PTC Creo `.prt`/`.asm` or CATIA `.CATPart`), along with its design table (Excel/CSV) that exposes:

- base plate thickness
- rib height/thickness
- fillet radius
- mounting-hole diameter and spacing

Export each configuration used in the parameter sweep as a neutral STEP file (`bracket_<config_name>.stp`) for `mesh_scripts/hypermesh_batch_mesh.tcl` to consume.
