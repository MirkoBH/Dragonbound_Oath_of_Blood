class_name EstadoJugador
extends EstadoBase
## Base de los estados de William, con acceso tipado al personaje.

var jugador: Jugador


func preparar(dueno: Node) -> void:
	jugador = dueno as Jugador


## Pasa al estado que corresponde a la situación actual, al terminar una
## acción (ataque o retroceso): en el suelo, Correr o Quieto; en el aire,
## Saltar (sin nuevo impulso) mientras sube, o Caer.
func volver_segun_situacion() -> void:
	if jugador.is_on_floor():
		cambiar_a(&"Correr" if jugador.obtener_direccion() != 0.0 else &"Quieto")
	elif jugador.velocity.y < 0.0:
		cambiar_a(&"Saltar", {"sin_impulso": true})
	else:
		cambiar_a(&"Caer")


## Revisa las acciones que se pueden iniciar en el suelo. Devuelve true si
## cambió de estado.
func revisar_acciones_en_suelo() -> bool:
	if not jugador.is_on_floor():
		cambiar_a(&"Caer")
		return true
	if Input.is_action_just_pressed(&"saltar"):
		cambiar_a(&"Saltar")
		return true
	if Input.is_action_just_pressed(&"atacar"):
		cambiar_a(&"Atacar")
		return true
	return false
