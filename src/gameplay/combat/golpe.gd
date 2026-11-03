class_name Golpe
extends RefCounted
## Datos de un golpe que una Hitbox entrega a una Hurtbox (1.4.4.2).
##
## Solo describe el impacto. El daño final (resistencias, talismanes,
## redondeo) lo calcula CalculoDanio (1.4.5.1) a partir de estos datos.

## Tipo de daño (1.2.4.2, sección 3).
enum TipoDanio {
	FISICO,
	MAGICO,
}

## Daño base en corazones (por ejemplo 0.5, 1, 2).
var danio: float = 0.0
## Tipo de daño.
var tipo: TipoDanio = TipoDanio.FISICO
## Daño mágico que se suma al golpe, en corazones: el de la runa de fuego en
## la espada (1.2.4.2, sección 5; lo carga 1.4.5.2).
var danio_magico_extra: float = 0.0
## Posición global de donde viene el golpe; define el sentido del retroceso.
var origen: Vector2 = Vector2.ZERO
## Nodo que golpea (William, un enemigo, una trampa).
var fuente: Node
## Hitbox que produjo el golpe.
var hitbox: Area2D


## Componente físico del golpe, en corazones.
func obtener_fisico() -> float:
	return danio if tipo == TipoDanio.FISICO else 0.0


## Componente mágico del golpe, en corazones (incluye el de la runa).
func obtener_magico() -> float:
	return (danio if tipo == TipoDanio.MAGICO else 0.0) + danio_magico_extra


func _to_string() -> String:
	return "%s corazón(es) %s de %s" % [danio, "físico" if tipo == TipoDanio.FISICO else "mágico", fuente.name if fuente else "?"]
