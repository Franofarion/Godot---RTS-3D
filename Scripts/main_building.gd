extends Building

class_name MainBuilding

func _ready():
	super._ready()
	building_type = building_types.MAIN_BUILDING
	cost = 500
	spawning_unit = worker_unit
	spawning_img = worker_unit_img
	unit_img = preload("res://Project Assets/GUI/MainBuildingImg.jpg")
