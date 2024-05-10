extends StaticBody3D

class_name MineralField

var rock_num: int
var mineral_locations: Array[Vector3] = []

func _ready():
	for mineral in get_children():
		if mineral is MeshInstance3D:
			mineral_locations.append(mineral.get_global_transform().origin)
	rock_num = mineral_locations.size()

func mine_field(unit):
	unit.add_minerals()

func get_field_pos():
	if rock_num == 0:
		rock_num = mineral_locations.size()
	rock_num -= 1
	return mineral_locations[rock_num]

