extends Node2D

onready var spawnPoint = $SpawnPoint
onready var levelPortal = $LevelPortal

export(bool) var finalLevel = false


func is_final_level():
	return finalLevel


func get_spawn_point():
	return spawnPoint.global_position


func activate_portal():
	levelPortal.active = true


func deactivate_portal():
	levelPortal.active = false


func reset_level():
	"""
	This can be overriden by instances of a level
	to execute any time a level is reloaded.
	"""
	pass
