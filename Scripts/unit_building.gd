extends Building

class_name UnitBuilding

func _ready():
	super._ready()
	building_type = building_types.UNIT_BUILDING
	cost = 300
	units_img = preload("res://Project Assets/GUI/UnitBuildingImg.jpg")
