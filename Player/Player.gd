extends RigidBody2D

onready var anim_state_machine = $AnimationTree.get("parameters/playback")
onready var texter = $TextTree.get("parameters/playback")
onready var gravity_magnitude = ProjectSettings.get_setting("physics/2d/default_gravity")

onready var SPRITE = $Character
onready var CAMERA = $Camera

export var seconds: int
export var charge: int
export var ChargeSpeedY: float
export var ChargeSpeedX: float
export var LandingCooldown: float

var ending = false
var game_started = false
var music_started = false
var checkpoint = 0
var start_counter = 0

var intro = false
var did_boat = false
var did_stuck = false

var timer = 99
var is_on_water = false
var is_on_ground = false
var jumping = false
var _landing_cooldown = 0

var dead = false
var respawning = false
var displacement = 0
var teleporting = false

func _ready():
	$UI/Control/CenterContainer/Opening/OpeningPlayer.play("Opening")
	anim_state_machine.travel("Idle")
	texter.travel("None")

func _integrate_forces(state):
	if !game_started:
		return	
	
	if ending && teleporting:
		camera.current = true
		teleporting = false
		teleported = true
	
	if ending && !teleported:
		texter.travel("Death")
		anim_state_machine.travel("Idle")
		state.linear_velocity = Vector2(0, -1.65)
		set_mode(0)
		gravity_scale = 0
		weight = 0
		mass = 0
		$Character.scale.x = 80
		$Character.scale.y = 80
		state.transform = Transform2D(0, Vector2(-446, 525))
		$AnimationTree.active = false
		$AnimationPlayer.play("Idle")
		
		var text = get_tree().get_root().get_node("/root/Game/Blackhole/Text/AnimationPlayer")
		text.play("RealText")		
		
		teleporting = true
		
	if respawning:
		respawn(state)
		
	state.integrate_forces()
	
	if state.get_contact_count() <= 0:
		is_on_ground = false
		return
	
	for i in state.get_contact_count():
		var yNormal = state.get_contact_local_normal(i)
		is_on_ground = yNormal.y <= -0.25
		if is_on_ground:
			return
		else:
			$DeathAudio.play()
			die()

func _physics_process(_delta):
	if !game_started:
		return		
	elif !intro:
		texter.travel("Intro")
		intro = true
		
	update()
	
	if dead:
		displacement = displacement + _delta
		
		if !respawning && is_on_ground && displacement >= 2.5:
			set_mode(2)
			set_inertia(0)
			respawning = true										
	elif !ending:
		if Input.is_key_pressed(KEY_A) || Input.is_key_pressed(KEY_LEFT):
			SPRITE.flip_h = true		
			if is_on_ground and charge == 0:			
				anim_state_machine.travel("Charge_Begin")	
		elif Input.is_key_pressed(KEY_D) || Input.is_key_pressed(KEY_RIGHT):
			SPRITE.flip_h = false
			if is_on_ground and charge == 0:
				anim_state_machine.travel("Charge_Begin")
				
		elif not jumping and is_on_ground and charge > 0:
			anim_state_machine.travel("Jump")
			
			var flip = 1
			if SPRITE.flip_h:
				flip = -1

			var vel = Vector2(flip * charge * ChargeSpeedX, (charge * ChargeSpeedY) * -1)
			
			apply_central_impulse(vel)
			$JumpAudio.play()
			jumping = true
			_landing_cooldown = LandingCooldown

var time_passed = 1
var new_scale = 80

func _process(delta):
	if ending:						
		time_passed = time_passed + delta
		if time_passed > 40:
			new_scale = new_scale - delta/32
			$AnimationPlayer.playback_speed = 0.01
		elif time_passed > 30:
			new_scale = new_scale - delta/16
			$AnimationPlayer.playback_speed = 0.03
		elif time_passed > 20:
			new_scale = new_scale - delta/8
			$AnimationPlayer.playback_speed = 0.1
		elif time_passed > 10:
			new_scale = new_scale - delta/2
			$AnimationPlayer.playback_speed = 0.4
		else:
			new_scale = new_scale - delta * 8
			
		
		$Character.scale.x = new_scale
		$Character.scale.y = new_scale
		
		if new_scale <= 0:
			ending = false
			game_started = false
			$AnimationPlayer.stop()
			$Character.visible = false
			
			var fade_out = get_tree().get_root().get_node("/root/Game/Blackhole/Fader/Credits")
			fade_out.play("Fade Out")
			$UI/Timer.visible = false
			
			
	
		
	if !game_started:
		start_counter = start_counter + delta
		if start_counter >= 5 && !music_started:
			music_started = true
			$Main_Music.play()
		elif start_counter >= 7:
			game_started = true
			start_counter = -1			
		else:
			return
		
	if seconds == 1:
		seconds = 0
		timer = timer -1
		
		if timer == -1:
			die()
	elif seconds == -1:
		if timer < 99:
			timer = timer + 1
				
	if jumping and is_on_ground:
		_landing_cooldown -= max(0, delta)
		if _landing_cooldown <= 0:
			CAMERA.add_shake(charge * 0.05)
			charge = 0
			jumping = false
			anim_state_machine.travel("Land")
			
			if is_on_water:
				anim_state_machine.travel("Water")
			$FallAudio.play()


var camera = null

func _on_portal_entered(body):
	if body.get_name() == "Player":
		$Main_Music.stop()
		$PortalAudio.play()
		
		VisualServer.set_default_clear_color(Color("150a1f"))		
		camera = get_tree().get_root().get_node("/root/Game/Blackhole/Camera")		
		
		ending = true
		
		mass = 0
		set_mode(1)	

func die():	
	if dead:
		return
		
	texter.travel("Death")

	$Charge_Bar.visible = false
	$AnimationTree.active = false
	
	charge = 0
	seconds = 0
	
	set_mode(0)
	set_inertia(1)
	apply_central_impulse(Vector2.ONE)	
	
	dead = true
	timer = -1
	
	$UI/Fader/DeathPlayer.play("Fade Out")

var teleported = false
	
func respawn(state):
	set_mode(2)		
	
	state.linear_velocity = Vector2()
	if checkpoint == 0:
		state.transform = Transform2D(0, Vector2(400, 106))
	elif checkpoint == 1:
		state.transform = Transform2D(0, Vector2(-391, -34))
	state.linear_velocity = Vector2()
	
	timer = 99
	displacement = 0
	
	dead = false # Order must be like dead = false then respawning = false
	respawning = false
	$AnimationTree.active = true
	
	$UI/Fader/DeathPlayer.play("Fade In")
	
func lake_body_entered(body):
	if body.get_name() == "Player":
		$DeathAudio.play()
		die()

func water_body_entered(body):
	if body.get_name() != "Player":
		return
		
	if is_on_water == true:
		return
	
	anim_state_machine.travel("Water")
	is_on_water = true
	
func water_body_exited(body):
	if body.get_name() != "Player":
		return
		
	if is_on_water == false:
		return;
	
	anim_state_machine.travel("Idle")
	is_on_water = false

func _on_first_water_body_entered(body):		
	water_body_entered(body)

var did_waterfall = false

func _on_second_water_body_entered(body):
	if body.get_name() == "Player" && !dead:
		checkpoint = 1	
		
		if !did_waterfall:
			texter.travel("Waterfall2")			
			did_waterfall = true
	water_body_entered(body)	

func _on_first_water_body_exited(body):
	water_body_exited(body)

func _on_second_water_body_exited(body):
	water_body_exited(body)

func _on_lake_1_body_entered(body):	
	lake_body_entered(body)

func _on_lake_2_body_entered(body):
	lake_body_entered(body)

func _on_stuck_body_entered(body):
	if body.get_name() != "Player" || dead:
		return;
		
	$Main_Music.stop()
	$Stuck_Music.play()
	
	did_stuck = true
	texter.travel("Stuck")


func _on_stuck_body_exited(body):
	if body.get_name() != "Player":
		return;
				
	$Stuck_Music.stop()
	$Main_Music.play()

func _on_boat_body_entered(body):
	if body.get_name() != "Player" || dead:
		return;
	
	did_boat = true
	texter.travel("Boat")

func _on_boat_body_exited(body):
	if body.get_name() != "Player":
		return;	

func _on_Sword_body_entered(body):
	if body.get_name() != "Player" || dead:
		return;
		
	texter.travel("Sword")


func _on_Portal_Room_body_entered(body):
	if body.get_name() != "Player" || dead:
		return;
		
	texter.travel("Portal")


func _on_Grave_body_entered(body):
	if body.get_name() != "Player" || dead:
		return;
		
	texter.travel("Grave")
