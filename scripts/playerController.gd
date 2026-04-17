extends RigidBody3D

#@onready var p1ship : RigidBody3D = $/root/World/playership
@onready var lasgun : Node3D = $fuselage/lasgun
@onready var lightL : SpotLight3D = $fuselage/lightcanL/frontlightL
@onready var lightR : SpotLight3D = $fuselage/lightcanR/frontlightR
@onready var coneLight : OmniLight3D = $fuselage/rocketcone/conelight
@onready var vaporjetUBR : GPUParticles3D = $fuselage/vaporjet_UBR
@onready var vaporjetUBL : GPUParticles3D = $fuselage/vaporjet_UBL
@onready var vaporjetUFR : GPUParticles3D = $fuselage/vaporjet_UFR
@onready var vaporjetUFL : GPUParticles3D = $fuselage/vaporjet_UFL
@onready var vaporjetDBR : GPUParticles3D = $fuselage/vaporjet_DBR
@onready var vaporjetDBL : GPUParticles3D = $fuselage/vaporjet_DBL
@onready var vaporjetDFR : GPUParticles3D = $fuselage/vaporjet_DFR
@onready var vaporjetDFL : GPUParticles3D = $fuselage/vaporjet_DFL
@onready var vaporjetRUF : GPUParticles3D = $fuselage/vaporjet_RUF
@onready var vaporjetRDF : GPUParticles3D = $fuselage/vaporjet_RDF
@onready var vaporjetRUB : GPUParticles3D = $fuselage/vaporjet_RUB
@onready var vaporjetRDB : GPUParticles3D = $fuselage/vaporjet_RDB
@onready var vaporjetLUF : GPUParticles3D = $fuselage/vaporjet_LUF
@onready var vaporjetLDF : GPUParticles3D = $fuselage/vaporjet_LDF
@onready var vaporjetLUB : GPUParticles3D = $fuselage/vaporjet_LUB
@onready var vaporjetLDB : GPUParticles3D = $fuselage/vaporjet_LDB
@onready var vaporjetFUR : GPUParticles3D = $fuselage/vaporjet_FUR
@onready var vaporjetFUL : GPUParticles3D = $fuselage/vaporjet_FUL
@onready var vaporjetFDR : GPUParticles3D = $fuselage/vaporjet_FDR
@onready var vaporjetFDL : GPUParticles3D = $fuselage/vaporjet_FDL
@export var lookSpeed : float = 0.1
@export var boostStrength : float = 100
@export var rollStrength : float = 0.67
@export var stabilizerStrength : float = 1.5
@export var thrustPowerMain : float = 3.0
@export var thrustPowerRCS : float = .67
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
			thrust += Vector3.MODEL_FRONT * thrustPowerMain
		elif Input.is_action_pressed("move_back"):
			thrust += Vector3.MODEL_REAR * thrustPowerRCS
		if Input.is_action_pressed("move_left") != Input.is_action_pressed("move_right"):
			if Input.is_action_pressed("move_left"):
				thrust += Vector3.MODEL_LEFT * thrustPowerRCS
			elif Input.is_action_pressed("move_right"):
				thrust += Vector3.MODEL_RIGHT * thrustPowerRCS
		if Input.is_action_pressed("move_up") != Input.is_action_pressed("move_down"):
			if Input.is_action_pressed("move_up"):
				thrust += Vector3.MODEL_TOP * thrustPowerRCS
			elif Input.is_action_pressed("move_down"):
				thrust += Vector3.MODEL_BOTTOM * thrustPowerRCS
	
	if Input.is_action_pressed("stabilize"):
		angular_damp = stabilizerStrength
	else:
		angular_damp = 0.0
	if Input.is_action_pressed("roll_CW") != Input.is_action_pressed("roll_CCW"):
		if Input.is_action_pressed("roll_CW"):
			pivot += Vector3.MODEL_FRONT
		elif Input.is_action_pressed("roll_CCW"):
			pivot += Vector3.MODEL_REAR
	
	coneLight.light_color = (coneLight.light_color+Color("c88c00")*thrust.z)/2
	toggle_RCS(thrust, pivot)
	
	apply_central_force(transform.basis*thrust.normalized()*boostStrength)
	apply_torque(transform.basis*pivot.normalized()*rollStrength)

func toggle_RCS(thrust:Vector3, pivot:Vector3) -> void:
	if not (thrust == Vector3.ONE or pivot == Vector3.ONE):
		vaporjetUBR.emitting = false
		vaporjetUBL.emitting = false
		vaporjetUFR.emitting = false
		vaporjetUFL.emitting = false
		vaporjetDBR.emitting = false
		vaporjetDBL.emitting = false
		vaporjetDFR.emitting = false
		vaporjetDFL.emitting = false
		vaporjetRUF.emitting = false
		vaporjetRDF.emitting = false
		vaporjetRUB.emitting = false
		vaporjetRDB.emitting = false
		vaporjetLUF.emitting = false
		vaporjetLDF.emitting = false
		vaporjetLUB.emitting = false
		vaporjetLDB.emitting = false
		vaporjetFUR.emitting = false
		vaporjetFUL.emitting = false
		vaporjetFDR.emitting = false
		vaporjetFDL.emitting = false
	if thrust.z < 0:
		vaporjetFUR.emitting = true
		vaporjetFUL.emitting = true
		vaporjetFDR.emitting = true
		vaporjetFDL.emitting = true
	if thrust.x > 0:
		vaporjetRDF.emitting = true
		vaporjetRDB.emitting = true
		vaporjetRUF.emitting = true
		vaporjetRUB.emitting = true
	if thrust.x < 0:
		vaporjetLDF.emitting = true
		vaporjetLDB.emitting = true
		vaporjetLUF.emitting = true
		vaporjetLUB.emitting = true
	if thrust.y > 0:
		vaporjetDBR.emitting = true
		vaporjetDBL.emitting = true
		vaporjetDFR.emitting = true
		vaporjetDFL.emitting = true
	if thrust.y < 0:
		vaporjetUBR.emitting = true
		vaporjetUBL.emitting = true
		vaporjetUFR.emitting = true
		vaporjetUFL.emitting = true
	if pivot.z > 0:
		vaporjetRDF.emitting = true
		vaporjetRDB.emitting = true
		vaporjetLUF.emitting = true
		vaporjetLUB.emitting = true
		vaporjetDBL.emitting = true
		vaporjetDFL.emitting = true
		vaporjetUBR.emitting = true
		vaporjetUFR.emitting = true
	if pivot.z < 0:
		vaporjetRUF.emitting = true
		vaporjetRUB.emitting = true
		vaporjetLDF.emitting = true
		vaporjetLDB.emitting = true
		vaporjetDBR.emitting = true
		vaporjetDFR.emitting = true
		vaporjetUBL.emitting = true
		vaporjetUFL.emitting = true
