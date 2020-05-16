extends StaticBody2D

onready var animationPlayer = $AnimationPlayer


func open():
	animationPlayer.play("Open")


func close():
	animationPlayer.play_backwards("Open")
