class_name Resistencias
extends Resource
## Resistencias de un enemigo al daño (1.2.4.2, sección 4).
##
## Cada ficha de enemigo (1.2.5.2 a 1.2.5.7) fija las suyas; se cargan en su
## definición (1.4.6.x). Las resistencias reducen el daño un 25 % o un 50 %.

## Fracción del daño físico que se descuenta: 0, 0,25 o 0,5.
@export_range(0.0, 0.5, 0.25) var resistencia_fisica: float = 0.0
## Fracción del daño mágico que se descuenta: 0, 0,25 o 0,5. Ningún enemigo es
## inmune a la magia.
@export_range(0.0, 0.5, 0.25) var resistencia_magica: float = 0.0
## Enemigo especial que no recibe daño físico: solo se lo daña con magia
## (runa de fuego o Aliento). Va fuera del camino principal (1.2.6.1, 5.3).
@export var solo_danio_magico: bool = false


## Revisa los valores. Devuelve la lista de errores (vacía si está bien).
func validar() -> PackedStringArray:
	var errores := PackedStringArray()
	for nombre in ["resistencia_fisica", "resistencia_magica"]:
		var valor: float = get(nombre)
		if not valor in [0.0, 0.25, 0.5]:
			errores.append("%s debe ser 0, 0,25 o 0,5 (es %s)." % [nombre, valor])
	return errores
