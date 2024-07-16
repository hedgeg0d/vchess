module main
import gg
import board
import saving
import gx
import time
import os

struct App {
mut:
	gg           &gg.Context = unsafe { nil }
	touch        TouchInfo
	ui           Ui
	board        board.Board
	undo         []string
	atickers     [5][5]int
	moves        int
	pawn_white   gg.Image
	knight_white gg.Image
	bishop_white gg.Image
	rook_white   gg.Image
	queen_white  gg.Image
	king_white   gg.Image
	pawn_black   gg.Image
	knight_black gg.Image
	bishop_black gg.Image
	rook_black   gg.Image
	queen_black  gg.Image
	king_black   gg.Image
	m_background gg.Image
	current_tile string
	saver        saving.Save
	state        State
	is_white     bool
	theme_index  u8
	theme        &Theme = themes[0]
	// engine       	engine.Engine
}

struct Ui {
mut:
	dpi_scale     f32
	font_size     int
	window_width  int
	window_height int
}

struct Theme {
	background_color        gx.Color
	button_main_color       gx.Color
	button_second_color     gx.Color
	light_tile_color        gx.Color
	dark_tile_color         gx.Color
	highlighted_light_color gx.Color
	highlighted_dark_color  gx.Color
	menu_font_color         gx.Color
	path2background_android string
	path2background         string
}

const window_title = 'VChess'
const window_width = 800
const window_height = 800
const main_save_name = 'SAVEFILE'
const themes = [
	&Theme{
		background_color: gx.rgb(7, 3, 61)
		button_main_color: gx.rgb(10, 5, 80)
		button_second_color: gx.white
		light_tile_color: gx.rgb(135, 157, 180)
		dark_tile_color: gx.rgb(97, 120, 141)
		highlighted_light_color: gx.rgb(72, 117, 110)
		highlighted_dark_color: gx.rgb(57, 100, 94)
		menu_font_color: gx.white
		path2background_android: 'menu/background.jpg'
		path2background: 'assets/menu/background.jpg'
	},
	&Theme{
		background_color: gx.rgb(22, 21, 18)
		button_main_color: gx.black
		button_second_color: gx.white
		light_tile_color: gx.rgb(166, 168, 178)
		dark_tile_color: gx.rgb(69, 70, 81)
		highlighted_light_color: gx.rgb(114, 128, 140)
		highlighted_dark_color: gx.rgb(107, 110, 124)
		menu_font_color: gx.white
		path2background_android: 'menu/background1.jpg'
		path2background: 'assets/menu/background1.jpg'
	},
	&Theme{
		background_color: gx.rgb(75, 7, 50)
		button_main_color: gx.rgb(109, 45, 80)
		button_second_color: gx.pink
		light_tile_color: gx.rgb(205, 176, 207)
		dark_tile_color: gx.rgb(109, 45, 80)
		highlighted_light_color: gx.rgb(208, 54, 158)
		highlighted_dark_color: gx.rgb(207, 91, 193)
		menu_font_color: gx.white
		path2background_android: 'menu/background2.jpg'
		path2background: 'assets/menu/background2.jpg'
	},
]

struct Pos {
	x int = -1
	y int = -1
}

struct TouchInfo {
mut:
	start Touch
	end   Touch
}

struct Touch {
mut:
	pos  Pos
	time time.Time
}

pub enum State {
	play
	menu
	end
}

fn init_images(mut app App) {
	app.resize()
	$if android {
		pawn_white := os.read_apk_asset('white/pawn.png') or { panic(err) }
		knight_white := os.read_apk_asset('white/knight.png') or { panic(err) }
		bishop_white := os.read_apk_asset('white/bishop.png') or { panic(err) }
		rook_white := os.read_apk_asset('white/rook.png') or { panic(err) }
		queen_white := os.read_apk_asset('white/queen.png') or { panic(err) }
		king_white := os.read_apk_asset('white/king.png') or { panic(err) }
		app.pawn_white = app.gg.create_image_from_byte_array(pawn_white)
		app.knight_white = app.gg.create_image_from_byte_array(knight_white)
		app.bishop_white = app.gg.create_image_from_byte_array(bishop_white)
		app.rook_white = app.gg.create_image_from_byte_array(rook_white)
		app.queen_white = app.gg.create_image_from_byte_array(queen_white)
		app.king_white = app.gg.create_image_from_byte_array(king_white)
		pawn_black := os.read_apk_asset('black/pawn.png') or { panic(err) }
		knight_black := os.read_apk_asset('black/knight.png') or { panic(err) }
		bishop_black := os.read_apk_asset('black/bishop.png') or { panic(err) }
		rook_black := os.read_apk_asset('black/rook.png') or { panic(err) }
		queen_black := os.read_apk_asset('black/queen.png') or { panic(err) }
		king_black := os.read_apk_asset('black/king.png') or { panic(err) }
		app.pawn_black = app.gg.create_image_from_byte_array(pawn_black)
		app.knight_black = app.gg.create_image_from_byte_array(knight_black)
		app.bishop_black = app.gg.create_image_from_byte_array(bishop_black)
		app.rook_black = app.gg.create_image_from_byte_array(rook_black)
		app.queen_black = app.gg.create_image_from_byte_array(queen_black)
		app.king_black = app.gg.create_image_from_byte_array(king_black)
		menu_background := os.read_apk_asset(app.theme.path2background_android) or { panic(err) }
		app.m_background = app.gg.create_image_from_byte_array(menu_background)
	} $else {
		app.pawn_white = app.gg.create_image(os.resource_abs_path('assets/white/pawn.png')) or {
			panic(err)
		}
		app.knight_white = app.gg.create_image(os.resource_abs_path('assets/white/knight.png')) or {
			panic(err)
		}
		app.bishop_white = app.gg.create_image(os.resource_abs_path('assets/white/bishop.png')) or {
			panic(err)
		}
		app.rook_white = app.gg.create_image(os.resource_abs_path('assets/white/rook.png')) or {
			panic(err)
		}
		app.queen_white = app.gg.create_image(os.resource_abs_path('assets/white/queen.png')) or {
			panic(err)
		}
		app.king_white = app.gg.create_image(os.resource_abs_path('assets/white/king.png')) or {
			panic(err)
		}

		app.pawn_black = app.gg.create_image(os.resource_abs_path('assets/black/pawn.png')) or {
			panic(err)
		}
		app.knight_black = app.gg.create_image(os.resource_abs_path('assets/black/knight.png')) or {
			panic(err)
		}
		app.bishop_black = app.gg.create_image(os.resource_abs_path('assets/black/bishop.png')) or {
			panic(err)
		}
		app.rook_black = app.gg.create_image(os.resource_abs_path('assets/black/rook.png')) or {
			panic(err)
		}
		app.queen_black = app.gg.create_image(os.resource_abs_path('assets/black/queen.png')) or {
			panic(err)
		}
		app.king_black = app.gg.create_image(os.resource_abs_path('assets/black/king.png')) or {
			panic(err)
		}

		app.m_background = app.gg.create_image(os.resource_abs_path(app.theme.path2background)) or {
			panic(err)
		}
	}
}