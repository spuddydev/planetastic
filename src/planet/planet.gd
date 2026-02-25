@tool
class_name Planet
extends Node3D
## Procedural planet generator — orchestrates the sphere generation pipeline.
##
## Attach to a Node3D in a scene. Exports are editable in the Inspector and
## trigger live regeneration in the editor thanks to @tool.

## Seed for deterministic generation. Same seed = same planet.
@export var seed: int = 0:
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

var _mesh_instance: MeshInstance3D
var _dirty := true


func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	# In-editor children need this to not be saved into the scene file.
	_mesh_instance.owner = null
	_regenerate()


func _process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		_regenerate()


func _set_seed(value: int) -> void:
	seed = value
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


func _regenerate() -> void:
	if not _mesh_instance:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed)

	# 1. Generate subdivided icosahedron.
	var data := SphereGenerator.generate(level)

	# 2. Perturb + relax for organic irregularity.
	SphereRelaxer.relax_full(data, distortion, rng)

	# 3. Build dual polyhedron (Voronoi-like tiles).
	var cells := DualMeshBuilder.build(data)

	# 4. Convert to renderable mesh.
	_mesh_instance.mesh = SphereMeshBuilder.build_mesh(cells, radius, rng)

	# Temporary: material that shows per-tile vertex colors.
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = mat
