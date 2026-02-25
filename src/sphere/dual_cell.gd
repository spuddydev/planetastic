class_name DualCell
extends RefCounted
## One tile in the dual polyhedron — a polygon on the sphere surface.
##
## Each cell corresponds to a vertex in the original triangle mesh.
## Pentagons (5 corners) come from vertices with 5 neighbor triangles,
## hexagons (6) from vertices with 6, heptagons (7) from vertices with 7.

## Center of this cell (the original triangle mesh vertex, on unit sphere).
var center: Vector3

## Corner positions in CCW order (triangle centroids, on unit sphere).
var corners: PackedVector3Array

## Indices of neighboring cells, matching corner order. neighbor_indices[i]
## is the cell that shares the edge between corners[i] and corners[i+1].
var neighbor_indices: PackedInt32Array
