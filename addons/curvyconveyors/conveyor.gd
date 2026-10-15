class_name Conveyor
extends Path3D

@export_group("Start & End positions")
@export var start: Vector3
@export var start_normal: Vector3
@export var end: Vector3
@export var end_normal: Vector3

@export_group("Conveyor settings")
@export var speed: float = 1
@export var dist_between_items: float = .25

@export_group("Curve settings")
@export var curve_strength: float = 3

@export_group("Meshing")
@export var segment_size: float = .25
@export var width: float = 1
@export var thickness: float = .2
@export var cap_ends: bool = false
@export var material: Material

var items: Array[ConveyorItem] = []
var can_accept = true
var _length = 0
var _port_a: ConveyorPort
var _port_b: ConveyorPort

func reset() -> void:
	for node in get_children():
		remove_child(node)

func update(add_collision: bool = true, reversed: bool = false) -> float:
	reset()
	if reversed:
		var tmp_s = start
		var tmp_n = start_normal
		start = end
		start_normal = end_normal
		end = tmp_s
		end_normal = tmp_n
	curve = Curve3D.new()
	curve.add_point(start, Vector3.ZERO, start_normal.normalized() * curve_strength)
	curve.add_point(end, end_normal.normalized() * curve_strength)
	var mesh = _build_mesh()
	_length = curve.get_baked_length()
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	if material:
		mi.set_surface_override_material(0, material)
	add_child(mi)
	if not add_collision: return _calculate_max_curve()
	var sb = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	sb.add_child(cs)
	cs.shape = mesh.create_trimesh_shape()
	add_child(sb)
	_port_a = ConveyorPort.new()
	_port_a.position = start
	_port_a.rotation = Vector3(0, _get_dir(start_normal), 0)
	_port_b = ConveyorPort.new()
	_port_b.position = end
	_port_b.rotation = Vector3(0, _get_dir(end_normal), 0)
	_port_a.direction = ConveyorPort.Direction.Input
	_port_b.direction = ConveyorPort.Direction.Output
	_port_a.conveyor = self
	_port_b.conveyor = self
	add_child(_port_a)
	add_child(_port_b)
	return _calculate_max_curve()

func _get_dir(dir: Vector3) -> float:
	var direction := Vector2(dir.x, -dir.z)
	print("dir: %s | dir2: %s | ang: %s" % [dir, direction, rad_to_deg(direction.angle())])
	return direction.angle() + PI / 2

func _calculate_max_curve() -> float:
	var points := curve.get_baked_points()

	var max_angle := 0.0
	for i in range(1, points.size() - 1):
		var incoming := (points[i] - points[i - 1]).normalized()
		var outgoing := (points[i + 1] - points[i]).normalized()

		if incoming.length_squared() > 0.0 and outgoing.length_squared() > 0.0:
			max_angle = maxf(max_angle, rad_to_deg(incoming.angle_to(outgoing)))

	return max_angle

func destroy():
	if _port_a: _port_a.disconnect_conveyor()
	if _port_b: _port_b.disconnect_conveyor()
	queue_free()

func _build_mesh() -> ArrayMesh:
	var points := curve.get_baked_points()
	if points.size() < 2:
		return ArrayMesh.new()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)

	var half_width := width * 0.5
	var half_thickness := thickness * 0.5

	# Add a quad as two triangles.
	var add_quad := func(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)

		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(d)

	# Cross-section corners at one point along the path.
	var corners_at := func(i: int) -> Array[Vector3]:
		var tangent: Vector3
		if i == 0:
			tangent = (points[1] - points[0]).normalized()
		elif i == points.size() - 1:
			tangent = (points[i] - points[i - 1]).normalized()
		else:
			tangent = (points[i + 1] - points[i - 1]).normalized()

		var up := Vector3.UP
		var right := up.cross(tangent)

		# Avoid a zero-width direction if the path is nearly vertical.
		if right.length_squared() < 0.0001:
			right = Vector3.RIGHT.cross(tangent)

		right = right.normalized()
		var thickness_axis := tangent.cross(right).normalized()

		var w := right * half_width
		var h := thickness_axis * half_thickness
		var p := points[i]

		# Consistent corner order: top-left, top-right, bottom-right, bottom-left.
		return [p - w + h, p + w + h, p + w - h, p - w - h]

	for i in range(points.size() - 1):
		var a : Array[Vector3] = corners_at.call(i)
		var b : Array[Vector3] = corners_at.call(i + 1)

		add_quad.call(a[0], a[1], b[1], b[0]) # top
		add_quad.call(a[3], b[3], b[2], a[2]) # bottom
		add_quad.call(a[0], b[0], b[3], a[3]) # left
		add_quad.call(a[1], a[2], b[2], b[1]) # right

	# caps
	if cap_ends:
		var first : Array[Vector3] = corners_at.call(0)
		add_quad.call(first[0], first[3], first[2], first[1])
		var last : Array[Vector3] = corners_at.call(points.size() - 1)
		add_quad.call(last[0], last[1], last[2], last[3])
	
	st.generate_normals()
	return st.commit()

func _process(delta: float) -> void:
	if _length == 0: return
	# probably not the best way to do this? idk
	var max_progress = _length
	var offset = Vector3.UP * thickness / 2
	for item in items:
		if item.progress < max_progress:
			item.progress += speed * delta
		if item.progress > max_progress:
			item.progress = max_progress
		if item.progress >= max_progress:
			max_progress -= dist_between_items
		item.node.position = curve.sample_baked(item.progress) + offset
	if len(items) > 0 and items[0].progress >= _length:
		if _port_b.push_item(items[0].node, true): items.pop_front()

func add_item(item: Node3D) -> bool:
	if len(items) > 0 and items[len(items)-1].progress <= dist_between_items:
		return false
	if not can_accept:
		return false
	var conv_item = ConveyorItem.new()
	conv_item.progress = 0
	conv_item.node = item
	if item.get_parent():
		item.reparent(self)
	else:
		add_child(item)
	item.position = curve.get_point_position(0)
	items.push_back(conv_item)
	return true

func take_item() -> Node3D:
	print("Called takeItem")
	if len(items) == 0:
		print("Take item: array empty")
		return null
	if items[0].progress < _length:
		print("Take item: last item progress: %d < %d" % [items[0].progress, _length])
		return null
	return items.pop_front().node
