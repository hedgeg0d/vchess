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
import uci
import sync

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
	app.promoting = false
	app.anims.clear()
}

fn (mut app App) start_anim(kind figure.FigureKind, from_row int, from_col int, to_row int, to_col int) {
	app.anims << Anim{
		kind: kind
		from_row: from_row
		from_col: from_col
		to_row: to_row
		to_col: to_col
		start: time.now().unix_milli()
	}
}

@[inline]
pub fn (mut app App) undo_move() {
	app.promoting = false
	if app.undo.len < 1 {
		return
	}
	fen_utils.fen_2_board(mut app.board, app.undo.last())
	app.undo.delete_last()
	app.current_tile = '-'
	app.board.highlighted_tiles.clear()
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
		// DPI could not be queried from the display server (LINUX_X11_QUERY_SYSTEM_DPI_FAILED).
		// Fall back to 1.0 which corresponds to the default 96 DPI.
		s = 1.0
	}
	// Allow the user to override DPI scale via the VCHESS_DPI_SCALE environment variable.
	// This is useful when the display server cannot report DPI (e.g., minimal X11 / Wayland
	// sessions) and the default scale produces wrong UI sizing.
	// Example: VCHESS_DPI_SCALE=1.5 ./vchess
	dpi_env := os.getenv('VCHESS_DPI_SCALE')
	if dpi_env != '' {
		parsed := dpi_env.f32()
		if parsed > 0.0 {
			s = parsed
		}
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

fn (mut app App) finish_move() {
	if !app.board.is_white_move {
		app.board.fullmove_number++
	}
	app.board.is_white_move = !app.board.is_white_move
	app.board.current_fen = fen_utils.board_2_fen(app.board)
	app.saver.writen2save(app.board.current_fen)
	if !app.board.has_legal_moves(app.board.is_white_move) {
		app.state = .end
		app.end_time = time.now().unix_milli()
		if app.board.is_king_attacked(app.board.is_white_move) {
			app.board.is_white_winner = !app.board.is_white_move
		} else {
			app.board.is_draw = true
		}
		return
	}
	if app.is_engine_turn() {
		app.engine_should_start = true
	}
}

fn (app &App) is_engine_turn() bool {
	return app.vs_engine && app.state == .play && app.board.is_white_move != app.is_white
}

fn difficulty_params(d int) (int, int) {
	return match d {
		0 { 1, 100 }
		1 { 5, 300 }
		2 { 12, 700 }
		else { 20, 1500 }
	}
}

fn difficulty_name(d int) string {
	return match d {
		0 { 'Easy' }
		1 { 'Medium' }
		2 { 'Hard' }
		else { 'Max' }
	}
}

fn resolve_engine_path(engine_override string) string {
	if engine_override != '' {
		return engine_override
	}
	bundled := os.resource_abs_path('assets/engine/stockfish')
	if os.exists(bundled) {
		return bundled
	}
	return os.find_abs_path_of_executable('stockfish') or { 'stockfish' }
}

fn (mut app App) ensure_engine() ! {
	if app.engine != unsafe { nil } {
		return
	}
	app.engine = uci.new_engine(app.engine_path)!
	app.engine_error = ''
}

fn (mut app App) start_game() {
	if app.vs_engine {
		app.ensure_engine() or {
			app.engine_error = err.msg()
			app.vs_engine = false
		}
	}
	app.state = .play
	app.board.current_fen = fen_utils.board_2_fen(app.board)
	if app.is_engine_turn() {
		app.engine_should_start = true
	}
}

fn (mut app App) think(fen string) {
	mut mv := ''
	if app.engine != unsafe { nil } {
		skill, mt := difficulty_params(app.difficulty)
		app.engine.set_skill(skill)
		mv = app.engine.best_move(fen, mt) or { '' }
	}
	app.engine_lock.lock()
	app.engine_result = mv
	app.engine_has_result = true
	app.engine_lock.unlock()
}

fn (mut app App) apply_engine_move(mv string) {
	if mv.len < 4 {
		return
	}
	oldcord := cords.chessboard2xy(mv[0..2])
	target := cords.chessboard2xy(mv[2..4])
	mut promo := -1
	if mv.len >= 5 {
		promo = match mv[4] {
			`r` { 3 }
			`b` { 1 }
			`n` { 2 }
			else { 4 }
		}
	}
	app.make_move(oldcord, target[0], target[1], promo)
}

fn (mut app App) make_move(oldcord []int, tilex int, tiley int, promo int) {
	app.undo << fen_utils.board_2_fen(app.board)
	app.anims.clear()
	piece := app.board.field[oldcord[0]][oldcord[1]]
	app.start_anim(piece, oldcord[0], oldcord[1], tilex, tiley)
	piecedx := if app.board.is_white_move { tilex + 1 } else { tilex - 1 }
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
	} else {
		app.board.last_en_passant = '-'
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
			app.start_anim(app.board.field[7][0], 7, 0, 7, 3)
			app.board.swap(7, 0, 7, 3)
		}
		if oldcord == [0, 4] && [tilex, tiley] == [0, 2] {
			app.start_anim(app.board.field[0][0], 0, 0, 0, 3)
			app.board.swap(0, 0, 0, 3)
		}
		if oldcord == [7, 4] && [tilex, tiley] == [7, 6] {
			app.start_anim(app.board.field[7][7], 7, 7, 7, 5)
			app.board.swap(7, 7, 7, 5)
		}
		if oldcord == [0, 4] && [tilex, tiley] == [0, 6] {
			app.start_anim(app.board.field[0][7], 0, 7, 0, 5)
			app.board.swap(0, 7, 0, 5)
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
	app.current_tile = '-'
	app.board.highlighted_tiles.clear()
	if piece.is_pawn() && (tilex == 0 || tilex == 7) {
		if promo >= 0 {
			app.board.field[tilex][tiley].promote(promo)
		} else {
			app.promoting = true
			app.promotion_x = tilex
			app.promotion_y = tiley
			return
		}
	}
	app.finish_move()
}

fn (mut app App) handle_promotion_tap(avgx int, avgy int) {
	w := int(math.min(app.ui.window_width, app.ui.window_height)) / 4
	cx := app.ui.window_width / 2
	cy := app.ui.window_height / 2
	x0 := cx - 2 * w
	y0 := cy - w / 2
	if avgx < x0 || avgx > x0 + 4 * w || avgy < y0 || avgy > y0 + w {
		return
	}
	idx := (avgx - x0) / w
	choice := match idx {
		0 { 4 }
		1 { 3 }
		2 { 1 }
		3 { 2 }
		else { 4 }
	}
	app.board.field[app.promotion_x][app.promotion_y].promote(choice)
	app.promoting = false
	app.finish_move()
}

fn (mut app App) handle_tap_play() {
	mut w, mut h := app.ui.window_width, app.ui.window_height
	wt, ht := math.min(w / 8, h / 8), math.min(w / 8, h / 8)
	s, e := app.touch.start, app.touch.end
	avgx, avgy := avg(s.pos.x, e.pos.x), avg(s.pos.y, e.pos.y)
	if app.promoting {
		app.handle_promotion_tap(avgx, avgy)
		return
	}
	width_unused, height_unused := app.ui.window_width - wt * 8, app.ui.window_height - ht * 8
	tilex := if app.is_white {
		(avgy - height_unused / 2) / wt
	} else {
		7 - ((avgy - height_unused / 2) / wt)
	}
	tiley := (avgx - width_unused / 2) / ht
	app.check_additional_touches(width_unused, height_unused, avgx, avgy)

	if app.engine_thinking || (app.vs_engine && app.board.is_white_move != app.is_white) {
		return
	}

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
				app.board.highlighted_tiles << app.board.legal_moves(tilex, tiley)
			}
		}
	} else {
		if [tilex, tiley] !in allowed {
			if app.board.field[tilex][tiley] != .nothing
				&& !(app.board.field[tilex][tiley].is_enemy(app.board.field[cords.chessboard2xy(app.current_tile)[0]][cords.chessboard2xy(app.current_tile)[1]])) {
				app.current_tile = cords.xy2chessboard(tilex, tiley)
				app.board.highlighted_tiles.clear()
				app.board.highlighted_tiles << app.board.legal_moves(tilex, tiley)
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
			app.make_move(oldcord, tilex, tiley, -1)
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
	w, h := app.ui.window_width, app.ui.window_height
	s, e := app.touch.start, app.touch.end
	avgx, avgy := avg(s.pos.x, e.pos.x), avg(s.pos.y, e.pos.y)
	if avgx > 3 && avgx < 3 + w / 15 && avgy > 3 && avgy < 3 + h / 15 {
		app.next_theme()
		return
	}
	for mr in app.menu_rects() {
		r := mr.rect
		if avgx >= r.x && avgx <= r.x + r.w && avgy >= r.y && avgy <= r.y + r.h {
			match mr.item {
				.start { app.start_game() }
				.opponent { app.vs_engine = !app.vs_engine }
				.difficulty { app.difficulty = (app.difficulty + 1) % 4 }
				.color { app.is_white = !app.is_white }
			}
			return
		}
	}
}

fn main() {
	$if android {
		os.chdir('/storage/emulated/0/Android/data/com.hedgegod.chessgame')!
	}
	// On Linux, sokol/EGL can fail to find any EGL configs when GPU drivers are
	// unavailable or misconfigured (LINUX_EGL_NO_CONFIGS).  Passing --software or
	// --disable-gpu asks Mesa to use its software (llvmpipe/softpipe) renderer
	// instead, which works in containers, remote sessions, and CI environments.
	// The same effect can be achieved by setting LIBGL_ALWAYS_SOFTWARE=1 in the
	// environment before launching the game.
	$if linux {
		if '--software' in os.args || '--disable-gpu' in os.args {
			os.setenv('LIBGL_ALWAYS_SOFTWARE', '1', true)
			eprintln('vchess: note: software rendering enabled (Mesa llvmpipe/softpipe)')
			eprintln('vchess: note: to disable, launch without --software / --disable-gpu')
		} else if os.getenv('LIBGL_ALWAYS_SOFTWARE') == '1' {
			eprintln('vchess: note: software rendering active (LIBGL_ALWAYS_SOFTWARE=1 is set)')
		}
	}
	mut engine_override := ''
	for i in 0 .. os.args.len {
		if os.args[i] == '--uci' && i + 1 < os.args.len {
			engine_override = os.args[i + 1]
		}
	}
	curves_quality := 4
	mut app := &App{}
	app.engine_lock = sync.new_mutex()
	app.engine_path = resolve_engine_path(engine_override)
	app.new_game(true)
	app.saver.load_save(mut app.board)
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
		cleanup_fn: cleanup
		fullscreen: $if android { true } $else { false }
	)
	app.gg.run()
}

fn cleanup(mut app App) {
	if app.engine != unsafe { nil } {
		app.engine.quit()
	}
}
