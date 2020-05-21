extends "res://Levels/Level.gd"

onready var button = $Button
onready var button2 = $Button2
onready var door = $Door
onready var door2 = $Door2


func _ready():
	button.connect("button_pressed", self, "_on_Button_pressed")
	button.connect("button_released", self, "_on_Button_released")
	button2.connect("button_pressed", self, "_on_Button2_pressed")
	button2.connect("button_released", self, "_on_Button2_released")


func _on_Button_pressed():
	door.open()


func _on_Button_released():
	door.close()


func _on_Button2_pressed():
	door2.open()


func _on_Button2_released():
	door2.close()
