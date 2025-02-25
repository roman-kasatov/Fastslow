extends KinematicBody2D

onready var Eyes = $Body/Eyes
onready var Mouth = $Body/Mouth
onready var Shake = preload("res://scenes/ShakeModule.tscn")

var timer_anim : Timer
var timer_safe_tick : Timer
var timer_safe : Timer

var gravity = 30
var max_fall_speed = 400
var min_speed = 200
var max_speed = 400
var jump_speed = 700
var boots_speed = 1
var height_to_fail #being calculated at the start at "PlatformManager" script
var was_falling = true
var shifted_time_left = 0
var safe = 0
var shining = 0
var can_pick = 1

var motion = Vector2(0, 0)
onready var Game = get_parent()
onready var Scarf = Game.get_node("Scarf")
var jump_left = 1

# bonuses
var shield_bn_active = false
var jetpack_bn_active = false
var jump_bn_left = 0
onready var shining_parts = [Scarf, $Legs, $Body, $Boots, $Jetpack]

var Floor_part = preload("res://scenes/particles/Floor_particles.tscn")
var Air_part = preload("res://scenes/particles/Air_particles.tscn")
var Air_part_boots = preload("res://scenes/particles/particles_air_boots.tscn")


func _ready():
	update_rate()
	timer_anim = Timer.new()
	timer_anim.wait_time = 2.0
	timer_anim.one_shot = true
	timer_anim.connect("timeout", self, "change_anim_usual")
	add_child(timer_anim)
	timer_safe_tick = Timer.new()
	timer_safe_tick.connect("timeout", self, "safe_tick")
	timer_safe = Timer.new()
	timer_safe.connect("timeout", self, "safe_stop")

func _physics_process(delta):
	if position.y > height_to_fail and motion.y >= 0:
		if jetpack_bn_active:
			motion.y = -4 * jump_speed
			change_anim_scared(2.0)
			jetpack_bn_active = false
			$Jetpack.launch()
			safe_enter(3.5, 0)
			can_pick = 0
		else:
			blow_up()
			Game.fail()
	update_rate()
	
	if shifted_time_left > 0:
		shifted_time_left -= delta
		if shifted_time_left <= 0:
			shifted_time_left = 0
			$Body.position.y -= 1
	
	if is_on_floor():
		if jump_bn_left > 0:
			jump_left = 2
		else:
			jump_left = 1
		if was_falling:
			was_falling = false
			shifted_time_left = 0.1
			$Body.position.y += 1
		
	motion.y += gravity
	if motion.y > max_fall_speed:
		motion.y = max_fall_speed
		
	move_and_slide(motion, Vector2.UP)
	
	for i in get_slide_count():
		var coll = get_slide_collision(i).collider
		if coll.is_in_group("touchable"):
			coll.touch(self)
	
	Game.get_node("Scarf").set_start_point(position)

	# bonuses
	jump_bn_left -= delta if jump_bn_left > 0 else 0
	if jump_bn_left <= 0:
		boots_speed = 1
		$Boots.disappear()
		

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			if $Jetpack.working:
				return
			if is_on_floor():
				motion.y = -jump_speed * boots_speed
				var particles = Floor_part.instance()
				particles.position = get_global_position() + Vector2(0, 16)
				get_tree().get_root().call_deferred("add_child", particles)
			elif jump_left > 0:
				motion.y = -jump_speed * boots_speed
				jump_left -= 1
				var particles = Air_part.instance()
				if jump_left == 0 and jump_bn_left > 0:
					particles = Air_part_boots.instance()
				particles.position = get_global_position() + Vector2(0, 16)
				get_tree().get_root().call_deferred("add_child", particles)

func update_rate():
	motion.x = lerp(min_speed, max_speed, Game.rate / 100)

func _on_DetectorEvil_area_entered(area):
	if area.is_in_group("enemy"):
		if safe:
			return
		if shield_bn_active:
			shield_bn_active = false
			$Bubble.disappear()
			safe_enter(1.5)
		else:
			blow_up()
			Game.fail()


func blow_up():
	$DeathParticles.emitting = true
	$Legs.visible = false
	$Body.visible = false
	$CPUParticles2D.emitting = false
	$Boots.disappear()
	$Bubble.disappear()
	$Jetpack.disappear()
	boots_speed = 1

func change_anim_scared(time):
	timer_anim.set_wait_time(time)
	Eyes.animation = "big"
	Mouth.animation = "fast"
	timer_anim.start()
	#Eyes.add_child(Shake)

func safe_enter(time, need_to_shine = 1):
	timer_safe.wait_time = time
	timer_safe_tick.wait_time = 0.06
	add_child(timer_safe_tick)
	add_child(timer_safe)
	timer_safe_tick.start()
	timer_safe.start()
	safe = 1
	shining = need_to_shine

func safe_tick():
	if !shining:
		return
	for i in shining_parts:
		if !i:
			continue
		i.modulate.a = 0.4 if i.modulate.a == 1 else 1

func safe_stop():
	can_pick = 1
	timer_safe_tick.stop()
	for i in shining_parts:
		if !i:
			continue
		i.modulate.a = 1
	remove_child(timer_safe)
	safe = 0
	shining = 0

func change_anim_usual():
	Eyes.animation = "small"
	Mouth.animation = "slow"
	
func add_bonus(type):
	if type == 'shield_bonus':
		if not shield_bn_active:
			shield_bn_active = true
			$Bubble.appear()
	elif type == 'jump_bonus':
		jump_bn_left = 4
		boots_speed = 1.33
		$Boots.appear()
	elif type == 'jetpack_bonus':
		$Jetpack.appear()
		jetpack_bn_active = true
