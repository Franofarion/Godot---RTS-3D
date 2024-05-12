extends RigidBody3D

class_name Unit

var units_in_vision: Array = []
var units_in_attack_radius: Array = []
var speed : float
var rotation_speed : int = 10
var vel : Vector3
var state_machine
enum states {IDLE, WALKING, ATTACKING, MINING, BUILDING}
var current_state = states.IDLE
@onready var animation_tree = $AnimationTree
@onready var unit_health_bar = $HealthBar/SubViewport/HealthProgressBar
@onready var rts_controller = get_tree().get_root().get_node("World/RTSController")
@onready var gui_controller = get_tree().get_root().get_node("World/CanvasLayer/GUIController")
@onready var nav_region = get_parent()

enum unit_types {WORKER, WARRIOR}
var unit_type
var current_enemy

var health: int = 100.0
var damage: int = 5.0
var cost: int = 50
var force_accel = 5
var unit_img = preload("res://Project Assets/GUI/WorkerImg.jpg")

# player team = 0
# enemy team = 1
var team : int = 0
var team_colors : Dictionary = {
	0: preload("res://Project Assets/Materials/TeamBlueMat.tres"),
	1: preload("res://Project Assets/Materials/TeamRedMat.tres")
}

# Called when the node enters the scene tree for the first time.
func _ready():
	unit_health_bar.value = health
	state_machine = animation_tree.get("parameters/playback")
	speed = 0
	if team in team_colors:
		$SelectionRing.material_override = team_colors[team]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var target = $NavigationAgent3D.get_next_path_position()
	var pos = get_global_transform().origin
	
	var n = $RayCast3D.get_collision_normal()
	if n.length_squared() < 0.001:
		n = Vector3(0, 1, 0)
	
	vel = (target - pos).slide(n).normalized() * speed
	
	for unit in units_in_vision:
		var force_vector = (self.global_transform.origin - unit.global_transform.origin).normalized()
		force_vector = Vector3(force_vector.x, 0, force_vector.y)
		apply_central_force(force_vector * force_accel)
	
	
	$Armature.rotation.y = lerp_angle($Armature.rotation.y, atan2(vel.x, vel.z), delta * rotation_speed)
	
	$NavigationAgent3D.set_velocity(vel)

func select():
	$SelectionRing.show()

func deselect():
	$SelectionRing.hide()

func change_state(state):
	# todo optimize
	match state:
		"idle":
			current_state = states.IDLE
			speed = 0.000001
			state_machine.travel("Idle")
		"walking":
			current_state = states.WALKING
			state_machine.travel("Walk")
			speed = 2
		"attacking":
			current_state = states.ATTACKING
		"mining":
			current_state = states.MINING
		"building":
			current_state = states.BUILDING

func move_to(target_pos):
	change_state("walking")
	var closest_pos = NavigationServer3D.map_get_closest_point(get_world_3d().get_navigation_map(), target_pos)
	$NavigationAgent3D.set_target_position(closest_pos)
	
func look_at_target(target_pos):
	var closest_pos = NavigationServer3D.map_get_closest_point(get_world_3d().get_navigation_map(), target_pos)
	$NavigationAgent3D.set_target_position(closest_pos)
	
func attack(): 
	speed = 0.0001
	state_machine.travel("Attack")

func get_closest_available_enemy_unit(group_name):
	var lowest_distance = 0
	units_in_attack_radius = $AttackRadius.get_overlapping_bodies()
	for unit in units_in_attack_radius:
		if unit.is_in_group(group_name):
			var distance_between = global_transform.origin.distance_to(unit.global_transform.origin)
			if lowest_distance == 0 or distance_between <= lowest_distance:
				current_enemy = unit
				lowest_distance = distance_between

func search_for_ennemies(group_name):
	if current_state == states.IDLE or current_state == states.ATTACKING:
		get_closest_available_enemy_unit(group_name)
		if current_enemy == null:
			$NavigationAgent3D.time_horizon_agents = 2
			force_accel = 5
			change_state("idle")
		else: 
			$NavigationAgent3D.time_horizon_agents = 1.5
			if units_in_attack_radius.has(current_enemy):
				var enemy_reached = self.global_transform.origin.distance_to(current_enemy.global_transform.origin) <= 1.5
				if !enemy_reached:
					move_to(current_enemy.get_global_transform().origin)
					force_accel = 5
				else: 
					look_at_target(current_enemy.get_global_transform().origin)
					attack()
					force_accel = 40
				change_state("attacking")

func attack_enemy():
	if current_enemy != null:
		current_enemy.lower_health(damage)

func lower_health(damage_inflected):
	health -= damage_inflected
	unit_health_bar.value = health
	if health <= 0:
		queue_free()

func _on_navigation_agent_3d_target_reached():
	change_state("idle")

func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	set_linear_velocity(safe_velocity)

func _on_vision_body_entered(body):
	if body is Unit:
		units_in_vision.append(body)

func _on_vision_body_exited(body):
	if body is Unit:
		units_in_vision.erase(body)

func _on_attack_radius_body_entered(body):
	if body is Unit:
		units_in_attack_radius.append(body)

func _on_attack_radius_body_exited(body):
	if body is Unit:
		units_in_attack_radius.erase(body)
