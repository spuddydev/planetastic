class_name TectonicGeneration
extends GenerationMethod
## Generates elevation via tectonic plate simulation.
##
## Assigns cells to plates, classifies boundary stress, and computes elevation
## from plate interactions. Assign this resource to planet.gd's
## generation_method export.

## Number of tectonic plates to generate
@export var plate_count: int = 12

## Ratio of oceanic to total plates (0.0 = all continental, 1.0 = all oceanic)
@export_range(0.0, 1.0, 0.01) var oceanic_ratio: float = 0.6

## Generated plates, available after generate() for later batches
var plates: Array[Plate]

## Maps cell index to plate id, available after generate()
var cell_plate_map: PackedInt32Array


func generate(_cells: Array[DualCell], _rng: RandomNumberGenerator) -> void:
	pass


func get_generation_name() -> String:
	return "Tectonic"


func get_provided_fields() -> PackedStringArray:
	return PackedStringArray(["elevation"])
