class_name ConveyorPort
extends Area3D

@export var direction: Direction
var CLICK_TARGET_Y_OFFSET := 0.45
var type: PortType = PortType.Persistent
var occupied = false
var other: ConveyorPort = null
var conveyor: Conveyor = null
var cs: CollisionShape3D

func _ready() -> void:
	cs = CollisionShape3D.new()
	cs.debug_color = Color(1, 0, 0, .5)
	cs.debug_fill = true
	var bs = BoxShape3D.new()
	bs.size = Vector3(1.2, 1.2, 0.2)
	cs.shape = bs
	add_child(cs)
	cs.position = Vector3(0, CLICK_TARGET_Y_OFFSET, 0)

func _process(_delta: float) -> void:
	if occupied:
		cs.debug_color = Color(0, 1, 0, .5)
	else:
		cs.debug_color = Color(1, 0, 0, .5)

func connect_conveyor(port: ConveyorPort) -> bool:
	if port.direction == direction:
		print("/!\\ port: %s | self: %s" % [port.direction, direction])
		return false
	if occupied or port.occupied:
		print("/!\\ port: %s | self: %s" % [port.occupied, occupied])
		return false
	other = port
	port._notify_connect(self)
	occupied = true
	return true

func disconnect_conveyor() -> void:
	if other:
		other._notify_disconnect()
	occupied = false

func _notify_disconnect():
	occupied = false
	other = null

func _notify_connect(port: ConveyorPort):
	occupied = true
	other = port

func push_item(item: Node3D, ignore_own_conveyor: bool = false) -> bool:
	if conveyor and not ignore_own_conveyor: return conveyor.add_item(item)
	if not other: return false
	return other._push_item(item)

func _push_item(item: Node3D) -> bool:
	if conveyor: return conveyor.add_item(item)
	return false

func pull_item() -> Node3D:
	print("pull, conveyor: %s, other: %s" % [not not conveyor, not not other])
	if conveyor: return conveyor.take_item()
	if not other: return null
	return other._pull_item()

func _pull_item() -> Node3D:
	print("_pull, conveyor: %s" % [not not conveyor, not not other])
	if conveyor: return conveyor.take_item()
	return null

enum PortType {
	Persistent,
	Conveyor
}

enum Direction {
	Input,
	Output
}
