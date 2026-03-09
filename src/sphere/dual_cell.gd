class_name DualCell
extends RefCounted
## One tile in the dual polyhedron — a polygon on the sphere surface.
##
## Each cell corresponds to a vertex in the original triangle mesh.
## Pentagons (5 corners) come from vertices with 5 neighbour triangles,
## hexagons (6) from vertices with 6, heptagons (7) from vertices with 7.

## Center of this cell (the original triangle mesh vertex, on unit sphere).
var center: Vector3

## Corner positions in CCW order (triangle centroids, on unit sphere).
var corners: PackedVector3Array

## Indices of neighbouring cells, matching corner order. neighbour_indices[i]
## is the cell that shares the edge between corners[i] and corners[i+1].
var neighbour_indices: PackedInt32Array

## Normalised elevation (0.0-1.0). NAN means not yet computed
var elevation: float = NAN

## Normalised moisture (0.0-1.0). NAN means not yet computed
var moisture: float = NAN

## Normalised temperature (0.0-1.0). NAN means not yet computed
var temperature: float = NAN

## Biome classification index (-1 = unassigned)
var biome: int = -1

## Display colour set by the generation method. Transparent = use default
var colour: Color = Color.TRANSPARENT
