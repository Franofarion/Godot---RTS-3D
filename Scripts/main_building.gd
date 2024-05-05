extends Building

class_name MainBuilding

func _ready():
	super._ready()
	building_type = building_types.MAIN_BUILDING
	cost = 500
	units_img = preload("res://Project Assets/GUI/MainBuildingImg.jpg")
