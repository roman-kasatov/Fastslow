extends AnimatedSprite

onready var Game = get_parent()


var speed = 2.0
var time_to_live = 5.0
var angle_min = 30.0
var angle_max = 60.0

var angle = 0.0
var timer : Timer

func _ready():
	print(1, position)
	angle = (angle_min + randf() * (angle_max - angle_min)) * PI / 180
	timer = Timer.new()
	timer.wait_time = time_to_live
	timer.autostart = true
	timer.connect("timeout", self, "delete")
	add_child(timer)

func _physics_process(delta):
	position += Vector2(speed * cos(angle), speed * sin(angle))

func delete():
	queue_free()
