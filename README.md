# CurvyConveyors

Simple Godot addon for building Satisfactory-like curvy conveyor belts

## How to use
0. Download the repo
1. Move the `addons` folder into your project
2. Add input mappings for `conveyor_place`, `conveyor_cancel` and `conveyor_destroy` 
2. Add a ConveyorBuilder node to every scene that you want conveyors to be buildable
3. In your player's `_ready` function, call `%ConveyorBuilder.set_raycast` with the
	raycast that will be used to build the conveyors
4. Add `ConveyorPort` nodes wherever necessary
	- Conveyors will start and end at the position of the port, position your visuals according to
		that
	- Since `ConveyorPort` extends `Area3D`, it will complain about not having a `CollisionShape3D`.
		The node will create its own `CollisionShape3D` at `_ready`, you don't have to add one
5. Start building!

## API

Usually, you'll only need to use two methods of `ConveyorPort`, `pull_item` and `push_item`.
- `push_item`, takes a Node3D, which should be the item that will move on the conveyor. Ideally it
	will also take some metadata for when you call `pull_item` later. Returns a bool, `true` if item
	was put on the conveyor successfully, `false` if the conveyor is full, or there's no conveyors
	connected.
- `pull_item` should be called whenever your machine is ready to take an item to its own internal
	inventory. It will return the same Node3D you gave `push_item`.

## Performance
idk
