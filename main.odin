package rpg

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:encoding/json"
import "core:os"
import "core:strings"

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

main :: proc(){
	context.logger = log.create_console_logger()

	rl.InitWindow(1400, 1000, "rpg")

	load_textures()
	load_map()
	load_json_file()

	camera = {
		zoom = f32(rl.GetScreenHeight()) / 200
	}

	save_button = ui_make_button(button_texture, {200, 60}, "save", test_button_click)

	turn = PLAYER_TURN

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
		
		rl.BeginDrawing()
		rl.BeginMode2D(camera)

		rl.ClearBackground(rl.BLUE)

		hoveredstr : cstring

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

		for entity in entities{
			rl.DrawTextureV(entity.texture, entity.pos, {255, 255, 255, 100})
			health_str := fmt.ctprintf("%v", entity.id)
			moves_left_str := fmt.ctprintf("%v", entity.moves_left)
			rl.DrawText(health_str, i32(entity.pos.x), i32(entity.pos.y), 2, rl.RED)
			rl.DrawText(moves_left_str, i32(entity.pos.x), i32(entity.pos.y + 10), 2, rl.GREEN)
		}

		turn_str := fmt.ctprintf("%v", turn)
		spbar_str := fmt.ctprintf("%v", wait_for_spacebar)
		list_str := fmt.ctprintf("size: %v", len(entities))

		in_editing_mode(hovered_tile)

		rl.DrawText(turn_str, 20, 20, 2, rl.WHITE)
		rl.DrawText(spbar_str, 20, 40, 2, rl.WHITE)
		rl.DrawText(list_str, 20, 60, 2, rl.WHITE)

		ui_draw_button(save_button)
		ui_draw_button(load_button)

		rl.DrawText(save_button.text, i32(save_button.text_start_pos.x), i32(save_button.text_start_pos.y), 1, rl.WHITE)

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()
	//save_and_export_json()
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

handle_player_input :: proc(e: ^Entity){
	wait_for_spacebar = false

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
		}
	}
}

save_and_export_json :: proc(){
	options := json.Marshal_Options{
		pretty = true
	}

	if level_data, err := json.marshal(entities,options, allocator = context.temp_allocator); err == nil{
		_ = os.write_entire_file("level.json", level_data)
	}
}

