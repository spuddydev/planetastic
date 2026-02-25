extends GutTest
## Tests for SphereRelaxer — centroid-based relaxation.


func test_vertices_stay_on_sphere() -> void:
	var data := SphereGenerator.generate(1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	SphereRelaxer.relax_full(data, 0.5, rng)

	for i in data.vertices.size():
		assert_almost_eq(
			data.vertices[i].length(),
			1.0,
			0.001,
			"vertex %d should still be on unit sphere after relaxation" % i,
		)


func test_zero_distortion_no_change() -> void:
	var data := SphereGenerator.generate(1)
	var original_verts := data.vertices.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	SphereRelaxer.relax_full(data, 0.0, rng)
	assert_eq(data.vertices, original_verts, "zero distortion should not move vertices")


func test_determinism() -> void:
	var data_a := SphereGenerator.generate(1)
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 77
	SphereRelaxer.relax_full(data_a, 0.5, rng_a)

	var data_b := SphereGenerator.generate(1)
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 77
	SphereRelaxer.relax_full(data_b, 0.5, rng_b)

	assert_eq(data_a.vertices, data_b.vertices, "same seed should produce same vertices")
	assert_eq(data_a.triangles, data_b.triangles, "same seed should produce same triangles")


func test_valence_constraints_after_full_pipeline() -> void:
	# After the full perturb+relax pipeline, valence should still be 5-7.
	var data := SphereGenerator.generate(2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	SphereRelaxer.relax_full(data, 1.0, rng)

	for vi in data.vertices.size():
		var valence := data.get_vertex_neighbor_count(vi)
		assert_true(
			valence >= 5 and valence <= 7,
			"vertex %d valence %d should be in [5, 7]" % [vi, valence],
		)
