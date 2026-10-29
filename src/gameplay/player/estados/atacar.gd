extends EstadoJugador
## Golpe de espada hacia donde mira William (AW-01 y AW-02 de 1.2.5.1).
##
## En el suelo, William se detiene mientras dura el golpe. En el aire conserva
## su impulso horizontal y sigue cayendo. El ataque se juega completo y emite
## [signal Jugador.golpe_activado] en el frame activo.

var _tiempo: float = 0.0
var _golpe_emitido: bool = false


func _init() -> void:
	prioridad = 4


func entrar(_datos: Dictionary = {}) -> void:
	_tiempo = 0.0
	_golpe_emitido = false
	if jugador.is_on_floor():
		jugador.velocity.x = 0.0


func actualizar_fisica(delta: float) -> void:
	_tiempo += delta
	jugador.aplicar_gravedad(delta)
	if jugador.is_on_floor():
		jugador.velocity.x = 0.0
	if not _golpe_emitido and _tiempo >= jugador.momento_golpe:
		_golpe_emitido = true
		jugador.golpe_activado.emit()
	if _tiempo >= jugador.duracion_ataque:
		volver_segun_situacion()
