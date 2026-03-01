class_name SphereMeshBuilder
extends RefCounted
## Converts dual cells into a renderable ArrayMesh.
##
## Fan-triangulates each cell from its center, assigns a random color per tile
## using the seeded RNG for deterministic coloring.


## Build an ArrayMesh from dual cells at the given radius.
static func build_mesh(
	cells: Array[DualCell],
	radius: float,
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for cell in cells:
		if cell.corners.size() < 3:
			continue

		# Debug rainbow: hue from longitude (X/Z), saturation from latitude (Y).
		var hue := fmod(atan2(cell.center.z, cell.center.x) / TAU + 1.0, 1.0)
		var sat := 0.6 + (cell.center.y + 1.0) / 2.0 * 0.4
		var color := Color.from_hsv(hue, sat, 0.9)
		st.set_color(color)

		var center := cell.center * radius

		# Fan triangulation: connect center to each consecutive pair of corners.
		# For a hexagon with corners [0,1,2,3,4,5], this creates triangles:
		#   (center, corner0, corner1), (center, corner1, corner2), etc.
		for i in cell.corners.size():
			var c0 := cell.corners[i] * radius
			var c1 := cell.corners[(i + 1) % cell.corners.size()] * radius

			# Normal points outward from sphere center (same as the vertex direction).
			var normal := cell.center.normalized()
			st.set_normal(normal)

			st.add_vertex(center)
			st.add_vertex(c1)
			st.add_vertex(c0)

	return st.commit()
