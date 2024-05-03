extends RigidBody3D

# player team = 0
# enemy team = 1
var team : int = 0
var team_colors : Dictionary = {
	0: preload("res://Project Assets/Materials/TeamBlueMat.tres"),
	1: preload("res://Project Assets/Materials/TeamRedMat.tres")
}

# Called when the node enters the scene tree for the first time.
func _ready():
	if team in team_colors:
		$SelectionRing.material_override = team_colors[team]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func select():
	$SelectionRing.show()

func deselect():
	$SelectionRing.hide()
