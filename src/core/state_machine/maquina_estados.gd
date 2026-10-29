class_name MaquinaEstados
extends Node
## Máquina de estados genérica.
##
## Sus hijos son nodos EstadoBase; cada uno se identifica por el nombre del nodo.
## No se actualiza sola: el dueño (por ejemplo, William) llama a
## [method actualizar_fisica] en su propio _physics_process, para controlar el
## orden entre la lógica del estado y el movimiento.

## Se emite en cada cambio de estado, con los nombres de ambos estados.
signal estado_cambiado(anterior: StringName, nuevo: StringName)

## Estado con el que arranca la máquina.
@export var estado_inicial: EstadoBase

## Estado activo.
var estado_actual: EstadoBase

var _estados: Dictionary[StringName, EstadoBase] = {}


## Registra los estados hijos, los prepara con [param dueno] y entra al
## estado inicial.
func iniciar(dueno: Node) -> void:
	for hijo in get_children():
		if hijo is EstadoBase:
			_estados[hijo.name] = hijo
			hijo.maquina = self
			hijo.preparar(dueno)
	assert(estado_inicial != null, "MaquinaEstados: falta el estado inicial.")
	estado_actual = estado_inicial
	estado_actual.entrar()


## Actualiza el estado activo. La llama el dueño en cada cuadro de física.
func actualizar_fisica(delta: float) -> void:
	if estado_actual:
		estado_actual.actualizar_fisica(delta)


## Cambia de estado sin revisar prioridades. La usan los propios estados para
## sus transiciones normales (por ejemplo, de Saltar a Caer).
func cambiar_a(nombre: StringName, datos: Dictionary = {}) -> void:
	assert(_estados.has(nombre), "MaquinaEstados: no existe el estado %s." % nombre)
	var anterior := estado_actual.name if estado_actual else &""
	if estado_actual:
		estado_actual.salir()
	estado_actual = _estados[nombre]
	estado_actual.entrar(datos)
	estado_cambiado.emit(anterior, nombre)


## Cambio pedido desde afuera (recibir daño, morir). Solo se aplica si el
## estado actual se puede interrumpir y el nuevo es igual o más prioritario.
## Devuelve true si se aplicó.
func interrumpir(nombre: StringName, datos: Dictionary = {}) -> bool:
	var nuevo: EstadoBase = _estados.get(nombre)
	if nuevo == null:
		return false
	if not estado_actual.puede_interrumpirse():
		return false
	if nuevo.prioridad > estado_actual.prioridad:
		return false
	cambiar_a(nombre, datos)
	return true


## Nombre del estado activo.
func obtener_nombre_estado() -> StringName:
	return estado_actual.name if estado_actual else &""


## Indica si existe un estado con ese nombre.
func tiene_estado(nombre: StringName) -> bool:
	return _estados.has(nombre)
