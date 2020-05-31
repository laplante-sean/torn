extends Control

var MainInstances = Utils.get_MainInstances()

onready var controlsMenu = $ControlsMenu


func _ready():
	VisualServer.set_default_clear_color(Color.black)


func load_world():
	"""
	Helper function used to change to the World scene
	"""
	get_tree().change_scene("res://World/World.tscn")


func _on_StartButton_pressed():
	MainInstances.is_new_game = true
	load_world()


func _on_QuitButton_pressed():
	get_tree().quit(0)


func _on_LoadButton_pressed():
	MainInstances.is_load_game = true
	load_world()


func _on_ControlsButton_pressed():
	controlsMenu.visible = true
