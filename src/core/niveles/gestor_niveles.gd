class_name GestorNiveles
extends Node
## Gestor de niveles (1.4.2.1): carga y descarga las escenas jugables dentro
## de LevelRoot y sigue el orden de [SecuenciaNiveles].
##
## MainGame queda siempre cargado: solo cambia lo que hay dentro de LevelRoot.
## William es uno solo durante toda la partida. Vive en EntityRoot, fuera del
## nivel, y en cada escena se ubica en su punto de aparición.
##
## Durante un cambio de escena el juego queda en pausa, lo que bloquea la
## entrada (NV-04). La pausa del jugador (1.4.1.2) debe revisar
## [method esta_en_transicion] para no abrirse durante el fundido (NV-06).
##
## No es parte de este gestor: los menús (1.4.1), conservar el estado de la
## partida (1.4.11.2), la muerte (1.4.11.3) ni la victoria (1.4.2.7).

## Cambió la escena, todavía con la pantalla en negro. Para la música
## (1.4.10.1) y para lo que deba restablecerse al entrar a un nivel (1.4.11.2).
signal escena_cambiada(paso: int, es_campamento: bool)
## Terminó el fundido de entrada: el jugador vuelve a tener el control.
signal transicion_terminada
## Se pidió avanzar desde la última escena: la victoria sigue en 1.4.2.7.
signal secuencia_terminada

const ESCENA_WILLIAM: PackedScene = preload("res://src/gameplay/player/player.tscn")

## Orden de las escenas de la partida.
@export var secuencia: SecuenciaNiveles

## William. Se crea al iniciar la primera partida.
var jugador: Jugador

var _nivel_actual: Nivel
## Paso actual de la secuencia. Al existir 1.4.11.1, el nivel actual pasa a
## guardarse en el estado de la partida.
var _paso: int = -1
var _en_transicion: bool = false

@onready var _raiz_nivel: Node2D = %LevelRoot
@onready var _raiz_entidades: Node2D = %EntityRoot
@onready var _fundido: Fundido = %Fundido


## Empieza desde el nivel 1. También sirve para reintentar después de morir.
func iniciar_partida() -> void:
	if jugador == null:
		jugador = ESCENA_WILLIAM.instantiate()
		_raiz_entidades.add_child(jugador)
	await _ir_a(0)


## Pasa a la escena siguiente. Lo llama el disparador de fin de nivel; el
## nivel 5 no lo tiene y termina con la derrota de Morgana.
func avanzar() -> void:
	if _en_transicion or _paso < 0:
		return
	if _paso + 1 >= secuencia.cantidad_pasos():
		secuencia_terminada.emit()
		return
	await _ir_a(_paso + 1)


## Indica si hay un cambio de escena en curso.
func esta_en_transicion() -> bool:
	return _en_transicion


## Paso actual de la secuencia, o -1 si todavía no empezó la partida.
func obtener_paso() -> int:
	return _paso


## Escena jugable cargada.
func obtener_nivel_actual() -> Nivel:
	return _nivel_actual


## Cambia de escena con el fundido. Carga con la pantalla en negro. Si la
## escena nueva tiene un problema, se queda en la actual.
func _ir_a(paso: int) -> void:
	if _en_transicion:
		return
	_en_transicion = true
	get_tree().paused = true
	await _fundido.oscurecer()
	var nivel := _cargar(paso)
	if nivel != null:
		_descargar_nivel_actual()
		var posicion := _raiz_nivel.global_transform * nivel.obtener_posicion_aparicion()
		jugador.aparecer(posicion)
		await _esperar_posicion_en_fisica(posicion)
		_colocar_nivel(nivel)
		_paso = paso
		escena_cambiada.emit(paso, secuencia.es_campamento(paso))
	await _fundido.aclarar()
	get_tree().paused = false
	_en_transicion = false
	transicion_terminada.emit()


## Espera a que el servidor de física tenga a William en [param posicion].
## Un cuerpo como William recién cambia de lugar en el servidor al avanzar la
## física, que está detenida por la pausa. Si la escena nueva entrara antes,
## sus áreas lo detectarían donde estaba en la escena anterior. Se activa la
## física solo durante esta espera: el resto del juego sigue en pausa y no hay
## ningún nivel cargado.
func _esperar_posicion_en_fisica(posicion: Vector2) -> void:
	PhysicsServer2D.set_active(true)
	while not _posicion_en_fisica().is_equal_approx(posicion):
		await get_tree().physics_frame
	PhysicsServer2D.set_active(false)


func _posicion_en_fisica() -> Vector2:
	var estado: Transform2D = PhysicsServer2D.body_get_state(jugador.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM)
	return estado.origin


## Crea la escena de [param paso]. Devuelve null, con el error en la consola,
## si no se puede usar.
func _cargar(paso: int) -> Nivel:
	var ruta := secuencia.obtener_ruta(paso)
	var escena := load(ruta) as PackedScene if ResourceLoader.exists(ruta) else null
	if escena == null:
		push_error("GestorNiveles: no se pudo cargar %s." % ruta)
		return null
	var nivel := escena.instantiate() as Nivel
	if nivel == null:
		push_error("GestorNiveles: la raíz de %s no es un Nivel." % ruta)
		return null
	var errores := nivel.validar()
	if not errores.is_empty():
		push_error("GestorNiveles: %s: %s" % [ruta, " ".join(errores)])
		nivel.free()
		return null
	return nivel


func _descargar_nivel_actual() -> void:
	if _nivel_actual != null:
		_raiz_nivel.remove_child(_nivel_actual)
		_nivel_actual.queue_free()


func _colocar_nivel(nivel: Nivel) -> void:
	_nivel_actual = nivel
	nivel.jugador = jugador
	_raiz_nivel.add_child(nivel)
	nivel.fin_alcanzado.connect(avanzar)
