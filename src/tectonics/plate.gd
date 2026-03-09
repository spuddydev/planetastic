class_name Plate
extends RefCounted
## Data class representing a single tectonic plate.

enum Type { OCEANIC, CONTINENTAL }

## Plate index (0 to N-1)
var id: int

## Whether this plate is oceanic or continental
var type: Type

## Tangent vector on the unit sphere at the plate's centre.
## Direction = drift direction, length = speed
var movement: Vector3

## Base elevation this plate tends toward in its interior.
## Oceanic ~0.1-0.3, continental ~0.5-0.8
var desired_elevation: float

## Indices into the cells array for cells belonging to this plate
var cell_indices: PackedInt32Array

## Plate centre on the unit sphere (seed cell position, recomputed after growth)
var centre: Vector3
