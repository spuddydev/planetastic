extends GutTest
## Tests for SpherePerturber — edge rotation.


func test_determinism() -> void:
	# Same seed should produce identical results.
	var data_a := SphereGenerator.generate(1)
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 42
	SpherePerturber.perturb(data_a, 0.5, rng_a)

	var data_b := SphereGenerator.generate(1)
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 42
	SpherePerturber.perturb(data_b, 0.5, rng_b)

	assert_eq(data_a.triangles, data_b.triangles, "same seed should produce same triangles")


func test_valence_constraints() -> void:
	# After perturbation, all vertices should have valence 5-7.
	var data := SphereGenerator.generate(2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	SpherePerturber.perturb(data, 1.0, rng)

	for vi in data.vertices.size():
		var valence := data.get_vertex_neighbour_count(vi)
		assert_true(
			valence >= 5 and valence <= 7,
			"vertex %d valence %d should be in [5, 7]" % [vi, valence],
		)


func test_triangle_count_unchanged() -> void:
	# Edge rotation doesn't add or remove triangles.
	var data := SphereGenerator.generate(1)
	var original_count := data.get_triangle_count()
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	SpherePerturber.perturb(data, 0.5, rng)
	assert_eq(data.get_triangle_count(), original_count, "triangle count should not change")


func test_vertex_count_unchanged() -> void:
	# Edge rotation doesn't add or remove vertices.
	var data := SphereGenerator.generate(1)
	var original_count := data.vertices.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	SpherePerturber.perturb(data, 0.5, rng)
	assert_eq(data.vertices.size(), original_count, "vertex count should not change")


func test_zero_distortion_no_change() -> void:
	var data := SphereGenerator.generate(1)
	var original_tris := data.triangles.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	SpherePerturber.perturb(data, 0.0, rng)
	assert_eq(data.triangles, original_tris, "zero distortion should not change triangles")
