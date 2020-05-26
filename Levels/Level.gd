extends Node2D

onready var spawnPoint = $SpawnPoint
onready var levelPortal = $LevelPortal


func get_spawn_point():
	return spawnPoint.global_position


func activate_portal():
	levelPortal.active = true


func deactivate_portal():
	levelPortal.active = false
