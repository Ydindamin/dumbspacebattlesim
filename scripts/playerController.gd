extends RigidBody3D

#@onready var p1ship : RigidBody3D = $/root/World/playership
@onready var lasgun : Node3D = $fuselage/lasgun
@onready var lightL : SpotLight3D = $fuselage/lightcanL/frontlightL
@onready var lightR : SpotLight3D = $fuselage/lightcanR/frontlightR
@onready var coneLight : OmniLight3D = $fuselage/rocketcone/conelight
@export var lookSpeed : float = 0.1
@export var boostStrength : float = 100
@export var rollStrength : float = 1.0
@export var stabilizerStrength : float = 1.5
@export var invertX : bool = false 
@export var invertY : bool = false

var cooldown : Timer = Timer.new()
var cooldownMax : float = 0.25
var Laser = preload("res://laser.tscn")
var lightsOn : bool = false
var coneFlame : float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cooldown.wait_time = cooldownMax

func _input(event):
	if event is InputEventMouseMotion:
		var pivotForce : Vector3 = Vector3.ZERO
		if invertX: pivotForce -= Vector3.DOWN * event.screen_relative.x * lookSpeed
		else: pivotForce += Vector3.DOWN * event.screen_relative.x * lookSpeed
		if invertY: pivotForce += Vector3.LEFT * event.screen_relative.y * lookSpeed
		else: pivotForce -= Vector3.LEFT * event.screen_relative.y * lookSpeed
		apply_torque(transform.basis * pivotForce)

func _physics_process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().quit()
	if Input.is_action_just_pressed("pause"):
		pass #TODO
		
	var thrust : Vector3 = Vector3.ZERO
	var pivot : Vector3 = Vector3.ZERO
	
	if Input.is_action_pressed("fire") and cooldown.time_left <= 0.0:
			var newLaser : Area3D = Laser.instantiate()
			add_child(newLaser)
			newLaser.position = lasgun.position
			newLaser.rotation = lasgun.rotation
			move_child(newLaser,1)
			cooldown.start()
	
	if Input.is_action_just_pressed("lights"):
		if lightsOn:
			lightsOn = false
			lightL.light_color = Color(0,0,0)
			lightR.light_color = Color(0,0,0)
		else:
			lightsOn = true
			lightL.light_color = Color(1,1,1)
			lightR.light_color = Color(1,1,1)
	
	if Input.is_action_pressed("arrest"):
		var V : Vector3 = get_linear_velocity() * transform.basis
		thrust = -1 * V
	else:
		if Input.is_action_pressed("move_forward"):
			thrust += Vector3.MODEL_FRONT
		elif Input.is_action_pressed("move_back"):
			thrust += Vector3.MODEL_REAR
		if Input.is_action_pressed("move_left") != Input.is_action_pressed("move_right"):
			if Input.is_action_pressed("move_left"):
				thrust += Vector3.MODEL_LEFT
			elif Input.is_action_pressed("move_right"):
				thrust += Vector3.MODEL_RIGHT
		if Input.is_action_pressed("move_up") != Input.is_action_pressed("move_down"):
			if Input.is_action_pressed("move_up"):
				thrust += Vector3.MODEL_TOP
			elif Input.is_action_pressed("move_down"):
				thrust += Vector3.MODEL_BOTTOM
	
	if Input.is_action_pressed("stabilize"):
		angular_damp = stabilizerStrength
	else:
		angular_damp = 0.0
	if Input.is_action_pressed("roll_CW") != Input.is_action_pressed("roll_CCW"):
		if Input.is_action_pressed("roll_CW"):
			pivot += Vector3.MODEL_FRONT
		elif Input.is_action_pressed("roll_CCW"):
			pivot += Vector3.MODEL_REAR
	
	apply_central_force(transform.basis*thrust.normalized()*boostStrength)
	coneLight.light_color = (coneLight.light_color+Color("c88c00")*thrust.z)/2
	apply_torque(transform.basis*pivot.normalized()*rollStrength)
