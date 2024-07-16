module main
import cords
import gx
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
				app.gg.draw_text(xcord, ycord, '${8 - y}', gx.TextCfg{
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
					gx.TextCfg{
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
	app.gg.draw_rect_filled(0, 0, app.ui.window_width, app.ui.window_height, gx.rgba(0,
		0, 0, 200))
	app.gg.draw_text(app.ui.window_width / 2, y, 'Game finished', gx.TextCfg{
		color: gx.white
		size: app.ui.font_size / 2
		align: .center
		vertical_align: .bottom
	})
	victor := if is_white_victory { 'White' } else { 'Black' }
	app.gg.draw_text(app.ui.window_width / 2, y + paddingy, '${victor} won', gx.TextCfg{
		color: gx.white
		size: app.ui.font_size / 3
		align: .center
		vertical_align: .bottom
	})
	app.gg.draw_text(app.ui.window_width / 2, (y + paddingy) * 2, 'Moves done: ${app.board.fullmove_number}',
		gx.TextCfg{
		color: gx.white
		size: app.ui.font_size / 3
		align: .center
		vertical_align: .bottom
	})
	app.gg.draw_text(app.ui.window_width / 2, y + paddingy * 10, 'Press any button to continue',
		gx.TextCfg{
		color: gx.white
		size: app.ui.font_size / 3
		align: .center
		vertical_align: .bottom
	})
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
	app.gg.draw_rounded_rect_filled(w / 2 - ((w / 4) / 2), h / 2, w / 4, h / 10, 10, app.theme.button_main_color)
	app.gg.draw_rounded_rect_empty(w / 2 - ((w / 4) / 2), h / 2, w / 4, h / 10, 10, app.theme.button_second_color)
	app.gg.draw_text(w / 2, h / 2 + h / 20 + app.ui.font_size / 4, 'Start game', gx.TextCfg{
		color: gx.white
		size: app.ui.font_size / 2
		align: .center
		vertical_align: .bottom
	})
	app.gg.draw_text(w / 2, h / 2 + h / 5, 'Play as', gx.TextCfg{
		color: gx.white
		size: app.ui.font_size / 2
		align: .center
		vertical_align: .bottom
	})
	app.gg.draw_rounded_rect_filled(w / 2 - w / 8, h / 2 + h / 4, w / 4, h / 12, 10, app.theme.button_main_color)
	app.gg.draw_rounded_rect_empty(w / 2 - w / 8, h / 2 + h / 4, w / 4, h / 12, 10, app.theme.button_second_color)
	mut choice := if app.is_white { 'white' } else { 'black' }
	app.gg.draw_text(w / 2, h / 2 + h / 4 + app.ui.font_size / 4 + h / 24, choice, gx.TextCfg{
		color: gx.white
		size: app.ui.font_size / 2
		align: .center
		vertical_align: .bottom
	})

	app.gg.draw_rounded_rect_filled(3, 3, w / 15, h / 15, 10, app.theme.button_main_color)
	app.gg.draw_rounded_rect_empty(3, 3, w / 15, h / 15, 10, app.theme.button_second_color)
	app.gg.draw_text(avg(3, w / 15), 3 + app.ui.font_size / 4 + h / 36, 'Theme', gx.TextCfg{
		color: app.theme.menu_font_color
		size: app.ui.font_size / 4
		align: .center
		vertical_align: .bottom
	})
	/*
	x := w / 2 - (app.ui.font_size / 2 + app.ui.font_size / 5)
	y := h / 2 + h / 3 - app.ui.font_size / 2
	app.gg.draw_triangle_filled(x, y, x, y + app.ui.font_size / 2, x - app.ui.font_size / 2, avg(y, y + app.ui.font_size/2), gx.white)*/
}

fn frame(app &App) {
	app.gg.begin()
	if app.state == .play || app.state == .end {
		app.draw_field()
	}
	if app.state == .menu {
		app.draw_menu()
	}
	app.gg.end()
}