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

pub fn (mut board Board) get_hline(y int) []figure_kind.FigureKind {
	if y < 0 || y > 7 {return []}
	mut results := []figure_kind.FigureKind{}
	for x in 0 .. 8 {
		results << board.field[y][x]
	}
	return results
}

pub fn (mut board Board) get_vline(x int) []figure_kind.FigureKind {
	if x < 0 || x > 7 {return []}
	mut results := []figure_kind.FigureKind{}
	for y in 0 .. 8 {
		results << board.field[y][x]
	}
	return results
}

[inline]
pub fn (mut board Board) get_line(coordinate int, is_horizontal bool, reversed bool) []figure_kind.FigureKind {
	if is_horizontal {return board.get_hline(coordinate)}
	else {return board.get_vline(coordinate)}
}

pub fn (mut board Board) is_allowed_step(x1 int, y1 int, x2 int, y2 int) bool {
	if x1 > 7 || x1 < 0 || y1 > 7 || y1 < 0 || x2 > 7 || x2 < 0 || y2 > 7 || y2 < 0 {return false}
	if x1 == x2 && y1 == y2 {return true}
	mut cord1 := 0
	mut cord2 := 0
	mut line := []figure_kind.FigureKind{}
	if x1 == x2 {
		line = board.get_vline(x1)
		cord1 = y1
		cord2 = y2
	}
	if y1 == y2 {
		line = board.get_hline(y1)
		cord1 = x1
		cord2 = x2
	}
	for i in 0 .. cord1 + 1 {line.delete(0)}
	for i in 0 .. 8 - cord2 {line.delete_last()}
	for i in line {if i != .nothing {return false}}
	return true
}

//here happans shit with coordinates TODO: fix thiss
pub fn (mut board Board) allowed_moves(x int, y int) []string {
	mut results := [][]int{}
	field := board.field[x][y]
	if field.is_pawn() {
		if field.is_white() {
			results << [[x - 1, y], [x - 2, y]]
		} else {
			results << [[x + 1, y], [x + 2, y]]
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

	if field.is_rook() {
		return [
			cords.xy2chessboard(x - 1, y)
			cords.xy2chessboard(x - 2, y)
			cords.xy2chessboard(x - 3, y)
			cords.xy2chessboard(x - 4, y)
			cords.xy2chessboard(x - 5, y)
			cords.xy2chessboard(x - 6, y)
			cords.xy2chessboard(x - 7, y)

			cords.xy2chessboard(x + 1, y)
			cords.xy2chessboard(x + 2, y)
			cords.xy2chessboard(x + 3, y)
			cords.xy2chessboard(x + 4, y)
			cords.xy2chessboard(x + 5, y)
			cords.xy2chessboard(x + 6, y)
			cords.xy2chessboard(x + 7, y)

			cords.xy2chessboard(x, y - 1)
			cords.xy2chessboard(x, y - 2)
			cords.xy2chessboard(x, y - 3)
			cords.xy2chessboard(x, y - 4)
			cords.xy2chessboard(x, y - 5)
			cords.xy2chessboard(x, y - 6)
			cords.xy2chessboard(x, y - 7)

			cords.xy2chessboard(x, y + 1)
			cords.xy2chessboard(x, y + 2)
			cords.xy2chessboard(x, y + 3)
			cords.xy2chessboard(x, y + 4)
			cords.xy2chessboard(x, y + 5)
			cords.xy2chessboard(x, y + 6)
			cords.xy2chessboard(x, y + 7)
		]
	}
	mut final := []string{}
	for i in results {final << cords.xy2chessboard(i[0], i[1])}
	return final
}
