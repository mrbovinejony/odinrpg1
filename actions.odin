package rpg

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:time"
import "core:strings"


action_taken :: proc(e: ^Entity){
	e.moves_left -= 1
	e.entity_state = .Stopped
	wait_for_spacebar = true

	if e.moves_left <= 0{
		next_turn()
	}
}

next_turn :: proc(){
	turn.moves_left = turn.max_moves
	turn.entity_state = .Stopped

	if len(active_entities) > 0{
		turn_index = (turn_index + 1) % len(active_entities)
		turn = active_entities[turn_index]
	}
}

melee_attack :: proc(e: ^Entity){

	stopwatch: time.Stopwatch
	time.stopwatch_start(&stopwatch)
	timer_duration := 1 * time.Second
	log.info("asdf")
	for{
		duration := time.stopwatch_duration(stopwatch)

		if duration >= timer_duration{
			do_damage(e, e.attack_target)
			break
		}
	}
	log.info("melee action")
	e.attack_range_tiles = 0
	action_taken(e)		
}

move_entity_to_tile :: proc(e: ^Entity, dir: Direction, num_to_move: f32){

	prev_pos := e.pos
	prev_tile := e.current_tile
	new_pos : rl.Vector2
	new_tile : Tile
 	
 	move_str := fmt.ctprintf("move action: %v", dir)
	//if check tile in direction is true, check if entity is there
	switch dir{
		case .Up:
			new_pos = {e.pos.x, e.pos.y - num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.pos = prev_pos
				}else{
					e.pos = new_pos
				}
				log.info(move_str)
			}
		case .Down:
			new_pos = {e.pos.x, e.pos.y + num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.pos = prev_pos
				}else{
					e.pos = new_pos
				}
				log.info(move_str)
			}
		case .Left:
			new_pos : rl.Vector2
			new_pos = {e.pos.x - e.speed * CELL_SIZE, e.pos.y}
			new_tile := get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.pos = prev_pos
				}else{
					e.pos = new_pos
				}
				log.info(move_str)
			}
		case .Right:
			new_pos = {e.pos.x + num_to_move * CELL_SIZE, e.pos.y}
			new_tile = get_tile_from_array(new_pos)
				if check_tile_in_direction(dir, prev_tile, new_tile) {
					has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
					if has_entity{
						e.pos = prev_pos
				}else{
					e.pos = new_pos
				}
				log.info(move_str)
			}
		case .UpLeft:
			new_pos = {e.pos.x - num_to_move * CELL_SIZE, e.pos.y - num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.pos = prev_pos
				}else{
					e.pos = new_pos
				}
				log.info(move_str)
			}
		case .UpRight:
			new_pos = {e.pos.x + num_to_move * CELL_SIZE, e.pos.y - num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.pos = prev_pos
				}else{
					e.pos = new_pos
				}
				log.info(move_str)
			}
		case .DownLeft:
			new_pos = {e.pos.x - num_to_move * CELL_SIZE, e.pos.y + num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
			if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
				if has_entity{
					e.pos = prev_pos
				}else{
					e.pos = new_pos
				}
				log.info(move_str)
			}
		case .DownRight:
			new_pos = {e.pos.x + num_to_move * CELL_SIZE, e.pos.y + num_to_move * CELL_SIZE}
			new_tile = get_tile_from_array(new_pos)
				if check_tile_in_direction(dir, prev_tile, new_tile) {
				has_entity, adjacent_entity := check_entity_in_direction(new_pos, e)
										
				if has_entity{
					e.pos = prev_pos
				}else{
					e.pos = new_pos
				}
				log.info(move_str)
			}
		}
		action_taken(e)

}