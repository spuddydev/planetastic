class_name SphereMeshBuilder
extends RefCounted
## Converts dual cells into a renderable ArrayMesh.
##
## Fan-triangulates each cell from its center. Uses cell.colour if set by a
## generation method; falls back to a debug rainbow otherwise.


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

		var colour: Color
		if cell.colour.a > 0.0:
			colour = cell.colour
		else:
			# Debug rainbow: hue from longitude, saturation from latitude
			var hue := fmod(atan2(cell.center.z, cell.center.x) / TAU + 1.0, 1.0)
			var sat := 0.6 + (cell.center.y + 1.0) / 2.0 * 0.4
			colour = Color.from_hsv(hue, sat, 0.9)
		st.set_color(colour)

		var center := cell.center * radius

		# Fan triangulation: connect center to each consecutive pair of corners
		for i in cell.corners.size():
			var c0 := cell.corners[i] * radius
			var c1 := cell.corners[(i + 1) % cell.corners.size()] * radius

			# Normal points outward from sphere center
			var normal := cell.center.normalized()
			st.set_normal(normal)

			st.add_vertex(center)
			st.add_vertex(c1)
			st.add_vertex(c0)

	return st.commit()
