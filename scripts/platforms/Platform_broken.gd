extends StaticBody2D

onready var Game = get_parent()

var timer
var being_destroyed = false

func _ready():
	timer = Timer.new()
	timer.wait_time = 0.2
	timer.autostart = true
	timer.connect("timeout", self, "destroy")

func destroy():
	var par = $CPUParticles2D
	remove_child($CPUParticles2D)
	par.position = position
	Game.add_child(par)	
	par.start()
	par.emitting = true
	queue_free()

func touch(player):
	if not being_destroyed:
		being_destroyed = true
		$Sprites/SpritePlatformAnim.play()
		add_child(timer)
		$Sprites/ShakeModule.start()
