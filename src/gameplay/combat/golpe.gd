class_name Golpe
extends RefCounted
## Datos de un golpe que una Hitbox entrega a una Hurtbox (1.4.4.2).
##
## Solo describe el impacto. El cálculo del daño final (resistencias,
## talismanes, redondeo) lo hace 1.4.5.1 a partir de estos datos.

## Tipo de daño (1.2.4.2, sección 3).
enum TipoDanio {
	FISICO,
	MAGICO,
}

## Daño base en corazones (por ejemplo 0.5, 1, 2).
var danio: float = 0.0
## Tipo de daño.
var tipo: TipoDanio = TipoDanio.FISICO
## Posición global de donde viene el golpe; define el sentido del retroceso.
var origen: Vector2 = Vector2.ZERO
## Nodo que golpea (William, un enemigo, una trampa).
var fuente: Node
## Hitbox que produjo el golpe.
var hitbox: Area2D


func _to_string() -> String:
	return "%s corazón(es) %s de %s" % [danio, "físico" if tipo == TipoDanio.FISICO else "mágico", fuente.name if fuente else "?"]
