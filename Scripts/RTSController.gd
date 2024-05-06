extends Node3D

const MOVE_MARGIN : int = 20
const MOVE_SPEED : int = 15
@onready var cam : Camera3D = $Camera3D
@onready var selection_box : Node = $UnitSelector
var m_pos := Vector2()
@export var units_in_circle : int = 4
@export var units_in_line: int = 6

signal units_selected(units: Array)

# team worker
var team : int = 0
const ray_length : int = 1000
var selected_units : Array = []
var old_selected_units : Array = []
var start_sel_pos = Vector2()
var target_positions_list : Array[Vector3] = []
var unit_pos_index = 0

const selection_limit = 24

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("wheel_down"):
		cam.fov = lerp(cam.fov, 75.0, 0.25)
	elif event.is_action_pressed("wheel_up"):
		cam.fov = lerp(cam.fov, 25.0, 0.25)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	m_pos = get_viewport().get_mouse_position()
	camera_movement(delta)
	
	# Inputs 
	if Input.is_action_just_pressed("command"):
		move_selected_units()
	if Input.is_action_just_pressed("select"):
		selection_box.start_pos = m_pos
		start_sel_pos = m_pos
	if Input.is_action_just_released("select"):
		select_units()
	if Input.is_action_pressed("select"):
		selection_box.m_pos = m_pos
		selection_box.is_visible = true
	else:
		selection_box.is_visible = false

func camera_movement(delta):
	var viewport_size : Vector2 = get_viewport().size
	var origin : Vector3 = global_transform.origin
	var move_vec := Vector3()
	# wtf is that 
	if origin.x > -62:
		if m_pos.x < MOVE_MARGIN:
			move_vec.x -= 1
	if origin.z > -65:
		if m_pos.y < MOVE_MARGIN:
			move_vec.z -= 1 
	if origin.x < 62:
		if m_pos.x > viewport_size.x - MOVE_MARGIN:
			move_vec.x += 1
	if origin.z < 90:
		if m_pos.y > viewport_size.y - MOVE_MARGIN:
			move_vec.z += 1
	move_vec = move_vec.rotated(Vector3(0, 1, 0), rad_to_deg(rotation.y))
	global_translate(move_vec  * delta * MOVE_SPEED)

func raycast_from_mouse(collision_mask):
	# standard position of the request
	var ray_start : Vector3 = cam.project_ray_origin(m_pos)
	
	var ray_end : Vector3 = ray_start + cam.project_ray_normal(m_pos) * ray_length
	var space_rate = get_world_3d().direct_space_state
	var prqp := PhysicsRayQueryParameters3D.new()
	
	prqp.from = ray_start
	prqp.to = ray_end
	prqp.collision_mask = collision_mask
	prqp.exclude = []
	return space_rate.intersect_ray(prqp)

func get_unit_under_mouse():
	## 0b110, second & third layer
	var result_unit = raycast_from_mouse(0b110)
	if result_unit and "team" in result_unit.collider and result_unit.collider.team == team:
		var selected_unit = result_unit.collider
		return selected_unit

func select_units():
	var main_unit = get_unit_under_mouse()
	if selected_units.size() != 0:
		old_selected_units = selected_units
	selected_units = []
	if m_pos.distance_squared_to(start_sel_pos) < 16: 
		if main_unit != null:
			selected_units.append(main_unit)
	else:
		selected_units = get_unit_in_box(start_sel_pos, m_pos)
	
	if selected_units.size() != 0:
		clean_current_units_and_apply_new(selected_units)
		emit_signal("units_selected", selected_units)
	if selected_units.size() == 0:
		selected_units = old_selected_units

func clean_current_units_and_apply_new(new_units):
	for unit in get_tree().get_nodes_in_group("units"):
		# todo: add if deselect exist in unit
		unit.deselect()
	for unit in new_units:
		# todo: add if select exist in unit
		unit.select()

func move_selected_units():
	# get collision on first, second, third and sixth layers
	# 1 => Map / 2 => units / 3 => building / 6 => Resources
	var result = raycast_from_mouse(0b100111)
	unit_pos_index = 0
	if selected_units.size() != 0:
		var first_unit = selected_units[0]
		if result.collider.is_in_group("surface"):
			if first_unit is Building:
				first_unit.move_to(result.position)
			elif first_unit is Unit:
				for unit in selected_units:
					position_units(unit, result)

func get_unit_in_box(top_left, bot_right):
	if top_left.x > bot_right.x:
		var tmp = top_left.x
		top_left.x = bot_right.x
		bot_right.x = tmp
	if top_left.y > bot_right.y:
		var tmp = top_left.y
		top_left.y = bot_right.y
		bot_right.y = tmp
		
	var box = Rect2(top_left, bot_right - top_left)
	var box_selected_unit = []
	for unit in get_tree().get_nodes_in_group("units"):
		if (unit.team == team 
			and unit is Unit
			and box.has_point(cam.unproject_position(unit.global_transform.origin))):
			if box_selected_unit.size() <= selection_limit:
				box_selected_unit.append(unit)
	return box_selected_unit

func create_units_position_in_a_circle(target_pos: Vector3, units_num: int):
	var position_list : Array[Vector3] = []
	var radius : float = 1.0
	var center = Vector2(target_pos.x, target_pos.z)
	var max_units_in_circle = units_in_circle
	var angle_step = PI * 2 / max_units_in_circle
	var angle = 0
	var unit_count = 0
	for i in range(0, units_num):
		if unit_count == max_units_in_circle:
			radius += 1
			unit_count = 0
			angle = 0
			max_units_in_circle *= 2
			angle_step = PI * 2 / max_units_in_circle
		var direction = Vector2(cos(angle), sin(angle))
		var pos = center + direction * radius
		var pos_3d = Vector3(pos.x, 0, pos.y)
		position_list.append(pos_3d)
		unit_count += 1
		angle += angle_step
	return position_list

func create_units_position_in_a_rect(target_pos: Vector3, units_num: int) -> Array[Vector3]:
	var line_position_list: Array[Vector3] = []
	var position_list: Array[Vector3] = []
	var new_target_position = target_pos
	var x_pos = 1
	var z_pos = 1
	var num_of_lines = ceil(units_num / units_in_line)
	for i in units_in_line:
		line_position_list.append(new_target_position)
		position_list.append(new_target_position)
		new_target_position = Vector3(target_pos.x + x_pos, target_pos.y, target_pos.z)
		if i%2 == 1:
			x_pos -= 1
		x_pos = -x_pos
	for i in num_of_lines:
		for k in units_in_line:
			var new_pos = Vector3(line_position_list[k].x,
									line_position_list[k].y,
									line_position_list[k].z + z_pos)
			position_list.append(new_pos)
		if i%2 == 1:
			z_pos -= 1
		z_pos = -z_pos
	return position_list


func position_units(unit, result):
	target_positions_list = create_units_position_in_a_rect(result.position, len(selected_units))
	unit.move_to(target_positions_list[unit_pos_index])
	unit_pos_index += 1
