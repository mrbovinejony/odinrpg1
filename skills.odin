package rpg

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:time"
import "core:strings"

all_skills : map[cstring]Skill

Skill :: struct{
	name: cstring,
	button: UI_Button,
	damage: f32,
	type: Attack_Type,
	is_selected: bool, 
	range: [dynamic; MAP_WIDTH * MAP_HEIGHT]rl.Vector2,
	owner: ^Entity,
	start_pos: rl.Vector2,
}


Attack_Type :: enum{
	Melee, 
	Range,
}

create_skill :: proc(name: cstring, type: Attack_Type, damage: f32, pos: rl.Vector2, on_click : ButtonClickProc) {
	skill := Skill{
		name = name,
		type = type,
		damage = damage,
		is_selected = false
	}

	skill.button = ui_make_button(
		button_texture,
		pos,
		name,
		use_skill
	)

	skill.button.on_button_click = on_click
	all_skills[name] = skill
}


 
set_entity_skill :: proc(e: ^Entity, skill_name: cstring){
	skill_to_add := all_skills[skill_name]
	skill_to_add.owner = e
	skill_to_add.range = set_range(e.pos, skill_to_add.type)
	append(&e.skill_list, skill_to_add)
	log.info(skill_to_add.range)
}

use_skill :: proc(){
	
}

set_range :: proc(e: rl.Vector2, type: Attack_Type) -> [dynamic; MAP_WIDTH * MAP_HEIGHT]rl.Vector2 {
	range_tiles: [dynamic; MAP_WIDTH * MAP_HEIGHT]rl.Vector2

	switch type{
		case .Melee:
		 	for i in 0..<len(Direction){
		 		log.info("melee")
		 		current_dir := Direction(i)
		 		append(&range_tiles, get_attack_range_tiles(e, current_dir, 1))
		 	}
		
		case .Range:
		//loop through dir switch 
			for i in 0..<len(Direction){
				log.info("range")
				current_dir := Direction(i)
				append(&range_tiles, get_attack_range_tiles(e, current_dir, 2))
				append(&range_tiles, get_attack_range_tiles(e, current_dir, 3))
			}

	}
	return range_tiles
}