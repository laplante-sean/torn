extends Control


func _ready():
	VisualServer.set_default_clear_color(Color.black)


func _on_BackToTitleTimer_timeout():
	get_tree().change_scene("res://Menus/StartMenu.tscn")
