module board

import figure_kind
import cords

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
	current_fen   				string
	highlighted_tiles			[]string
	is_first_move				bool
}

pub fn (mut board Board) clear () {
	for y in 0 .. 8 {
		for x in 0 .. 8 {board.field[y][x] = .nothing}
	}
}

pub fn (mut board Board) swap (x1 int, y1 int, x2 int, y2 int) {
	tile1 := board.field[x1][y1]
	mut tile2 := board.field[x2][y2]
	if board.field[x1][y1].is_enemy(board.field[x2][y2]) {
		tile2 = .nothing
	}
	board.field[x1][y1] = tile2
	board.field[x2][y2] = tile1
}


//here happans shit with coordinates TODO: fix thiss
pub fn (mut board Board) allowed_moves(x int, y int) []string {
	mut results := [[u8(0)]]
	results.clear()
	field := board.field[x][y]
	if field.is_pawn() {
		if field.is_white() {
			return [cords.xy2chessboard(x - 1, y), cords.xy2chessboard(x - 2, y)]
		} else {
			return [cords.xy2chessboard(x + 1, y), cords.xy2chessboard(x + 2, y)]
		}
	}

	if field.is_knight() {
		return [
			cords.xy2chessboard(x - 2, y + 1)
			cords.xy2chessboard(x - 2, y - 1)
			cords.xy2chessboard(x + 2, y + 1)
			cords.xy2chessboard(x + 2, y - 1)

			cords.xy2chessboard(x + 1, y + 2)
			cords.xy2chessboard(x + 1, y - 2)
			cords.xy2chessboard(x - 1, y + 2)
			cords.xy2chessboard(x - 1, y - 2)
		]
	}

	if field.is_king() {
		return [
			cords.xy2chessboard(x + 1, y)
			cords.xy2chessboard(x - 1, y)
			cords.xy2chessboard(x, y + 1)
			cords.xy2chessboard(x, y -1)
			cords.xy2chessboard(x + 1, y + 1)
			cords.xy2chessboard(x - 1, y + 1)
			cords.xy2chessboard(x + 1, y - 1)
			cords.xy2chessboard(x - 1, y - 1)
		]
	}
	return []
}
