extends Control

var paused = false setget set_paused


func _ready():
	visible = false


func _process(delta):
	if Input.is_action_just_pressed("pause"):
		self.paused = !paused


func set_paused(value):
	paused = value
	get_tree().paused = paused
	visible = paused


func _on_ResumeButton_pressed():
	self.paused = false


func _on_QuitButton_pressed():
	get_tree().quit(0)
