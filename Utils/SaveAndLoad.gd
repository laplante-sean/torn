extends Node

const SAVE_DATA_PATH = "res://torn_save_data.json"

var default_save_data = {
	level = "res://Levels/Level_00.tscn"
}


func save_data_to_file(save_data):
	"""
	Write a file with the current save data
	
	:param save_data: Data to save to the file
	"""
	var json_string = to_json(save_data)
	var save_file = File.new()
	save_file.open(SAVE_DATA_PATH, File.WRITE)
	save_file.store_line(json_string)
	save_file.close()


func load_data_from_file():
	"""
	Load save data from our save location
	
	:returns: The loaded save data or the default save data if a new game.
	"""
	var save_file = File.new()
	if not save_file.file_exists(SAVE_DATA_PATH):
		return default_save_data
		
	save_file.open(SAVE_DATA_PATH, File.READ)
	var save_data = parse_json(save_file.get_as_text())
	save_file.close()
	return save_data
