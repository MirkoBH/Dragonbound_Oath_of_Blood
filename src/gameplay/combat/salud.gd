class_name Salud
extends Node
## Salud en corazones de William o de un enemigo (1.4.5.1, según 1.2.4.1).
##
## Componente reutilizable: se agrega como hijo del personaje. Siempre guarda
## múltiplos de ½ corazón y nunca baja de 0 ni pasa del máximo. Avisa cada
## cambio (para el HUD, 1.4.1.5) y la muerte (para la máquina de estados, el
## reinicio de 1.4.11.3 o el botín de 1.4.7).
##
## PROVISORIO para William: cuando exista el estado global (1.4.11.1), la
## salud de William se lee y se guarda ahí.

## Cambió la salud actual o la máxima.
signal salud_cambiada(actual: float, maxima: float)
## Se aplicó daño (ya calculado y redondeado). [param golpe] puede ser null
## (por ejemplo, una caída al vacío, 1.4.4.3).
signal danio_recibido(cantidad: float, golpe: Golpe)
## Un golpe aceptado no hizo daño: el enemigo solo recibe daño mágico y el
## golpe era físico. 1.4.10 muestra el efecto de «no le hace nada».
signal golpe_sin_efecto(golpe: Golpe)
## La salud llegó a 0. Se emite una sola vez.
signal murio

## Salud máxima en corazones (William: 5, 1.2.4.1; enemigos: su ficha, 1.2.5).
@export var salud_maxima: float = 5.0

var _actual: float = 0.0
var _murio: bool = false


func _ready() -> void:
	_actual = CalculoDanio.redondear(salud_maxima) if salud_maxima > 0.0 else 0.0


## Salud actual en corazones.
func obtener_actual() -> float:
	return _actual


## Indica si la salud llegó a 0.
func esta_muerto() -> bool:
	return _murio


## Resta [param cantidad] corazones (ya calculados con CalculoDanio). Si la
## cantidad es 0, avisa golpe_sin_efecto. Devuelve el daño aplicado.
func aplicar_danio(cantidad: float, golpe: Golpe = null) -> float:
	if _murio:
		return 0.0
	if cantidad <= 0.0:
		golpe_sin_efecto.emit(golpe)
		return 0.0
	var aplicado := minf(CalculoDanio.redondear(cantidad), _actual)
	_actual -= aplicado
	danio_recibido.emit(aplicado, golpe)
	salud_cambiada.emit(_actual, salud_maxima)
	if _actual <= 0.0:
		_actual = 0.0
		_murio = true
		murio.emit()
	return aplicado


## Suma [param cantidad] corazones sin pasar del máximo (pociones, 1.4.9.4;
## campamento, 1.4.11.2). Devuelve lo que realmente se curó.
func curar(cantidad: float) -> float:
	if _murio or cantidad <= 0.0:
		return 0.0
	var curado := minf(CalculoDanio.redondear(cantidad), salud_maxima - _actual)
	_actual += curado
	if curado > 0.0:
		salud_cambiada.emit(_actual, salud_maxima)
	return curado


## Cambia la salud máxima (mejoras de armadura, 1.2.4.5). Si
## [param sumar_a_actual], la actual sube lo mismo que el máximo.
func cambiar_maxima(nueva: float, sumar_a_actual: bool = true) -> void:
	var diferencia := nueva - salud_maxima
	salud_maxima = nueva
	if sumar_a_actual and diferencia > 0.0:
		_actual += diferencia
	_actual = clampf(_actual, 0.0, salud_maxima)
	salud_cambiada.emit(_actual, salud_maxima)
