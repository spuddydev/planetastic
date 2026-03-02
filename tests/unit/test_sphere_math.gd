extends GutTest
## Tests for SphereMath static helpers.


func test_slerp_at_zero_returns_start() -> void:
	var a := Vector3(1, 0, 0)
	var b := Vector3(0, 1, 0)
	var result := SphereMath.slerp_unit(a, b, 0.0)
	assert_almost_eq(result, a, Vector3.ONE * 0.0001, "slerp(t=0) should return a")


func test_slerp_at_one_returns_end() -> void:
	var a := Vector3(1, 0, 0)
	var b := Vector3(0, 1, 0)
	var result := SphereMath.slerp_unit(a, b, 1.0)
	assert_almost_eq(result, b, Vector3.ONE * 0.0001, "slerp(t=1) should return b")


func test_slerp_midpoint_on_sphere() -> void:
	var a := Vector3(1, 0, 0)
	var b := Vector3(0, 1, 0)
	var mid := SphereMath.slerp_unit(a, b, 0.5)
	assert_almost_eq(mid.length(), 1.0, 0.0001, "slerp midpoint should be on unit sphere")


func test_slerp_nearly_identical_vectors() -> void:
	var a := Vector3(1, 0, 0)
	var b := Vector3(1, 0.00001, 0).normalized()
	var mid := SphereMath.slerp_unit(a, b, 0.5)
	assert_almost_eq(mid.length(), 1.0, 0.0001, "slerp of near-identical vectors should not NaN")


func test_project_to_sphere() -> void:
	var v := Vector3(3, 4, 0)
	var result := SphereMath.project_to_sphere(v)
	assert_almost_eq(result.length(), 1.0, 0.0001)


func test_edge_key_canonical() -> void:
	assert_eq(SphereMath.edge_key(3, 7), Vector2i(3, 7))
	assert_eq(SphereMath.edge_key(7, 3), Vector2i(3, 7))
	assert_eq(SphereMath.edge_key(5, 5), Vector2i(5, 5))


func test_triangle_angle_right_angle() -> void:
	var a := Vector3(1, 0, 0)
	var b := Vector3(0, 0, 0)
	var c := Vector3(0, 1, 0)
	var angle := SphereMath.triangle_angle_at(a, b, c)
	assert_almost_eq(angle, PI / 2.0, 0.0001, "should be 90 degrees")
