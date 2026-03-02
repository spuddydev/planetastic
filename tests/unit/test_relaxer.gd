extends GutTest
## Tests for SphereRelaxer — centroid-based relaxation.


func test_vertices_stay_on_sphere() -> void:
	var data := SphereGenerator.generate(1)
	SphereRelaxer.relax_until_converged(data)

	for i in data.vertices.size():
		assert_almost_eq(
			data.vertices[i].length(),
			1.0,
			0.001,
			"vertex %d should still be on unit sphere after relaxation" % i,
		)


func test_relax_pass_reduces_displacement() -> void:
	# A single relax pass should move vertices, and subsequent passes should
	# reduce displacement (converging towards uniform spacing).
	var data := SphereGenerator.generate(1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	SpherePerturber.perturb(data, 0.5, rng)

	var ideal_dist := SphereRelaxer.compute_ideal_distance(data)
	var first := SphereRelaxer.relax_pass(data, ideal_dist)
	var second := SphereRelaxer.relax_pass(data, ideal_dist)
	assert_true(second < first, "displacement should decrease across passes")


func test_relax_until_converged_stabilises() -> void:
	# After full convergence, an extra pass should produce near-zero displacement.
	var data := SphereGenerator.generate(1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	SpherePerturber.perturb(data, 0.5, rng)

	SphereRelaxer.relax_until_converged(data)

	var ideal_dist := SphereRelaxer.compute_ideal_distance(data)
	var extra := SphereRelaxer.relax_pass(data, ideal_dist)
	assert_true(
		extra < SphereRelaxer.CONVERGENCE_THRESHOLD,
		"should be converged after relax_until_converged",
	)


func test_compute_ideal_distance_constant_across_calls() -> void:
	# ideal distance depends only on triangle count, which doesn't change.
	var data := SphereGenerator.generate(2)
	var d1 := SphereRelaxer.compute_ideal_distance(data)
	var d2 := SphereRelaxer.compute_ideal_distance(data)
	assert_eq(d1, d2, "ideal distance should be constant for the same mesh")


func test_determinism() -> void:
	var data_a := SphereGenerator.generate(1)
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 77
	SpherePerturber.perturb(data_a, 0.5, rng_a)
	SphereRelaxer.relax_until_converged(data_a)

	var data_b := SphereGenerator.generate(1)
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 77
	SpherePerturber.perturb(data_b, 0.5, rng_b)
	SphereRelaxer.relax_until_converged(data_b)

	assert_eq(data_a.vertices, data_b.vertices, "same seed should produce same vertices")
