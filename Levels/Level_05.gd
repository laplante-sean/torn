extends "res://Levels/Level.gd"

const target_scene = preload("res://World/Target.tscn")

var num_destroyed = 0
var positions = []

onready var button = $Button
onready var door = $Door
onready var door2 = $Door2
onready var target = $Target
onready var target2 = $Target2
onready var target3 = $Target3


func _ready():
	button.connect("button_pressed", self, "_on_Button_pressed")
	button.connect("button_released", self, "_on_Button_released")
	target.connect("destroyed", self, "_on_Target_destroyed")
	target.connect("destroyed", self, "_on_Target_destroyed")
	target2.connect("destroyed", self, "_on_Target_destroyed")
	target3.connect("destroyed", self, "_on_Target_destroyed")


func _on_Button_pressed():
	door.open()


func _on_Button_released():
	door.close()


func reset_level():
	print("RESET")
	door2.close()
	num_destroyed = 0
	
	for pos in positions:
		Utils.instance_scene_on_main(target_scene, pos)


func _on_Target_destroyed(targ):
	if num_destroyed == 3:
		num_destroyed = 0  # Reset
	
	positions.push_back(targ.global_position)
	num_destroyed += 1
	if num_destroyed == 3:
		door2.open()
		door.close()
