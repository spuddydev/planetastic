class_name GenerationMethod
extends Resource
## Base class for world generation layers (elevation, moisture, biomes, etc.).
##
## Subclass this Resource and override the virtual methods to create a new
## generation strategy. Assign the resource to planet.gd's generation_method
## export to swap strategies in the inspector.


## Populate cell data (elevation, moisture, etc.) for the given cells.
## Subclasses must override this with their generation logic.
func generate(_cells: Array[DualCell], _rng: RandomNumberGenerator) -> void:
	pass


## Human-readable name for UI and debugging (e.g. "Tectonic").
func get_generation_name() -> String:
	return ""


## Which DualCell fields this method populates (e.g. ["elevation"]).
## The renderer can check this to know what data is available.
func get_provided_fields() -> PackedStringArray:
	return PackedStringArray()
