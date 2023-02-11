module main

import gg
import gx
import time
import os
import math

struct App {
	mut:
	gg           &gg.Context = unsafe { nil }
	touch        TouchInfo
	ui           Ui
	board        Board
	undo         []Undo
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
	window_title= "VChess"
	window_width= 800
	window_height= 600
	tile_light = gx.rgb(135, 157, 180)
	tile_dark = gx.rgb(97, 120, 141)
)

struct Pos {
	x int = -1
	y int = -1
}

struct Board {
	mut: field [8][8]FigureKind
}

struct Undo {
	board Board
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

enum FigureKind {
	nothing
	pawn_white
	pawn_black
	knight_white
	knight_black
	bishop_white
	bishop_black
	rook_white
	rook_black
	queen_white
	queen_black
	king_white
	king_black
}

fn (mut app App) new_game() {
	app.board = Board{}
	for y in 0 .. 8 {
		for x in 0 .. 8 {
			if y == 0 {
				app.board.field[y][x] = match x {
					0 {FigureKind.rook_black}
					1 {FigureKind.knight_black}
					2 {FigureKind.bishop_black}
					3 {FigureKind.queen_black}
					4 {FigureKind.king_black}
					5 {FigureKind.bishop_black}
					6 {FigureKind.knight_black}
					7 {FigureKind.rook_black}
					else {FigureKind.nothing}
				}
			}
			if y == 1 { app.board.field[y][x] = FigureKind.pawn_black }
			if y == 6 { app.board.field[y][x] = FigureKind.pawn_white }
			if y == 7 {
				app.board.field[y][x] = match x {
					0 {FigureKind.rook_white}
					1 {FigureKind.knight_white}
					2 {FigureKind.bishop_white}
					3 {FigureKind.king_white}
					4 {FigureKind.queen_white}
					5 {FigureKind.bishop_white}
					6 {FigureKind.knight_white}
					7 {FigureKind.rook_white}
					else {FigureKind.nothing}
				}
			}
		}
	}
	app.undo = []Undo{cap: 4096}
	app.moves = 0
}

[inline]
fn avg(a int, b int) int {
	return (a + b) / 2
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

fn (mut app App) handle_swipe() {
	s, e := app.touch.start, app.touch.end
	w, h := app.ui.window_width, app.ui.window_height
	dx, dy := e.pos.x - s.pos.x, e.pos.y - s.pos.y
	adx, ady := math.abs(dx), math.abs(dy)
	dmin := if math.min(adx, ady) > 0 { math.min(adx, ady) } else { 1 }
	dmax := if math.max(adx, ady) > 0 { math.max(adx, ady) } else { 1 }
	tdiff := int(e.time.unix_time_milli() - s.time.unix_time_milli())
	min_swipe_distance := int(math.sqrt(math.min(w, h) * tdiff / 100)) + 20
	if dmax < min_swipe_distance || dmax / dmin < 2 {
		return
	}
	/*
	if adx > ady {
		if dx < 0 {
			app.move(.left)
		} else {
			app.move(.right)
		}
	}*/
}

fn (mut app App) on_key_down(key gg.KeyCode) {
	match key {
		.c {  }
		else {}
	}
}

fn (mut app App) handle_touches() {
	s, e := app.touch.start, app.touch.end
	adx, ady := math.abs(e.pos.x - s.pos.x), math.abs(e.pos.y - s.pos.y)
	if math.max(adx, ady) < 10 {
		app.handle_tap()
	} else {
		app.handle_swipe()
	}
}

fn (mut app App) handle_tap() {
	_, ypad := app.ui.x_padding, app.ui.y_padding
	w, h := app.ui.window_width, app.ui.window_height
	m := math.min(w, h)
	s, e := app.touch.start, app.touch.end
	avgx, avgy := avg(s.pos.x, e.pos.x), avg(s.pos.y, e.pos.y)
	/*if avgx < 80 && h - avgy < 80 {
		app.next_theme()
	}*/
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
	app.pawn_white   = app.gg.create_image(os.resource_abs_path('assets/white/pawn.png'))
	app.knight_white = app.gg.create_image(os.resource_abs_path('assets/white/knight.png'))
	app.bishop_white = app.gg.create_image(os.resource_abs_path('assets/white/bishop.png'))
	app.rook_white   = app.gg.create_image(os.resource_abs_path('assets/white/rook.png'))
	app.queen_white  = app.gg.create_image(os.resource_abs_path('assets/white/queen.png'))
	app.king_white   = app.gg.create_image(os.resource_abs_path('assets/white/king.png'))

	app.pawn_black   = app.gg.create_image(os.resource_abs_path('assets/black/pawn.png'))
	app.knight_black = app.gg.create_image(os.resource_abs_path('assets/black/knight.png'))
	app.bishop_black = app.gg.create_image(os.resource_abs_path('assets/black/bishop.png'))
	app.rook_black   = app.gg.create_image(os.resource_abs_path('assets/black/rook.png'))
	app.queen_black  = app.gg.create_image(os.resource_abs_path('assets/black/queen.png'))
	app.king_black   = app.gg.create_image(os.resource_abs_path('assets/black/king.png'))
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
	app.draw()
	app.gg.end()
}

fn (app &App) draw() {
	w := app.ui.window_width / 8
	h := app.ui.window_height / 8
	mut xcord := 0
	mut ycord := 0
	mut is_dark := true
	mut piece := app.rook_white
	for y in 0 .. 8 {
		for x in 0 .. 8 {
			app.gg.draw_rect_filled(xcord, ycord, w, h, if is_dark {tile_dark} else {tile_light})
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
			xcord += w
			is_dark = !is_dark

		}
		is_dark = !is_dark
		xcord = 0
		ycord += h
	}
}

fn main() {
	$if android{
		os.chdir('/storage/emulated/0/Android/data/com.hedgegod.chessgame')!
	}
	mut app := &App{}
	app.new_game()
	app.print_field()
	font_path := $if android {'fonts/RobotoMono-Regular.ttf'} $else {os.resource_abs_path('assets/fonts/RobotoMono-Regular.ttf')}
	app.gg = gg.new_context(
		bg_color: gx.rgb(22, 21, 18)
		width: window_width
		height: window_height
		sample_count: 4
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
