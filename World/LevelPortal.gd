extends Area2D

export(String, FILE, "*.tscn") var next_level_path = ""

var active = true

onready var newLevelSpawn = $NewLevelSpawn


func get_next_level_spawn_loc():
	return newLevelSpawn.global_position


func _on_LevelPortal_body_entered(player):
	if active:
		player.emit_signal("hit_door", self)
		active = false
