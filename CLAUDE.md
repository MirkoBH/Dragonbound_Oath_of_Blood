# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Dragonbound: Oath of Blood" is a 2D pixel-art platformer built with **Godot 4.7** and GDScript only. There is no other build system. The player character is **William**.

**Language convention:** all identifiers, class names, node names, input actions, doc comments and commit messages are in **Spanish**, for example `MaquinaEstados`, `recibir_danio`, `mover_derecha`, `prioridad`. Leave out accents and ñ in identifiers (`danio`, `dueno`), but keep them in comments and strings. Follow this convention in new code.

Doc comments use `##` and often cite design-document section numbers, for example `(1.2.6.1)` or `(1.4.5.2)`. These numbers refer to the team's external design and task plan. Keep them when editing, and cite the relevant section for new work. Many systems are marked as provisional and name the task that will replace them (for example, player movement is to be recalibrated in 1.4.3.2). Respect those boundaries.

Git workflow: feature branches named `feature/<tema>`, merged into `dev` via PR. Commit subjects are short Spanish phrases that end with the task number, for example `Máquina de estados de William (1.4.3.1)`.

## Commands

Run from the project root (assuming `godot` is on PATH):

```bash
godot --headless --import                                          # required once after cloning (builds .godot/)
godot --editor .                                                   # open the editor
godot .                                                            # run the main scene (MainGame)
godot --headless res://src/debug/prueba_maquina_estados.tscn       # run one test scene
```

`.godot/` is not committed. On a fresh clone, run `--import` first: otherwise `class_name` types are not found, and a test scene prints parse errors and never exits. Wrap test runs in `timeout 120` so that case cannot hang.

There is no test framework. Tests are **self-checking scenes in `src/debug/prueba_*.tscn`**. Each one prints `OK` / `FALLA` lines plus a final `Resultado: ...`, then calls `get_tree().quit(0 or 1)`, so you can read the exit code. Current headless tests:
- `prueba_catalogo_tienda.tscn`: shop catalog
- `prueba_capas_colision.tscn`: collision layers and masks
- `prueba_maquina_estados.tscn`: William's state machine, driven by simulated input

`prueba_jugador.tscn` is an interactive playground, not an automated test (A/D, Space, J, H = take hit, M = die, R = reset).

To add a test, copy the existing pattern: a `_verificar(condicion, descripcion)` helper, a `_fallas` counter, and a `quit` with the exit code. Use `EscenarioPrueba.crear_terreno()` (`src/debug/escenario_prueba.gd`) to build floor geometry in code. Simulate input with `Input.action_press/release` and wait on `get_tree().physics_frame`.

## Architecture

- **Layout:** `src/core` (engine-level systems), `src/gameplay` (player, enemies, shop, etc.), `src/resources` (data `.tres` + their `Resource` scripts), `src/levels`, `src/debug`. Art and audio go in `assets/`. Many folders are still `.gitkeep` placeholders.
- **Main scene** `src/core/main_game/main_game.tscn` is a fixed skeleton: `Systems`, `World/{LevelRoot,EntityRoot,EffectRoot}`, and CanvasLayers for HUD, pause, transitions and debug. Levels (template: `src/levels/test_level_01.tscn`) use `Background / Tilemaps / LevelObjects / Environment`. No autoloads exist yet.
- **State machine** (`src/core/state_machine/`): `MaquinaEstados` holds child `EstadoBase` nodes, each keyed by its **node name** (`&"Quieto"`, `&"RecibirDanio"`, ...). Two things matter here:
  - The machine does **not** tick itself. The owner calls `maquina.iniciar(self)` in `_ready` and `maquina.actualizar_fisica(delta)` in `_physics_process` before `move_and_slide()`.
  - `cambiar_a()` is for a state's own transitions and skips priority checks. `interrumpir()` is for external events such as damage or death. It only applies if the current state allows interruption and the new state's `prioridad` is equal or lower (a lower number means higher priority). States set `prioridad` in `_init`.
  - Player states (`src/gameplay/player/estados/`) extend `EstadoJugador`, which gives typed access to `jugador: Jugador` and shared transition helpers (`volver_segun_situacion`, `revisar_acciones_en_suelo`). To add a state, add a script there and a node under `MaquinaEstados` in `player.tscn`. The same machine is meant to be reused for enemies (1.4.6.1).
- **Collision** (`src/core/physics/capas_colision.gd`): never hard-code layer or mask bits. Call `CapasColision.configurar(obj, CapasColision.Perfil.X)` in `_ready`. The 11 named layers in `project.godot` `[layer_names]` must stay in sync with `CapasColision.NOMBRES`/constants. The file header lists the design rules: body is separate from hurtbox, no friendly fire, enemies pass through each other, and projectiles pass through platforms. `CapasColision.describir()` prints a readable table.
- **Data resources:** shop items are `DefinicionObjeto` `.tres` files in `src/resources/item_definitions/`, listed in `src/resources/catalogo_tienda.tres` (`CatalogoTienda`). The catalog never reads global game state. It takes an `EstadoCompras` (a temporary stand-in until the global game state of 1.4.11.1 exists) and returns `OfertaTienda` objects. `validar()` methods on items and the catalog return a list of error strings.
- **Input actions** are defined in `project.godot` with Spanish names (`mover_izquierda`, `saltar`, `atacar`, `aliento`, `armadura`, `pocion_curacion`, `interactuar`, `pausa`, ...). Expected key bindings are checked by `prueba_maquina_estados.gd`.
- **Pixel-art settings:** 640×360 viewport, integer scaling, nearest filtering, 2D pixel snapping. Gameplay units are tiles of 16 px (`Jugador.TILE`), and tuning values are written as `n * TILE`.

## Conventions

- Use static typing everywhere, `StringName` literals (`&"..."`) for state names and actions, and typed dictionaries (`Dictionary[StringName, int]`).
- Commit the `.uid` files that Godot creates next to scripts.
- Edit `.tscn`/`.tres`/`project.godot` by hand carefully. Keep `ext_resource` ids and node paths consistent.
