class_name DualMeshBuilder
extends RefCounted
## Converts a triangle mesh into its dual polyhedron (Voronoi-like tiles).
##
## Each vertex becomes a tile, each triangle centroid becomes a tile corner.
## Uses centroids rather than circumcenters for stability on distorted meshes.


## Build dual cells from the triangle mesh.
## Returns an Array of DualCell — one per vertex in the input data.
static func build(data: SphereData) -> Array[DualCell]:
	# Precompute all triangle centroids (projected onto unit sphere).
	var centroids := PackedVector3Array()
	centroids.resize(data.get_triangle_count())
	for ti in data.get_triangle_count():
		var tri := data.get_triangle(ti)
		var c := (data.vertices[tri.x] + data.vertices[tri.y] + data.vertices[tri.z]) / 3.0
		centroids[ti] = c.normalized()

	# Build one cell per vertex.
	var cells: Array[DualCell] = []
	cells.resize(data.vertices.size())

	for vi in data.vertices.size():
		var cell := DualCell.new()
		cell.center = data.vertices[vi]

		# Walk the triangle fan around this vertex topologically (via shared
		# edges) rather than sorting by angle. This is correct by construction
		# regardless of triangle shape.
		var fan := _walk_fan(data, vi)

		# Ensure CCW winding by checking the cross product of the first two
		# corners against the vertex normal (outward on a unit sphere).
		var c0 := centroids[fan[0]]
		var c1 := centroids[fan[1]]
		var cross := (c0 - cell.center).cross(c1 - cell.center)
		if cross.dot(cell.center) < 0.0:
			fan.reverse()

		# Build corners and neighbour indices from the fan order.
		var corners := PackedVector3Array()
		for ti in fan:
			corners.append(centroids[ti])
		cell.corners = corners
		cell.neighbour_indices = _find_neighbours(data, vi, fan)

		cells[vi] = cell

	return cells


## Walk the triangle fan around a vertex by following shared edges.
## Returns triangle indices in topological fan order (consistent winding,
## but not guaranteed CCW — caller must check).
static func _walk_fan(data: SphereData, vi: int) -> PackedInt32Array:
	var tri_indices := data.get_vertex_triangles(vi)
	var fan := PackedInt32Array()
	fan.append(tri_indices[0])

	# From the starting triangle, find the two edges through vi and pick one
	# to establish a walking direction.
	var current_ti: int = tri_indices[0]
	var tri := data.get_triangle(current_ti)
	var verts := [tri.x, tri.y, tri.z]

	# Find the first edge through vi — pick the first other vertex in the triangle.
	var prev_shared := -1
	for v: int in verts:
		if v != vi:
			prev_shared = v
			break

	# Walk around the fan by crossing edges.
	for _step in tri_indices.size() - 1:
		# Find the other vertex in current triangle (not vi, not prev_shared).
		tri = data.get_triangle(current_ti)
		verts = [tri.x, tri.y, tri.z]
		var next_shared := -1
		for v: int in verts:
			if v != vi and v != prev_shared:
				next_shared = v
				break

		# Cross the edge (vi, next_shared) to the adjacent triangle.
		var adj := data.get_edge_triangles(vi, next_shared)
		var next_ti: int = adj[1] if adj[0] == current_ti else adj[0]

		fan.append(next_ti)
		prev_shared = next_shared
		current_ti = next_ti

	return fan


## Find the neighbour cell indices for a vertex's dual cell.
## Each consecutive pair of fan-ordered triangle indices shares an edge,
## and the shared vertex (other than vi) is the neighbour cell index.
static func _find_neighbours(
	data: SphereData,
	vi: int,
	fan: PackedInt32Array,
) -> PackedInt32Array:
	var neighbours := PackedInt32Array()

	for ci in fan.size():
		var ti_a := fan[ci]
		var ti_b := fan[(ci + 1) % fan.size()]

		# The neighbour is the vertex (other than vi) shared by both triangles.
		var tri_a := data.get_triangle(ti_a)
		var tri_b := data.get_triangle(ti_b)
		var verts_a := [tri_a.x, tri_a.y, tri_a.z]
		var verts_b := [tri_b.x, tri_b.y, tri_b.z]

		var found := -1
		for v in verts_a:
			if v != vi and v in verts_b:
				found = v
				break
		neighbours.append(found)

	return neighbours
