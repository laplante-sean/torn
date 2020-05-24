extends StaticBody2D

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
			player.emit_signal("level_complete", self)
	else:
		sprite.frame = 0


func _on_PlayerDetector_body_entered(player):
	self.player = player
	if self.active:
		player.emit_signal("level_complete", self)
