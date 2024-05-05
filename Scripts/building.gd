extends Node3D

class_name Building

@onready var units_hbox = $UnitProgressContainer/VBoxContainer/HBoxContainer
@onready var unit_destination = $UnitDestination
@onready var unit_progress_bar = $UnitProgressContainer/VBoxContainer/UnitProgressBar
@onready var unit_progress_bar_container = $UnitProgressContainer
@onready var nav_mesh = get_parent()

# player team = 0
# enemy team = 1
var team : int = 0
var team_colors : Dictionary = {
	0: preload("res://Project Assets/Materials/TeamBlueMat.tres"),
	1: preload("res://Project Assets/Materials/TeamRedMat.tres")
}

const worker_unit = preload("res://Scenes/worker.tscn")
const warrior_unit = preload("res://Scenes/warrior.tscn")
const worker_unit_img = preload("res://Project Assets/GUI/WorkerImg.jpg")
const warrior_unit_img = preload("res://Project Assets/GUI/WarriorImg.jpg")
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
var units_images = []
var unit_building
var can_build = true

var health = 100.0
var progress_start = 10.0
var active = true
var is_rotating = false

const unit_img_button = preload("res://Scenes/unit_img_button.tscn")

var new_tween: Tween
var tween_callable_spawn_unit = Callable(self, "spawn_unit")
var tween_callable_spawn_repeat = Callable(self, "spawn_repeat")

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

func add_unit_to_spawn(unit):
	if current_created_units < max_units:
		var unit_img = unit_img_button.instantiate()
		unit_img.texture_normal = spawning_img
		current_created_units += 1
		units_hbox.add_child(unit_img)
		var callable = Callable(self, "cancel_unit")
		unit_img.pressed.connect(callable.bind(unit_img, unit))
		units_images.append(unit_img)
		units_to_spawn.append(unit)
		if current_created_units == 1:
			var tween := get_tree().create_tween()
			new_tween = tween
			new_tween.tween_property(unit_progress_bar, "value", 100.0, 3)
			spawn_repeat()
			unit_progress_bar_container.visible = true 

func spawn_repeat():
	new_tween.finished.connect(tween_callable_spawn_unit)

func spawn_unit():
	new_tween.stop()
	var unit = spawning_unit.instantiate()
	units_to_spawn.remove_at(0)
	units_images.remove_at(0)
	units_hbox.get_child(0).queue_free()
	
	var spawn_pos = NavigationServer3D.map_get_closest_point(
		get_world_3d().get_navigation_map(), $UnitSpawnPoint.global_transform.origin
	)
	nav_mesh.add_child(unit)
	unit.global_transform.origin = spawn_pos
	unit.move_to(unit_destination.global_transform.origin)
	
	unit_progress_bar.value = 0
	current_created_units -= 1
	
	# burk
	repeat_or_finish_spawning()

func repeat_or_finish_spawning():
	if current_created_units == 0:
		new_tween.kill()
		unit_progress_bar_container.visible = false
	else:
		new_tween.play()
		new_tween.tween_callback(tween_callable_spawn_repeat)
		unit_progress_bar_container.visible = true

func cancel_unit(img, unit):
	if units_images[0] == img:
		unit_progress_bar.value = 0
		new_tween.stop()
		new_tween.play()
	units_to_spawn.erase(unit)
	unit.queue_free()
	units_images.erase(unit)
	img.queue_free()
	current_created_units -= 1
	repeat_or_finish_spawning()

func move_to(target_pos):
	var closest_pos = NavigationServer3D.map_get_closest_point(
		get_world_3d().get_navigation_map(), target_pos
	)
	unit_destination.global_transform.origin = closest_pos
	
