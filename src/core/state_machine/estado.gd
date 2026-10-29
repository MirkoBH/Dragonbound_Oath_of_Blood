class_name EstadoBase
extends Node
## Estado genérico de una máquina de estados (William, y más adelante los
## enemigos de 1.4.6.1).
##
## Cada estado es un nodo hijo de una MaquinaEstados. El nombre del nodo es el
## nombre del estado (por ejemplo, «Quieto»). La máquina llama a [method entrar]
## al activarlo, a [method actualizar_fisica] en cada cuadro de física y a
## [method salir] al dejarlo.

## Prioridad del estado: cuanto más bajo el número, más importante.
## Un evento externo (recibir daño, morir) solo interrumpe al estado actual si
## su prioridad es igual o más importante (ver [method MaquinaEstados.interrumpir]).
var prioridad: int = 9

## Máquina a la que pertenece. La asigna [method MaquinaEstados.iniciar].
var maquina: MaquinaEstados


## Se llama una vez al iniciar la máquina, con el nodo que la usa.
func preparar(_dueno: Node) -> void:
	pass


## Se llama al entrar al estado. [param datos] trae información opcional.
func entrar(_datos: Dictionary = {}) -> void:
	pass


## Se llama al salir del estado.
func salir() -> void:
	pass


## Se llama en cada cuadro de física mientras el estado está activo.
func actualizar_fisica(_delta: float) -> void:
	pass


## Indica si un evento externo puede sacar a la máquina de este estado.
func puede_interrumpirse() -> bool:
	return true


## Atajo para pasar a otro estado desde el propio estado.
func cambiar_a(nombre: StringName, datos: Dictionary = {}) -> void:
	maquina.cambiar_a(nombre, datos)
