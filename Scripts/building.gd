extends Node3D

class_name Building

@onready var units_hbox = $UnitProgressContainer/VBoxContainer/HBoxContainer
@onready var unit_destination = $UnitDestination
@onready var unit_progress_bar = $UnitProgressContainer/VBoxContainer/UnitProgressBar
@onready var unit_progress_bar_container = $UnitProgressContainer
@onready var nav_mesh = get_parent()
@onready var unit_health_bar = $HealthBar/SubViewport/HealthProgressBar
@onready var rts_controller = get_tree().get_root().get_node("World/RTSController")
@onready var gui_controller = get_tree().get_root().get_node("World/CanvasLayer/GUIController")


# player team = 0
# enemy team = 1
var team : int = 0
var team_colors : Dictionary = {
	0: preload("res://Project Assets/Materials/TeamBlueMat.tres"),
	1: preload("res://Project Assets/Materials/TeamRedMat.tres")
}

var green_mat = preload("res://Project Assets/Materials/GreenStracture.tres")
var red_mat = preload("res://Project Assets/Materials/RedStracture.tres")
var see_through_mat = preload("res://Project Assets/Materials/SeeThroughStracture.tres")

var selected: bool = false

const worker_unit = preload("res://Scenes/worker.tscn")
const warrior_unit = preload("res://Scenes/warrior.tscn")
const worker_unit_img = preload("res://Project Assets/GUI/WorkerImg.jpg")
const warrior_unit_img = preload("res://Project Assets/GUI/WarriorImg.jpg")
var unit_img = preload("res://Project Assets/GUI/MainBuildingImg.jpg")
const building_process_img = preload("res://Project Assets/GUI/progress_bar.png")
const building_health_img = preload("res://Project Assets/GUI/HealthBar.png")


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
	unit_health_bar.value = health

func _process(delta):
	if under_construction:
		$HealthBar.visible = false
		rts_controller.is_building = true
		var raycast_pos = rts_controller.raycast_from_mouse(1).position
		if !is_rotating:
			self.position = raycast_pos
		if Input.is_action_pressed("select"):
			is_rotating = true
			if raycast_pos != global_transform.origin:
				look_at(raycast_pos)
		elif Input.is_action_just_pressed("select") and !can_build and is_rotating:
			is_rotating = false
		elif Input.is_action_just_released("select") and can_build and is_rotating:
			unit_health_bar.texture_progress = building_process_img
			unit_health_bar.value = progress_start
			$HealthBar.visible = true
			$BuildArea/CollisionShape3D.disabled = true
			$Mesh.material_override = see_through_mat
			nav_mesh.bake_navigation_mesh()
			$CollisionShape3D.disabled = false
			nav_mesh.bake_finished.connect(send_unit, CONNECT_ONE_SHOT)
			under_construction = false
			self.set_process(false)
		
		if Input.is_action_just_pressed("command"):
			rts_controller.is_building = false
			gui_controller.add_minerals(cost)
			queue_free()

func send_unit():
	unit_building.call_deferred("build_structure", self)
	rts_controller.is_building = false

func create_structure(unit):
	$Mesh.material_override = green_mat
	under_construction = true
	$CollisionShape3D.disabled = true
	unit_building = unit

func activate_building():
	active = true
	$Mesh.material_override = null
	$CollisionShape3D.disabled = false
	unit_health_bar.texture_progress = building_health_img

func add_health(unit):
	if unit_health_bar.value == 100:
		unit.change_state("idle")
		activate_building()
		return
	unit_health_bar.value += 1
func select():
	selected = false
	$BuildingRing.visible = true
	unit_destination.visible = true
	if current_created_units != 0:
		unit_progress_bar_container.visible = true

func deselect():
	selected = false
	$BuildingRing.visible = false
	unit_destination.visible = false
	unit_progress_bar_container.visible = false
	

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
			new_tween.finished.connect(tween_callable_spawn_unit)			
			spawn_repeat()
			unit_progress_bar_container.visible = true 

func spawn_repeat():
	new_tween.play()

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
		spawn_repeat()
		new_tween.tween_callback(tween_callable_spawn_repeat)
	if current_created_units != 0 and selected:
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

func _on_build_area_body_entered(body):
	if under_construction:
		$Mesh.material_override = red_mat
		can_build = false


func _on_build_area_body_exited(body):
	if $BuildArea.get_overlapping_bodies().size() == 0:
		$Mesh.material_override = green_mat
		can_build = true
