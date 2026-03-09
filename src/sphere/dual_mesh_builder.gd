class_name DualMeshBuilder
extends RefCounted
## Converts a triangle mesh into its dual polyhedron (Voronoi-like tiles).
##
## Each vertex becomes a tile, each triangle centroid becomes a tile corner.
## Uses centroids rather than circumcenters for stability on distorted meshes.


## Build dual cells from the triangle mesh.
## Returns an Array of DualCell — one per vertex in the input data.
static func build(data: SphereData) -> Array[DualCell]:
	# Precompute all triangle centroids on the unit sphere
	var centroids := PackedVector3Array()
	centroids.resize(data.get_triangle_count())
	for ti in data.get_triangle_count():
		var tri := data.get_triangle(ti)
		var c := (data.vertices[tri.x] + data.vertices[tri.y] + data.vertices[tri.z]) / 3.0
		centroids[ti] = c.normalized()

	# Build one cell per vertex
	var cells: Array[DualCell] = []
	cells.resize(data.vertices.size())

	for vi in data.vertices.size():
		var cell := DualCell.new()
		cell.center = data.vertices[vi]

		# Walk the triangle fan topologically via shared edges
		var result := _walk_fan(data, vi)
		var fan: PackedInt32Array = result["fan"]
		var neighbours: PackedInt32Array = result["neighbours"]

		# Ensure CCW winding via summed cross product
		var winding_cross := Vector3.ZERO
		for fi in fan.size():
			var ca := centroids[fan[fi]]
			var cb := centroids[fan[(fi + 1) % fan.size()]]
			winding_cross += (ca - cell.center).cross(cb - cell.center)
		if winding_cross.dot(cell.center) < 0.0:
			fan.reverse()
			# Reverse first N-1 neighbours to match new fan order; last stays
			var n := neighbours.size()
			var fixed := PackedInt32Array()
			fixed.resize(n)
			for i in n - 1:
				fixed[i] = neighbours[n - 2 - i]
			fixed[n - 1] = neighbours[n - 1]
			neighbours = fixed

		# Build corners from the fan order
		var corners := PackedVector3Array()
		for ti in fan:
			corners.append(centroids[ti])
		cell.corners = corners
		cell.neighbour_indices = neighbours

		cells[vi] = cell

	return cells


## Walk the triangle fan around a vertex by following shared edges.
## Returns { "fan": PackedInt32Array, "neighbours": PackedInt32Array }.
## Fan entries are triangle indices in topological order (consistent winding,
## but not guaranteed CCW — caller must check). Neighbours[i] is the vertex
## index shared by fan[i] and fan[(i+1) % N], i.e. the adjacent dual cell.
static func _walk_fan(data: SphereData, vi: int) -> Dictionary:
	var tri_indices := data.get_vertex_triangles(vi)
	var fan := PackedInt32Array()
	var neighbours := PackedInt32Array()
	fan.append(tri_indices[0])

	# Pick the first other vertex in the starting triangle as initial direction
	var current_ti: int = tri_indices[0]
	var tri := data.get_triangle(current_ti)
	var verts := [tri.x, tri.y, tri.z]

	var first_shared := -1
	for v: int in verts:
		if v != vi:
			first_shared = v
			break

	# Walk around the fan by crossing edges
	var prev_shared := first_shared
	for _step in tri_indices.size() - 1:
		# Find the other vertex in current triangle (not vi, not prev_shared)
		tri = data.get_triangle(current_ti)
		verts = [tri.x, tri.y, tri.z]
		var next_shared := -1
		for v: int in verts:
			if v != vi and v != prev_shared:
				next_shared = v
				break

		# next_shared is the neighbour between this fan entry and the next
		neighbours.append(next_shared)

		# Cross the edge (vi, next_shared) to the adjacent triangle
		var adj := data.get_edge_triangles(vi, next_shared)
		var next_ti: int = adj[1] if adj[0] == current_ti else adj[0]

		fan.append(next_ti)
		prev_shared = next_shared
		current_ti = next_ti

	# Wrap-around: first_shared is shared between the last and first fan entry
	neighbours.append(first_shared)

	return {"fan": fan, "neighbours": neighbours}
