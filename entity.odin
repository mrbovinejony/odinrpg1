package rpg

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:time"
import "core:strings"

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
	skill_list: [dynamic]Skill,
	attack_type: Attack_Type `json:"-"`,
	attack_range_tiles: [8]rl.Vector2 `json:"-"`, 
	attack_target: ^Entity `json:"-"`, 
	aggro_target: ^Entity `json:"-"`, 

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

	for &entity_in_range in entities{
		for tile in e.attack_range_tiles{
			loop: if entity_in_range.pos == tile && entity_in_range.entity_type == .Player{
				e.attack_target = &entity_in_range
				e.aggro_target = nil
				e.entity_state = .Attacking
				return
			}else{
				wait_for_spacebar = true
				e.attack_target = nil
				e.aggro_target = active_entities[0]
				e.entity_state = .Moving
			}
		}
	}
}

do_damage :: proc(attacking_e, damaged_e: ^Entity){
	log.info(damaged_e.health)
	if damaged_e.entity_type != .Static{
		damaged_e.health -= attacking_e.damage
		log.info(damaged_e.health)
	}
}

handle_entity :: proc(e: ^Entity){
	if wait_for_spacebar == false{
		switch e.entity_type{
			case .Player:
				//check_melee_range(e)
				handle_player(e)
			case .Enemy:
				handle_enemy()
			case .Static:
		}

	}
	if e.health <= 0 && e.entity_type != .Static{
		unordered_remove(&entities, e.id)
	}
}


handle_player :: proc(e: ^Entity){
	if turn.entity_type == .Player{	
		e.entity_state = .Moving
		//check_melee_range(e)
		handle_player_input()
	}
}

handle_enemy :: proc(){
	if turn.entity_type == .Enemy{
		switch turn.entity_state{
			case .Moving:
				move_to_entity(turn, turn.aggro_target)
			case .Attacking:
				melee_attack(turn)
			case .Stopped:
				check_melee_range(turn)

		}	
	}
}

move_to_entity :: proc(e, target_e: ^Entity){
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

get_entity_from_array :: proc(t: Tile) -> ^Entity{
	tile_pos := get_tile_pos(t)

	for &entity in entities{
		if tile_pos == entity.pos
		{
			return &entity
		}
	}
	return {}
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