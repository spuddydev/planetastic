class_name SphereRelaxer
extends RefCounted
## Relaxes vertex positions for more uniform triangle shapes.
##
## Uses centroid-based relaxation (not Lloyd's — centroids are more stable than
## circumcenters for distorted meshes). Interleaved with perturbation passes
## per the Experilous approach.

## Number of interleaved perturbation + relaxation rounds.
const INTERLEAVE_ROUNDS := 6

## Maximum relaxation-only passes after interleaving.
const MAX_RELAX_PASSES := 20

## Stop when no vertex moves more than this distance in a pass.
const CONVERGENCE_THRESHOLD := 0.0001

## How aggressively vertices move toward ideal positions (0-1).
const RELAX_STRENGTH := 0.5


## Run the full pipeline: interleaved perturbation+relaxation, then pure relaxation.
static func relax_full(data: SphereData, distortion: float, rng: RandomNumberGenerator) -> void:
	if distortion <= 0.0:
		return

	# Phase 1: Interleaved rounds — perturb a bit, relax a bit, repeat.
	var partial_distortion := distortion / INTERLEAVE_ROUNDS
	for _round in INTERLEAVE_ROUNDS:
		SpherePerturber.perturb(data, partial_distortion, rng)
		_relax_pass(data)

	# Phase 2: Pure relaxation until the mesh settles.
	for _pass in MAX_RELAX_PASSES:
		var max_displacement := _relax_pass(data)
		if max_displacement < CONVERGENCE_THRESHOLD:
			break


## One relaxation pass over all vertices. Returns max displacement for convergence.
static func _relax_pass(data: SphereData) -> float:
	var max_displacement := 0.0
	var ideal_dist := _compute_ideal_distance(data)

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
			if current_dist < 0.00001:
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


## Ideal corner-to-centroid distance for equilateral triangles at this mesh density.
static func _compute_ideal_distance(data: SphereData) -> float:
	var area_per_tri := 4.0 * PI / data.get_triangle_count()
	var side_length := sqrt(4.0 * area_per_tri / sqrt(3.0))
	# Slight underestimate to avoid triangles flipping inside-out from too much pressure.
	return side_length / sqrt(3.0) * 0.95
