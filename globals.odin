package rpg

import rl "vendor:raylib"

camera: rl.Camera2D
entities: [dynamic]Entity
turn: int
dt: f32

PLAYER_TURN :: 0
ENEMY_TURN :: 1

MAP_WIDTH :: 10
MAP_HEIGHT :: 10
MAP_SIZE :: MAP_WIDTH * MAP_HEIGHT
CELL_SIZE :: 16
CANVAS_SIZE :: MAP_WIDTH * CELL_SIZE
MAP_OFFSET :: 20

player_texture : rl.Texture2D
enemy_texture: rl.Texture2D
hill_texture: rl.Texture2D

tile_texture: rl.Texture2D
tile_hovered_texture: rl.Texture2D

player: Entity

