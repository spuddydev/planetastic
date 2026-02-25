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


func test_neighbor_symmetry() -> void:
	# If cell A lists cell B as a neighbor, cell B should list cell A.
	var cells := DualMeshBuilder.build(_data)
	for i in cells.size():
		for ni in cells[i].neighbor_indices:
			if ni == -1:
				continue
			var found := false
			for nj in cells[ni].neighbor_indices:
				if nj == i:
					found = true
					break
			assert_true(found, "cell %d neighbors %d, but not vice versa" % [i, ni])
