module board

import figure_kind

pub struct Board {
	pub mut:
	field 		   				[8][8]figure_kind.FigureKind
	is_white_move  				bool
	white_long_castle_allowed   bool
	white_short_castle_allowed  bool
	black_long_castle_allowed   bool
	black_short_castle_allowed  bool
	last_en_passant				string
	halfmove_clock				u16
	fullmove_number				u16
}

pub fn (mut board Board) clear () {
	for y in 0 .. 8 {
		for x in 0 .. 8 {
			board.field[y][x] = .nothing
		}
	}
}

pub fn (mut board Board) swap (x1 int, y1 int, x2 int, y2 int) {
	tile1 := board.field[x1][y1]
	tile2 := board.field[x2][y2]
	board.field[x1][y1] = tile2
	board.field[x2][y2] = tile1
}
