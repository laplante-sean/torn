extends StaticBody2D

const BreakTheLoop = preload("res://UI/BreakTheLoop.tscn")

export(String, FILE, "*.tscn") var next_level_path = ""

var player = null
var active = true setget set_active

onready var sprite = $Sprite
onready var playerDetector = $PlayerDetector
onready var playerDetectCollisionShape = $PlayerDetector/CollisionShape2D


func set_active(value):
	active = value
	if value:
		sprite.frame = 1
		if player != null:
			player.emit_signal("exit_level", self)
	else:
		sprite.frame = 0


func _on_PlayerDetector_body_entered(player):
	self.player = player
	if self.active:
		player.emit_signal("exit_level", self)
	else:
		Events.emit_signal("add_camera_shake", 0.25, 0.5)
		Utils.instance_scene_on_main(BreakTheLoop, player.global_position - Vector2(0, 30))


func _on_PlayerDetector_body_exited(body):
	self.player = null
