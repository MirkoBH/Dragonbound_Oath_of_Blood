class_name Jugador
extends CharacterBody2D
## William: cuerpo, entrada y máquina de estados (1.4.3.1).
##
## Estados (1.2.5.1, sección 5.3, de mayor a menor prioridad):
## Morir · RecibirDanio · Atacar · Saltar / Caer · Correr · Quieto.
## Las habilidades dracónicas (1.4.5) se agregan como estados nuevos.
##
## Movimiento (1.4.3.2): aceleración y frenado, control en el aire, salto de
## altura variable, gravedad simétrica, margen al borde y memoria del salto.
## Los valores están en [member metricas] (src/resources/metricas_william.tres).
## Las animaciones de cada estado se conectan en 1.4.10.
##
## Daño (1.4.5.1): cada golpe aceptado por la hurtbox se calcula con
## CalculoDanio (talismanes de [member protecciones]) y se descuenta de la
## [Salud]. Después, retroceso, invulnerabilidad de 1 s con parpadeo y, si la
## salud llega a 0, el estado Morir y el aviso [signal murio].

## Cambio de estado, para la animación (1.4.10) y la depuración.
signal estado_cambiado(anterior: StringName, nuevo: StringName)
## Momento del ataque en que la espada golpea (frame activo de ATTACK 1).
## Lo usa la hitbox de 1.4.5.2.
signal golpe_activado
## Terminó la animación de muerte: la partida puede reiniciarse (1.4.11.3).
signal muerte_terminada
## William recibió un golpe: ya se descontó la salud y se aplicaron el
## retroceso y la invulnerabilidad (el daño aplicado lo avisa salud.danio_recibido).
signal golpe_recibido(golpe: Golpe)
## La salud llegó a 0: aviso de muerte, apenas ocurre (1.4.11.3 reinicia la
## aventura cuando termina la animación, con [signal muerte_terminada]).
signal murio

const TILE := 16.0

## Métricas de movimiento (1.2.6.1). Se calibran editando el .tres.
@export var metricas: MetricasJugador = preload("res://src/resources/metricas_william.tres")

@export_group("Combate (1.2.4.2 y 1.2.5.1)")
## Duración del ataque: 8 frames a 20 cuadros/s.
@export var duracion_ataque: float = 0.4
## Momento del golpe dentro del ataque: 4.º frame.
@export var momento_golpe: float = 0.15
## Tiempo sin control al recibir un golpe.
@export var duracion_retroceso: float = 0.2
## Distancia del retroceso: ½ tile.
@export var distancia_retroceso: float = 0.5 * TILE
## Duración de la animación de muerte: 15 frames a 12 cuadros/s.
@export var duracion_muerte: float = 1.25
## Invulnerabilidad después de recibir un golpe (1.2.4.2).
@export var duracion_invulnerabilidad: float = 1.0
## Tiempo que la hitbox de la espada queda activa desde el frame del golpe.
@export var ventana_golpe: float = 0.1
## Daño base de la espada, en corazones (1.2.4.2). Las mejoras las suma 1.4.5.2.
@export var danio_espada: float = 1.0
## Parpadeo durante la invulnerabilidad: medio ciclo, en segundos (1.2.4.2).
@export var intervalo_parpadeo: float = 0.08
## Talismanes de William. PROVISORIO hasta el estado global (1.4.11.1).
@export var protecciones: ProteccionesJugador

## Lado hacia el que mira William: 1 derecha, -1 izquierda.
var mirando: int = 1

@onready var maquina: MaquinaEstados = $MaquinaEstados
## Hitbox de la espada: 24 px (1,5 tiles) frente al cuerpo (1.2.5.1, 6.2).
@onready var espada: Hitbox = $Espada
## Área donde William recibe golpes: 12 × 28 px (1.2.5.1, 6.2).
@onready var area_golpes: Hurtbox = $AreaGolpes
## Salud en corazones: 5 al empezar (1.2.4.1).
@onready var salud: Salud = $Salud

var _desplazamiento_espada: float = 0.0
## Segundos desde que se presionó Espacio (memoria del salto).
var _tiempo_desde_pedido_salto: float = INF
## Segundos desde la última vez que William tocó el suelo (margen al borde).
var _tiempo_desde_suelo: float = 0.0
## Si todavía puede usar el margen al borde: se pierde al saltar.
var _margen_disponible: bool = true
## Altura (posición y) desde la que despegó el último salto.
var y_despegue: float = 0.0


func _ready() -> void:
	CapasColision.configurar(self, CapasColision.Perfil.CUERPO_WILLIAM)
	_configurar_suelo()
	_desplazamiento_espada = absf(espada.position.x)
	espada.danio = danio_espada
	golpe_activado.connect(_activar_espada)
	area_golpes.golpe_recibido.connect(_al_recibir_golpe)
	salud.murio.connect(_al_morir)
	if protecciones == null:
		protecciones = ProteccionesJugador.new()
	maquina.estado_cambiado.connect(func(anterior: StringName, nuevo: StringName) -> void:
		estado_cambiado.emit(anterior, nuevo))
	maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(&"saltar"):
		_tiempo_desde_pedido_salto = 0.0
	else:
		_tiempo_desde_pedido_salto += delta
	maquina.actualizar_fisica(delta)
	_corregir_esquinas(delta)
	move_and_slide()
	if is_on_ceiling() and velocity.y < 0.0:
		velocity.y = 0.0
	if is_on_floor():
		_tiempo_desde_suelo = 0.0
		_margen_disponible = true
	else:
		_tiempo_desde_suelo += delta


# --- Colisión con terreno y plataformas (1.4.3.3) ---

## La caja de colisión (player.tscn) tiene las esquinas de abajo cortadas
## 3 px, para que no se enganche en las uniones entre tiles al pasar de llano
## a rampa ni en el borde de una plataforma.
##
## Configura cómo William pisa el suelo: rampas de hasta 45° cuentan como
## suelo, se queda quieto sobre ellas sin resbalar y se pega al suelo al bajar.
func _configurar_suelo() -> void:
	up_direction = Vector2.UP
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_max_angle = deg_to_rad(metricas.angulo_max_suelo)
	floor_snap_length = metricas.pegado_al_suelo
	floor_stop_on_slope = true
	floor_block_on_wall = true
	floor_constant_speed = true


## Corrección de esquinas: si al subir la cabeza va a chocar con el borde de
## un techo, busca un desplazamiento lateral de hasta
## [member MetricasJugador.correccion_esquinas] px que lo libere y lo aplica.
## Prueba primero hacia donde se mueve William. Busca hasta 1 px más que el
## roce permitido, porque Godot deja un margen de seguridad (safe_margin)
## entre el cuerpo y el terreno.
func _corregir_esquinas(delta: float) -> void:
	if velocity.y >= 0.0:
		return
	var paso := Vector2(0.0, velocity.y * delta)
	if not test_move(global_transform, paso):
		return
	var primero := 1.0 if velocity.x >= 0.0 else -1.0
	for distancia in range(1, int(metricas.correccion_esquinas) + 2):
		for lado: float in [primero, -primero]:
			var corrimiento := Vector2(lado * distancia, 0.0)
			if test_move(global_transform, corrimiento):
				continue
			if not test_move(global_transform.translated(corrimiento), paso):
				global_position += corrimiento
				return


# --- Valores derivados ---

## Gravedad, en px/s² (igual al subir y al bajar).
func obtener_gravedad() -> float:
	return metricas.obtener_gravedad()


## Velocidad inicial del salto máximo, en px/s.
func obtener_velocidad_salto() -> float:
	return metricas.obtener_velocidad_salto()


# --- Ayudas para los estados ---

## Dirección pedida por el jugador: -1, 0 o 1.
func obtener_direccion() -> float:
	return Input.get_axis(&"mover_izquierda", &"mover_derecha")


## Aplica la gravedad, con tope en la velocidad máxima de caída.
## Apoyado en el suelo no acumula velocidad hacia abajo: así no resbala
## quieto en una rampa ni depende de redondeos de la física (1.4.3.3). El
## pegado al suelo lo mantiene en contacto al bajar rampas.
func aplicar_gravedad(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		velocity.y = 0.0
		return
	velocity.y = minf(velocity.y + obtener_gravedad() * delta, metricas.obtener_velocidad_max_caida())


## Acelera o frena en horizontal hacia [param direccion] y actualiza hacia
## dónde mira. Frena más rápido de lo que acelera, también al dar la vuelta.
## En el aire se aplica el control aéreo de las métricas.
func mover_horizontal(direccion: float, delta: float) -> void:
	var objetivo := direccion * metricas.obtener_velocidad()
	var cambio: float
	if direccion == 0.0 or (velocity.x != 0.0 and signf(direccion) != signf(velocity.x)):
		cambio = metricas.obtener_frenado()
	else:
		cambio = metricas.obtener_aceleracion()
	if not is_on_floor():
		cambio *= metricas.control_aereo
	velocity.x = move_toward(velocity.x, objetivo, cambio * delta)
	if direccion != 0.0:
		mirando = 1 if direccion > 0.0 else -1


## Velocidad hacia arriba (positiva) para subir [param altura] px más.
## Resta medio cuadro de gravedad: los estados aplican la gravedad antes de
## moverse, y sin esta corrección cada salto subiría unos 2,6 px de más.
func calcular_velocidad_para_subir(altura: float) -> float:
	if altura <= 0.0:
		return 0.0
	var paso := 1.0 / Engine.physics_ticks_per_second
	return maxf(sqrt(2.0 * obtener_gravedad() * altura) - obtener_gravedad() * paso / 2.0, 0.0)


## Despega: impulso para el salto máximo. Guarda la altura de despegue para
## el salto variable y consume el pedido de salto y el margen al borde.
func impulsar_salto() -> void:
	velocity.y = -calcular_velocidad_para_subir(metricas.altura_salto_max * TILE)
	y_despegue = position.y
	_tiempo_desde_pedido_salto = INF
	_margen_disponible = false


## Salto variable: al soltar Espacio, limita lo que le queda por subir para
## que el salto total sea como mínimo la altura del toque (1,5 tiles). Si ya
## pasó esa altura, deja de subir ahí mismo.
func cortar_salto() -> void:
	var subido := y_despegue - position.y
	var restante := metricas.altura_salto_min * TILE - subido
	velocity.y = maxf(velocity.y, -calcular_velocidad_para_subir(restante))


## Indica si hay un salto pedido dentro de la memoria del salto.
func hay_salto_pedido() -> bool:
	return _tiempo_desde_pedido_salto <= metricas.memoria_salto


## Indica si William puede saltar en el aire por el margen al borde: dejó el
## suelo caminando hace menos de [member MetricasJugador.margen_borde].
func puede_saltar_por_margen() -> bool:
	return _margen_disponible and _tiempo_desde_suelo <= metricas.margen_borde


# --- Golpes ---

## Activa la espada hacia donde mira William durante [member ventana_golpe].
func _activar_espada() -> void:
	espada.position.x = _desplazamiento_espada * mirando
	espada.activar(ventana_golpe)


## La hurtbox aceptó un golpe (1.2.4.2, sección 8.2): calcula el daño con
## los talismanes, lo descuenta y aplica la invulnerabilidad. Si William sigue
## vivo, además lo hace retroceder.
func _al_recibir_golpe(golpe: Golpe) -> void:
	var danio := CalculoDanio.danio_a_william(golpe, protecciones)
	salud.aplicar_danio(danio, golpe)
	area_golpes.aplicar_invulnerabilidad(duracion_invulnerabilidad)
	if not salud.esta_muerto():
		recibir_danio(golpe.origen.x)
	golpe_recibido.emit(golpe)


func _al_morir() -> void:
	morir()
	murio.emit()


func _process(_delta: float) -> void:
	# Parpadeo mientras dura la invulnerabilidad. Usa la transparencia del
	# personaje entero, así funciona con cualquier sprite (1.4.10).
	if area_golpes.esta_invulnerable() and not salud.esta_muerto():
		var ciclo := fmod(area_golpes.obtener_invulnerabilidad_restante(), intervalo_parpadeo * 2.0)
		modulate.a = 0.3 if ciclo < intervalo_parpadeo else 1.0
	else:
		modulate.a = 1.0


# --- Eventos externos ---

## William recibe un golpe desde la posición horizontal [param origen_x].
## Solo hace el retroceso; la salud y la invulnerabilidad las maneja
## [method _al_recibir_golpe]. Devuelve false si no se aplicó (por ejemplo,
## si está muriendo).
func recibir_danio(origen_x: float) -> bool:
	return maquina.interrumpir(&"RecibirDanio", {"origen_x": origen_x})


## La salud llegó a 0. Devuelve false si ya estaba muriendo.
func morir() -> bool:
	return maquina.interrumpir(&"Morir")


## Nombre del estado actual.
func obtener_estado() -> StringName:
	return maquina.obtener_nombre_estado()
