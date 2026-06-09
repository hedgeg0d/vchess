module main
import cords
import gg
import math

fn (app &App) draw_field() {
	w, h := math.min(app.ui.window_height / 8, app.ui.window_width / 8), math.min(app.ui.window_height / 8,
		app.ui.window_width / 8)
	width_unused, height_unused := app.ui.window_width - w * 8, app.ui.window_height - h * 8
	mut xcord := width_unused / 2
	mut ycord := if app.is_white {
		height_unused / 2
	} else {
		app.ui.window_height - height_unused / 2 - h
	}
	mut higlighted_l := [][]int{}
	for i in app.board.highlighted_tiles {
		higlighted_l << cords.chessboard2xy(i)
	}
	mut is_dark := false
	for y in 0 .. 8 {
		for x in 0 .. 8 {
			if app.current_tile != '-' && [y, x] == cords.chessboard2xy(app.current_tile) {
				app.gg.draw_rect_filled(xcord, ycord, w, h, if is_dark {
					app.theme.highlighted_dark_color
				} else {
					app.theme.highlighted_light_color
				})
			} else if [y, x] in higlighted_l && (app.board.field[y][x] == .nothing
				|| app.board.field[cords.chessboard2xy(app.current_tile)[0]][cords.chessboard2xy(app.current_tile)[1]].is_enemy(app.board.field[y][x])) {
				app.gg.draw_rect_filled(xcord, ycord, w, h, if is_dark {
					app.theme.highlighted_dark_color
				} else {
					app.theme.highlighted_light_color
				})
			} else {
				app.gg.draw_rect_filled(xcord, ycord, w, h, if is_dark {
					app.theme.dark_tile_color
				} else {
					app.theme.light_tile_color
				})
			}
			match app.board.field[y][x] {
				.pawn_white { app.gg.draw_image(xcord, ycord, w, h, app.pawn_white) }
				.bishop_white { app.gg.draw_image(xcord, ycord, w, h, app.bishop_white) }
				.knight_white { app.gg.draw_image(xcord, ycord, w, h, app.knight_white) }
				.rook_white { app.gg.draw_image(xcord, ycord, w, h, app.rook_white) }
				.king_white { app.gg.draw_image(xcord, ycord, w, h, app.king_white) }
				.queen_white { app.gg.draw_image(xcord, ycord, w, h, app.queen_white) }
				.pawn_black { app.gg.draw_image(xcord, ycord, w, h, app.pawn_black) }
				.bishop_black { app.gg.draw_image(xcord, ycord, w, h, app.bishop_black) }
				.knight_black { app.gg.draw_image(xcord, ycord, w, h, app.knight_black) }
				.rook_black { app.gg.draw_image(xcord, ycord, w, h, app.rook_black) }
				.king_black { app.gg.draw_image(xcord, ycord, w, h, app.king_black) }
				.queen_black { app.gg.draw_image(xcord, ycord, w, h, app.queen_black) }
				else {}
			}
			if x == 0 {
				app.gg.draw_text(xcord, ycord, '${8 - y}', gg.TextCfg{
					color: if is_dark {
						app.theme.light_tile_color
					} else {
						app.theme.dark_tile_color
					}
					size: app.ui.font_size / 3
					align: .left
					vertical_align: .top
				})
			}
			if (y == 7 && app.is_white) || (y == 0 && !app.is_white) {
				app.gg.draw_text(xcord + w, ycord + h, '${cords.xy2chessboard(y, x)[0].ascii_str()}',
					gg.TextCfg{
					color: if is_dark {
						app.theme.light_tile_color
					} else {
						app.theme.dark_tile_color
					}
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
		ycord = if app.is_white { ycord + h } else { ycord - h }
	}
	app.draw_additional_buttons(width_unused, height_unused)
	app.draw_final_screen(app.board.is_white_winner)
}

fn (app &App) draw_additional_buttons(width_unused int, height_unused int) {
	if width_unused > height_unused {
		if width_unused > app.ui.window_width / 6 {
			paddingx := width_unused / 20
			paddingy := app.ui.window_height / 40
			app.gg.draw_rounded_rect_filled(paddingx, paddingy, width_unused / 2 - paddingx * 2,
				app.ui.window_height / 2 - paddingy, 10, app.theme.button_main_color)
			app.gg.draw_rounded_rect_empty(paddingx, paddingy, width_unused / 2 - paddingx * 2,
				app.ui.window_height / 2 - paddingy, 10, app.theme.button_second_color)
			app.gg.draw_rounded_rect_filled(paddingx, paddingy * 2 + app.ui.window_height / 2 - paddingy,
				width_unused / 2 - paddingx * 2, app.ui.window_height / 2 - paddingy * 2,
				10, app.theme.button_main_color)
			app.gg.draw_rounded_rect_empty(paddingx, paddingy * 2 + app.ui.window_height / 2 - paddingy,
				width_unused / 2 - paddingx * 2, app.ui.window_height / 2 - paddingy * 2,
				10, app.theme.button_second_color)
		}
	} else {
		if height_unused > app.ui.window_height / 6 {
			paddingx := app.ui.window_width / 40
			y := app.ui.window_height - height_unused / 2
			paddingy := height_unused / 20
			app.gg.draw_rounded_rect_filled(paddingx, y + paddingy, app.ui.window_width / 2 - paddingx,
				height_unused / 2 - paddingy * 2, 10, app.theme.button_main_color)
			app.gg.draw_rounded_rect_empty(paddingx, y + paddingy, app.ui.window_width / 2 - paddingx,
				height_unused / 2 - paddingy * 2, 10, app.theme.button_second_color)
			app.gg.draw_rounded_rect_filled(paddingx * 2 + app.ui.window_width / 2 - paddingx,
				y + paddingy, app.ui.window_width / 2 - paddingx * 2, height_unused / 2 - paddingy * 2,
				10, app.theme.button_main_color)
			app.gg.draw_rounded_rect_empty(paddingx * 2 + app.ui.window_width / 2 - paddingx,
				y + paddingy, app.ui.window_width / 2 - paddingx * 2, height_unused / 2 - paddingy * 2,
				10, app.theme.button_second_color)
		}
	}
}

fn (app &App) draw_final_screen(is_white_victory bool) {
	if app.state != .end {
		return
	}
	y := app.ui.window_height / 3
	paddingy := app.ui.window_height / 15
	app.gg.draw_rect_filled(0, 0, app.ui.window_width, app.ui.window_height, gg.rgba(0,
		0, 0, 200))
	app.gg.draw_text(app.ui.window_width / 2, y, 'Game finished', gg.TextCfg{
		color: gg.white
		size: app.ui.font_size / 2
		align: .center
		vertical_align: .bottom
	})
	result_text := if app.board.is_draw {
		'Stalemate - Draw'
	} else {
		victor := if is_white_victory { 'White' } else { 'Black' }
		'${victor} won'
	}
	app.gg.draw_text(app.ui.window_width / 2, y + paddingy, result_text, gg.TextCfg{
		color: gg.white
		size: app.ui.font_size / 3
		align: .center
		vertical_align: .bottom
	})
	app.gg.draw_text(app.ui.window_width / 2, (y + paddingy) * 2, 'Moves done: ${app.board.fullmove_number}',
		gg.TextCfg{
		color: gg.white
		size: app.ui.font_size / 3
		align: .center
		vertical_align: .bottom
	})
	app.gg.draw_text(app.ui.window_width / 2, y + paddingy * 10, 'Press any button to continue',
		gg.TextCfg{
		color: gg.white
		size: app.ui.font_size / 3
		align: .center
		vertical_align: .bottom
	})
}

fn (app &App) draw_promotion() {
	w := int(math.min(app.ui.window_width, app.ui.window_height)) / 4
	cx := app.ui.window_width / 2
	cy := app.ui.window_height / 2
	x0 := cx - 2 * w
	y0 := cy - w / 2
	app.gg.draw_rect_filled(0, 0, app.ui.window_width, app.ui.window_height, gg.rgba(0,
		0, 0, 150))
	app.gg.draw_rect_filled(x0, y0, 4 * w, w, app.theme.button_main_color)
	app.gg.draw_rounded_rect_empty(x0, y0, 4 * w, w, 5, app.theme.button_second_color)
	is_white := app.board.field[app.promotion_x][app.promotion_y].is_white()
	imgs := if is_white {
		[app.queen_white, app.rook_white, app.bishop_white, app.knight_white]
	} else {
		[app.queen_black, app.rook_black, app.bishop_black, app.knight_black]
	}
	for i, img in imgs {
		app.gg.draw_image(x0 + i * w, y0, w, w, img)
	}
}

fn (app &App) menu_rects() []MenuRect {
	w, h := app.ui.window_width, app.ui.window_height
	cx := w / 2
	bw := w / 3
	bh := h / 14
	gap := h / 50
	mut y := h / 2 - bh
	mut res := []MenuRect{}
	res << MenuRect{.start, Rect{cx - bw / 2, y, bw, bh}}
	y += bh + gap * 2
	res << MenuRect{.opponent, Rect{cx - bw / 2, y, bw, bh}}
	y += bh + gap
	res << MenuRect{.difficulty, Rect{cx - bw / 2, y, bw, bh}}
	y += bh + gap
	res << MenuRect{.color, Rect{cx - bw / 2, y, bw, bh}}
	return res
}

fn (app &App) menu_label(item MenuItem) string {
	return match item {
		.start { 'Start game' }
		.opponent { if app.vs_engine { 'Opponent: Engine' } else { 'Opponent: Human' } }
		.difficulty { 'Level: ' + difficulty_name(app.difficulty) }
		.color { if app.is_white { 'Play: White' } else { 'Play: Black' } }
	}
}

fn (app &App) draw_menu() {
	w, h := app.ui.window_width, app.ui.window_height
	app.gg.draw_image(0, 0, w, h, app.m_background)
	app.gg.draw_text(w / 2, h / 2 - h / 4, 'VChess', gg.TextCfg{
		color: gg.white
		size: app.ui.font_size
		align: .center
		vertical_align: .bottom
	})
	for mr in app.menu_rects() {
		r := mr.rect
		app.gg.draw_rounded_rect_filled(r.x, r.y, r.w, r.h, 10, app.theme.button_main_color)
		app.gg.draw_rounded_rect_empty(r.x, r.y, r.w, r.h, 10, app.theme.button_second_color)
		app.gg.draw_text(r.x + r.w / 2, r.y + r.h / 2, app.menu_label(mr.item), gg.TextCfg{
			color: gg.white
			size: app.ui.font_size / 3
			align: .center
			vertical_align: .middle
		})
	}
	if app.engine_error != '' {
		app.gg.draw_text(w / 2, h - h / 12, 'Engine unavailable: ${app.engine_error}', gg.TextCfg{
			color: gg.white
			size: app.ui.font_size / 4
			align: .center
			vertical_align: .bottom
		})
	}

	app.gg.draw_rounded_rect_filled(3, 3, w / 15, h / 15, 10, app.theme.button_main_color)
	app.gg.draw_rounded_rect_empty(3, 3, w / 15, h / 15, 10, app.theme.button_second_color)
	app.gg.draw_text(avg(3, w / 15), 3 + app.ui.font_size / 4 + h / 36, 'Theme', gg.TextCfg{
		color: app.theme.menu_font_color
		size: app.ui.font_size / 4
		align: .center
		vertical_align: .bottom
	})
}

fn frame(mut app App) {
	if app.engine_should_start && !app.engine_thinking {
		app.engine_should_start = false
		app.engine_thinking = true
		fen := app.board.current_fen
		spawn app.think(fen)
	}
	if app.engine_thinking {
		app.engine_lock.lock()
		has := app.engine_has_result
		mv := app.engine_result
		if has {
			app.engine_has_result = false
		}
		app.engine_lock.unlock()
		if has {
			app.engine_thinking = false
			app.apply_engine_move(mv)
		}
	}
	app.gg.begin()
	if app.state == .play || app.state == .end {
		app.draw_field()
	}
	if app.state == .menu {
		app.draw_menu()
	}
	if app.promoting {
		app.draw_promotion()
	}
	if app.engine_thinking {
		app.gg.draw_text(app.ui.window_width / 2, app.ui.font_size / 2, 'Engine thinking...',
			gg.TextCfg{
			color: gg.white
			size: app.ui.font_size / 4
			align: .center
			vertical_align: .top
		})
	}
	app.gg.end()
}