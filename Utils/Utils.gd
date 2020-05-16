extends Node


func instance_scene_on_main(packed_scene, position):
	"""
	Helper method that takes a packed scene, creates an instance
	of it, then adds it as a child to the current scene, sets the
	global position and returns the instance.
	
	:param packed_scene: A packed scene usually loaded with preload()
	:param position: Vector2 to set as the new instance's global_position
	:returns: The newly created instance
	"""
	var main = get_tree().current_scene
	var instance = packed_scene.instance()
	main.add_child(instance)
	instance.global_position = position
	return instance


func get_MainInstances():
	"""
	Helper method to load our MainInstances resource which
	allows for shared access to things like the player,
	player camera, etc...

	:returns: The MainInstances resource.
	"""
	return ResourceLoader.load("res://MainInstances/MainInstances.tres")
