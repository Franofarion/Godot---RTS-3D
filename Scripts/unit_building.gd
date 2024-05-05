extends Building

class_name UnitBuilding

func _ready():
	super._ready()
	building_type = building_types.UNIT_BUILDING
	cost = 300
	spawning_unit = warrior_unit
	spawning_img = warrior_unit_img
	unit_img = preload("res://Project Assets/GUI/UnitBuildingImg.jpg")
