extends "res://Levels/Level.gd"

onready var button = $Button
onready var door = $Door


func _ready():
	button.connect("button_pressed", self, "_on_Button_pressed")
	button.connect("button_released", self, "_on_Button_released")


func _on_Button_pressed():
	door.open()


func _on_Button_released():
	door.close()
