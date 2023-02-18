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
		mut nx := x
		self := board.field[x][y]
		for nx < 7 {
			nx++
			if board.field[nx][y] == .nothing {results << [[nx, y]]}
			else { if board.field[nx][y].is_enemy(self) {results << [[nx, y]]}
				break}
		}
		nx = x
		for nx > 0 {
			nx--
			if board.field[nx][y] == .nothing {results << [[nx, y]]}
			else { if board.field[nx][y].is_enemy(self) {results << [[nx, y]]}
				break}
		}
		mut ny := y
		for ny < 7 {
			ny++
			if board.field[x][ny] == .nothing {results << [[x, ny]]}
			else { if board.field[x][ny].is_enemy(self) {results << [[nx, y]]}
				break}
		}
		ny = y
		for ny > 0 {
			ny--
			if board.field[x][ny] == .nothing {results << [[x, ny]]}
			else { if board.field[x][ny].is_enemy(self) {results << [[x, ny]]}
				break}
		}
	}
	mut final := []string{}
	for i in results {final << cords.xy2chessboard(i[0], i[1])}
	return final
}
