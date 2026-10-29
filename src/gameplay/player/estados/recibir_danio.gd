extends EstadoJugador
## William recibe un golpe: retroceso de ½ tile y 0,2 s sin control (1.2.4.2).
##
## Interrumpe el ataque (el golpe que estaba saliendo se cancela).
## Datos de entrada: {"origen_x": posición horizontal de quien golpea}.

var _tiempo: float = 0.0


func _init() -> void:
	prioridad = 2


func entrar(datos: Dictionary = {}) -> void:
	_tiempo = 0.0
	var origen_x: float = datos.get("origen_x", jugador.global_position.x + jugador.mirando)
	var sentido := signf(jugador.global_position.x - origen_x)
	if sentido == 0.0:
		sentido = -jugador.mirando
	jugador.velocity.x = sentido * jugador.distancia_retroceso / jugador.duracion_retroceso


func actualizar_fisica(delta: float) -> void:
	_tiempo += delta
	jugador.aplicar_gravedad(delta)
	if _tiempo >= jugador.duracion_retroceso:
		volver_segun_situacion()
