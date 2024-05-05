extends Node3D

class_name Building

@onready var unit_destination = $UnitDestination

# player team = 0
# enemy team = 1
var team : int = 0
var team_colors : Dictionary = {
	0: preload("res://Project Assets/Materials/TeamBlueMat.tres"),
	1: preload("res://Project Assets/Materials/TeamRedMat.tres")
}

var unit_img = preload("res://Project Assets/GUI/MainBuildingImg.jpg")

enum building_types {MAIN_BUILDING, UNIT_BUILDING}
var building_type

var spawning_unit
var spawning_img

var units_to_spawn = []
var under_construction = false

var cost: int = 200
var max_units: int = 4
var current_created_units: int = 0
var units_img = []
var unit_building
var can_build = true

var health = 100.0
var progress_start = 10.0
var active = true
var is_rotating = false

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("units")
	if team in team_colors:
		$BuildingRing.material_override = team_colors[team]
	unit_destination.position = $UnitSpawnPoint.position + Vector3(0.1, 0, 0.1)

func select():
	$BuildingRing.visible = true
	unit_destination.visible = true

func deselect():
	$BuildingRing.visible = false
	unit_destination.visible = false


