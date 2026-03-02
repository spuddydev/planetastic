class_name SphereRelaxer
extends RefCounted
## Relaxes vertex positions for more uniform triangle shapes.
##
## Uses centroid-based relaxation (not Lloyd's — centroids are more stable than
## circumcenters for distorted meshes). Only handles relaxation — pipeline
## orchestration (interleaving with perturbation) lives in planet.gd.

## Maximum relaxation-only passes before giving up.
const MAX_RELAX_PASSES := 20

## Stop when no vertex moves more than this distance in a pass.
const CONVERGENCE_THRESHOLD := 0.0001

## How aggressively vertices move toward ideal positions (0-1).
const RELAX_STRENGTH := 0.5

## Minimum centroid distance to avoid normalising a near-zero vector.
const MIN_CENTROID_DISTANCE := 0.00001

## Underestimate factor for ideal distance — prevents triangles flipping
## inside-out from too much relaxation pressure.
const IDEAL_DISTANCE_FACTOR := 0.95


## Run a single relaxation pass. Returns the maximum vertex displacement.
## [param ideal_dist]: precomputed ideal corner-to-centroid distance.
static func relax_pass(data: SphereData, ideal_dist: float) -> float:
	var max_displacement := 0.0

	for vi in data.vertices.size():
		var tri_indices := data.get_vertex_triangles(vi)
		if tri_indices.size() < 3:
			continue

		# For each triangle around this vertex, compute centroid and compare
		# the vertex-to-centroid distance against the ideal.
		var displacement := Vector3.ZERO
		for ti in tri_indices:
			var tri := data.get_triangle(ti)
			var centroid := (
				(data.vertices[tri.x] + data.vertices[tri.y] + data.vertices[tri.z]) / 3.0
			)
			var to_centroid := centroid - data.vertices[vi]
			var current_dist := to_centroid.length()
			if current_dist < MIN_CENTROID_DISTANCE:
				continue
			var delta := current_dist - ideal_dist
			displacement += to_centroid.normalized() * delta

		displacement /= tri_indices.size()

		var new_pos := data.vertices[vi] + displacement * RELAX_STRENGTH
		new_pos = SphereMath.project_to_sphere(new_pos)

		var moved := data.vertices[vi].distance_to(new_pos)
		if moved > max_displacement:
			max_displacement = moved
		data.vertices[vi] = new_pos

	return max_displacement


## Run relaxation passes until convergence or the pass limit is reached.
static func relax_until_converged(data: SphereData) -> void:
	var ideal_dist := compute_ideal_distance(data)
	for _pass in MAX_RELAX_PASSES:
		var max_displacement := relax_pass(data, ideal_dist)
		if max_displacement < CONVERGENCE_THRESHOLD:
			break


## Ideal corner-to-centroid distance for equilateral triangles at this mesh density.
static func compute_ideal_distance(data: SphereData) -> float:
	var area_per_tri := 4.0 * PI / data.get_triangle_count()
	var side_length := sqrt(4.0 * area_per_tri / sqrt(3.0))
	# Slight underestimate to avoid triangles flipping inside-out from too much pressure.
	return side_length / sqrt(3.0) * IDEAL_DISTANCE_FACTOR
