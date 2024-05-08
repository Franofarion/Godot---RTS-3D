extends Unit

class_name Worker

@onready var build_timer = $WorkTimer
@onready var mine_timer = $MineTimer

var minerals : int = 0
var structure_to_build
var mineral_field_to_mine
var rock_mine = false
var mine_point : Vector3

func _ready():
	super._ready()
	unit_type = unit_types.WORKER
	cost = 35
	damage = 5
	unit_img = preload("res://Project Assets/GUI/WorkerImg.jpg")

func create_structure(structure):
	structure.position = NavigationServer3D.map_get_closest_point(get_world_3d().get_navigation_map(), rts_controller.raycast_from_mouse(1).position)
	structure.create_structure(self)
	nav_region.add_child(structure)

func build_structure(structure):
	structure_to_build = structure
	move_to(lerp_from_self(structure_to_build.get_global_transform().origin))
	change_state("building")

func work():
	speed = 0.00001
	state_machine.travel("Build")
	build_timer.start()

func move_to(target_pos):
	super.move_to(target_pos)
	build_timer.stop()

func _on_navigation_agent_3d_target_reached():
	if current_state == states.BUILDING:
		work()
	else:
		build_timer.stop()
		change_state("idle")

func lerp_from_self(position):
	var change_point_by = 0
	var point = position.lerp(get_global_transform().origin, change_point_by)
	var desired_distance = 2.5
	
	while point.distance_to(position) < desired_distance:
		change_point_by += 0.01
		point = position.lerp(get_global_transform().origin, change_point_by)
		if point.distance_to(position) >= desired_distance:
			break
	return point

func _on_work_timer_timeout():
	structure_to_build.add_health(self)


func _on_mine_timer_timeout():
	pass # Replace with function body.
