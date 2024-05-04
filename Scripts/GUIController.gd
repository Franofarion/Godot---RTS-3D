extends Control

var unit_img_button = preload("res://Scenes/unit_img_button.tscn")
var current_units = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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
