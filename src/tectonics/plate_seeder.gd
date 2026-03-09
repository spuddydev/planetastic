class_name PlateSeeder
extends RefCounted
## Seeds tectonic plates across the sphere and assigns every cell to a plate.
##
## Uses farthest-point heuristic for seed placement, then simultaneous BFS
## flood-fill to grow plates into roughly equal, organic shapes.

const OCEANIC_ELEVATION_MIN := -1
const OCEANIC_ELEVATION_MAX := 0
const CONTINENTAL_ELEVATION_MIN := 0
const CONTINENTAL_ELEVATION_MAX := 1

const TANGENT_EPSILON := 0.0001


## Seed plates and assign every cell to one. Returns a dictionary with:
##   "plates": Array[Plate] — the generated plates
##   "cell_plate_map": PackedInt32Array — plate id for each cell (indexed by cell index)
static func seed_plates(
	cells: Array[DualCell],
	plate_count: int,
	oceanic_ratio: float,
	rng: RandomNumberGenerator,
	speed_min: float,
	speed_max: float,
	growth_min: float,
	growth_max: float,
) -> Dictionary:
	var count := mini(plate_count, cells.size())
	var seed_indices := _pick_seeds(cells, count, rng)
	var plates := _create_plates(seed_indices, cells, count)
	_assign_types(plates, oceanic_ratio, rng)
	_assign_desired_elevations(plates, rng)
	_assign_movements(plates, rng, speed_min, speed_max)

	var cell_plate_map := _flood_fill(cells, plates, rng, growth_min, growth_max)
	_recompute_centres(cells, plates)

	return {"plates": plates, "cell_plate_map": cell_plate_map}


## Pick seed cells randomly across the sphere
static func _pick_seeds(
	cells: Array[DualCell],
	count: int,
	rng: RandomNumberGenerator,
) -> PackedInt32Array:
	var seeds := PackedInt32Array()
	var used := {}
	for _i in count:
		var idx := rng.randi_range(0, cells.size() - 1)
		while used.has(idx):
			idx = rng.randi_range(0, cells.size() - 1)
		used[idx] = true
		seeds.append(idx)
	return seeds


## Create plate objects from seed indices
static func _create_plates(
	seed_indices: PackedInt32Array,
	cells: Array[DualCell],
	count: int,
) -> Array[Plate]:
	var plates: Array[Plate] = []
	for i in count:
		var plate := Plate.new()
		plate.id = i
		plate.centre = cells[seed_indices[i]].center
		plates.append(plate)
	return plates


## Randomly assign oceanic/continental types respecting the ratio
static func _assign_types(
	plates: Array[Plate],
	oceanic_ratio: float,
	rng: RandomNumberGenerator,
) -> void:
	var count := plates.size()
	var oceanic_count := roundi(count * oceanic_ratio)

	# Build shuffled type list
	var types: Array[int] = []
	for i in count:
		if i < oceanic_count:
			types.append(Plate.Type.OCEANIC)
		else:
			types.append(Plate.Type.CONTINENTAL)

	# Fisher-Yates shuffle with seeded rng
	for i in range(count - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := types[i]
		types[i] = types[j]
		types[j] = tmp

	for i in count:
		plates[i].type = types[i] as Plate.Type


## Randomise desired elevation within type range
static func _assign_desired_elevations(
	plates: Array[Plate],
	rng: RandomNumberGenerator,
) -> void:
	for plate in plates:
		if plate.type == Plate.Type.OCEANIC:
			plate.desired_elevation = rng.randf_range(OCEANIC_ELEVATION_MIN, OCEANIC_ELEVATION_MAX)
		else:
			plate.desired_elevation = rng.randf_range(
				CONTINENTAL_ELEVATION_MIN, CONTINENTAL_ELEVATION_MAX
			)


## Generate random tangent movement vectors at each plate's centre
static func _assign_movements(
	plates: Array[Plate],
	rng: RandomNumberGenerator,
	speed_min: float,
	speed_max: float,
) -> void:
	for plate in plates:
		var random_vec := Vector3(
			rng.randf_range(-1.0, 1.0),
			rng.randf_range(-1.0, 1.0),
			rng.randf_range(-1.0, 1.0),
		)
		# Project onto tangent plane: subtract component along centre normal
		var normal := plate.centre.normalized()
		var tangent := random_vec - normal * random_vec.dot(normal)
		if tangent.length_squared() < TANGENT_EPSILON:
			tangent = normal.cross(Vector3.UP)
			if tangent.length_squared() < TANGENT_EPSILON:
				tangent = normal.cross(Vector3.RIGHT)
		tangent = tangent.normalized()

		# Scale by random speed
		var speed := rng.randf_range(speed_min, speed_max)
		plate.movement = tangent * speed


## Weighted BFS flood-fill from all seeds. Each plate gets a random growth
## rate so some plates grow faster than others, producing varied sizes.
## Returns cell-to-plate map
static func _flood_fill(
	cells: Array[DualCell],
	plates: Array[Plate],
	rng: RandomNumberGenerator,
	growth_min: float,
	growth_max: float,
) -> PackedInt32Array:
	var cell_count := cells.size()
	var cell_plate_map := PackedInt32Array()
	cell_plate_map.resize(cell_count)
	cell_plate_map.fill(-1)

	# Random growth rate per plate (0.3 = slow/small, 2.0 = fast/large)
	var growth_rates := PackedFloat32Array()
	growth_rates.resize(plates.size())
	for i in plates.size():
		growth_rates[i] = rng.randf_range(growth_min, growth_max)

	# Initialise frontiers with seed cells (one per plate)
	var frontiers: Array[Array] = []
	for plate in plates:
		# Find the closest cell to the plate centre (the seed)
		var best_idx := 0
		var best_dist := INF
		for i in cell_count:
			var d := cells[i].center.distance_squared_to(plate.centre)
			if d < best_dist:
				best_dist = d
				best_idx = i
		cell_plate_map[best_idx] = plate.id
		plate.cell_indices.append(best_idx)
		frontiers.append([best_idx])

	# Weighted BFS: accumulate growth rate each round, expand when >= 1.0
	var accumulators := PackedFloat32Array()
	accumulators.resize(plates.size())
	accumulators.fill(0.0)

	var assigned := plates.size()
	while assigned < cell_count:
		for plate_idx in plates.size():
			var frontier: Array = frontiers[plate_idx]
			if frontier.is_empty():
				continue

			accumulators[plate_idx] += growth_rates[plate_idx]
			if accumulators[plate_idx] < 1.0:
				continue
			accumulators[plate_idx] -= 1.0

			var next_frontier: Array = []
			for cell_idx: int in frontier:
				for neighbour_idx in cells[cell_idx].neighbour_indices:
					if cell_plate_map[neighbour_idx] == -1:
						cell_plate_map[neighbour_idx] = plate_idx
						plates[plate_idx].cell_indices.append(neighbour_idx)
						next_frontier.append(neighbour_idx)
						assigned += 1
			frontiers[plate_idx] = next_frontier

	return cell_plate_map


## Recompute plate centres as average of member cell positions
static func _recompute_centres(
	cells: Array[DualCell],
	plates: Array[Plate],
) -> void:
	for plate in plates:
		if plate.cell_indices.is_empty():
			continue
		var sum := Vector3.ZERO
		for idx in plate.cell_indices:
			sum += cells[idx].center
		plate.centre = (sum / plate.cell_indices.size()).normalized()
