class_name IcospherePerturber
extends RefCounted
## Perturbs icosphere topology via seeded edge rotation for organic irregularity.
##
## Edge rotation ("edge flip") replaces the shared diagonal of a quad formed by
## two adjacent triangles with the other diagonal. This breaks the regular grid
## pattern of a subdivided icosahedron.

## Minimum allowed vertex valence (number of adjacent triangles).
const MIN_VALENCE := 5

## Maximum allowed vertex valence.
const MAX_VALENCE := 7

## Maximum allowed ratio between new and old edge lengths.
const MAX_EDGE_RATIO := 2.0

## Maximum allowed angle (radians) at the new edge endpoints (~150°).
const MAX_ANGLE := 2.618


## Perform edge rotation perturbation on the icosphere.
## [param data]: The icosphere topology to modify (mutated in place).
## [param distortion]: 0.0 = no perturbation, 1.0 = full perturbation.
## [param rng]: Seeded RandomNumberGenerator for deterministic results.
static func perturb(data: IcosphereData, distortion: float, rng: RandomNumberGenerator) -> void:
	if distortion <= 0.0:
		return

	# Collect all edges into an array for random selection.
	var edges: Array = data._edge_triangles.keys()
	var attempt_count := int(distortion * edges.size() * 2)

	for _i in attempt_count:
		var edge: Vector2i = edges[rng.randi_range(0, edges.size() - 1)]
		_try_rotate_edge(data, edge)

	data.build_adjacency()


## Attempt to rotate a single edge. Returns true if the rotation was performed.
static func _try_rotate_edge(data: IcosphereData, edge: Vector2i) -> bool:
	var adj := data.get_edge_triangles(edge.x, edge.y)
	if adj.size() != 2:
		return false

	# Find the quad: two triangles sharing this edge form a diamond.
	# edge.x and edge.y are the shared vertices (A, B).
	# We need the two opposite vertices (C, D) — one from each triangle.
	var tri_a := data.get_triangle(adj[0])
	var tri_b := data.get_triangle(adj[1])
	var c := _opposite_vertex(tri_a, edge.x, edge.y)
	var d := _opposite_vertex(tri_b, edge.x, edge.y)

	if c == -1 or d == -1:
		return false

	# --- Constraint checks ---

	# 1. Valence: A and B lose a triangle, C and D gain one.
	var val_a := data.get_vertex_neighbor_count(edge.x)
	var val_b := data.get_vertex_neighbor_count(edge.y)
	var val_c := data.get_vertex_neighbor_count(c)
	var val_d := data.get_vertex_neighbor_count(d)
	if val_a - 1 < MIN_VALENCE or val_b - 1 < MIN_VALENCE:
		return false
	if val_c + 1 > MAX_VALENCE or val_d + 1 > MAX_VALENCE:
		return false

	# 2. Edge ratio: new edge (C,D) shouldn't be too different from old (A,B).
	var old_len := data.vertices[edge.x].distance_to(data.vertices[edge.y])
	var new_len := data.vertices[c].distance_to(data.vertices[d])
	var ratio := new_len / old_len if old_len > 0.0001 else 999.0
	if ratio > MAX_EDGE_RATIO or ratio < 1.0 / MAX_EDGE_RATIO:
		return false

	# 3. Angle: no overly obtuse angles at the new edge endpoints.
	if (
		SphereMath.triangle_angle_at(data.vertices[edge.x], data.vertices[c], data.vertices[d])
		> MAX_ANGLE
	):
		return false
	if (
		SphereMath.triangle_angle_at(data.vertices[edge.x], data.vertices[d], data.vertices[c])
		> MAX_ANGLE
	):
		return false

	# --- Perform the rotation ---
	# Old: tri_a = (A, B, C), tri_b = (A, B, D) [approximately]
	# New: tri_a → (A, C, D), tri_b → (B, D, C)
	# We must ensure correct CCW winding using cross product checks.
	_set_triangle(data, adj[0], edge.x, c, d)
	_set_triangle(data, adj[1], edge.y, d, c)

	# Verify winding: normal should point outward (same direction as vertex).
	_ensure_outward_winding(data, adj[0])
	_ensure_outward_winding(data, adj[1])

	# Rebuild adjacency for the affected region.
	data.build_adjacency()
	return true


## Find the vertex in the triangle that is NOT a or b (the "opposite" vertex).
static func _opposite_vertex(tri: Vector3i, a: int, b: int) -> int:
	if tri.x != a and tri.x != b:
		return tri.x
	if tri.y != a and tri.y != b:
		return tri.y
	if tri.z != a and tri.z != b:
		return tri.z
	return -1


## Overwrite a triangle's vertex indices in the flat array.
static func _set_triangle(data: IcosphereData, tri_idx: int, a: int, b: int, c: int) -> void:
	var base := tri_idx * 3
	data.triangles[base] = a
	data.triangles[base + 1] = b
	data.triangles[base + 2] = c


## Ensure a triangle's winding produces an outward-facing normal.
## If the cross-product normal points inward (away from vertex), swap two verts.
static func _ensure_outward_winding(data: IcosphereData, tri_idx: int) -> void:
	var base := tri_idx * 3
	var v0 := data.vertices[data.triangles[base]]
	var v1 := data.vertices[data.triangles[base + 1]]
	var v2 := data.vertices[data.triangles[base + 2]]

	var normal := (v1 - v0).cross(v2 - v0)
	# On a unit sphere, the centroid of the triangle roughly points outward.
	var centroid := (v0 + v1 + v2) / 3.0
	if normal.dot(centroid) < 0.0:
		# Winding is clockwise — swap last two vertices to fix.
		var tmp := data.triangles[base + 1]
		data.triangles[base + 1] = data.triangles[base + 2]
		data.triangles[base + 2] = tmp
