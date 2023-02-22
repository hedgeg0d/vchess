module main

import gg
import gx
import time
import os
import math
import fen_utils
import figure_kind
import board
import cords
import saving

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
	saver		 saving.Save
	state		 State
}

struct Ui {
	mut:
	dpi_scale     f32
	tile_size     int
	border_size   int
	padding_size  int
	header_size   int
	font_size     int
	window_width  int
	window_height int
	x_padding     int
	y_padding     int
}

const (
    window_title = "VChess"
	window_width= 800
	window_height= 800
	tile_light = gx.rgb(135, 157, 180)
	tile_dark = gx.rgb(97, 120, 141)
	highlighted_light = gx.rgb(72, 117, 110)
	highlighted_dark = gx.rgb(57, 100, 94)
	main_save_name = 'SAVEFILE'
)

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


fn (mut app App) new_game() {
	app.board = board.Board{}
	app.board.is_white_move = true
	app.board.black_short_castle_allowed = true
	app.board.black_long_castle_allowed = true
	app.board.white_long_castle_allowed = true
	app.board.white_short_castle_allowed = true
	app.board.last_en_passant = '-'
	app.board.halfmove_clock = 0
	app.board.fullmove_number = 1
	app.board.current_fen = ''
	app.board.highlighted_tiles = []
	app.board.is_first_move = true
	app.current_tile = '-'
	app.saver = saving.Save{}
	app.saver.main_name = main_save_name
	app.state = .menu
	for y in 0 .. 8 {
		for x in 0 .. 8 {
			if y == 0 {
				app.board.field[y][x] = match x {
					0 {figure_kind.FigureKind.rook_black}
					1 {figure_kind.FigureKind.knight_black}
					2 {figure_kind.FigureKind.bishop_black}
					3 {figure_kind.FigureKind.queen_black}
					4 {figure_kind.FigureKind.king_black}
					5 {figure_kind.FigureKind.bishop_black}
					6 {figure_kind.FigureKind.knight_black}
					7 {figure_kind.FigureKind.rook_black}
					else {figure_kind.FigureKind.nothing}
				}
			}
			if y == 1 { app.board.field[y][x] = figure_kind.FigureKind.pawn_black }
			if y == 6 { app.board.field[y][x] = figure_kind.FigureKind.pawn_white }
			if y == 7 {
				app.board.field[y][x] = match x {
					0 {figure_kind.FigureKind.rook_white}
					1 {figure_kind.FigureKind.knight_white}
					2 {figure_kind.FigureKind.bishop_white}
					3 {figure_kind.FigureKind.queen_white}
					4 {figure_kind.FigureKind.king_white}
					5 {figure_kind.FigureKind.bishop_white}
					6 {figure_kind.FigureKind.knight_white}
					7 {figure_kind.FigureKind.rook_white}
					else {figure_kind.FigureKind.nothing}
				}
			}
		}
	}
	app.undo = []string{cap: 4096}
	app.moves = 0
}

[inline]
pub fn (mut app App) undo_move() {
	if app.undo.len < 1 {return}
	fen_utils.fen_2_board(mut app.board, app.undo.last())
	app.undo.delete_last()
}

[inline]
fn avg(a int, b int) int {
	return (a + b) / 2
}

[inline]
pub fn is_valid(pos []int) bool{
	return pos[0] >= 0 && pos[0] < 8 && pos[1] >= 0 && pos[1] < 8
}

fn (mut app App) resize() {
	mut s := app.gg.scale
	if s == 0.0 {s = 1.0}
	real_window_size := app.gg.window_size()
	w := real_window_size.width
	h := real_window_size.height
	m := f32(math.min(w, h))
	app.ui.dpi_scale = s
	app.ui.window_width = w
	app.ui.window_height = h
	app.ui.padding_size = int(m / 38)
	app.ui.header_size = app.ui.padding_size
	app.ui.border_size = app.ui.padding_size * 2
	app.ui.tile_size = int((m - app.ui.padding_size * 5 - app.ui.border_size * 2) / 4)
	app.ui.font_size = int(m / 10)
	if w > h {
		app.ui.y_padding = 0
		app.ui.x_padding = (app.ui.window_width - app.ui.window_height) / 2
	} else {
		app.ui.y_padding = (app.ui.window_height - app.ui.window_width - app.ui.header_size) / 2
		app.ui.x_padding = 0
	}
}

fn (mut app App) handle_swipe_play() {
	s, e := app.touch.start, app.touch.end
	w, h := app.ui.window_width, app.ui.window_height
	dx, dy := e.pos.x - s.pos.x, e.pos.y - s.pos.y
	adx, ady := math.abs(dx), math.abs(dy)
	dmin := if math.min(adx, ady) > 0 { math.min(adx, ady) } else { 1 }
	dmax := if math.max(adx, ady) > 0 { math.max(adx, ady) } else { 1 }
	tdiff := int(e.time.unix_time_milli() - s.time.unix_time_milli())
	min_swipe_distance := int(math.sqrt(math.min(w, h) * tdiff / 100)) + 20
	if dmax < min_swipe_distance {
		return
	}
	/*
	DO NOT DELETE. this is an example how to add swipe actions:
	if adx > ady {
		if dx < 0 {
			app.move(.left)
		} else {
			app.move(.right)
		}
	}*/
}

fn (mut app App) handle_swipe_menu() {
	app.handle_swipe_play()
}


fn (mut app App) on_key_down(key gg.KeyCode) {
	match key {
		.backspace {
			if app.undo.len == 0 {fen_utils.fen_2_board(mut app.board, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')} else {
				fen_utils.fen_2_board(mut app.board, app.undo.last())
				app.undo.delete_last()
			}
			app.current_tile = '-'
			app.board.highlighted_tiles.clear()
		}
		.r {
			app.new_game()
		}
		else {}
	}
}

fn (mut app App) handle_touches() {
	s, e := app.touch.start, app.touch.end
	adx, ady := math.abs(e.pos.x - s.pos.x), math.abs(e.pos.y - s.pos.y)
	if math.max(adx, ady) < 10 {
		if app.state == .play {app.handle_tap_play()} else {app.handle_tap_menu()}
	} else {
		if app.state == .play {app.handle_swipe_play()} else {app.handle_tap_menu()}
	}
}

fn (mut app App) handle_tap_play() {
	_, ypad := app.ui.x_padding, app.ui.y_padding
	mut w, mut h := app.ui.window_width, app.ui.window_height
	wt, ht := math.min(w / 8, h / 8), math.min(w / 8, h / 8)
	s, e := app.touch.start, app.touch.end
	avgx, avgy := avg(s.pos.x, e.pos.x), avg(s.pos.y, e.pos.y)
	width_unused, height_unused := app.ui.window_width - wt * 8, app.ui.window_height - ht * 8
	tilex := (avgy - height_unused / 2) / (wt)
	tiley := (avgx - width_unused / 2) / (ht)

	if tilex > 7 || tiley > 7 || tilex < 0 || tiley < 0 {return}

	mut allowed := [][]int{}
	for i in app.board.highlighted_tiles {
		pos := cords.chessboard2xy(i)
		if is_valid(pos) && (app.board.field[pos[0]][pos[1]] == .nothing ||
		app.board.field[cords.chessboard2xy(app.current_tile)[0]][cords.chessboard2xy(app.current_tile)[1]].is_enemy(app.board.field[pos[0]][pos[1]])) {
			allowed << pos
		}
	}



	if app.current_tile == '-'{
		if app.board.field[tilex][tiley] != .nothing{
			if app.board.is_white_move == app.board.field[tilex][tiley].is_white() {
				app.current_tile = cords.xy2chessboard(tilex, tiley)
				app.board.highlighted_tiles << app.board.allowed_moves(tilex, tiley)
			}
		}
	} else {
		if !([tilex, tiley] in allowed) {
			if app.board.field[tilex][tiley] != .nothing && !(app.board.field[tilex][tiley].is_enemy(app.board.field[cords.chessboard2xy(app.current_tile)[0]][cords.chessboard2xy(app.current_tile)[1]])) {
			app.current_tile = cords.xy2chessboard(tilex, tiley)
			app.board.highlighted_tiles.clear()
			app.board.highlighted_tiles << app.board.allowed_moves(tilex, tiley)}
			else {app.current_tile = '-'
			app.board.highlighted_tiles.clear()}
			return
		}
		oldcord := cords.chessboard2xy(app.current_tile)
		if oldcord[0] == tilex && oldcord[1] == tiley {
			app.current_tile = '-'
			app.board.highlighted_tiles.clear()
			return
		}
		if [tilex, tiley] in allowed {
			app.undo << fen_utils.board_2_fen(app.board)
			piece := app.board.field[oldcord[0]][oldcord[1]]
			piecedx := if app.board.is_white_move {tilex + 1} else {tilex - 1}
			if is_valid([piecedx, tiley]) {
				pieced := app.board.field[piecedx][tiley]
				if piece.is_pawn() && pieced.is_pawn() && pieced.is_enemy(piece) && cords.en_passant2xy(app.board.last_en_passant, app.board.is_white_move).reverse() == [piecedx, tiley]{app.board.kill(piecedx, tiley)}
				if piece.is_pawn() && math.abs(oldcord[0] - tilex) > 1 {app.board.last_en_passant = cords.xy2chessboard(piecedx, tiley)} else {app.board.last_en_passant = '-'}
			}
			if oldcord == [7, 4] && [tilex, tiley] == [7, 2] {app.board.swap(7, 0, 7,  3)}
			if oldcord == [0, 4] && [tilex, tiley] == [0, 2] {app.board.swap(0, 0, 0,  3)}
			if oldcord == [7, 4] && [tilex, tiley] == [7, 6] {app.board.swap(7, 7, 7,  5)}
			if oldcord == [0, 4] && [tilex, tiley] == [0, 6] {app.board.swap(0, 7, 0,  5)}
			if piece.is_rook() {
				if piece.is_white() {
					if oldcord[0] == 7 && oldcord[1] == 7 {app.board.white_short_castle_allowed = false}
					if oldcord[0] == 7 && oldcord[1] == 0 {app.board.white_long_castle_allowed = false}
				} else {
					if oldcord[0] == 0 && oldcord[1] == 7 {app.board.black_short_castle_allowed = false}
					if oldcord[0] == 0 && oldcord[1] == 0 {app.board.black_long_castle_allowed = false}
				}
			}
			app.board.swap(oldcord[0], oldcord[1], tilex, tiley)
			if piece.is_pawn() && (tilex == 0 || tilex == 7) {
				app.board.field[tilex][tiley].promote(4)
			}
			app.current_tile = '-'
			if !app.board.is_white_move {app.board.fullmove_number++}
			app.board.is_white_move = !app.board.is_white_move
			app.board.current_fen = fen_utils.board_2_fen(app.board)
			app.board.highlighted_tiles.clear()
		}
	}
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.key_down {
			app.on_key_down(e.key_code)
		}
		.resized, .restored, .resumed {
			app.resize()
		}
		.touches_began {
			if e.num_touches > 0 {
				t := e.touches[0]
				app.touch.start = Touch{
					pos: Pos{
						x: int(t.pos_x / app.ui.dpi_scale)
						y: int(t.pos_y / app.ui.dpi_scale)
					}
					time: time.now()
				}
			}
		}
		.touches_ended {
			if e.num_touches > 0 {
				t := e.touches[0]
				app.touch.end = Touch{
					pos: Pos{
						x: int(t.pos_x / app.ui.dpi_scale)
						y: int(t.pos_y / app.ui.dpi_scale)
					}
					time: time.now()
				}
				app.handle_touches()
			}
		}
		.mouse_down {
			app.touch.start = Touch{
				pos: Pos{
					x: int(e.mouse_x / app.ui.dpi_scale)
					y: int(e.mouse_y / app.ui.dpi_scale)
				}
				time: time.now()
			}
		}
		.mouse_up {
			app.touch.end = Touch{
				pos: Pos{
					x: int(e.mouse_x / app.ui.dpi_scale)
					y: int(e.mouse_y / app.ui.dpi_scale)
				}
				time: time.now()
			}
			app.handle_touches()
		}
		else {}
	}
}

fn init_images(mut app App) {
	app.resize()
	$if android {
		pawn_white := os.read_apk_asset('white/pawn.png') or {panic(err)}
		knight_white := os.read_apk_asset('white/knight.png') or {panic(err)}
		bishop_white := os.read_apk_asset('white/bishop.png') or {panic(err)}
		rook_white := os.read_apk_asset('white/rook.png') or {panic(err)}
		queen_white := os.read_apk_asset('white/queen.png') or {panic(err)}
		king_white := os.read_apk_asset('white/king.png') or {panic(err)}
		app.pawn_white = app.gg.create_image_from_byte_array(pawn_white)
		app.knight_white = app.gg.create_image_from_byte_array(knight_white)
		app.bishop_white = app.gg.create_image_from_byte_array(bishop_white)
		app.rook_white = app.gg.create_image_from_byte_array(rook_white)
		app.queen_white = app.gg.create_image_from_byte_array(queen_white)
		app.king_white = app.gg.create_image_from_byte_array(king_white)
		pawn_black := os.read_apk_asset('black/pawn.png') or {panic(err)}
		knight_black := os.read_apk_asset('black/knight.png') or {panic(err)}
		bishop_black := os.read_apk_asset('black/bishop.png') or {panic(err)}
		rook_black := os.read_apk_asset('black/rook.png') or {panic(err)}
		queen_black := os.read_apk_asset('black/queen.png') or {panic(err)}
		king_black := os.read_apk_asset('black/king.png') or {panic(err)}
		app.pawn_black = app.gg.create_image_from_byte_array(pawn_black)
		app.knight_black = app.gg.create_image_from_byte_array(knight_black)
		app.bishop_black = app.gg.create_image_from_byte_array(bishop_black)
		app.rook_black = app.gg.create_image_from_byte_array(rook_black)
		app.queen_black = app.gg.create_image_from_byte_array(queen_black)
		app.king_black = app.gg.create_image_from_byte_array(king_black)
		menu_background := os.read_apk_asset('menu/background1.jpg') or {panic(err)}
		app.m_background = app.gg.create_image_from_byte_array(menu_background)
	} $else {
		app.pawn_white = app.gg.create_image(os.resource_abs_path('assets/white/pawn.png'))
		app.knight_white = app.gg.create_image(os.resource_abs_path('assets/white/knight.png'))
		app.bishop_white = app.gg.create_image(os.resource_abs_path('assets/white/bishop.png'))
		app.rook_white = app.gg.create_image(os.resource_abs_path('assets/white/rook.png'))
		app.queen_white = app.gg.create_image(os.resource_abs_path('assets/white/queen.png'))
		app.king_white = app.gg.create_image(os.resource_abs_path('assets/white/king.png'))

		app.pawn_black = app.gg.create_image(os.resource_abs_path('assets/black/pawn.png'))
		app.knight_black = app.gg.create_image(os.resource_abs_path('assets/black/knight.png'))
		app.bishop_black = app.gg.create_image(os.resource_abs_path('assets/black/bishop.png'))
		app.rook_black = app.gg.create_image(os.resource_abs_path('assets/black/rook.png'))
		app.queen_black = app.gg.create_image(os.resource_abs_path('assets/black/queen.png'))
		app.king_black = app.gg.create_image(os.resource_abs_path('assets/black/king.png'))

		app.m_background = app.gg.create_image(os.resource_abs_path('assets/menu/background1.jpg'))
	}
}

fn (mut app App) print_field() {
	for y in 0 .. 8 {
		for x in 0 .. 8 {
			print("${app.board.field[y][x]} ")
		}
		println('')
	}
}

fn frame(app &App) {
	app.gg.begin()
	if app.state == .play {app.draw_field()}
	if app.state == .menu {app.draw_menu()}
	app.gg.end()
}

fn (app &App) draw_field() {
	w, h := math.min(app.ui.window_height / 8, app.ui.window_width / 8), math.min(app.ui.window_height / 8, app.ui.window_width / 8)
	width_unused, height_unused := app.ui.window_width - w * 8, app.ui.window_height - h * 8
	mut xcord := width_unused / 2
	mut ycord := height_unused / 2
	mut higlighted_l := [][]int{}
	for i in app.board.highlighted_tiles {higlighted_l << cords.chessboard2xy(i)}
	mut is_dark := false
	for y in 0 .. 8 {
		for x in 0 .. 8 {
			if app.current_tile != '-' && ([y, x] == cords.chessboard2xy(app.current_tile)) {
				app.gg.draw_rect_filled(xcord, ycord, w, h, if is_dark {highlighted_dark} else {highlighted_light})
			} else {
				if [y, x] in higlighted_l && (app.board.field[y][x] == .nothing || app.board.field[cords.chessboard2xy(app.current_tile)[0]][cords.chessboard2xy(app.current_tile)[1]].is_enemy(app.board.field[y][x])) {app.gg.draw_rect_filled(xcord, ycord, w, h, if is_dark {highlighted_dark} else {highlighted_light})} else {
					app.gg.draw_rect_filled(xcord, ycord, w, h, if is_dark {tile_dark} else {tile_light})
				}
			}
			match app.board.field[y][x] {
				.pawn_white {app.gg.draw_image(xcord, ycord, w, h, app.pawn_white)}
				.bishop_white {app.gg.draw_image(xcord, ycord, w, h, app.bishop_white)}
				.knight_white {app.gg.draw_image(xcord, ycord, w, h, app.knight_white)}
				.rook_white {app.gg.draw_image(xcord, ycord, w, h, app.rook_white)}
				.king_white {app.gg.draw_image(xcord, ycord, w, h, app.king_white)}
				.queen_white {app.gg.draw_image(xcord, ycord, w, h, app.queen_white)}

				.pawn_black {app.gg.draw_image(xcord, ycord, w, h, app.pawn_black)}
				.bishop_black {app.gg.draw_image(xcord, ycord, w, h, app.bishop_black)}
				.knight_black {app.gg.draw_image(xcord, ycord, w, h, app.knight_black)}
				.rook_black {app.gg.draw_image(xcord, ycord, w, h, app.rook_black)}
				.king_black {app.gg.draw_image(xcord, ycord, w, h, app.king_black)}
				.queen_black {app.gg.draw_image(xcord, ycord, w, h, app.queen_black)}
				else {}
			}
			if x == 0 {
				app.gg.draw_text(xcord, ycord, "${8 - y}", gx.TextCfg {
					color: if is_dark {tile_light} else {tile_dark}
					size: app.ui.font_size / 3
					align: .left
					vertical_align: .top
				})
			}
			if y == 7 {
				app.gg.draw_text(xcord + w, ycord + h, '${cords.xy2chessboard(y, x)[0].ascii_str()}', gx.TextCfg {
					color: if is_dark {tile_light} else {tile_dark}
					size: app.ui.font_size / 3
					align: .right
					vertical_align: .bottom
				})
			}
			xcord += w
			is_dark = !is_dark

		}
		is_dark = !is_dark
		xcord = width_unused / 2
		ycord += h
	}
}

fn (app &App) draw_menu() {
	w, h := app.ui.window_width, app.ui.window_height
	app.gg.draw_image(0, 0, w, h, app.m_background)
	app.gg.draw_text(w / 2, h / 2 - h / 4, 'VChess', gx.TextCfg{
		color: gx.white
		size: app.ui.font_size
		align: .center
		vertical_align: .bottom
	})
	app.gg.draw_rounded_rect_filled(w / 2 - ((w / 4) / 2), h / 2, w / 4, h / 10, 10, gx.black)
	app.gg.draw_rounded_rect_empty(w / 2 - ((w / 4) / 2), h / 2, w / 4, h / 10, 10, gx.white)
	app.gg.draw_text(w / 2, h / 2 + h / 13, "Start game", gx.TextCfg{
		color: gx.white
		size: app.ui.font_size / 2
		align: .center
		vertical_align: .bottom
	})
}


fn (mut app App) handle_tap_menu() {
	_, ypad := app.ui.x_padding, app.ui.y_padding
	mut w, mut h := app.ui.window_width, app.ui.window_height
	s, e := app.touch.start, app.touch.end
	avgx, avgy := avg(s.pos.x, e.pos.x), avg(s.pos.y, e.pos.y)
	if avgx > (w / 2 - ((w / 4) / 2)) && avgx < (w / 2 + ((w / 4) / 2)) && avgy > h / 2 && avgy < (h / 2) + (h / 10) {app.state = .play}
}

fn main() {
	$if android{
		os.chdir('/storage/emulated/0/Android/data/com.hedgegod.chessgame')!
	}

	curves_quality := 30
	mut app := &App{}
	app.new_game()
	//fen_utils.fen_2_board(mut app.board, '4k3/8/8/1r6/8/8/8/R3K2R w KQ - 0 1')
	font_path := $if android {'fonts/RobotoMono-Regular.ttf'} $else {os.resource_abs_path('assets/fonts/RobotoMono-Regular.ttf')}
	app.gg = gg.new_context(
		bg_color: gx.rgb(22, 21, 18)
		width: window_width
		height: window_height
		sample_count: curves_quality
		create_window: true
		window_title: window_title
		font_path: font_path
		user_data: app
		event_fn: on_event
		frame_fn: frame
		init_fn: init_images
	)
	app.gg.run()
}
