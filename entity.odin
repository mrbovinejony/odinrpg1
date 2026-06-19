package rpg

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"

Entity :: struct {
	texture : rl.Texture2D,
	pos : rl.Vector2,
	current_tile : Tile,
	speed: f32,
	id: int,
	entity_type: Entity_Type,
	entity_state: Entity_State,
	max_moves: f32,
	moves_left: f32,
	health: f32,
	damage: f32,
}

Entity_State :: enum {
	Moving,
	Stopped
}

Entity_Type :: enum {
	Player,
	Enemy,
	Static,
}

check_entity_in_direction :: proc(next_pos: rl.Vector2, e: ^Entity) {
	adjacent_entity : ^Entity

	for &entity in entities{
		if next_pos == entity.pos{
			adjacent_entity = &entity
		}
	}

	switch adjacent_entity.entity_type{
		case .Player:
			do_damage(e, adjacent_entity)
		case .Enemy:
			do_damage(e, adjacent_entity)
		case .Static:
	}
}

do_damage :: proc(attacking_e, damaged_e: ^Entity){
	damaged_e.health -= attacking_e.damage
}

move_entity_to_tile :: proc(e: ^Entity, dir: Direction, num_to_move: f32){
	prev_pos := e.pos
	prev_tile := e.current_tile
	new_pos : rl.Vector2
	new_tile : Tile


	switch dir{
		case .Up:
			new_pos = {e.pos.x, e.pos.y - num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) !check_entity_in_direction(new_pos){
				e.pos = new_pos
				e.current_tile = new_tile
			}else{
				e.pos = prev_pos
				e.current_tile = prev_tile
			}
		case .Down:
			new_pos = {e.pos.x, e.pos.y + num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) && !check_entity_in_direction(new_pos){
				e.pos = new_pos
				e.current_tile = new_tile
			}else{
				e.pos = prev_pos
				e.current_tile = prev_tile
			}
		case .Left:
			new_pos : rl.Vector2
			new_pos = {e.pos.x - e.speed * CELL_SIZE, e.pos.y}
			new_tile := get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) && !check_entity_in_direction(new_pos){
				e.pos = new_pos
				e.current_tile = new_tile
			}else{
				e.pos = prev_pos
				e.current_tile = prev_tile
			}
		case .Right:
			new_pos = {e.pos.x + num_to_move * CELL_SIZE, e.pos.y}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) && !check_entity_in_direction(new_pos){
				e.pos = new_pos
				e.current_tile = new_tile
			}else{
				e.pos = prev_pos
				e.current_tile = prev_tile
			}
		case .UpLeft:
			new_pos = {e.pos.x - num_to_move * CELL_SIZE, e.pos.y - num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) && !check_entity_in_direction(new_pos){
				e.pos = new_pos
				e.current_tile = new_tile
			}else{
				e.pos = prev_pos
				e.current_tile = prev_tile
			}
		case .UpRight:
			new_pos = {e.pos.x + num_to_move * CELL_SIZE, e.pos.y - num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) && !check_entity_in_direction(new_pos){
				e.pos = new_pos
				e.current_tile = new_tile
			}else{
				e.pos = prev_pos
				e.current_tile = prev_tile
			}
		case .DownLeft:
			new_pos = {e.pos.x - num_to_move * CELL_SIZE, e.pos.y + num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) && !check_entity_in_direction(new_pos){
				e.pos = new_pos
				e.current_tile = new_tile
			}else{
				e.pos = prev_pos
				e.current_tile = prev_tile
			}
		case .DownRight:
			new_pos = {e.pos.x + num_to_move * CELL_SIZE, e.pos.y + num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) && !check_entity_in_direction(new_pos){
				e.pos = new_pos
				e.current_tile = new_tile
			}else{
				e.pos = prev_pos
				e.current_tile = prev_tile
			}
		}
}


handle_entity :: proc(e: ^Entity){
	switch e.entity_type{
		case .Player: 			
			if turn == PLAYER_TURN{	
				handle_player_input(e)

				if e.moves_left <= 0{
					turn = ENEMY_TURN
					e.moves_left = e.max_moves
				}
			}

		case .Enemy:
			if turn == ENEMY_TURN{
				move_to_entity_target(e, &entities[0])

				if e.moves_left <= 0{
					turn = PLAYER_TURN
					e.moves_left = e.max_moves
				}
			}

		case .Static:
	}
}

move_to_entity_target :: proc(e, target_e: ^Entity){
	dir_to_target := target_e.pos - e.pos
	dir_to_move := linalg.normalize0(dir_to_target)

	dir: Direction
	//return direction enum based on dir_to_move
	if dir_to_move.x <= -0.3 && dir_to_move.y <= -0.3{
		dir = .UpLeft
	}else if dir_to_move.x <= -0.3 && dir_to_move.y >= 0.3{
		dir = .DownLeft
	}else if dir_to_move.x >= 0.3 && dir_to_move.y <= -0.3{
		dir = .UpRight
	}else if dir_to_move.x >= 0.3 && dir_to_move.y >= 0.3{
		dir = .DownRight
	}else if dir_to_move.x <= -0.3 && dir_to_move.y == 0{
		dir = .Left
	}else if dir_to_move.x >= 0.3 && dir_to_move.y == 0{
		dir = .Right
	}else if dir_to_move.x == 0 && dir_to_move.y >= 0.3{
		dir = .Down
	}else if dir_to_move.x == 0 && dir_to_move.y <= -0.3{
		dir = .Up
	}

	move_entity_to_tile(e, dir, e.speed)

	e.moves_left -= e.speed
}
