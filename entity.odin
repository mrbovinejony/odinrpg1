package rpg

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:time"

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
	
	//every entity will be melee
	attack_type: Attack_Type,
	attack_range_tiles: [8]rl.Vector2,
	attack_target: ^Entity,

}

Entity_State :: enum {
	Moving,
	Attacking,
	Stopped,
}

Entity_Type :: enum {
	Player,
	Enemy,
	Static,
}

Attack_Type :: enum{
	Melee, 
	Range,
}

surrounding_tiles: [8]rl.Vector2

check_entity_in_direction :: proc(next_pos: rl.Vector2, e: ^Entity) -> (bool, ^Entity){
	adjacent_entity : ^Entity

	for &entity in entities{
		if next_pos == entity.pos{
			adjacent_entity = &entity
			return true, adjacent_entity
		}
	}
	return false, nil
}

check_melee_range :: proc(e: ^Entity){
	//check 8 surrounding tiles, if type is player then switch to attack state
	 attack_range_tiles := [8]rl.Vector2{
		{e.pos.x - CELL_SIZE, e.pos.y}, //left
		{e.pos.x + CELL_SIZE, e.pos.y}, //right
		{e.pos.x, e.pos.y + CELL_SIZE}, //down
		{e.pos.x, e.pos.y - CELL_SIZE}, //up
		{e.pos.x - CELL_SIZE, e.pos.y - CELL_SIZE}, //ul
		{e.pos.x - CELL_SIZE, e.pos.y + CELL_SIZE}, //dl
		{e.pos.x + CELL_SIZE, e.pos.y - CELL_SIZE}, //ur
		{e.pos.x + CELL_SIZE, e.pos.y + CELL_SIZE}, //dr
	}
	e.attack_range_tiles = attack_range_tiles
}

melee_attack :: proc(e: ^Entity){

	stopwatch: time.Stopwatch
	time.stopwatch_start(&stopwatch)
	timer_duration := 1 * time.Second

	for{
		duration := time.stopwatch_duration(stopwatch)

		if duration >= timer_duration{
			do_damage(e, e.attack_target)
			break
		}
	}
	e.attack_range_tiles = 0
	e.moves_left -= 1
	e.entity_state = .Moving		
}

do_damage :: proc(attacking_e, damaged_e: ^Entity){
	if damaged_e.entity_type != .Static{
		damaged_e.health -= attacking_e.damage
		log.info(damaged_e.health)
	}
}

handle_entity :: proc(e: ^Entity){
	if wait_for_spacebar == false{
		switch e.entity_type{
			case .Player:
				check_melee_range(e)
				handle_player(e)
			case .Enemy:
				check_melee_range(e)
				handle_enemy(e)
			case .Static:
		}
	}
	if e.health <= 0 && e.entity_type != .Static{
		unordered_remove(&entities, e.id)
	}
}


handle_player :: proc(e: ^Entity){
	if turn == PLAYER_TURN{	
		handle_player_input(e)

		if e.moves_left <= 0{
			turn = ENEMY_TURN
			e.moves_left = e.max_moves
			e.entity_state = .Moving
		}
	}
}

handle_enemy :: proc(e: ^Entity){
	if turn == ENEMY_TURN{
		switch e.entity_state{
			case .Moving:
				move_to_entity_target(e, &entities[0])
			case .Attacking:
			//create array of attack ranges, then set 2 sec timer to draw on the tiles
				melee_attack(e)
			case .Stopped:

		}	

		if e.moves_left <= 0{
			turn = PLAYER_TURN
			e.moves_left = e.max_moves
			e.entity_state = .Moving
		}
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
}

move_entity_to_tile :: proc(e: ^Entity, dir: Direction, num_to_move: f32){
	prev_pos := e.pos
	prev_tile := e.current_tile
	new_pos : rl.Vector2
	new_tile : Tile

	//if check tile in direction is true, check if entity is there
	switch dir{
		case .Up:
			new_pos = {e.pos.x, e.pos.y - num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.attack_target = adjacent_entity
					e.pos = prev_pos
					e.entity_state = .Attacking

				}else{
					e.pos = new_pos
				}

			}else{
				e.pos = prev_pos
			}
		case .Down:
			new_pos = {e.pos.x, e.pos.y + num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.attack_target = adjacent_entity
					e.pos = prev_pos
					e.entity_state = .Attacking
				}else{
					e.pos = new_pos
				}

			}else{
				e.pos = prev_pos
			}
		case .Left:
			new_pos : rl.Vector2
			new_pos = {e.pos.x - e.speed * CELL_SIZE, e.pos.y}
			new_tile := get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.attack_target = adjacent_entity
					e.pos = prev_pos
					e.entity_state = .Attacking
				}else{
					e.pos = new_pos
				}

			}else{
				e.pos = prev_pos
			}
		case .Right:
			new_pos = {e.pos.x + num_to_move * CELL_SIZE, e.pos.y}
			new_tile = get_tile_from_array(new_pos)
				if check_tile_in_direction(dir, prev_tile, new_tile) {
					has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
					if has_entity{
						e.attack_target = adjacent_entity
						e.pos = prev_pos
						e.entity_state = .Attacking
				}else{
					e.pos = new_pos
				}

			}else{
				e.pos = prev_pos
			}
		case .UpLeft:
			new_pos = {e.pos.x - num_to_move * CELL_SIZE, e.pos.y - num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.attack_target = adjacent_entity
					e.pos = prev_pos
					e.entity_state = .Attacking
				}else{
					e.pos = new_pos
				}

			}else{
				e.pos = prev_pos
			}
		case .UpRight:
			new_pos = {e.pos.x + num_to_move * CELL_SIZE, e.pos.y - num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.attack_target = adjacent_entity
					e.pos = prev_pos
					e.entity_state = .Attacking
				}else{
					e.pos = new_pos
				}

			}else{
				e.pos = prev_pos
			}
		case .DownLeft:
			new_pos = {e.pos.x - num_to_move * CELL_SIZE, e.pos.y + num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.attack_target = adjacent_entity
					e.pos = prev_pos
					e.entity_state = .Attacking
				}else{
					e.pos = new_pos
				}

			}else{
				e.pos = prev_pos
			}
		case .DownRight:
			new_pos = {e.pos.x + num_to_move * CELL_SIZE, e.pos.y + num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
					if check_tile_in_direction(dir, prev_tile, new_tile) {

				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
										
				if has_entity{
					e.attack_target = adjacent_entity
					e.pos = prev_pos
					e.entity_state = .Attacking
				}else{
					e.pos = new_pos
				}

			}else{
				e.pos = prev_pos
			}
		}
		e.moves_left -= 1
		log.info(e.entity_type)
	    log.info(e.pos)

		if e.entity_type == .Enemy{
			wait_for_spacebar = true
		}
}

reset_entity_array :: proc(){
	for i in 0..<len(entities){
		entities[i].id = i
	}
}

add_entity :: proc(e: Entity){
	append(&entities, e)
}

remove_entity :: proc(index: int){
	unordered_remove(&entities, index)
}