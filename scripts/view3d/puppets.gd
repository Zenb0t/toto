class_name Puppets
extends Node3D
## 3D stand-ins for 2D actors. Every frame each model moves to where its actor is on the 2D plane, shows
## only while the actor does, and goes away with it. An optional pose callback copies anything else the
## model shows (where it faces, its health...).


class Puppet:
	var actor: Node2D
	var model: Node3D
	var pose: Callable

	func _init(followed: Node2D, stand_in: Node3D, posing: Callable) -> void:
		actor = followed
		model = stand_in
		pose = posing


var _puppets: Array[Puppet] = []


## pose, if given, is called with the model after it has moved.
func add(actor: Node2D, model: Node3D, pose := Callable()) -> void:
	add_child(model)
	var puppet := Puppet.new(actor, model, pose)
	_puppets.append(puppet)
	_follow(puppet)


func count() -> int:
	return _puppets.size()


func _process(_delta: float) -> void:
	for puppet in _puppets.duplicate():
		if is_instance_valid(puppet.actor):
			_follow(puppet)
		else:
			_puppets.erase(puppet)
			puppet.model.queue_free()


## An actor that isn't in the world yet (things placed a frame late) stays hidden until it is.
func _follow(puppet: Puppet) -> void:
	if not puppet.actor.is_inside_tree():
		puppet.model.visible = false
		return
	puppet.model.position = WorldSpace.to_3d(puppet.actor.global_position)
	puppet.model.visible = puppet.actor.is_visible_in_tree()
	if puppet.pose.is_valid():
		puppet.pose.call(puppet.model)
