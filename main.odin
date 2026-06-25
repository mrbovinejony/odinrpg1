package rpg

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:encoding/json"
import "core:os"
import "core:strings"
import "core:time"
import vmem "core:mem/virtual"
import "core:io"

Direction :: enum {
	Up,
	Down,
	Left,
	Right,
	UpLeft,
	UpRight,
	DownLeft,
	DownRight,
}

//debug stuff
editing_mode: bool
show_path: bool
wait_for_spacebar: bool
selected_entity: ^Entity

main :: proc(){
	context.logger = log.create_console_logger()

	rl.InitWindow(1400, 1000, "rpg")

	load_textures()
	load_map()
	//load_json_file()

	camera = {
		zoom = f32(rl.GetScreenHeight()) / 200
	}

	save_button = ui_make_button(button_texture, {200, 10}, "save", save_and_export_json)
	load_button = ui_make_button(button_texture, {200, 30}, "load", load_json_file)
	reset_button = ui_make_button(button_texture, {200, 50}, "reset", reset_level)
	

	player := Entity {
		texture = player_texture,
		pos = {MAP_WIDTH /2, MAP_WIDTH / 2},
		speed = 1,
		entity_type = .Player,
		entity_state = .Stopped,
		moves_left = 10,
		max_moves = 10,
		health = 5,
		damage = 3,
	}

	enemy := Entity {
		texture = enemy_texture,
		pos = {5, 5},
		speed = 1,
		entity_type = .Enemy,
		entity_state = .Stopped,
		moves_left = 2,
		max_moves = 2,
		health = 5,
		damage = 3,
	}

	enemy1 := Entity {
		texture = enemy_texture,
		pos = {7, 7},
		speed = 1,
		entity_type = .Enemy,
		entity_state = .Stopped,
		moves_left = 2,
		max_moves = 2,
		health = 5,
		damage = 3,
	}

	hill := Entity{
		texture = hill_texture,
		entity_type = .Static,
		pos = {3,3},
	}

	hill1 := Entity{
		texture = hill_texture,
		entity_type = .Static, 
		pos = {4, 4},
	}

	set_entity_pos(&player, 2, 2)
	set_entity_pos(&enemy, 5, 5)
	set_entity_pos(&hill, 3, 3)
	set_entity_pos(&hill1, 4, 4)
	set_entity_pos(&enemy1, 6, 6)
	append(&entities, player)
	append(&entities, enemy)
	append(&entities, hill)
	append(&entities, hill1)
	append(&entities, enemy1)

	active_entities = make([dynamic]^Entity)

	for &e in entities{
		if e.entity_type != .Static{
			append(&active_entities, &e)
		}
	}
	turn = active_entities[0]

	log.info(len(active_entities))

	for !rl.WindowShouldClose(){
		dt = rl.GetFrameTime()
		if rl.IsKeyPressed(.SPACE){
			wait_for_spacebar = false
		}
		if rl.IsKeyPressed(.F2){
			editing_mode = !editing_mode
		}

		set_tile_hovered(&map_grid)

		for &entity in entities{
			handle_entity(&entity)
		}

		player = entities[0]

		ui_update_button(&save_button)
		ui_update_button(&load_button)
		ui_update_button(&reset_button)

		rl.BeginDrawing()
		rl.BeginMode2D(camera)

		rl.ClearBackground(rl.BLUE)

		draw_grid()

		select_entity()

		for entity in entities{
			rl.DrawTextureV(entity.texture, entity.pos, {255, 255, 255, 100})

			if entity.entity_state == .Attacking{
				for pos in entity.attack_range_tiles{
					rl.DrawTextureV(tile_texture, pos, HOVERED_COLOR)
				}
			}
		}

		in_editing_mode(hovered_tile)		

		draw_selected_entity_information(selected_entity)
			
		ui_draw_button(save_button)
		ui_draw_button(load_button)
		ui_draw_button(reset_button)

		rl.EndMode2D()
		rl.EndDrawing()
		
	}

	rl.CloseWindow()
	save_and_export_json()
}

draw_selected_entity_information :: proc(e: ^Entity){
	if e != nil{
	turn_str := fmt.ctprintf("turn: %v", turn_index)
	pos_str := fmt.ctprintf(" pos: %v", e.pos)
	state_str := fmt.ctprintf("state: %v", e.entity_state)
	health_str := fmt.ctprintf("health: %v", e.health)
	spcbar_str := fmt.ctprintf("press spacebar: %v", wait_for_spacebar)
	moves_str := fmt.ctprintf("moves left: %v", e.moves_left)

	rl.DrawTextureV(tile_texture, e.pos, SELECTED_ENTITY_COLOR)

	rl.DrawTextEx(DEFAULT_FONT, moves_str, {200, 90}, 5, 1, rl.RED)
	rl.DrawTextEx(DEFAULT_FONT, turn_str, {200, 110}, 5, 1, rl.RED)
	rl.DrawTextEx(DEFAULT_FONT, state_str, {200, 130}, 5, 1, rl.RED)
	rl.DrawTextEx(DEFAULT_FONT, health_str, {200, 150}, 5, 1, rl.RED)
	rl.DrawTextEx(DEFAULT_FONT, spcbar_str, {200, 170}, 5, 1, rl.RED)

	if e.attack_target != nil{
		target_str := fmt.ctprintf("Target: %v", e.attack_target.entity_type)

		rl.DrawTextEx(DEFAULT_FONT, target_str, {200, 70}, 5, 1, rl.RED)

	}

	if e.aggro_target != nil{
		aggro_str := fmt.ctprintf("Aggro target: %v", e.aggro_target.entity_type)
		rl.DrawTextEx(DEFAULT_FONT, aggro_str, {200, 50}, 5, 1, rl.RED)
	}


}
}

select_entity :: proc(){
	mp := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

	if rl.IsMouseButtonPressed(.LEFT){
		if rl.CheckCollisionPointRec(mp, hovered_tile.rect){
			selected_entity = get_entity_from_array(hovered_tile)
		}
	}
}

in_editing_mode :: proc(tile: Tile){
	if editing_mode{
		mp := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
		can_place := true

		rl.DrawTextureV(hill_texture, mp, rl.WHITE)

		if rl.IsMouseButtonPressed(.LEFT){
			new_entity := Entity{
				texture = hill_texture,
				pos = { tile.rect.x, tile.rect.y},
				entity_type = .Static,
				current_tile = hovered_tile,
				id = len(entities) + 1
			}
			for e in entities{
				if e.pos.x == tile.rect.x && e.pos.y == tile.rect.y{
					can_place = false
				}
			}
			if can_place{
				add_entity(new_entity)
			}
		}

		if rl.IsMouseButtonPressed(.RIGHT){
			for e, idx in entities{
				e_rect := rl.Rectangle{
					e.pos.x, e.pos.y, f32(e.texture.width), f32(e.texture.height)
				}
				if rl.CheckCollisionPointRec(mp, e_rect){
					remove_entity(idx)
					break
				}
			}
		}
	}
}

handle_player_input :: proc(){
	wait_for_spacebar = false

	e := active_entities[0]
	if rl.IsKeyPressed(.LEFT) || rl.IsKeyPressed(.KP_4){
		move_entity_to_tile(e, .Left,  e.speed)
	}
	if rl.IsKeyPressed(.RIGHT)|| rl.IsKeyPressed(.KP_6){
		move_entity_to_tile(e, .Right, e.speed)
	}
	if rl.IsKeyPressed(.UP)|| rl.IsKeyPressed(.KP_8){
		move_entity_to_tile(e, .Up, e.speed)
	}
	if rl.IsKeyPressed(.DOWN)|| rl.IsKeyPressed(.KP_2){
		move_entity_to_tile(e, .Down, e.speed)
	}
	if rl.IsKeyPressed(.KP_7){
		move_entity_to_tile(e, .UpLeft, e.speed)
	}
	if rl.IsKeyPressed(.KP_9){
		move_entity_to_tile(e, .UpRight, e.speed)
	}
	if rl.IsKeyPressed(.KP_1){
		move_entity_to_tile(e, .DownLeft, e.speed)
	}
	if rl.IsKeyPressed(.KP_3){
		move_entity_to_tile(e, .DownRight, e.speed)
	}

	if rl.IsKeyPressed(.ENTER){
		e.moves_left -= 1
	}
}

draw_grid :: proc(){
	for tile in map_grid{
		
		rl.DrawTextureRec(tile_texture, tile.rect, {tile.rect.x, tile.rect.y}, rl.WHITE)
		
		top_left := rl.Vector2{
				tile.rect.x, tile.rect.y
			}

		top_right := rl.Vector2{
			tile.rect.x + tile.rect.width, tile.rect.y
		}

		bottom_left := rl.Vector2{
			tile.rect.x, tile.rect.y + tile.rect.height
		}

		bottom_right := rl.Vector2{
			tile.rect.x + tile.rect.width, tile.rect.y + tile.rect.height
		}

		rl.DrawLineEx(top_left, top_right, 1, {255, 255, 150, 100})
		rl.DrawLineEx(top_left, bottom_left, 1, {255, 255, 150, 100})
		rl.DrawLineEx(top_right, bottom_right, 1, {0, 0, 50, 100})
		rl.DrawLineEx(bottom_left, bottom_right, 1, {0, 0, 50, 100})
	}
		rl.DrawTextureRec(tile_texture, hovered_tile.rect, {hovered_tile.rect.x, hovered_tile.rect.y}, HOVERED_COLOR)

}

load_textures :: proc(){
	player_texture = rl.LoadTexture("player.png")
	enemy_texture = rl.LoadTexture("enemy.png")
	hill_texture = rl.LoadTexture("hill.png")
	
	tile_texture= rl.LoadTexture("tile.png")
	button_texture = rl.LoadTexture("button.png")
}

load_json_file :: proc(){
	if level_data, ok := os.read_entire_file("level.json", context.temp_allocator); ok == nil{
		if json.unmarshal(level_data, &entities) != nil {
			//if unmarshal fails
			log.info("loaded")
		}
	}
}

save_and_export_json :: proc(){

	options := json.Marshal_Options{
		pretty = true
	}

	if level_data, err := json.marshal(&entities, options, allocator = context.temp_allocator); err == nil{
		_ = os.write_entire_file("level.json", level_data)
		log.info("level.json")
	}else{
		
		log.info(err)
	}
}

reset_level :: proc(){
	load_json_file()
	turn = active_entities[0]
	wait_for_spacebar = false
}

