@tool
class_name TectonicGeneration
extends GenerationMethod
## Generates elevation via tectonic plate simulation.
##
## Assigns cells to plates, classifies boundary stress, and computes elevation
## from plate interactions. Assign this resource to planet.gd's
## generation_method export.

## Number of tectonic plates to generate
@export var plate_count: int = 30

## Ratio of oceanic to total plates (0.0 = all continental, 1.0 = all oceanic)
@export_range(0.0, 1.0, 0.01) var oceanic_ratio: float = 0.35

## Generated plates, available after generate() for later batches
var plates: Array[Plate]

## Maps cell index to plate id, available after generate()
var cell_plate_map: PackedInt32Array


func generate(cells: Array[DualCell], rng: RandomNumberGenerator) -> void:
	var result := PlateSeeder.seed_plates(cells, plate_count, oceanic_ratio, rng)
	plates = result["plates"]
	cell_plate_map = result["cell_plate_map"]
	_colour_by_plate(cells, rng)


func get_generation_name() -> String:
	return "Tectonic"


func get_provided_fields() -> PackedStringArray:
	return PackedStringArray(["elevation"])


## Assign each cell a colour based on its plate
func _colour_by_plate(cells: Array[DualCell], rng: RandomNumberGenerator) -> void:
	var plate_colours: PackedColorArray = PackedColorArray()
	plate_colours.resize(plates.size())
	for plate in plates:
		if plate.type == Plate.Type.OCEANIC:
			plate_colours[plate.id] = Color.from_hsv(0.65, 0.9, 0.25)
		else:
			var hue := rng.randf()
			var sat := rng.randf_range(0.4, 1.0)
			var val := rng.randf_range(0.5, 0.95)
			plate_colours[plate.id] = Color.from_hsv(hue, sat, val)

	for idx in cells.size():
		cells[idx].colour = plate_colours[cell_plate_map[idx]]
