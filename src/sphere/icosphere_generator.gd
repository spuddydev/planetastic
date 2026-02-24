class_name IcosphereGenerator
extends RefCounted
## Generates a subdivided icosahedron on the unit sphere.
##
## Usage: [code]var data := IcosphereGenerator.generate(level)[/code]
## Level 0 = base icosahedron (12 vertices, 20 triangles).
## Each level multiplies the triangle count by 4.

## The golden ratio, used to construct icosahedron vertex positions.
const PHI := 1.6180339887498948


## Generate a subdivided icosahedron at the given subdivision level.
## Returns an [IcosphereData] with vertices on the unit sphere and
## adjacency caches built.
static func generate(level: int) -> IcosphereData:
	var data := _create_base()
	for i in level:
		data = _subdivide(data)
	data.build_adjacency()
	return data


## Create the base icosahedron: 12 vertices and 20 equilateral triangles.
static func _create_base() -> IcosphereData:
	var data := IcosphereData.new()

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

	# 20 triangles with consistent counter-clockwise winding. Winding order
	# determines which side is the "front" face — CCW when viewed from
	# outside the sphere means the normal points outward.
	data.triangles = PackedInt32Array(
		[
			# 5 faces around vertex 0 (top)
			0,
			11,
			5,
			0,
			5,
			1,
			0,
			1,
			7,
			0,
			7,
			10,
			0,
			10,
			11,
			# 5 adjacent faces
			1,
			5,
			9,
			5,
			11,
			4,
			11,
			10,
			2,
			10,
			7,
			6,
			7,
			1,
			8,
			# 5 faces around vertex 3 (bottom)
			3,
			9,
			4,
			3,
			4,
			2,
			3,
			2,
			6,
			3,
			6,
			8,
			3,
			8,
			9,
			# 5 adjacent faces
			4,
			9,
			5,
			2,
			4,
			11,
			6,
			2,
			10,
			8,
			6,
			7,
			9,
			8,
			1,
		]
	)

	return data


## Subdivide every triangle into 4 smaller triangles via edge midpoints.
## New midpoint vertices are created using slerp to keep them on the sphere.
static func _subdivide(data: IcosphereData) -> IcosphereData:
	var result := IcosphereData.new()
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

		# Replace the original triangle with 4 sub-triangles,
		# preserving CCW winding:
		#       v0
		#      / \
		#    m01---m20
		#    / \ / \
		#  v1--m12--v2
		(
			result
			. triangles
			. append_array(
				PackedInt32Array(
					[
						v0,
						m01,
						m20,
						m01,
						v1,
						m12,
						m20,
						m12,
						v2,
						m01,
						m12,
						m20,
					]
				)
			)
		)

	return result


## Get (or create) the midpoint vertex between two vertices.
## Uses slerp so the new point lies on the sphere surface.
static func _get_midpoint(data: IcosphereData, cache: Dictionary, a: int, b: int) -> int:
	var key := SphereMath.edge_key(a, b)
	if cache.has(key):
		return cache[key]

	var mid := SphereMath.slerp_unit(data.vertices[a], data.vertices[b], 0.5)
	var idx := data.vertices.size()
	data.vertices.append(mid)
	cache[key] = idx
	return idx
