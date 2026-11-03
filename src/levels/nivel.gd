class_name Nivel
extends Node2D
## Base de toda escena jugable: niveles y campamento (1.4.2.1).
##
## Cada escena define dónde aparece William y, si termina al llegar a un lugar,
## su disparador de fin de nivel. El nivel 5 no lo usa: termina con la derrota
## de Morgana (1.2.6.1, sección 4).

## William llegó al disparador de fin de nivel.
signal fin_alcanzado

## Punto donde aparece William. Se apoya sobre el suelo.
@export var punto_aparicion: Marker2D
## Disparador de fin de nivel. Se deja vacío en el nivel 5.
@export var disparador_fin: DisparadorFinNivel


func _ready() -> void:
	if disparador_fin != null:
		disparador_fin.william_llego.connect(fin_alcanzado.emit)


## Devuelve la lista de errores, vacía si la escena está bien.
func validar() -> PackedStringArray:
	var errores := PackedStringArray()
	if punto_aparicion == null:
		errores.append("Falta el punto de aparición.")
	return errores
