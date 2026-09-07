
extends CharacterBody3D

var sens_X = 0.08
var sens_Y = 0.08
const SPEED = 10.0
const JUMP_VELOCITY = 6.0
@onready var camara: Camera3D = $Camera3D

# Configuración del Dash (Física)
const DISTANCIA_DASH = 10.0
const TIEMPO_DASH = 0.2  
var tiempo_dash_restante = 0.0  

# SISTEMA DE ENERGÍA DEL DASH
var energia: float = 3.0       
const MAX_ENERGIA: float = 3.0 
const TIEMPO_POR_CARGA = 3.0   

# SISTEMA DE COOLDOWN DEL DASH
const TIEMPO_COOLDOWN = 0.4   
var cooldown_restante = 0.0

# CONFIGURACIÓN DEL WALLKICK (Físicas hacia el negativo de la pared)
const FUERZA_WALLKICK_UP = 6.5     # Impulso vertical mientras sube
const FUERZA_WALLKICK_OUT = 8.5    # Impulso horizontal exacto hacia afuera del muro (Negativo)
const DURACION_IMPULSO_WK = 0.25   # Bloqueo temporal de WASD para romper inercia
var tiempo_impulso_wk_restante = 0.0

# ENERGÍA EXCLUSIVA DEL WALLKICK CON COMBO TIMED (2s ventana / 4s castigo)
var wallkicks_realizados: int = 0       
const VENTANA_COMBO_MAX = 2.0           
var ventana_combo_restante = 0.0        

const RECARGA_WK_CASTIGO = 2.0          
var bloqueo_recarga_wk = 0.0            

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# REGISTRO AUTOMÁTICO DE LA TECLA SHIFT
	if not InputMap.has_action("ui_dash"):
		InputMap.add_action("ui_dash")
		var event = InputEventKey.new()
		event.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("ui_dash", event)

func dash():
	if energia >= 1.0 and cooldown_restante <= 0.0 and camara:
		var dir_dash = -camara.global_transform.basis.z
		dir_dash.y = 0
		dir_dash = dir_dash.normalized()
		
		if dir_dash.length() > 0:
			energia -= 1.0             
			cooldown_restante = TIEMPO_COOLDOWN  
			tiempo_dash_restante = TIEMPO_DASH   
			
			velocity.x = dir_dash.x * (DISTANCIA_DASH * 4.0)
			velocity.z = dir_dash.z * (DISTANCIA_DASH * 4.0)
			
			Audio.reproducir("res://dash.mp3") 

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# GRAVEDAD SIEMPRE ACTIVA
	if not is_on_floor():
		velocity += get_gravity() * delta

	# CONTROL DEL TIEMPO DEL CASTIGO (4 SEGUNDOS)
	if bloqueo_recarga_wk > 0.0:
		bloqueo_recarga_wk = maxf(0.0, bloqueo_recarga_wk - delta)

	# CONTROL DE LA VENTANA DE COMBO (2 SEGUNDOS)
	if wallkicks_realizados > 0 and bloqueo_recarga_wk <= 0.0:
		ventana_combo_restante = maxf(0.0, ventana_combo_restante - delta)
		if ventana_combo_restante == 0.0:
			wallkicks_realizados = 0

	# REDUCCIÓN DE COOLDOWN DEL DASH
	if cooldown_restante > 0.0:
		cooldown_restante = maxf(0.0, cooldown_restante - delta)

	# REGENERACIÓN DE ENERGÍA DEL DASH
	if energia < MAX_ENERGIA:
		energia = minf(MAX_ENERGIA, energia + (1.0 / TIEMPO_POR_CARGA) * delta)

	# MANEJO DE MOVIMIENTO vs IMPULSOS (DASH Y WALLKICK)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if tiempo_dash_restante > 0.0:
		tiempo_dash_restante -= delta
	elif tiempo_impulso_wk_restante > 0.0:
		tiempo_impulso_wk_restante -= delta
	else:
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	# MANEJO DE SALTO Y WALLKICK (Espacio)
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall() and not is_on_floor():
			if bloqueo_recarga_wk <= 0.0:
				
				wallkicks_realizados += 1
				ventana_combo_restante = VENTANA_COMBO_MAX
				
				if wallkicks_realizados >= 3:
					bloqueo_recarga_wk = RECARGA_WK_CASTIGO
					wallkicks_realizados = 0 
				
				# ¡EL CAMBIO AQUÍ!:
				# get_wall_normal() nos da el vector exacto perpendicular que apunta "hacia afuera" de la pared.
				# Esto es matemáticamente el opuesto (negativo) al impacto del cuerpo.
				var dir_repulsion = get_wall_normal()
				dir_repulsion.y = 0 
				dir_repulsion = dir_repulsion.normalized()
				
				# Inyectamos la velocidad de rebote de forma pura
				velocity.y = FUERZA_WALLKICK_UP
				velocity.x = dir_repulsion.x * FUERZA_WALLKICK_OUT
				velocity.z = dir_repulsion.z * FUERZA_WALLKICK_OUT
				
				# Activamos el freno temporal del WASD para que salgas despedido
				tiempo_impulso_wk_restante = DURACION_IMPULSO_WK
		
	# DETECCIÓN DE DASH
	if Input.is_action_just_pressed("ui_dash"):
		dash()

	move_and_slide()

	# LOG DE DEBUG
	var debug = true
	if debug:
		print("DASH ENERGÍA: ", "%.2f" % energia, 
			" | WK PASO ACTUAL: ", wallkicks_realizados, " / 3",
			" | REBOTE ACTIVO: ", "%.2f" % tiempo_impulso_wk_restante)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_X))
		$Camera3D.rotate_x(deg_to_rad(-event.relative.y * sens_Y))
