class_name SecuenciaNiveles
extends Resource
## Orden de las escenas de la partida (1.2.3.2, sección 3.1):
## nivel 1 → campamento → nivel 2 → … → campamento → nivel 5.
##
## Guarda rutas y no escenas, para no cargar todos los niveles en memoria al
## abrir el juego. El campamento es una sola escena reutilizada (1.4.2.8).

const CANTIDAD_NIVELES := 5

## Rutas de las escenas de los niveles, en orden.
@export_file("*.tscn") var niveles: Array[String] = []
## Ruta de la escena del campamento.
@export_file("*.tscn") var campamento: String = ""


## Cantidad de escenas que se recorren: los niveles con un campamento entre
## cada par.
func cantidad_pasos() -> int:
	return maxi(niveles.size() * 2 - 1, 0)


## Indica si [param paso] es un campamento (los pasos impares).
func es_campamento(paso: int) -> bool:
	return paso % 2 == 1


## Ruta de la escena de [param paso].
func obtener_ruta(paso: int) -> String:
	return campamento if es_campamento(paso) else niveles[paso / 2]


## Devuelve la lista de errores, vacía si la secuencia está bien.
func validar() -> PackedStringArray:
	var errores := PackedStringArray()
	if niveles.size() != CANTIDAD_NIVELES:
		errores.append("Debe tener %d niveles y tiene %d." % [CANTIDAD_NIVELES, niveles.size()])
	if campamento.is_empty():
		errores.append("Falta el campamento.")
	for ruta in niveles + [campamento]:
		if not ruta.is_empty() and not ResourceLoader.exists(ruta):
			errores.append("No existe la escena %s." % ruta)
	return errores
