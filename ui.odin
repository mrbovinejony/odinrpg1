package rpg

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:encoding/json"
import "core:os"
import "core:strings"


UI_Button :: struct{
	texture: rl.Texture2D,
	pos : rl.Vector2,
	rect : rl.Rectangle,
	size_rect : rl.Rectangle,
	text: cstring,
	hovered: bool,
	text_start_pos : rl.Vector2,
	button_center : rl.Vector2,
	on_button_click : ButtonClickProc
}

save_button: UI_Button
load_button: UI_Button
reset_button: UI_Button

ButtonClickProc :: proc()


ui_make_button :: proc(texture: rl.Texture2D, pos: rl.Vector2, text: cstring, on_click_proc : ButtonClickProc) -> UI_Button{

    rect := rl.Rectangle{
    	pos.x, pos.y, f32(texture.width), f32(texture.height)
    }

	button := UI_Button{
		texture = texture,
		pos = pos, 
		text = text,
		hovered = false,
		rect = rect,
	}
	button.button_center = ui_get_button_center(pos, texture)
	button.text_start_pos = ui_set_text_in_center(DEFAULT_FONT, button)

	size_rect := rl.Rectangle{
		button.pos.x,
		button.pos.y,
		button.rect.width * 2,
		button.rect.height
	} 

	button.size_rect = size_rect

	button.on_button_click = on_click_proc

	return button
}

ui_update_button :: proc(button: ^UI_Button){
	mp := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

	if rl.CheckCollisionPointRec(mp, button.size_rect){
		button.hovered = true
		if rl.IsMouseButtonPressed(.LEFT){
			button.on_button_click()
		}
	}else{
		button.hovered = false
	}
}

ui_draw_button :: proc(button: UI_Button){

	button_str := fmt.ctprintf("%v", button.text)

	if button.hovered == false{
		rl.DrawTexturePro(button.texture, button.rect, button.size_rect, {0, 0}, 0, rl.WHITE)
	}else if button.hovered == true{
		rl.DrawTexturePro(button.texture, button.rect, button.size_rect, {0, 0}, 0, HOVERED_COLOR)
	}

	rl.DrawText(button.text, i32(button.text_start_pos.x), i32(button.text_start_pos.y), 1, rl.WHITE)

}

ui_get_button_center :: proc(pos: rl.Vector2, texture: rl.Texture2D) -> rl.Vector2{
	button_center := rl.Vector2{
		pos.x + (f32(texture.width / 2)),
		pos.y + (f32(texture.height / 2)),
	}

	return button_center
}

ui_get_string_bounds :: proc(button: UI_Button) -> rl.Rectangle{
	text_size := rl.MeasureTextEx(rl.GetFontDefault(), button.text, f32(rl.GetFontDefault().baseSize), 1)

	rect := rl.Rectangle{
		button.text_start_pos.x,
		button.text_start_pos.y,
		text_size.x,
		text_size.y,
	}

	return rect
}

ui_set_text_in_center :: proc(font: rl.Font, button: UI_Button ) -> rl.Vector2{

	font_size := f32(rl.GetFontDefault().baseSize)
	text_size := rl.MeasureTextEx(rl.GetFontDefault(), button.text, font_size, 1 )
	text_middle := rl.Vector2{
		text_size.x / 2, text_size.y / 2
	}
	
	text_center_to_left := button.pos.x + text_middle.x /2
	text_center_to_top := button.button_center.y - text_middle.y

	start_pos := rl.Vector2{
		text_center_to_left,
		text_center_to_top
	}
	return start_pos
}


