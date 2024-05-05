extends Control

#Units and building scenes
const main_building: PackedScene = preload("res://Scenes/main_building.tscn")
const unit_building: PackedScene = preload("res://Scenes/unit_building.tscn")
const worker_unit: PackedScene = preload("res://Scenes/worker.tscn")
const warrior_unit: PackedScene = preload("res://Scenes/warrior.tscn")

const main_building_img: CompressedTexture2D = preload("res://Project Assets/GUI/MainBuildingImg.jpg")
const unit_building_img: CompressedTexture2D = preload("res://Project Assets/GUI/UnitBuildingImg.jpg")
const worker_unit_img: CompressedTexture2D = preload("res://Project Assets/GUI/WorkerImg.jpg")
const warrior_unit_img: CompressedTexture2D = preload("res://Project Assets/GUI/WarriorImg.jpg")

@onready var main_unit_img = $MainUnitImgContainer/MainUnitImg
@onready var button_one_img = $SelectionBar/BuildingGrid/OptionButtonOne
@onready var button_two_img = $SelectionBar/BuildingGrid/OptionButtonTwo
@onready var minerals_label = $Minerals/Label

var unit_img_button = preload("res://Scenes/unit_img_button.tscn")
var current_units = []
var button_one_unit
var button_two_unit
var minerals : int = 5000

# Called when the node enters the scene tree for the first time.
func _ready():
	minerals_label.text = str(minerals)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_rts_controller_units_selected(units):
	current_units = units
	var units_grid = $UnitsGrid
	for n in units_grid.get_children():
		units_grid.remove_child(n)
		n.queue_free()
	for i in range(1, len(units)):
		var img_button = unit_img_button.instantiate()
		units_grid.add_child(img_button)
		# This looks useless AF
		img_button.texture_normal = units[i].unit_img
	
	main_unit_img.texture = current_units[0].unit_img
	set_button_images()

func hide_buttons():
	for button in $SelectionBar/BuildingGrid.get_children():
		button.visible = false

func show_buttons(active_buttons_num):
	hide_buttons()
	for i in range(active_buttons_num):
		$SelectionBar/BuildingGrid.get_child(i).visible = true


func _on_option_button_one_pressed():
	pass # Replace with function body.


func _on_option_button_two_pressed():
	pass # Replace with function body.

func set_button_images():
	if current_units[0] is MainBuilding:
		show_buttons(1)
		button_one_unit = worker_unit
		button_one_img.texture_normal = worker_unit_img
	if current_units[0] is UnitBuilding:
		show_buttons(1)
		button_one_unit = warrior_unit
		button_one_img.texture_normal = warrior_unit_img
	if current_units[0] is Worker:
		show_buttons(2)
		button_one_unit = main_building
		button_one_img.texture_normal = main_building_img
		button_two_unit = unit_building
		button_two_img.texture_normal = unit_building_img
	if current_units[0] is Warrior:
		hide_buttons()

func spend_minerals(num):
	if minerals >= num:
		minerals -= num
		minerals_label.text = str(minerals)

func add_minerals(num):
	minerals += num
	minerals_label.text = str(minerals)
