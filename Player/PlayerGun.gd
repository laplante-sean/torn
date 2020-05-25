extends Node2D

onready var animationPlayer = $AnimationPlayer

export(bool) var follow_mouse = true


func _physics_process(_delta):
	if follow_mouse:
		var sprite = get_parent()
		rotation = sprite.get_local_mouse_position().angle()


func play_death_animation():
	animationPlayer.play("Die")
