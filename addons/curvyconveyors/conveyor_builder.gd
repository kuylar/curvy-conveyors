class_name ConveyorBuilder
extends Node

var building = false
var _raycast: RayCast3D
var pos_a: Vector3
var nor_a: Vector3
var port_a: ConveyorPort
var preview_conveyor: Conveyor
var preview_material: StandardMaterial3D
@export var conveyor_material: StandardMaterial3D
var ang = 0
var preview_ang = 0
var rotate_speed = .2

func _ready():
	preview_conveyor = Conveyor.new()
	preview_material = StandardMaterial3D.new()
	preview_material.albedo_color = Color(0, 0.8, 0, 0.4)
	preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_conveyor.material = preview_material
	add_child(preview_conveyor)

func _process(_delta: float) -> void:
	if not _raycast: return
	if building:
		if _raycast.is_colliding():
			var node := _raycast.get_collider()
			preview_conveyor.visible = true
			preview_conveyor.start = pos_a
			preview_conveyor.start_normal = nor_a
			if not node is ConveyorPort:
				preview_conveyor.end = _raycast.get_collision_point()
				preview_conveyor.end_normal = Vector3.FORWARD.rotated(Vector3.UP, preview_ang)
			else:
				preview_conveyor.end = node.global_position
				preview_conveyor.end_normal = -node.global_transform.basis.z
			ang = preview_conveyor.update(false)
			if ang < 25:
				preview_material.albedo_color = Color(0, 0.8, 0, 0.4)
			else:
				preview_material.albedo_color = Color(0.8, 0, 0, 0.4)
		else:
			preview_conveyor.visible = false
			preview_conveyor.reset()
	else:
		preview_conveyor.visible = false
		preview_conveyor.reset()
	
	if Input.is_action_just_pressed("conveyor_place") and _raycast.is_colliding():
		var node := _raycast.get_collider()
		if node is ConveyorPort:
			var port := node as ConveyorPort
			if port.occupied: 
				print("Port is full")
				return
			var pos := port.global_position
			var normal := -port.global_transform.basis.z
			if not building:
				pos_a = pos
				nor_a = normal
				port_a = port
				building = true
			else:
				if port == port_a:
					print("same port!")
					return
				if ang > 25:
					print("invalid!")
					return
				var conveyor := Conveyor.new()
				conveyor.material = conveyor_material
				conveyor.start = pos_a
				conveyor.start_normal = nor_a
				conveyor.end = pos
				conveyor.end_normal = normal
				var reversed = port_a.direction == ConveyorPort.Direction.Input
				conveyor.update(true, reversed)
				if reversed:
					conveyor._port_a.connect_conveyor(port)
					conveyor._port_b.connect_conveyor(port_a)
				else:
					conveyor._port_a.connect_conveyor(port_a)
					conveyor._port_b.connect_conveyor(port)
				add_child(conveyor)
				building = false
		elif building:
			var conveyor = Conveyor.new()
			conveyor.material = conveyor_material
			conveyor.start = pos_a
			conveyor.start_normal = nor_a
			conveyor.end = _raycast.get_collision_point()
			conveyor.end_normal = Vector3.FORWARD.rotated(Vector3.UP, preview_ang)
			var reversed = port_a.direction == ConveyorPort.Direction.Input
			conveyor.update(true, reversed)
			conveyor._port_a.connect_conveyor(port_a)
			add_child(conveyor)
			building = false
	if Input.is_action_just_pressed("conveyor_cancel") and building:
		building = false
	if Input.is_action_just_pressed("conveyor_destroy"):
		if _raycast.is_colliding():
			var node = _raycast.get_collider().get_parent()
			if node is Conveyor:
				node.destroy()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			preview_ang += rotate_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			preview_ang -= rotate_speed


func set_raycast(new: RayCast3D):
	new.collide_with_areas = true
	_raycast = new
