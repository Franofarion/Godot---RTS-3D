extends Unit

class_name Worker

func _ready():
	super._ready()
	unit_type = unit_types.WORKER
	cost = 35
	damage = 5
	unit_img = preload("res://Project Assets/GUI/WorkerImg.jpg")

