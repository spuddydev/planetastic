extends GutTest
## Tests for SphereGenerator — base icosahedron and subdivision.


func test_base_icosahedron_vertex_count() -> void:
	var data := SphereGenerator.generate(0)
	assert_eq(data.vertices.size(), 12, "base icosahedron should have 12 vertices")


func test_base_icosahedron_triangle_count() -> void:
	var data := SphereGenerator.generate(0)
	assert_eq(data.get_triangle_count(), 20, "base icosahedron should have 20 triangles")


func test_level_1_vertex_count() -> void:
	var data := SphereGenerator.generate(1)
	# Formula: 10 * 4^level + 2
	assert_eq(data.vertices.size(), 42, "level 1 should have 42 vertices")


func test_level_1_triangle_count() -> void:
	var data := SphereGenerator.generate(1)
	# Formula: 20 * 4^level
	assert_eq(data.get_triangle_count(), 80, "level 1 should have 80 triangles")


func test_level_2_counts() -> void:
	var data := SphereGenerator.generate(2)
	assert_eq(data.vertices.size(), 162)
	assert_eq(data.get_triangle_count(), 320)


func test_all_vertices_on_unit_sphere() -> void:
	var data := SphereGenerator.generate(2)
	for i in data.vertices.size():
		assert_almost_eq(
			data.vertices[i].length(),
			1.0,
			0.0001,
			"vertex %d should be on unit sphere" % i,
		)


func test_all_edges_shared_by_exactly_two_triangles() -> void:
	var data := SphereGenerator.generate(1)
	# On a closed mesh, every edge borders exactly 2 triangles.
	for ti in data.get_triangle_count():
		var tri := data.get_triangle(ti)
		for edge in [
			[tri.x, tri.y],
			[tri.y, tri.z],
			[tri.z, tri.x],
		]:
			var adj := data.get_edge_triangles(edge[0], edge[1])
			assert_eq(adj.size(), 2, "edge %d-%d should have 2 adjacent triangles" % edge)


func test_base_vertex_valence() -> void:
	# On a base icosahedron, every vertex is shared by exactly 5 triangles.
	var data := SphereGenerator.generate(0)
	for vi in data.vertices.size():
		assert_eq(
			data.get_vertex_valence(vi),
			5,
			"base icosahedron vertex %d should have valence 5" % vi,
		)


func test_subdivided_interior_vertex_valence() -> void:
	# After subdivision, the original 12 vertices keep valence 5,
	# all new (interior) vertices should have valence 6.
	var data := SphereGenerator.generate(1)
	for vi in range(12, data.vertices.size()):
		assert_eq(
			data.get_vertex_valence(vi),
			6,
			"subdivided interior vertex %d should have valence 6" % vi,
		)
