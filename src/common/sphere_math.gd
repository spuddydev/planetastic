class_name SphereMath
extends RefCounted
## Static math helpers for sphere tessellation.

## Dot product threshold above which two vectors are nearly parallel (slerp fallback).
const NEAR_PARALLEL_THRESHOLD := 0.9999


## Spherical linear interpolation between two unit vectors.
static func slerp_unit(a: Vector3, b: Vector3, t: float) -> Vector3:
	var dot := clampf(a.dot(b), -1.0, 1.0)
	if dot > NEAR_PARALLEL_THRESHOLD:
		return a.lerp(b, t).normalized()
	var theta := acos(dot)
	var sin_theta := sin(theta)
	var wa := sin((1.0 - t) * theta) / sin_theta
	var wb := sin(t * theta) / sin_theta
	return (a * wa + b * wb).normalized()


## Project a point onto the unit sphere.
static func project_to_sphere(v: Vector3) -> Vector3:
	return v.normalized()


## Create a canonical edge key (smaller index first) for deduplication.
static func edge_key(a: int, b: int) -> Vector2i:
	return Vector2i(mini(a, b), maxi(a, b))


## Compute the angle at vertex B in triangle (A, B, C).
static func triangle_angle_at(a: Vector3, b: Vector3, c: Vector3) -> float:
	var ba := (a - b).normalized()
	var bc := (c - b).normalized()
	return acos(clampf(ba.dot(bc), -1.0, 1.0))
