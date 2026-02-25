class_name SphereData
extends RefCounted
## Data container for icosphere topology: vertices, triangles, and adjacency.
##
## Call [method build_adjacency] after modifying triangles to rebuild caches.

## Positions of every vertex on the unit sphere.
var vertices: PackedVector3Array

## Flat array of triangle indices — every 3 consecutive ints define one triangle.
## E.g. [0,1,2, 0,2,3, ...] means triangle 0 is (v0,v1,v2), triangle 1 is (v0,v2,v3).
var triangles: PackedInt32Array

## Edge → adjacent triangle indices. Key: Vector2i(min_idx, max_idx).
## Value: PackedInt32Array of triangle indices (usually exactly 2 for a closed mesh).
var _edge_triangles: Dictionary

## Vertex → triangle indices containing that vertex.
## Indexed by vertex index; each entry is a PackedInt32Array.
var _vertex_triangles: Array


## Return the number of triangles.
func get_triangle_count() -> int:
	return triangles.size() / 3  # This is fine! Triangles always come in threes...


## Return the vertex indices for triangle at the given index.
func get_triangle(tri_idx: int) -> Vector3i:
	var base := tri_idx * 3
	return Vector3i(triangles[base], triangles[base + 1], triangles[base + 2])


## Rebuild all adjacency caches from the current triangles array.
func build_adjacency() -> void:
	_edge_triangles = {}
	_vertex_triangles = []
	_vertex_triangles.resize(vertices.size())
	for vi in vertices.size():
		_vertex_triangles[vi] = PackedInt32Array()

	var tri_count := get_triangle_count()
	for ti in tri_count:
		var base := ti * 3
		var v0 := triangles[base]
		var v1 := triangles[base + 1]
		var v2 := triangles[base + 2]

		# Register this triangle for each of its three vertices.
		_vertex_triangles[v0].append(ti)
		_vertex_triangles[v1].append(ti)
		_vertex_triangles[v2].append(ti)

		# Register this triangle for each of its three edges.
		for edge: Vector2i in [
			SphereMath.edge_key(v0, v1),
			SphereMath.edge_key(v1, v2),
			SphereMath.edge_key(v2, v0),
		]:
			if not _edge_triangles.has(edge):
				_edge_triangles[edge] = PackedInt32Array()
			_edge_triangles[edge].append(ti)


## Get the triangle indices that share the given edge.
func get_edge_triangles(a: int, b: int) -> PackedInt32Array:
	var key := SphereMath.edge_key(a, b)
	if _edge_triangles.has(key):
		return _edge_triangles[key]
	return PackedInt32Array()


## Get the triangle indices that contain the given vertex.
func get_vertex_triangles(vi: int) -> PackedInt32Array:
	return _vertex_triangles[vi]


## Get how many triangles share this vertex (its "valence").
func get_vertex_neighbor_count(vi: int) -> int:
	return _vertex_triangles[vi].size()


## Remove a triangle from the adjacency caches (but not from the triangles array).
## Used for incremental updates when rotating an edge.
func _unregister_triangle(ti: int) -> void:
	var tri := get_triangle(ti)
	var verts := [tri.x, tri.y, tri.z]

	# Remove from vertex → triangle cache.
	for v in verts:
		var arr: PackedInt32Array = _vertex_triangles[v]
		var idx := arr.find(ti)
		if idx != -1:
			_vertex_triangles[v].remove_at(idx)

	# Remove from edge → triangle cache.
	for i in 3:
		var key := SphereMath.edge_key(verts[i], verts[(i + 1) % 3])
		if _edge_triangles.has(key):
			var arr: PackedInt32Array = _edge_triangles[key]
			var idx := arr.find(ti)
			if idx != -1:
				arr.remove_at(idx)
			if arr.is_empty():
				_edge_triangles.erase(key)


## Add a triangle to the adjacency caches (assumes it's already in the triangles array).
## Used for incremental updates when rotating an edge.
func _register_triangle(ti: int) -> void:
	var tri := get_triangle(ti)
	var verts := [tri.x, tri.y, tri.z]

	for v in verts:
		_vertex_triangles[v].append(ti)

	for i in 3:
		var key := SphereMath.edge_key(verts[i], verts[(i + 1) % 3])
		if not _edge_triangles.has(key):
			_edge_triangles[key] = PackedInt32Array()
		_edge_triangles[key].append(ti)
