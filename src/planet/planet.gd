@tool
class_name Planet
extends Node3D
## Procedural planet generator — orchestrates the sphere generation pipeline.
##
## Attach to a Node3D in a scene. Exports are editable in the Inspector and
## trigger live regeneration in the editor thanks to @tool.

## Number of interleaved perturbation and relaxation rounds.
const INTERLEAVE_ROUNDS := 6

## Seed for deterministic generation. Same seed = same planet.
@export var planet_seed: int = 0:
	set = _set_seed

## Subdivision level. 0 = 20 triangles, each level multiplies by 4.
## Level 3 (1280 triangles) is a good starting point.
@export_range(0, 6) var level: int = 4:
	set = _set_level

## How much to break the regular icosahedron pattern (0 = none, 1 = maximum).
@export_range(0.0, 1.0, 0.01) var distortion: float = 0.7:
	set = _set_distortion

## Radius of the planet mesh in world units.
@export_range(0.1, 1000.0) var radius: float = 100.0:
	set = _set_radius

## Generation method resource (e.g. TectonicGeneration). Assign in the
## inspector to control how elevation, moisture, etc. are computed.
@export var generation_method: GenerationMethod:
	set = _set_generation_method

## Generated sphere topology — kept for future systems (tectonics, biomes, etc.).
var sphere_data: SphereData

## Dual cells (Voronoi-like tiles) — kept for future systems.
var cells: Array[DualCell]

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _dirty := true


func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	# In-editor children need this to not be saved into the scene file
	_mesh_instance.owner = null

	# Placeholder material for development; the game will provide its own
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.cull_mode = BaseMaterial3D.CULL_BACK
	_mesh_instance.material_override = _material

	_dirty = false
	_regenerate()


func _process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		_regenerate()


func _set_seed(value: int) -> void:
	planet_seed = value
	_dirty = true


func _set_level(value: int) -> void:
	level = value
	_dirty = true


func _set_distortion(value: float) -> void:
	distortion = value
	_dirty = true


func _set_radius(value: float) -> void:
	radius = value
	_dirty = true


func _set_generation_method(value: GenerationMethod) -> void:
	generation_method = value
	_dirty = true


func _regenerate() -> void:
	if not _mesh_instance:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(planet_seed)

	# Generate subdivided icosahedron
	sphere_data = SphereGenerator.generate(level)

	# Interleaved perturbation and relaxation for organic irregularity
	if distortion > 0.0:
		var ideal_dist := SphereRelaxer.compute_ideal_distance(sphere_data)
		var partial_distortion := distortion / INTERLEAVE_ROUNDS
		for _round in INTERLEAVE_ROUNDS:
			SpherePerturber.perturb(sphere_data, partial_distortion, rng)
			SphereRelaxer.relax_pass(sphere_data, ideal_dist)
		SphereRelaxer.relax_until_converged(sphere_data)

	# Build dual polyhedron (Voronoi-like tiles)
	cells = DualMeshBuilder.build(sphere_data)

	# Run generation method (elevation, moisture, biomes, etc.)
	if generation_method:
		var gen_rng := RandomNumberGenerator.new()
		gen_rng.seed = hash(planet_seed)
		generation_method.generate(cells, gen_rng)

	# Convert to renderable mesh
	_mesh_instance.mesh = SphereMeshBuilder.build_mesh(cells, radius)
