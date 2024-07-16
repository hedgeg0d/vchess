module main

import gg
import time
import os
import math
import fen_utils
import figure
import board
import cords
import saving
///import engine

fn (mut app App) new_game(to_menu bool) {
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
	if to_menu {
		app.state = .menu
	} else {
		app.state = .play
	}
	app.is_white = true
	// app.engine.engine_name = 'stockfish'
	// app.engine.path2engine = os.resource_abs_path('src/${app.engine.engine_name}')
	for y in 0 .. 8 {
		for x in 0 .. 8 {
			if y == 0 {
				app.board.field[y][x] = match x {
					0 { figure.FigureKind.rook_black }
					1 { figure.FigureKind.knight_black }
					2 { figure.FigureKind.bishop_black }
					3 { figure.FigureKind.queen_black }
					4 { figure.FigureKind.king_black }
					5 { figure.FigureKind.bishop_black }
					6 { figure.FigureKind.knight_black }
					7 { figure.FigureKind.rook_black }
					else { figure.FigureKind.nothing }
				}
			}
			if y == 1 {
				app.board.field[y][x] = figure.FigureKind.pawn_black
			}
			if y == 6 {
				app.board.field[y][x] = figure.FigureKind.pawn_white
			}
			if y == 7 {
				app.board.field[y][x] = match x {
					0 { figure.FigureKind.rook_white }
					1 { figure.FigureKind.knight_white }
					2 { figure.FigureKind.bishop_white }
					3 { figure.FigureKind.queen_white }
					4 { figure.FigureKind.king_white }
					5 { figure.FigureKind.bishop_white }
					6 { figure.FigureKind.knight_white }
					7 { figure.FigureKind.rook_white }
					else { figure.FigureKind.nothing }
				}
			}
		}
	}
	app.undo = []string{cap: 8192}
	app.moves = 0
}

@[inline]
pub fn (mut app App) undo_move() {
	if app.undo.len < 1 {
		return
	}
	fen_utils.fen_2_board(mut app.board, app.undo.last())
	app.undo.delete_last()
	app.current_tile = '-'
	app.board.fullmove_number--
}

@[inline]
fn (mut app App) set_theme(idx int) {
	theme := themes[idx]
	app.theme_index = u8(idx)
	app.theme = theme
	app.gg.set_bg_color(theme.background_color)
	$if android {
		new_bg := os.read_apk_asset(app.theme.path2background_android) or { panic(err) }
		app.m_background = app.gg.create_image_from_byte_array(new_bg)
	} $else {
		app.m_background = app.gg.create_image(os.resource_abs_path(app.theme.path2background)) or {
			panic(err)
		}
	}
}

@[inline]
fn (mut app App) next_theme() {
	app.set_theme(if app.theme_index == themes.len - 1 { 0 } else { app.theme_index + 1 })
}

@[inline]
fn avg(a int, b int) int {
	return (a + b) / 2
}

@[inline]
pub fn is_valid(pos []int) bool {
	return pos[0] >= 0 && pos[0] < 8 && pos[1] >= 0 && pos[1] < 8
}

fn (mut app App) resize() {
	mut s := app.gg.scale
	if s == 0.0 {
		s = 1.0
	}
	real_window_size := app.gg.window_size()
	w := real_window_size.width
	h := real_window_size.height
	m := f32(math.min(w, h))
	app.ui.dpi_scale = s
	app.ui.window_width = w
	app.ui.window_height = h
	app.ui.font_size = int(m / 10)
}

fn (mut app App) handle_swipe_play() {
	s, e := app.touch.start, app.touch.end
	w, h := app.ui.window_width, app.ui.window_height
	dx, dy := e.pos.x - s.pos.x, e.pos.y - s.pos.y
	adx, ady := math.abs(dx), math.abs(dy)
	// dmin := if math.min(adx, ady) > 0 { math.min(adx, ady) } else { 1 }
	dmax := if math.max(adx, ady) > 0 { math.max(adx, ady) } else { 1 }
	tdiff := int(e.time.unix_milli() - s.time.unix_milli())
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
	if app.state == .end {
		app.new_game(true)
		return
	}
	match key {
		.backspace {
			if app.undo.len == 0 {
				fen_utils.fen_2_board(mut app.board, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
				app.board.fullmove_number = 1
			} else {
				fen_utils.fen_2_board(mut app.board, app.undo.last())
				app.undo.delete_last()
			}
			app.current_tile = '-'
			app.board.highlighted_tiles.clear()
			app.board.current_fen = fen_utils.board_2_fen(app.board)
			app.saver.writen2save(app.board.current_fen)
		}
		.r {
			app.new_game(false)
			app.saver.writen2save('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
		}
		.m {
			app.new_game(true)
		}
		.escape {
			app.new_game(true)
		}
		.t {
			app.next_theme()
		}
		.e {
			for i in app.board.get_reachable_fields(true) {
				println(cords.xy2chessboard(i[0], i[1]))
			}
			app.saver.get_undoes()
			println(app.board.last_en_passant)
		}
		else {}
	}
}

fn (mut app App) on_key_menu(key gg.KeyCode) {
	match key {
		.enter { app.state = .play }
		.space { app.state = .play }
		.t { app.next_theme() }
		else {}
	}
}

fn (mut app App) handle_touches() {
	s, e := app.touch.start, app.touch.end
	adx, ady := math.abs(e.pos.x - s.pos.x), math.abs(e.pos.y - s.pos.y)
	if math.max(adx, ady) < 10 {
		if app.state == .play {
			app.handle_tap_play()
		} else {
			app.handle_tap_menu()
		}
	} else {
		if app.state == .play {
			app.handle_swipe_play()
		} else {
			app.handle_tap_menu()
		}
	}
}

fn (mut app App) handle_tap_play() {
	mut w, mut h := app.ui.window_width, app.ui.window_height
	wt, ht := math.min(w / 8, h / 8), math.min(w / 8, h / 8)
	s, e := app.touch.start, app.touch.end
	avgx, avgy := avg(s.pos.x, e.pos.x), avg(s.pos.y, e.pos.y)
	width_unused, height_unused := app.ui.window_width - wt * 8, app.ui.window_height - ht * 8
	tilex := if app.is_white {
		(avgy - height_unused / 2) / wt
	} else {
		7 - ((avgy - height_unused / 2) / wt)
	}
	tiley := (avgx - width_unused / 2) / ht
	app.check_additional_touches(width_unused, height_unused, avgx, avgy)
	// mut ycord := if app.is_white {height_unused / 2} else {app.ui.window_height - height_unused / 2 - h}

	if tilex > 7 || tiley > 7 || tilex < 0 || tiley < 0 {
		return
	}

	mut allowed := [][]int{}
	for i in app.board.highlighted_tiles {
		pos := cords.chessboard2xy(i)
		if is_valid(pos) && (app.board.field[pos[0]][pos[1]] == .nothing
			|| app.board.field[cords.chessboard2xy(app.current_tile)[0]][cords.chessboard2xy(app.current_tile)[1]].is_enemy(app.board.field[pos[0]][pos[1]])) {
			allowed << pos
		}
	}

	if app.current_tile == '-' {
		if app.board.field[tilex][tiley] != .nothing {
			if app.board.is_white_move == app.board.field[tilex][tiley].is_white() {
				app.current_tile = cords.xy2chessboard(tilex, tiley)
				app.board.highlighted_tiles << app.board.allowed_moves(tilex, tiley)
			}
		}
	} else {
		if [tilex, tiley] !in allowed {
			if app.board.field[tilex][tiley] != .nothing
				&& !(app.board.field[tilex][tiley].is_enemy(app.board.field[cords.chessboard2xy(app.current_tile)[0]][cords.chessboard2xy(app.current_tile)[1]])) {
				app.current_tile = cords.xy2chessboard(tilex, tiley)
				app.board.highlighted_tiles.clear()
				app.board.highlighted_tiles << app.board.allowed_moves(tilex, tiley)
			} else {
				app.current_tile = '-'
				app.board.highlighted_tiles.clear()
			}
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
			piecedx := if app.board.is_white_move { tilex + 1 } else { tilex - 1 }
			if piece.is_king() {
				app.state = .end
				app.board.is_white_winner = piece.is_white()
			}
			if is_valid([piecedx, tiley]) {
				pieced := app.board.field[piecedx][tiley]
				if app.board.last_en_passant != '-' {
					if piece.is_pawn() && pieced.is_pawn() && pieced.is_enemy(piece)
						&& cords.en_passant2xy(app.board.last_en_passant, app.board.is_white_move).reverse() == [piecedx, tiley] {
						app.board.kill(piecedx, tiley)
					}
				}
				if piece.is_pawn() && math.abs(oldcord[0] - tilex) > 1 {
					app.board.last_en_passant = cords.xy2chessboard(piecedx, tiley)
				} else {
					app.board.last_en_passant = '-'
				}
			}
			if piece.is_king() {
				if piece.is_white() {
					app.board.white_short_castle_allowed = false
					app.board.white_long_castle_allowed = false
				} else {
					app.board.black_short_castle_allowed = false
					app.board.black_long_castle_allowed = false
				}

				if oldcord == [7, 4] && [tilex, tiley] == [7, 2] {
					app.board.swap(7, 0, 7, 3)
					app.board.white_long_castle_allowed = false
					app.board.white_short_castle_allowed = false
				}
				if oldcord == [0, 4] && [tilex, tiley] == [0, 2] {
					app.board.swap(0, 0, 0, 3)
					app.board.black_long_castle_allowed = false
					app.board.black_short_castle_allowed = false
				}
				if oldcord == [7, 4] && [tilex, tiley] == [7, 6] {
					app.board.swap(7, 7, 7, 5)
					app.board.white_short_castle_allowed = false
					app.board.white_long_castle_allowed = false
				}
				if oldcord == [0, 4] && [tilex, tiley] == [0, 6] {
					app.board.swap(0, 7, 0, 5)
					app.board.black_short_castle_allowed = false
					app.board.black_long_castle_allowed = false
				}
			}
			if piece.is_rook() {
				if piece.is_white() {
					if oldcord[0] == 7 && oldcord[1] == 7 {
						app.board.white_short_castle_allowed = false
					}
					if oldcord[0] == 7 && oldcord[1] == 0 {
						app.board.white_long_castle_allowed = false
					}
				} else {
					if oldcord[0] == 0 && oldcord[1] == 7 {
						app.board.black_short_castle_allowed = false
					}
					if oldcord[0] == 0 && oldcord[1] == 0 {
						app.board.black_long_castle_allowed = false
					}
				}
			}
			app.board.swap(oldcord[0], oldcord[1], tilex, tiley)
			if piece.is_pawn() && (tilex == 0 || tilex == 7) {
				app.board.field[tilex][tiley].promote(4)
			}
			app.current_tile = '-'
			if !app.board.is_white_move {
				app.board.fullmove_number++
			}
			app.board.is_white_move = !app.board.is_white_move
			app.board.current_fen = fen_utils.board_2_fen(app.board)
			app.board.highlighted_tiles.clear()

			app.saver.writen2save(app.board.current_fen)
		}
	}
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.key_down {
			if app.state == .play || app.state == .end {
				app.on_key_down(e.key_code)
			} else {
				app.on_key_menu(e.key_code)
			}
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

fn (mut app App) print_field() {
	for y in 0 .. 8 {
		for x in 0 .. 8 {
			print('${app.board.field[y][x]} ')
		}
		println('')
	}
}

fn (mut app App) check_additional_touches(width_unused int, height_unused int, avgx int, avgy int) {
	if width_unused > height_unused {
		if width_unused > app.ui.window_width / 6 {
			paddingx := width_unused / 20
			paddingy := app.ui.window_height / 40
			if avgx > paddingx && avgx < (paddingx + (width_unused / 2 - paddingx * 2))
				&& avgy > paddingy && avgy < (paddingy + (app.ui.window_height / 2 - paddingy)) {
				app.new_game(true)
			}
			if avgx > paddingx && avgx < (paddingx + (width_unused / 2 - paddingx * 2))
				&& avgy > paddingy * 2 + app.ui.window_height / 2 - paddingy
				&& avgy < (paddingy * 2 + app.ui.window_height / 2 - paddingy + (app.ui.window_height / 2 - paddingy * 2)) {
				app.undo_move()
			}
		}
	} else {
		if height_unused > app.ui.window_height / 6 {
			paddingx := app.ui.window_width / 40
			y := app.ui.window_height - height_unused / 2
			paddingy := height_unused / 20
			if avgx > paddingx && avgx < (paddingx + (app.ui.window_width / 2 - paddingx))
				&& avgy > y + paddingy && avgy < (y + paddingy + (height_unused / 2 - paddingy * 2)) {
				app.new_game(true)
			}
			if avgx > (paddingx * 2 + app.ui.window_width / 2 - paddingx)
				&& avgx < (paddingx * 2 + app.ui.window_width / 2 - paddingx + app.ui.window_width / 2 - paddingx * 2)
				&& avgy > y + paddingy && avgy < (y + paddingy + (height_unused / 2 - paddingy * 2)) {
				app.undo_move()
			}
		}
	}
}

fn (mut app App) handle_tap_menu() {
	mut w, mut h := app.ui.window_width, app.ui.window_height
	s, e := app.touch.start, app.touch.end
	avgx, avgy := avg(s.pos.x, e.pos.x), avg(s.pos.y, e.pos.y)
	if avgx > (w / 2 - ((w / 4) / 2)) && avgx < (w / 2 + ((w / 4) / 2)) && avgy > h / 2
		&& avgy < (h / 2) + (h / 10) {
		app.state = .play
	} else if avgx > (w / 2 - w / 8) && avgx < (w / 2 - w / 8) + (w / 4) && avgy > (h / 2 + h / 4)
		&& avgy < ((h / 2 + h / 4) + h / 12) {
		app.is_white = !app.is_white
	} else if avgx > 3 && avgx < 3 + w / 15 && avgy > 3 && avgy < 3 + h / 15 {
		app.next_theme()
	}
}

fn main() {
	$if android {
		os.chdir('/storage/emulated/0/Android/data/com.hedgegod.chessgame')!
	}
	curves_quality := 30
	mut app := &App{}
	app.new_game(true)
	app.saver.load_save(mut app.board)
	// fen_utils.fen_2_board(mut app.board, '4k3/8/8/1r6/8/8/8/R3K2R w KQ - 0 1')
	font_path := $if android {
		'fonts/RobotoMono-Regular.ttf'
	} $else {
		os.resource_abs_path('assets/fonts/RobotoMono-Regular.ttf')
	}
	app.gg = gg.new_context(
		bg_color: app.theme.background_color
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
		fullscreen: $if android { true } $else { false }
	)
	app.gg.run()
}
