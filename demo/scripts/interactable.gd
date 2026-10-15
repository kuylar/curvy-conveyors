class_name Interactable
extends Area3D

@export var conveyor: ConveyorPort

func interact():
	if not conveyor:
		print("no conveyor?? :(")
		return
	
	if conveyor.direction == ConveyorPort.Direction.Input:
		pull()
	else:
		push()

func push():
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3.ONE * .3
	mi.mesh = bm
	add_child(mi)
	mi.global_position = Vector3.DOWN * 100
	if not conveyor.push_item(mi):
		print("Failed!")
		mi.queue_free()

func pull():
	var item = conveyor.pull_item()
	if not item: print("Failed!")
	else:
		print(item.name)
		item.queue_free()
