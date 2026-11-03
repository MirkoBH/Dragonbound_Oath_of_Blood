class_name Hurtbox
extends Area2D
## Área que recibe golpes (1.4.4.2).
##
## Se agrega como hijo del personaje, con su CollisionShape2D. Las Hitbox la
## detectan y le entregan un [Golpe]. La hurtbox solo decide si lo acepta:
## no lo acepta si está desactivada (por ejemplo, con la Armadura de dragón,
## 1.4.5.10) o mientras dura la invulnerabilidad. El daño lo calcula 1.4.5.1.

## Se emite cada vez que se acepta un golpe.
signal golpe_recibido(golpe: Golpe)

## Perfil de colisión: RECIBE_GOLPES_WILLIAM o RECIBE_GOLPES_ENEMIGO.
@export var perfil: CapasColision.Perfil = CapasColision.Perfil.RECIBE_GOLPES_ENEMIGO
## Si es false, no acepta ningún golpe.
@export var activa: bool = true

var _invulnerable_restante: float = 0.0


func _ready() -> void:
	CapasColision.configurar(self, perfil)
	# La hurtbox solo es detectada: quien busca es la Hitbox.
	monitoring = false
	monitorable = true


func _physics_process(delta: float) -> void:
	_invulnerable_restante = maxf(_invulnerable_restante - delta, 0.0)


## Intenta recibir un golpe. Devuelve true si lo aceptó.
func recibir(golpe: Golpe) -> bool:
	if not activa or esta_invulnerable():
		return false
	golpe_recibido.emit(golpe)
	return true


## Ignora todos los golpes durante [param segundos] (1 s tras un golpe, 1.2.4.2).
func aplicar_invulnerabilidad(segundos: float) -> void:
	_invulnerable_restante = maxf(_invulnerable_restante, segundos)


## Termina la invulnerabilidad en curso (William al aparecer, 1.4.2.1).
func quitar_invulnerabilidad() -> void:
	_invulnerable_restante = 0.0


## Indica si está en período de invulnerabilidad.
func esta_invulnerable() -> bool:
	return _invulnerable_restante > 0.0


## Segundos de invulnerabilidad que quedan.
func obtener_invulnerabilidad_restante() -> float:
	return _invulnerable_restante
