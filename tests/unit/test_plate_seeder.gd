extends GutTest
## Tests for PlateSeeder — plate assignment via seed selection and BFS flood-fill.

var _cells: Array[DualCell]
var _plate_count: int = 8
var _oceanic_ratio: float = 0.6


func before_each() -> void:
	var data := SphereGenerator.generate(2)
	_cells = DualMeshBuilder.build(data)


func _seed_plates(seed_value: int = 42) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return PlateSeeder.seed_plates(_cells, _plate_count, _oceanic_ratio, rng, 0.3, 1.0, 0.75, 1.0)


func test_correct_plate_count() -> void:
	var result := _seed_plates()
	var plates: Array[Plate] = result["plates"]
	assert_eq(plates.size(), _plate_count, "should create requested number of plates")


func test_every_cell_assigned() -> void:
	var result := _seed_plates()
	var cell_plate_map: PackedInt32Array = result["cell_plate_map"]
	for i in cell_plate_map.size():
		assert_true(
			cell_plate_map[i] >= 0,
			"cell %d should be assigned to a plate (got %d)" % [i, cell_plate_map[i]],
		)


func test_cell_plate_map_size_matches_cells() -> void:
	var result := _seed_plates()
	var cell_plate_map: PackedInt32Array = result["cell_plate_map"]
	assert_eq(
		cell_plate_map.size(),
		_cells.size(),
		"cell_plate_map should have one entry per cell",
	)


func test_plate_ids_within_range() -> void:
	var result := _seed_plates()
	var cell_plate_map: PackedInt32Array = result["cell_plate_map"]
	for i in cell_plate_map.size():
		assert_true(
			cell_plate_map[i] >= 0 and cell_plate_map[i] < _plate_count,
			"cell %d plate_id %d should be in [0, %d)" % [i, cell_plate_map[i], _plate_count],
		)


func test_cell_indices_consistent_with_map() -> void:
	# Each plate's cell_indices should match the cells mapped to it
	var result := _seed_plates()
	var plates: Array[Plate] = result["plates"]
	var cell_plate_map: PackedInt32Array = result["cell_plate_map"]

	for plate in plates:
		for idx in plate.cell_indices:
			assert_eq(
				cell_plate_map[idx],
				plate.id,
				(
					"cell %d in plate %d cell_indices but map says %d"
					% [idx, plate.id, cell_plate_map[idx]]
				),
			)


func test_all_cells_covered_by_plates() -> void:
	# The union of all plate cell_indices should cover every cell exactly once
	var result := _seed_plates()
	var plates: Array[Plate] = result["plates"]
	var total := 0
	for plate in plates:
		total += plate.cell_indices.size()
	assert_eq(total, _cells.size(), "sum of plate cell counts should equal total cells")


func test_oceanic_continental_ratio() -> void:
	var result := _seed_plates()
	var plates: Array[Plate] = result["plates"]
	var oceanic_count := 0
	for plate in plates:
		if plate.type == Plate.Type.OCEANIC:
			oceanic_count += 1
	var expected := roundi(_plate_count * _oceanic_ratio)
	assert_eq(oceanic_count, expected, "oceanic count should match ratio")


func test_desired_elevation_within_type_range() -> void:
	var result := _seed_plates()
	var plates: Array[Plate] = result["plates"]
	for plate in plates:
		if plate.type == Plate.Type.OCEANIC:
			assert_true(
				(
					plate.desired_elevation >= PlateSeeder.OCEANIC_ELEVATION_MIN
					and plate.desired_elevation <= PlateSeeder.OCEANIC_ELEVATION_MAX
				),
				"oceanic plate %d elevation %f out of range" % [plate.id, plate.desired_elevation],
			)
		else:
			assert_true(
				(
					plate.desired_elevation >= PlateSeeder.CONTINENTAL_ELEVATION_MIN
					and plate.desired_elevation <= PlateSeeder.CONTINENTAL_ELEVATION_MAX
				),
				(
					"continental plate %d elevation %f out of range"
					% [plate.id, plate.desired_elevation]
				),
			)


func test_movement_vectors_are_nonzero() -> void:
	# Every plate should have a non-zero movement vector
	var result := _seed_plates()
	var plates: Array[Plate] = result["plates"]
	for plate in plates:
		assert_true(
			plate.movement.length() > 0.0,
			"plate %d should have non-zero movement" % plate.id,
		)


func test_plate_centres_on_unit_sphere() -> void:
	var result := _seed_plates()
	var plates: Array[Plate] = result["plates"]
	for plate in plates:
		assert_almost_eq(
			plate.centre.length(),
			1.0,
			0.01,
			"plate %d centre should be on unit sphere" % plate.id,
		)


func test_plates_are_contiguous() -> void:
	# Every cell in a plate should be reachable from every other cell in the
	# same plate through same-plate neighbours
	var result := _seed_plates()
	var plates: Array[Plate] = result["plates"]
	var cell_plate_map: PackedInt32Array = result["cell_plate_map"]

	for plate in plates:
		if plate.cell_indices.is_empty():
			continue

		# BFS from the first cell in this plate
		var visited := {}
		var queue: Array[int] = [plate.cell_indices[0]]
		visited[plate.cell_indices[0]] = true

		while not queue.is_empty():
			var current: int = queue.pop_front()
			for ni in _cells[current].neighbour_indices:
				if cell_plate_map[ni] == plate.id and not visited.has(ni):
					visited[ni] = true
					queue.append(ni)

		assert_eq(
			visited.size(),
			plate.cell_indices.size(),
			(
				"plate %d should be contiguous (visited %d of %d cells)"
				% [plate.id, visited.size(), plate.cell_indices.size()]
			),
		)


func test_deterministic_same_seed() -> void:
	var result_a := _seed_plates(99)
	var result_b := _seed_plates(99)
	var map_a: PackedInt32Array = result_a["cell_plate_map"]
	var map_b: PackedInt32Array = result_b["cell_plate_map"]

	assert_eq(map_a.size(), map_b.size(), "maps should be same size")
	for i in map_a.size():
		assert_eq(map_a[i], map_b[i], "cell %d plate should be identical with same seed" % i)


func test_different_seed_produces_different_result() -> void:
	var result_a := _seed_plates(1)
	var result_b := _seed_plates(2)
	var map_a: PackedInt32Array = result_a["cell_plate_map"]
	var map_b: PackedInt32Array = result_b["cell_plate_map"]

	var differences := 0
	for i in map_a.size():
		if map_a[i] != map_b[i]:
			differences += 1
	assert_true(differences > 0, "different seeds should produce different plate assignments")


func test_no_empty_plates() -> void:
	var result := _seed_plates()
	var plates: Array[Plate] = result["plates"]
	for plate in plates:
		assert_true(
			plate.cell_indices.size() > 0,
			"plate %d should have at least one cell" % plate.id,
		)
