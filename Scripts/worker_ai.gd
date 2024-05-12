extends Worker



# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	team = 1


func _on_attack_timer_timeout():
	search_for_ennemies("units")
