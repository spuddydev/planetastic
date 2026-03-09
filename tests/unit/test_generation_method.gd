extends GutTest
## Tests for GenerationMethod base class — virtual method defaults and subclassing.


func test_base_generate_does_not_crash() -> void:
	var method := GenerationMethod.new()
	var data := SphereGenerator.generate(0)
	var cells := DualMeshBuilder.build(data)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# Should not error — base implementation is a no-op
	method.generate(cells, rng)
	assert_true(true, "base generate() should not crash")


func test_base_generation_name_is_empty() -> void:
	var method := GenerationMethod.new()
	assert_eq(method.get_generation_name(), "", "base name should be empty string")


func test_base_provided_fields_is_empty() -> void:
	var method := GenerationMethod.new()
	assert_eq(
		method.get_provided_fields().size(),
		0,
		"base provided fields should be empty",
	)


func test_base_generate_does_not_modify_cells() -> void:
	var method := GenerationMethod.new()
	var data := SphereGenerator.generate(0)
	var cells := DualMeshBuilder.build(data)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	method.generate(cells, rng)
	for i in cells.size():
		assert_true(is_nan(cells[i].elevation), "cell %d elevation should still be NAN" % i)
		assert_eq(cells[i].biome, -1, "cell %d biome should still be -1" % i)


func test_subclass_can_override_all_methods() -> void:
	var method := TectonicGeneration.new()
	assert_eq(method.get_generation_name(), "Tectonic", "subclass should override name")
	assert_true(
		method.get_provided_fields().has("elevation"),
		"subclass should declare elevation field",
	)
