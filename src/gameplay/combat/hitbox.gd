class_name Hitbox
extends Area2D
## Área que emite golpes (1.4.4.2): espada, ataques de enemigos, proyectiles y
## trampas.
##
## Se agrega como hijo de quien golpea, con su CollisionShape2D. Mientras está
## activa, entrega un [Golpe] a cada Hurtbox que toca, según su modo:
## - POR_ACTIVACION: golpea una sola vez a cada objetivo por activación
##   (espada, Aliento, ataques de enemigos).
## - CONTINUO: sigue intentando golpear mientras haya contacto. La Hurtbox lo
##   rechaza mientras el objetivo es invulnerable, así que vuelve a dañar
##   cuando termina la invulnerabilidad (trampas, 1.2.6.3).
## No hay daño por contacto entre cuerpos: solo dañan las Hitbox (1.4.4.1).

## Se emite cada vez que un golpe es aceptado por una Hurtbox.
signal impacto(hurtbox: Hurtbox, golpe: Golpe)

## Cómo repite el golpe sobre un mismo objetivo.
enum Modo {
	POR_ACTIVACION,
	CONTINUO,
}

## Perfil de colisión: ATAQUE_WILLIAM, ATAQUE_ENEMIGO, PROYECTIL_* o TRAMPA.
@export var perfil: CapasColision.Perfil = CapasColision.Perfil.ATAQUE_ENEMIGO
@export var modo: Modo = Modo.POR_ACTIVACION
## Daño base en corazones.
@export var danio: float = 1.0
@export var tipo: Golpe.TipoDanio = Golpe.TipoDanio.FISICO
## Si es true, empieza activa (por ejemplo, una trampa fija).
@export var activa_al_iniciar: bool = false
## Quién golpea. Si queda vacío, se usa el nodo padre.
@export var fuente: Node

var _activa: bool = false
var _tiempo_restante: float = -1.0
var _golpeados: Dictionary[int, bool] = {}


func _ready() -> void:
	CapasColision.configurar(self, perfil)
	monitoring = true
	monitorable = false
	if fuente == null:
		fuente = get_parent()
	if activa_al_iniciar:
		activar()


func _physics_process(delta: float) -> void:
	if not _activa:
		return
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null:
			continue
		var id := hurtbox.get_instance_id()
		if modo == Modo.POR_ACTIVACION and _golpeados.has(id):
			continue
		var golpe := crear_golpe()
		if hurtbox.recibir(golpe):
			_golpeados[id] = true
			impacto.emit(hurtbox, golpe)
	if _tiempo_restante > 0.0:
		_tiempo_restante -= delta
		if _tiempo_restante <= 0.0:
			desactivar()


## Activa la hitbox. Con [param duracion] mayor a 0 se desactiva sola después
## de ese tiempo; con -1 queda activa hasta llamar a [method desactivar].
## Cada activación vuelve a permitir golpear a todos los objetivos.
func activar(duracion: float = -1.0) -> void:
	_activa = true
	_tiempo_restante = duracion
	_golpeados.clear()


## Desactiva la hitbox (por ejemplo, si el ataque se interrumpe).
func desactivar() -> void:
	_activa = false
	_tiempo_restante = -1.0


## Indica si la hitbox está activa.
func esta_activa() -> bool:
	return _activa


## Arma el golpe con los datos de esta hitbox.
func crear_golpe() -> Golpe:
	var golpe := Golpe.new()
	golpe.danio = danio
	golpe.tipo = tipo
	golpe.origen = (fuente as Node2D).global_position if fuente is Node2D else global_position
	golpe.fuente = fuente
	golpe.hitbox = self
	return golpe
