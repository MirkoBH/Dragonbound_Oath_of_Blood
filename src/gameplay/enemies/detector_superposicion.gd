class_name DetectorSuperposicion
extends Area2D
## Avisa cuando un enemigo queda superpuesto con otro demasiado tiempo.
##
## Los enemigos se atraviesan entre sí (1.4.4.1). Este sensor se agrega como
## hijo de cada enemigo, con su CollisionShape2D, y cuenta cuánto tiempo lleva
## superpuesto con cada otro enemigo. Al superar el umbral emite
## [signal superposicion_prolongada]; la IA del enemigo (1.4.6.1) decide cómo
## separarse, por ejemplo invirtiendo la patrulla hacia
## [method obtener_direccion_separacion].

## Se emite cada vez que la superposición con [param otro] supera el umbral.
## Si siguen superpuestos, se vuelve a emitir tras otro umbral completo.
signal superposicion_prolongada(otro: Node2D)

## Segundos de superposición continua antes de avisar.
@export var umbral_segundos: float = 1.0

## Tiempo acumulado con cada enemigo: { id de instancia: segundos }.
var _tiempos: Dictionary[int, float] = {}


func _ready() -> void:
	CapasColision.configurar(self, CapasColision.Perfil.DETECTOR_SUPERPOSICION)
	monitorable = false


func _physics_process(delta: float) -> void:
	var propio := get_parent()
	var vistos: Dictionary[int, bool] = {}
	for cuerpo in get_overlapping_bodies():
		if cuerpo == propio:
			continue
		var id := cuerpo.get_instance_id()
		vistos[id] = true
		_tiempos[id] = _tiempos.get(id, 0.0) + delta
		if _tiempos[id] >= umbral_segundos:
			_tiempos[id] = 0.0
			superposicion_prolongada.emit(cuerpo)
	for id in _tiempos.keys():
		if not vistos.has(id):
			_tiempos.erase(id)


## Tiempo que lleva superpuesto con [param otro] (0 si no lo está).
func obtener_tiempo_superpuesto(otro: Node2D) -> float:
	return _tiempos.get(otro.get_instance_id(), 0.0)


## Dirección horizontal (-1 o 1) para alejarse de [param otro].
## Si están exactamente en la misma posición, elige 1.
func obtener_direccion_separacion(otro: Node2D) -> int:
	var propio := get_parent() as Node2D
	if propio == null:
		return 1
	return -1 if propio.global_position.x < otro.global_position.x else 1
