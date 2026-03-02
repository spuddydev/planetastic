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

		# The triangles around this vertex provide the cell's corners.
		var tri_indices := data.get_vertex_triangles(vi)
		var corners := PackedVector3Array()
		for ti in tri_indices:
			corners.append(centroids[ti])

		# Sort corners in CCW order around the cell center so they form a
		# proper polygon (not a zigzag mess). Returns both sorted corners
		# and the corresponding triangle indices in the same order.
		var sorted := _sort_ccw(cell.center, corners, tri_indices)
		cell.corners = sorted.corners
		var sorted_tri_indices: PackedInt32Array = sorted.tri_indices

		# Find neighbour cells: for each edge of this cell (between consecutive
		# corners), the neighbour is the other vertex that shares that triangle.
		cell.neighbour_indices = _find_neighbours(data, vi, sorted_tri_indices)

		cells[vi] = cell

	return cells


## Sort corner points in counter-clockwise order around a center point.
## Projects onto the tangent plane at center, then sorts by angle.
## Returns a dictionary with "corners" (PackedVector3Array) and
## "tri_indices" (PackedInt32Array) sorted in the same order.
static func _sort_ccw(
	center: Vector3,
	corners: PackedVector3Array,
	tri_indices: PackedInt32Array,
) -> Dictionary:
	# Build a local 2D coordinate system on the tangent plane at center.
	# "up" is the center itself (the normal to the sphere at this point).
	var normal := center.normalized()

	# Pick an arbitrary tangent vector not parallel to the normal.
	var ref := Vector3.UP
	if absf(normal.dot(ref)) > 0.9:
		ref = Vector3.RIGHT
	var tangent_u := normal.cross(ref).normalized()
	var tangent_v := normal.cross(tangent_u).normalized()

	# Project each corner onto the tangent plane and compute its angle.
	var angles: Array[float] = []
	for c in corners:
		var d := c - center
		var u := d.dot(tangent_u)
		var v := d.dot(tangent_v)
		angles.append(atan2(v, u))

	# Sort by angle using an index array.
	var indices: Array[int] = []
	for i in corners.size():
		indices.append(i)
	indices.sort_custom(func(a: int, b: int) -> bool: return angles[a] < angles[b])

	var sorted_corners := PackedVector3Array()
	var sorted_tri := PackedInt32Array()
	for i in indices:
		sorted_corners.append(corners[i])
		sorted_tri.append(tri_indices[i])
	return {"corners": sorted_corners, "tri_indices": sorted_tri}


## Find the neighbour cell indices for a vertex's dual cell.
## Each consecutive pair of sorted triangle indices shares an edge with a neighbour.
static func _find_neighbours(
	data: SphereData,
	vi: int,
	sorted_tri_indices: PackedInt32Array,
) -> PackedInt32Array:
	var neighbours := PackedInt32Array()

	# For each pair of consecutive corners, find which vertex shares both
	# of the triangles that produced those corners.
	for ci in sorted_tri_indices.size():
		var ti_a := sorted_tri_indices[ci]
		var ti_b := sorted_tri_indices[(ci + 1) % sorted_tri_indices.size()]

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
