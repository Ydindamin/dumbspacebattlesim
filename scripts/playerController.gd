extends RigidBody3D

@export var healthMax : float = 100.0
@export var lookSpeed : float = 10.0
@export var boostStrength : float = 100
@export var rollStrength : float = 0.67
@export var stabilizerStrength : float = 1.5
@export var thrustPowerMain : float = 5.0
@export var thrustPowerRCS : float = 0.67
@export var invertX : bool = false 
@export var invertY : bool = false

@onready var health : float = healthMax
@onready var lasgun : Node3D = $fuselage/lasgun
@onready var lightL : SpotLight3D = $fuselage/lightcanL/frontlightL
@onready var lightR : SpotLight3D = $fuselage/lightcanR/frontlightR
@onready var coneLight : OmniLight3D = $fuselage/rocketcone/conelight
@onready var cannonMuzzle : Node3D = $fuselage/gun/barrel/muzzle
@onready var throttleBar : ProgressBar = $Camera3D/shipUI/throttlebar
@onready var debugText1 : Label = $Camera3D/shipUI/debugtext1
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

signal receiveDamage(amount)
signal receiveForce(amount, applyPoint, applyDir)

var canControl : bool = true
var pivotForce : Vector3 = Vector3.ZERO
var deadZone : float = 0.67
var beamtrail = preload("res://effects/beamtrail.tscn")
var shell = preload("res://prefabs/shell.tscn")
var Laser = preload("res://effects/laser.tscn")

var throttle : float = 0.5
var cooldown : Timer = Timer.new()
var cooldownMax : float = 1.0
var lightsOn : bool = false
var coneFlame : float = 0.0
var debug : bool = false


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_child(cooldown)
	cooldown.wait_time = 0.0
	cooldown.timeout.connect(reload)
	receiveDamage.connect(applyDamage)
	receiveForce.connect(applyForce)

func _input(event):
	if event is InputEventMouseMotion:
		if abs(event.screen_relative.x) > deadZone:
			if invertX: pivotForce -= Vector3.DOWN * event.screen_relative.x * lookSpeed
			else: pivotForce += Vector3.DOWN * event.screen_relative.x * lookSpeed
		if abs(event.screen_relative.y) > deadZone:
			if invertY: pivotForce += Vector3.LEFT * event.screen_relative.y * lookSpeed
			else: pivotForce -= Vector3.LEFT * event.screen_relative.y * lookSpeed

func _physics_process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().quit()
	if Input.is_action_just_released("debug"):
		debug = not debug
		if debug:
			debugText1.visible = true
		else:
			debugText1.visible = false
			
	if canControl:
		var thrust : Vector3 = Vector3.ZERO
		
		if Input.is_action_just_pressed("fire") and cooldown.is_stopped():
				fire_railgun()
		
		if Input.is_action_just_pressed("lights"):
			if lightsOn:
				lightsOn = false
				lightL.light_energy = 0.0
				lightR.light_energy = 0.0
			else:
				lightsOn = true
				lightL.light_energy = 1.0
				lightR.light_energy = 1.0
		
		if Input.is_action_just_pressed("throttle_up"):
			throttle = min(1.0, throttle+0.1)
			throttleBar.value = throttle
		elif Input.is_action_just_pressed("throttle_down"):
			throttle = max(0.0, throttle-0.1)
			throttleBar.value = throttle
			
		if Input.is_action_pressed("arrest"):
			var V : Vector3 = get_linear_velocity() * transform.basis
			thrust = -1 * V
		else:
			if Input.is_action_pressed("move_forward"):
				thrust += Vector3.MODEL_FRONT * thrustPowerMain * throttle
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
				pivotForce += Vector3.MODEL_FRONT * rollStrength
			elif Input.is_action_pressed("roll_CCW"):
				pivotForce += Vector3.MODEL_REAR * rollStrength
		
		coneLight.light_color = (coneLight.light_color+Color("c88c00")*thrust.z)/2
		toggle_RCS(thrust, pivotForce)
		
		apply_central_force(transform.basis*thrust.normalized()*boostStrength)
		#apply_torque(transform.basis*pivotForce.normalized()*rollStrength)
		apply_torque(transform.basis*pivotForce)
		if debug:
			debugText1.text = "linear_vel: " + str(round(10*linear_velocity)/10) + "\nangular_vel: " + str(round(10*angular_velocity)/10) + "\npivot_vel: " + str(round(10*pivotForce)/10) + "\nthrust_vel: " + str(round(10*thrust)/10)
		pivotForce = Vector3.ZERO

func reload() -> void:
	cooldown.stop()

func fire_railgun() -> void:
	var newShot : GPUParticles3D = beamtrail.instantiate()
	get_tree().root.add_child(newShot)
	newShot.global_position = cannonMuzzle.global_position
	newShot.global_rotation = cannonMuzzle.global_rotation
	newShot.emitting = true
	apply_central_impulse(basis * Vector3.FORWARD * 5000)
	cooldown.wait_time = cooldownMax
	cooldown.start()

func toggle_RCS(thrust:Vector3, pivot:Vector3) -> void:
	#if not (thrust == Vector3.ONE or pivot == Vector3.ONE):
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
	if thrust.z < -0.1:
		vaporjetFUR.emitting = true
		vaporjetFUL.emitting = true
		vaporjetFDR.emitting = true
		vaporjetFDL.emitting = true
	if thrust.x > 0.1:
		vaporjetRDF.emitting = true
		vaporjetRDB.emitting = true
		vaporjetRUF.emitting = true
		vaporjetRUB.emitting = true
	if thrust.x < -0.1:
		vaporjetLDF.emitting = true
		vaporjetLDB.emitting = true
		vaporjetLUF.emitting = true
		vaporjetLUB.emitting = true
	if thrust.y > 0.1:
		vaporjetDBR.emitting = true
		vaporjetDBL.emitting = true
		vaporjetDFR.emitting = true
		vaporjetDFL.emitting = true
	if thrust.y < -0.1:
		vaporjetUBR.emitting = true
		vaporjetUBL.emitting = true
		vaporjetUFR.emitting = true
		vaporjetUFL.emitting = true
	if pivot.x > 1.0:
		vaporjetDBL.emitting = true
		vaporjetDBR.emitting = true
		vaporjetUFL.emitting = true
		vaporjetUFR.emitting = true
	if pivot.x < -1.0:
		vaporjetDFL.emitting = true
		vaporjetDFR.emitting = true
		vaporjetUBL.emitting = true
		vaporjetUBR.emitting = true
	if pivot.y > 1.0:
		vaporjetRDF.emitting = true
		vaporjetRUF.emitting = true
		vaporjetLDB.emitting = true
		vaporjetLUB.emitting = true
	if pivot.y < -1.0:
		vaporjetRDB.emitting = true
		vaporjetRUB.emitting = true
		vaporjetLDF.emitting = true
		vaporjetLUF.emitting = true
	if pivot.z > 1.0:
		vaporjetRDF.emitting = true
		vaporjetRDB.emitting = true
		vaporjetLUF.emitting = true
		vaporjetLUB.emitting = true
		vaporjetDBL.emitting = true
		vaporjetDFL.emitting = true
		vaporjetUBR.emitting = true
		vaporjetUFR.emitting = true
	if pivot.z < -1.0:
		vaporjetRUF.emitting = true
		vaporjetRUB.emitting = true
		vaporjetLDF.emitting = true
		vaporjetLDB.emitting = true
		vaporjetDBR.emitting = true
		vaporjetDFR.emitting = true
		vaporjetUBL.emitting = true
		vaporjetUFL.emitting = true

func applyDamage(amount) -> void:
	print("received ", amount, "damage")
	health -= amount
	if health <= 0:
		kill()

func applyForce(amount, applyPoint, applyDir) -> void:
	print("received ", amount, "force")
	apply_impulse(applyDir.normalized() * amount, applyPoint)

func kill() -> void:
	# TODO: death effect(s)
	canControl = false
	$fuselage.queue_free()
