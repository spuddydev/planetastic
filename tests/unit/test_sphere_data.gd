extends GutTest
## Tests for SphereData — adjacency caches and incremental updates.


func test_incremental_matches_full_rebuild() -> void:
	# After perturbing (which uses register/unregister), the adjacency caches
	# should exactly match a full build_adjacency() rebuild.
	var data := SphereGenerator.generate(2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	SpherePerturber.perturb(data, 0.7, rng)

	# Snapshot the incrementally maintained adjacency.
	var inc_vertex_tris: Array = []
	for vi in data.vertices.size():
		inc_vertex_tris.append(data.get_vertex_triangles(vi).duplicate())

	var inc_edge_keys: Array = data.get_all_edges().duplicate()
	var inc_edge_tris: Dictionary = {}
	for key: Vector2i in inc_edge_keys:
		inc_edge_tris[key] = data.get_edge_triangles(key.x, key.y).duplicate()

	# Full rebuild from scratch.
	data.build_adjacency()

	# Compare vertex → triangle caches.
	for vi in data.vertices.size():
		var rebuilt := data.get_vertex_triangles(vi).duplicate()
		var incremental: PackedInt32Array = inc_vertex_tris[vi]
		# Sort both so order doesn't matter.
		rebuilt.sort()
		incremental.sort()
		assert_eq(
			incremental,
			rebuilt,
			"vertex %d triangle cache should match full rebuild" % vi,
		)

	# Compare edge → triangle caches.
	var rebuilt_edges: Array = data.get_all_edges()
	assert_eq(
		inc_edge_keys.size(),
		rebuilt_edges.size(),
		"edge count should match full rebuild",
	)
	for key: Vector2i in rebuilt_edges:
		assert_true(inc_edge_tris.has(key), "incremental should have edge %s" % str(key))
		if inc_edge_tris.has(key):
			var rebuilt_adj := data.get_edge_triangles(key.x, key.y).duplicate()
			var inc_adj: PackedInt32Array = inc_edge_tris[key]
			rebuilt_adj.sort()
			inc_adj.sort()
			assert_eq(
				inc_adj,
				rebuilt_adj,
				"edge %s triangle cache should match full rebuild" % str(key),
			)


func test_register_unregister_roundtrip() -> void:
	# Unregistering then re-registering a triangle should restore adjacency.
	var data := SphereGenerator.generate(1)

	# Snapshot original adjacency for triangle 0.
	var tri := data.get_triangle(0)
	var verts := [tri.x, tri.y, tri.z]
	var original_valences: Array[int] = []
	for v: int in verts:
		original_valences.append(data.get_vertex_valence(v))

	# Unregister — valence should decrease.
	data.unregister_triangle(0)
	for i in verts.size():
		assert_eq(
			data.get_vertex_valence(verts[i]),
			original_valences[i] - 1,
			"vertex %d valence should decrease by 1" % verts[i],
		)

	# Re-register — valence should restore.
	data.register_triangle(0)
	for i in verts.size():
		assert_eq(
			data.get_vertex_valence(verts[i]),
			original_valences[i],
			"vertex %d valence should be restored" % verts[i],
		)


func test_edge_triangles_on_closed_mesh() -> void:
	# On a closed mesh every edge should have exactly 2 adjacent triangles.
	var data := SphereGenerator.generate(1)
	for key: Vector2i in data.get_all_edges():
		var adj := data.get_edge_triangles(key.x, key.y)
		assert_eq(adj.size(), 2, "edge %s should have 2 adjacent triangles" % str(key))
