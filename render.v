module main
import cords
import figure
import gg
import math
import time

fn (app &App) piece_image(kind figure.FigureKind) gg.Image {
	return match kind {
		.pawn_white { app.pawn_white }
		.bishop_white { app.bishop_white }
		.knight_white { app.knight_white }
		.rook_white { app.rook_white }
		.king_white { app.king_white }
		.queen_white { app.queen_white }
		.pawn_black { app.pawn_black }
		.bishop_black { app.bishop_black }
		.knight_black { app.knight_black }
		.rook_black { app.rook_black }
		.king_black { app.king_black }
		.queen_black { app.queen_black }
		else { app.pawn_white }
	}
}

fn (app &App) cell_screen_pos(row int, col int) (int, int) {
	w := math.min(app.ui.window_height / 8, app.ui.window_width / 8)
	width_unused := app.ui.window_width - w * 8
	height_unused := app.ui.window_height - w * 8
	px := width_unused / 2 + col * w
	py := if app.is_white {
		height_unused / 2 + row * w
	} else {
		app.ui.window_height - height_unused / 2 - w - row * w
	}
	return px, py
}

fn (app &App) is_anim_dest(row int, col int) bool {
	for a in app.anims {
		if a.to_row == row && a.to_col == col {
			return true
		}
	}
	return false
}

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
			if app.board.field[y][x] != .nothing && !app.is_anim_dest(y, x) {
				app.gg.draw_image(xcord, ycord, w, h, app.piece_image(app.board.field[y][x]))
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
	now := time.now().unix_milli()
	for a in app.anims {
		mut t := f32(now - a.start) / f32(anim_duration_ms)
		if t < 0 {
			t = 0
		}
		if t > 1 {
			t = 1
		}
		fx, fy := app.cell_screen_pos(a.from_row, a.from_col)
		tx, ty := app.cell_screen_pos(a.to_row, a.to_col)
		px := int(f32(fx) + (f32(tx) - f32(fx)) * t)
		py := int(f32(fy) + (f32(ty) - f32(fy)) * t)
		app.gg.draw_image(px, py, w, h, app.piece_image(a.kind))
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
	w, h := app.ui.window_width, app.ui.window_height
	now := time.now().unix_milli()
	mut p := f32(now - app.end_time) / 320.0
	if p < 0 {
		p = 0
	}
	if p > 1 {
		p = 1
	}
	ease := 1.0 - (1.0 - p) * (1.0 - p)

	app.gg.draw_rect_filled(0, 0, w, h, gg.rgba(0, 0, 0, u8(190 * ease)))

	short := math.min(w, h)
	pw := int(f32(short) * 0.66)
	ph := int(f32(short) * 0.6)
	px := (w - pw) / 2
	slide := int((1.0 - ease) * f32(short) / 8)
	py := (h - ph) / 2 + slide

	accent := if app.board.is_draw {
		app.theme.button_second_color
	} else if is_white_victory {
		gg.rgb(235, 235, 235)
	} else {
		gg.rgb(40, 40, 40)
	}
	app.gg.draw_rounded_rect_filled(px - 5, py - 5, pw + 10, ph + 10, 22, accent)
	app.gg.draw_rounded_rect_filled(px, py, pw, ph, 18, app.theme.button_main_color)
	app.gg.draw_rounded_rect_empty(px, py, pw, ph, 18, app.theme.button_second_color)

	icon := ph / 3
	icon_x := px + pw / 2 - icon / 2
	icon_y := py + ph / 12
	if app.board.is_draw {
		gap := icon / 6
		app.gg.draw_image(icon_x - icon / 2 - gap / 2, icon_y, icon, icon, app.king_white)
		app.gg.draw_image(icon_x + icon / 2 + gap / 2, icon_y, icon, icon, app.king_black)
	} else {
		king := if is_white_victory { app.king_white } else { app.king_black }
		app.gg.draw_image(icon_x, icon_y, icon, icon, king)
	}

	title := if app.board.is_draw { 'Stalemate' } else { 'Checkmate!' }
	app.gg.draw_text(w / 2, icon_y + icon + ph / 12, title, gg.TextCfg{
		color: gg.white
		size: app.ui.font_size / 2
		align: .center
		vertical_align: .top
	})

	subtitle := if app.board.is_draw {
		'It\'s a draw'
	} else {
		victor := if is_white_victory { 'White' } else { 'Black' }
		'${victor} wins'
	}
	app.gg.draw_text(w / 2, icon_y + icon + ph / 12 + app.ui.font_size / 2 + ph / 20, subtitle,
		gg.TextCfg{
		color: accent
		size: app.ui.font_size / 3
		align: .center
		vertical_align: .top
	})

	app.gg.draw_text(w / 2, py + ph - ph / 4, 'Moves: ${app.board.fullmove_number}', gg.TextCfg{
		color: gg.white
		size: app.ui.font_size / 4
		align: .center
		vertical_align: .top
	})

	pulse := u8(140.0 + 115.0 * (0.5 + 0.5 * math.sinf(f32(now) / 280.0)))
	app.gg.draw_text(w / 2, py + ph - ph / 12, 'Press any key to continue', gg.TextCfg{
		color: gg.rgba(255, 255, 255, pulse)
		size: app.ui.font_size / 5
		align: .center
		vertical_align: .top
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
	if app.anims.len > 0 {
		now := time.now().unix_milli()
		app.anims = app.anims.filter(now - it.start < anim_duration_ms)
	}
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