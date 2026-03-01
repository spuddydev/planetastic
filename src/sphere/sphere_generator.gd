class_name SphereGenerator
extends RefCounted
## Generates a subdivided icosahedron on the unit sphere.
##
## Usage: [code]var data := SphereGenerator.generate(level)[/code]
## Level 0 = base icosahedron (12 vertices, 20 triangles).
## Each level multiplies the triangle count by 4.

## The golden ratio, used to construct icosahedron vertex positions.
const PHI := (1 + sqrt(5)) / 2


## Generate a subdivided icosahedron at the given subdivision level.
## Returns an [SphereData] with vertices on the unit sphere and
## adjacency caches built.
static func generate(level: int) -> SphereData:
	var data := _create_base()
	for i in level:
		data = _subdivide(data)
	data.build_adjacency()
	return data


## Create the base icosahedron: 12 vertices and 20 equilateral triangles.
static func _create_base() -> SphereData:
	var data := SphereData.new()

	# The 12 vertices of a regular icosahedron lie at the corners of three
	# mutually perpendicular golden rectangles (aspect ratio 1:φ). We
	# normalize them to place them on the unit sphere.
	var raw_verts: Array[Vector3] = [
		Vector3(-1, PHI, 0),
		Vector3(1, PHI, 0),
		Vector3(-1, -PHI, 0),
		Vector3(1, -PHI, 0),
		Vector3(0, -1, PHI),
		Vector3(0, 1, PHI),
		Vector3(0, -1, -PHI),
		Vector3(0, 1, -PHI),
		Vector3(PHI, 0, -1),
		Vector3(PHI, 0, 1),
		Vector3(-PHI, 0, -1),
		Vector3(-PHI, 0, 1),
	]
	data.vertices = PackedVector3Array()
	for v in raw_verts:
		data.vertices.append(v.normalized())

	# This fucking suuuucks man the formatter will not let me arrange these into
	# triplets... now it just looks terrible... there is no option to change this.
	# These are the 20 base triangles.
	# I have broken them up with empty comments for my own sake
	data.triangles = PackedInt32Array(
		[
			0,
			11,
			5,
			# t1
			0,
			5,
			1,
			# t2
			0,
			1,
			7,
			# t3
			0,
			7,
			10,
			# t4
			0,
			10,
			11,
			# t5
			1,
			5,
			9,
			# t6
			5,
			11,
			4,
			# t7
			11,
			10,
			2,
			# t8
			10,
			7,
			6,
			# t9
			7,
			1,
			8,
			# t10
			3,
			9,
			4,
			# t11
			3,
			4,
			2,
			# t12
			3,
			2,
			6,
			# t13
			3,
			6,
			8,
			# t14
			3,
			8,
			9,
			# t15
			4,
			9,
			5,
			# t16
			2,
			4,
			11,
			# t17
			6,
			2,
			10,
			# t18
			8,
			6,
			7,
			# t19
			9,
			8,
			1,
			# t20
		]
	)

	return data


## Subdivide every triangle into 4 smaller triangles via edge midpoints.
## New midpoint vertices are created using slerp to keep them on the sphere.
static func _subdivide(data: SphereData) -> SphereData:
	var result := SphereData.new()
	result.vertices = data.vertices.duplicate()
	result.triangles = PackedInt32Array()

	# Cache of midpoints: edge_key → vertex index. This ensures that when
	# two triangles share an edge, they reuse the same midpoint vertex
	# instead of creating a duplicate.
	var midpoint_cache: Dictionary = {}

	var tri_count := data.get_triangle_count()
	for ti in tri_count:
		var tri := data.get_triangle(ti)
		var v0 := tri.x
		var v1 := tri.y
		var v2 := tri.z

		# Get or create the midpoint vertex for each edge.
		var m01 := _get_midpoint(result, midpoint_cache, v0, v1)
		var m12 := _get_midpoint(result, midpoint_cache, v1, v2)
		var m20 := _get_midpoint(result, midpoint_cache, v2, v0)

		# Replace the original triangle with 4 sub-triangles
		# See above (51) angry comment about formatter
		(
			result
			. triangles
			. append_array(
				PackedInt32Array(
					[
						v0,
						m01,
						m20,
						# st1
						m01,
						v1,
						m12,
						# st2
						m20,
						m12,
						v2,
						# st3
						m01,
						m12,
						m20,
						# st4
					]
				)
			)
		)

	return result


## Get (or create) the midpoint vertex between two vertices.
## Uses slerp so the new point lies on the sphere surface.
static func _get_midpoint(data: SphereData, cache: Dictionary, a: int, b: int) -> int:
	var key := SphereMath.edge_key(a, b)
	if cache.has(key):
		return cache[key]

	var mid := SphereMath.slerp_unit(data.vertices[a], data.vertices[b], 0.5)
	var idx := data.vertices.size()
	data.vertices.append(mid)
	cache[key] = idx
	return idx
