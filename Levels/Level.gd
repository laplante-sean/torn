extends Node2D

const WORLD = preload("res://World/World.gd")

onready var spawnPoint = $SpawnPoint


func _ready():
	var parent = get_parent()
	if parent is WORLD:
		parent.currentLevel = self
