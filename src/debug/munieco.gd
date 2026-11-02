class_name Munieco
extends CharacterBody2D
## Enemigo de prueba (solo depuración) para probar hitboxes y hurtboxes.
##
## Bloquea el paso de William, recibe golpes en su hurtbox y, si [member ataca]
## es true, lanza un golpe hacia William cada [member intervalo] segundos.

## Si es true, ataca periódicamente hacia [member objetivo].
@export var ataca: bool = false
@export var intervalo: float = 1.5
@export var danio: float = 0.5
var objetivo: Node2D

var golpes_recibidos: int = 0
var ultimo_golpe: Golpe
var destello: float = 0.0
var hurtbox: Hurtbox
var hitbox: Hitbox

var _espera: float = 0.0


func _ready() -> void:
	CapasColision.configurar(self, CapasColision.Perfil.CUERPO_ENEMIGO)
	add_child(_forma(Vector2(14, 28), Vector2(0, -14)))
	hurtbox = Hurtbox.new()
	hurtbox.perfil = CapasColision.Perfil.RECIBE_GOLPES_ENEMIGO
	hurtbox.add_child(_forma(Vector2(14, 28), Vector2(0, -14)))
	add_child(hurtbox)
	hurtbox.golpe_recibido.connect(_al_recibir_golpe)
	if ataca:
		hitbox = Hitbox.new()
		hitbox.perfil = CapasColision.Perfil.ATAQUE_ENEMIGO
		hitbox.danio = danio
		hitbox.position = Vector2(-16, -14)
		hitbox.add_child(_forma(Vector2(20, 20), Vector2.ZERO))
		add_child(hitbox)
	_espera = intervalo


func _physics_process(delta: float) -> void:
	destello = maxf(destello - delta, 0.0)
	velocity.y = minf(velocity.y + 700.0 * delta, 240.0)
	velocity.x = 0.0
	move_and_slide()
	if ataca and objetivo:
		_espera -= delta
		if _espera <= 0.0:
			_espera = intervalo
			var lado := -1.0 if objetivo.global_position.x < global_position.x else 1.0
			hitbox.position.x = 16.0 * lado
			hitbox.activar(0.2)


func _al_recibir_golpe(golpe: Golpe) -> void:
	golpes_recibidos += 1
	ultimo_golpe = golpe
	destello = 0.15


func _forma(tamanio: Vector2, posicion: Vector2) -> CollisionShape2D:
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = tamanio
	forma.shape = rect
	forma.position = posicion
	return forma
