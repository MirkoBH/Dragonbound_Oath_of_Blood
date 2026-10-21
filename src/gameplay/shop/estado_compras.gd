class_name EstadoCompras
extends RefCounted
## Interfaz provisoria con lo que el catálogo necesita saber de la partida.
##
## El catálogo no lee el estado global directamente: recibe este objeto.
## Cuando exista el estado global de la partida (1.4.11.1), alcanza con
## armar un EstadoCompras a partir de él; el catálogo no cambia.

## Oro disponible.
var oro: int = 0
## Niveles comprados de cada mejora por niveles: { id: nivel }.
var niveles_comprados: Dictionary[StringName, int] = {}
## Objetos únicos ya comprados: { id: true }.
var unicos_comprados: Dictionary[StringName, bool] = {}
## Cantidad de cada consumible en el inventario: { id: cantidad }.
var consumibles: Dictionary[StringName, int] = {}


## Nivel comprado de una mejora (0 si todavía no se compró ninguno).
func obtener_nivel(id: StringName) -> int:
	return niveles_comprados.get(id, 0)


## Indica si un objeto único ya se compró.
func tiene_unico(id: StringName) -> bool:
	return unicos_comprados.get(id, false)


## Cantidad de un consumible en el inventario.
func obtener_cantidad(id: StringName) -> int:
	return consumibles.get(id, 0)
