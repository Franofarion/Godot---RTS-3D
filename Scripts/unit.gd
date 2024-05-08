extends RigidBody3D

class_name Unit

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

func _on_navigation_agent_3d_target_reached():
	change_state("idle")


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	set_linear_velocity(safe_velocity)
