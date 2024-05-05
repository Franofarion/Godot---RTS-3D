extends Unit

func _ready():
	super._ready()
	unit_type = unit_types.WARRIOR
	cost = 65
	damage = 10
	unit_img = preload("res://Project Assets/GUI/WarriorImg.jpg")

