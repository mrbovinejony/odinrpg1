package rpg

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"

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

main :: proc(){
	context.logger = log.create_console_logger()

	rl.InitWindow(1000, 1000, "rpg")

	load_textures()

	player := Entity {
		texture = player_texture,
		pos = {MAP_WIDTH /2, MAP_WIDTH / 2},
		speed = 1,
		entity_type = .Player,
		entity_state = .Stopped,
		moves_left = 2,
		max_moves = 5,
		health = 5,
		damage = 3,
	}

	enemy := Entity {
		texture = enemy_texture,
		pos = {5, 5},
		speed = 1,
		entity_type = .Enemy,
		entity_state = .Stopped,
		moves_left = 1,
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

	camera = {
		zoom = f32(rl.GetScreenHeight()) / 200
	}

	load_map()

	set_entity_pos(&player, 2, 2)
	set_entity_pos(&enemy, 5, 5)
	set_entity_pos(&hill, 3, 3)
	set_entity_pos(&hill1, 4, 4)

	append(&entities, player)
	append(&entities, enemy)
	append(&entities, hill)
	append(&entities, hill1)

	turn = PLAYER_TURN

	for !rl.WindowShouldClose(){
		dt = rl.GetFrameTime()

		set_tile_hovered(&map_grid)

		player = entities[0]

		for &entity in entities{
			entity.current_tile = get_tile_from_array(entity.pos)
			handle_entity(&entity)
		}
		
		rl.BeginDrawing()
		rl.BeginMode2D(camera)

		rl.ClearBackground(rl.BLUE)

		hoveredstr : cstring
		for tile in map_grid{
			if tile.hovered{
				hoveredstr = fmt.ctprintf("%v", tile.rect)
				rl.DrawTextureRec(tile_hovered_texture, tile.rect, {tile.rect.x, tile.rect.y}, rl.WHITE)

			}else{
				rl.DrawTextureRec(tile_texture, tile.rect, {tile.rect.x, tile.rect.y}, rl.WHITE)
			}

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


			if tile.occupied{
				rl.DrawText("true", i32(tile.rect.x), i32(tile.rect.y), 1, rl.BLUE)
			}
		}

		for entity in entities{
			rl.DrawTextureV(entity.texture, entity.pos, {255, 255, 255, 100})
			health_str := fmt.ctprintf("%v", entity.health)
			rl.DrawText(health_str, i32(entity.pos.x), i32(entity.pos.y), 2, rl.RED)
		}

		pos_str := fmt.ctprintf("pos: %v", player.pos)
		ct_str := fmt.ctprintf("current tile: %v", player.current_tile.rect)
				movesleft_str : cstring
		if turn == PLAYER_TURN{
			movesleft_str = fmt.ctprintf("moves left: %v", entities[0].moves_left)
		} else if turn == ENEMY_TURN{
			movesleft_str = fmt.ctprintf("moves left: %v", entities[1].moves_left)
		}
		rl.EndMode2D()
		rl.DrawText(pos_str, 1, 1, 20, rl.WHITE)
		rl.DrawText(hoveredstr, 1, 25, 20, rl.WHITE)
		rl.DrawText(ct_str, 1, 40, 20, rl.WHITE)
		turn_str := fmt.ctprintf("turn: %v", turn)
		state_str := fmt.ctprintf("%v", entities[0].entity_state)
		rl.DrawText(turn_str, 200, 1, 20, rl.WHITE)
		rl.DrawText(movesleft_str, 400, 1, 20 ,rl.WHITE)
		rl.DrawText(state_str, 600, 1, 20, rl.WHITE)


		rl.EndDrawing()
	}

	rl.CloseWindow()
}

handle_player_input :: proc(e: ^Entity){
	if rl.IsKeyPressed(.LEFT) || rl.IsKeyPressed(.KP_4){
		move_entity_to_tile(e, .Left,  e.speed)
		e.moves_left -= 1
	}
	if rl.IsKeyPressed(.RIGHT)|| rl.IsKeyPressed(.KP_6){
		move_entity_to_tile(e, .Right, e.speed)
		e.moves_left -= e.speed
	}
	if rl.IsKeyPressed(.UP)|| rl.IsKeyPressed(.KP_8){
		move_entity_to_tile(e, .Up, e.speed)
		e.moves_left -= e.speed
	}
	if rl.IsKeyPressed(.DOWN)|| rl.IsKeyPressed(.KP_2){
		move_entity_to_tile(e, .Down, e.speed)
		e.moves_left -= e.speed
	}
	if rl.IsKeyPressed(.KP_7){
		move_entity_to_tile(e, .UpLeft, e.speed)
		e.moves_left -= e.speed
	}
	if rl.IsKeyPressed(.KP_9){
		move_entity_to_tile(e, .UpRight, e.speed)
		e.moves_left -= e.speed
	}
	if rl.IsKeyPressed(.KP_1){
		move_entity_to_tile(e, .DownLeft, e.speed)
		e.moves_left -= e.speed
	}
	if rl.IsKeyPressed(.KP_3){
		move_entity_to_tile(e, .DownRight, e.speed)
		e.moves_left -= e.speed
	}
}

load_textures :: proc(){
	player_texture = rl.LoadTexture("player.png")
	enemy_texture = rl.LoadTexture("enemy.png")
	hill_texture = rl.LoadTexture("hill.png")
	
	tile_texture= rl.LoadTexture("tile.png")
	tile_hovered_texture = rl.LoadTexture("tile_hovered.png")
}