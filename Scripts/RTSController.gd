extends Node3D

const MOVE_MARGIN : int = 20
const MOVE_SPEED : int = 15
@onready var cam : Camera3D = $Camera3D
var m_pos := Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("wheel_down"):
		cam.fov = lerp(cam.fov, 75.0, 0.25)
	elif event.is_action_pressed("wheel_up"):
		cam.fov = lerp(cam.fov, 45.0, 0.25)		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	m_pos = get_viewport().get_mouse_position()
	camera_movement(m_pos, delta)

func camera_movement(m_pos_p, delta):
	var viewport_size : Vector2 = get_viewport().size
	var origin : Vector3 = global_transform.origin
	var move_vec := Vector3()
	# wtf is that 
	if origin.x > -62:
		if m_pos_p.x < MOVE_MARGIN:
			move_vec.x -= 1
	if origin.z > -65:
		if m_pos_p.y < MOVE_MARGIN:
			move_vec.z -= 1 
	if origin.x < 62:
		if m_pos_p.x > viewport_size.x - MOVE_MARGIN:
			move_vec.x += 1
	if origin.z < 90:
		if m_pos_p.y > viewport_size.y - MOVE_MARGIN:
			move_vec.z += 1
	move_vec = move_vec.rotated(Vector3(0, 1, 0), rad_to_deg(rotation.y))
	global_translate(move_vec  * delta * MOVE_SPEED)
