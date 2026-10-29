class_name Jugador
extends CharacterBody2D
## William: cuerpo, entrada y máquina de estados (1.4.3.1).
##
## Estados (1.2.5.1, sección 5.3, de mayor a menor prioridad):
## Morir · RecibirDanio · Atacar · Saltar / Caer · Correr · Quieto.
## Las habilidades dracónicas (1.4.5) se agregan como estados nuevos.
##
## El movimiento de este script es provisional: usa las métricas de 1.2.6.1
## sin aceleración ni salto variable. Lo reemplaza y lo calibra 1.4.3.2.
## Las animaciones de cada estado se conectan en 1.4.10.

## Cambio de estado, para la animación (1.4.10) y la depuración.
signal estado_cambiado(anterior: StringName, nuevo: StringName)
## Momento del ataque en que la espada golpea (frame activo de ATTACK 1).
## Lo usa la hitbox de 1.4.5.2.
signal golpe_activado
## Terminó la animación de muerte: la partida puede reiniciarse (1.4.11.3).
signal muerte_terminada

const TILE := 16.0

@export_group("Movimiento provisional (1.2.6.1)")
## Velocidad al correr: 7 tiles/s.
@export var velocidad_correr: float = 7.0 * TILE
## Altura del salto: 3.5 tiles.
@export var altura_salto: float = 3.5 * TILE
## Tiempo desde el despegue hasta la parte más alta del salto.
@export var tiempo_hasta_cima: float = 0.4
## Velocidad máxima de caída: 15 tiles/s.
@export var velocidad_max_caida: float = 15.0 * TILE

@export_group("Combate (1.2.4.2 y 1.2.5.1)")
## Duración del ataque: 8 frames a 20 cuadros/s.
@export var duracion_ataque: float = 0.4
## Momento del golpe dentro del ataque: 4.º frame.
@export var momento_golpe: float = 0.15
## Tiempo sin control al recibir un golpe.
@export var duracion_retroceso: float = 0.2
## Distancia del retroceso: ½ tile.
@export var distancia_retroceso: float = 0.5 * TILE
## Duración de la animación de muerte: 15 frames a 12 cuadros/s.
@export var duracion_muerte: float = 1.25

## Lado hacia el que mira William: 1 derecha, -1 izquierda.
var mirando: int = 1

@onready var maquina: MaquinaEstados = $MaquinaEstados


func _ready() -> void:
	CapasColision.configurar(self, CapasColision.Perfil.CUERPO_WILLIAM)
	maquina.estado_cambiado.connect(func(anterior: StringName, nuevo: StringName) -> void:
		estado_cambiado.emit(anterior, nuevo))
	maquina.iniciar(self)


func _physics_process(delta: float) -> void:
	maquina.actualizar_fisica(delta)
	move_and_slide()


# --- Valores derivados ---

## Gravedad que produce un salto de [member altura_salto] en [member tiempo_hasta_cima].
func obtener_gravedad() -> float:
	return 2.0 * altura_salto / (tiempo_hasta_cima * tiempo_hasta_cima)


## Velocidad inicial del salto.
func obtener_velocidad_salto() -> float:
	return 2.0 * altura_salto / tiempo_hasta_cima


# --- Ayudas para los estados ---

## Dirección pedida por el jugador: -1, 0 o 1.
func obtener_direccion() -> float:
	return Input.get_axis(&"mover_izquierda", &"mover_derecha")


## Aplica la gravedad, con tope en la velocidad máxima de caída.
func aplicar_gravedad(delta: float) -> void:
	velocity.y = minf(velocity.y + obtener_gravedad() * delta, velocidad_max_caida)


## Mueve en horizontal según [param direccion] y actualiza hacia dónde mira.
func mover_horizontal(direccion: float) -> void:
	velocity.x = direccion * velocidad_correr
	if direccion != 0.0:
		mirando = 1 if direccion > 0.0 else -1


# --- Eventos externos ---

## William recibe un golpe desde la posición horizontal [param origen_x].
## Devuelve false si no se aplicó (por ejemplo, si está muriendo).
## La salud y la invulnerabilidad las maneja 1.4.5.1.
func recibir_danio(origen_x: float) -> bool:
	return maquina.interrumpir(&"RecibirDanio", {"origen_x": origen_x})


## La salud llegó a 0. Devuelve false si ya estaba muriendo.
func morir() -> bool:
	return maquina.interrumpir(&"Morir")


## Nombre del estado actual.
func obtener_estado() -> StringName:
	return maquina.obtener_nombre_estado()
