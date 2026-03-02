extends GutTest
## Tests for DualMeshBuilder — triangle mesh to dual cells.

var _data: SphereData


func before_each() -> void:
	_data = SphereGenerator.generate(1)


func test_cell_count_equals_vertex_count() -> void:
	var cells := DualMeshBuilder.build(_data)
	assert_eq(cells.size(), _data.vertices.size(), "one cell per vertex")


func test_cell_corners_on_unit_sphere() -> void:
	var cells := DualMeshBuilder.build(_data)
	for i in cells.size():
		for j in cells[i].corners.size():
			assert_almost_eq(
				cells[i].corners[j].length(),
				1.0,
				0.01,
				"cell %d corner %d should be on unit sphere" % [i, j],
			)


func test_pentagon_count_at_base() -> void:
	# An unperturbed level 1 icosphere should have exactly 12 pentagons
	# (the original icosahedron vertices) and the rest hexagons.
	var cells := DualMeshBuilder.build(_data)
	var pentagons := 0
	var hexagons := 0
	for cell in cells:
		if cell.corners.size() == 5:
			pentagons += 1
		elif cell.corners.size() == 6:
			hexagons += 1
	assert_eq(pentagons, 12, "should have exactly 12 pentagons")
	assert_eq(hexagons, _data.vertices.size() - 12, "remaining should be hexagons")


func test_neighbour_symmetry() -> void:
	# If cell A lists cell B as a neighbour, cell B should list cell A.
	var cells := DualMeshBuilder.build(_data)
	for i in cells.size():
		for ni in cells[i].neighbour_indices:
			if ni == -1:
				continue
			var found := false
			for nj in cells[ni].neighbour_indices:
				if nj == i:
					found = true
					break
			assert_true(found, "cell %d neighbours %d, but not vice versa" % [i, ni])


func test_no_negative_neighbour_indices() -> void:
	# Every cell should have valid neighbour indices (no -1 failures).
	var cells := DualMeshBuilder.build(_data)
	for i in cells.size():
		for ni in cells[i].neighbour_indices:
			assert_true(ni >= 0, "cell %d has invalid neighbour index %d" % [i, ni])


func test_neighbour_count_matches_corner_count() -> void:
	# Each cell should have exactly as many neighbours as corners.
	var cells := DualMeshBuilder.build(_data)
	for i in cells.size():
		assert_eq(
			cells[i].neighbour_indices.size(),
			cells[i].corners.size(),
			"cell %d neighbour count should match corner count" % i,
		)


func test_neighbours_correct_after_perturbation() -> void:
	# After perturbation (which changes topology), neighbour symmetry and
	# validity should still hold — validates that tracked triangle indices
	# work correctly with modified meshes.
	var data := SphereGenerator.generate(2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	SpherePerturber.perturb(data, 0.7, rng)

	var cells := DualMeshBuilder.build(data)

	for i in cells.size():
		# No -1 neighbours.
		for ni in cells[i].neighbour_indices:
			assert_true(ni >= 0, "cell %d has invalid neighbour after perturbation" % i)

		# Symmetry: if I list you, you list me.
		for ni in cells[i].neighbour_indices:
			var found := false
			for nj in cells[ni].neighbour_indices:
				if nj == i:
					found = true
					break
			assert_true(
				found,
				"cell %d neighbours %d after perturbation, but not vice versa" % [i, ni],
			)
