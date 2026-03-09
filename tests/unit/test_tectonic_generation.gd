extends GutTest
## Tests for TectonicGeneration — orchestration and end-to-end determinism.

var _cells: Array[DualCell]


func before_each() -> void:
	var data := SphereGenerator.generate(2)
	_cells = DualMeshBuilder.build(data)


func _run_generation(cells: Array[DualCell], seed_value: int = 42) -> TectonicGeneration:
	var gen := TectonicGeneration.new()
	gen.plate_count = 10
	gen.oceanic_ratio = 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	gen.generate(cells, rng)
	return gen


func test_generate_produces_plates() -> void:
	var gen := _run_generation(_cells)
	assert_eq(gen.plates.size(), 10, "should produce requested plate count")


func test_generate_fills_cell_plate_map() -> void:
	var gen := _run_generation(_cells)
	assert_eq(
		gen.cell_plate_map.size(),
		_cells.size(),
		"cell_plate_map should cover all cells",
	)
	for i in gen.cell_plate_map.size():
		assert_true(gen.cell_plate_map[i] >= 0, "cell %d should be assigned" % i)


func test_generate_sets_cell_colours() -> void:
	var gen := _run_generation(_cells)
	# TectonicGeneration colours cells by plate; all should be non-transparent
	for i in _cells.size():
		assert_true(
			_cells[i].colour.a > 0.0,
			"cell %d should have a colour set (got %s)" % [i, _cells[i].colour],
		)


func test_generation_name() -> void:
	var gen := TectonicGeneration.new()
	assert_eq(gen.get_generation_name(), "Tectonic")


func test_provided_fields() -> void:
	var gen := TectonicGeneration.new()
	var fields := gen.get_provided_fields()
	assert_true(fields.has("elevation"), "should declare elevation")


func test_end_to_end_determinism() -> void:
	# Same seed, same cells = identical results
	var data_a := SphereGenerator.generate(2)
	var cells_a := DualMeshBuilder.build(data_a)
	var gen_a := _run_generation(cells_a, 77)

	var data_b := SphereGenerator.generate(2)
	var cells_b := DualMeshBuilder.build(data_b)
	var gen_b := _run_generation(cells_b, 77)

	assert_eq(gen_a.cell_plate_map.size(), gen_b.cell_plate_map.size())
	for i in gen_a.cell_plate_map.size():
		assert_eq(
			gen_a.cell_plate_map[i],
			gen_b.cell_plate_map[i],
			"cell %d plate should match with same seed" % i,
		)


func test_different_seed_differs() -> void:
	var data_a := SphereGenerator.generate(2)
	var cells_a := DualMeshBuilder.build(data_a)
	var gen_a := _run_generation(cells_a, 1)

	var data_b := SphereGenerator.generate(2)
	var cells_b := DualMeshBuilder.build(data_b)
	var gen_b := _run_generation(cells_b, 2)

	var differences := 0
	for i in gen_a.cell_plate_map.size():
		if gen_a.cell_plate_map[i] != gen_b.cell_plate_map[i]:
			differences += 1
	assert_true(differences > 0, "different seeds should produce different results")


func test_plate_types_are_valid() -> void:
	var gen := _run_generation(_cells)
	for plate in gen.plates:
		assert_true(
			plate.type == Plate.Type.OCEANIC or plate.type == Plate.Type.CONTINENTAL,
			"plate %d should have a valid type" % plate.id,
		)
