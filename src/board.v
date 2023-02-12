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
