package rpg

import rl "vendor:raylib"
import "core:log"
import "core:math"
import "core:math/linalg"

map_grid: [MAP_WIDTH * MAP_HEIGHT]Tile
hovered_tile: Tile

Tile :: struct {
	rect: rl.Rectangle,
	occupied: bool,
	selected: bool, 
	hovered: bool,
}


calc_tile_rect :: proc(x, y: int) -> rl.Rectangle{
	return{
		f32(x * CELL_SIZE) + MAP_OFFSET,
		f32(y * CELL_SIZE) + MAP_OFFSET,
		CELL_SIZE, CELL_SIZE
	}
}

get_attack_range_tiles :: proc(start_pos: rl.Vector2, dir: Direction, tiles_from_start: int) -> rl.Vector2{
	tile: rl.Vector2
	offset := f32(CELL_SIZE * tiles_from_start)

	switch dir{
		case .Up:
			tile ={start_pos.x, start_pos.y - offset} //up
		case .Down:
			tile = {start_pos.x, start_pos.y + offset} //down
		case .Left:
			tile = {start_pos.x - offset, start_pos.y} //left
		case .Right:
			tile = {start_pos.x + offset, start_pos.y}
		case .UpLeft:
			tile = {start_pos.x - offset, start_pos.y - offset} //ul

		case .UpRight:
			tile = {start_pos.x + offset, start_pos.y - offset} //ur

		case .DownLeft:
			tile = {start_pos.x - offset, start_pos.y + offset} //dl

		case .DownRight:
			tile = {start_pos.x + offset, start_pos.y + offset} //dr
	}
	return tile

	/*switch dir{
		case .Up:
			tile ={e.pos.x, e.pos.y - offset} //up
		case .Down:
			tile = {e.pos.x, e.pos.y + offset} //down
		case .Left:
			tile = {e.pos.x - offset, e.pos.y} //left
		case .Right:
			tile = {e.pos.x + offset, e.pos.y}
		case .UpLeft:
			tile = {e.pos.x - offset, e.pos.y - offset} //ul

		case .UpRight:
			tile = {e.pos.x + offset, e.pos.y - offset} //ur

		case .DownLeft:
			tile = {e.pos.x - offset, e.pos.y + offset} //dl

		case .DownRight:
			tile = {e.pos.x + offset, e.pos.y + offset} //dr
	}
	return tile*/
}

get_tile_pos :: proc(t: Tile) -> rl.Vector2{
	x := f32(t.rect.x)
	y := f32(t.rect.y)

	return {x, y}
}

get_tile_from_array :: proc(vec2: rl.Vector2) -> Tile{
	for tile in map_grid{
		if vec2 == {tile.rect.x, tile.rect.y}{
			return tile
		}
	}
	empty_tile := Tile{}
	return empty_tile
}

tile_to_world_pos :: proc(tile: Tile) -> rl.Vector2{
	x := tile.rect.x
	y := tile.rect.y 
	return {
		x, y
	}
}

set_entity_pos :: proc(e: ^Entity, x, y: f32){
	e.pos = {x, y} * CELL_SIZE + MAP_OFFSET
	e.current_tile = get_tile_from_array(e.pos)
}


check_tile_in_direction :: proc (dir: Direction, current_tile, checking_tile: Tile) -> bool{
	if checking_tile.rect.y < 0 + MAP_OFFSET || checking_tile.rect.y >= CANVAS_SIZE + MAP_OFFSET ||
		checking_tile.rect.x < 0 + MAP_OFFSET || checking_tile.rect.x >= CANVAS_SIZE + MAP_OFFSET || checking_tile.occupied{
			return false
		}else{
		return true
	}
}

load_map :: proc(){
	counter := 0
	for x in 0..<MAP_WIDTH{
		for y in 0..<MAP_HEIGHT{
			map_grid[counter].rect = calc_tile_rect(x, y)
			counter += 1
		}
	}
}

set_tile_hovered :: proc(m: ^[MAP_WIDTH * MAP_HEIGHT]Tile){
	mp := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

	for &tile in m{
		if rl.CheckCollisionPointRec(mp, tile.rect){
			hovered_tile = tile
			tile.hovered = true
		} else{
			tile.hovered = false
		}
	}
}

