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
	is_white_winner				bool = true
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

[inline]
pub fn is_valid(pos []int) bool{
	return pos[0] >= 0 && pos[0] < 8 && pos[1] >= 0 && pos[1] < 8
}
[inline]
pub fn (mut board Board) is_unmoved_pawn(is_white bool, y int) bool {
	return (is_white && y == 6) || (!is_white && y == 1)
}

[inline]
pub fn (mut board Board) kill (x int, y int) {
	board.field[x][y] = .nothing
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

pub fn (mut board Board) get_reachable_fields(ignore_kings bool) [][]int{
	mut results := [][]int{}
	for x in 0 .. 8 {
		for y in 0 .. 8 {
			piece := board.field[y][x]
			if piece != .nothing && !piece.is_king() && (piece.is_white() != board.is_white_move) {for i in board.allowed_moves(y, x) {if i.len == 2 && is_valid(cords.chessboard2xy(i)) {results << cords.chessboard2xy(i)}}}}
	}
	return results
}

pub fn (mut board Board) get_kings_cords (is_white bool) []int{
	for x in 0 .. 8 {
		for y in 0 .. 8 {
			if board.field[y][x].is_king() && board.field[y][x].is_white() == is_white {return [y, x]}
		}
	}
	return [0, 0]
}

[inline]
pub fn (mut board Board) get_line(coordinate int, is_horizontal bool, reversed bool) []figure_kind.FigureKind {
	if is_horizontal {return board.get_hline(coordinate)}
	else {return board.get_vline(coordinate)}
}

pub fn (mut board Board) allowed_moves(x int, y int) []string {
	mut results := [][]int{}
	field := board.field[x][y]
	if field.is_pawn() {
		self := board.field[x][y]
		if field.is_white() {
			if is_valid([x - 1, y]) && board.field[x - 1][y] == .nothing {results << [[x - 1, y]]}
			if is_valid([x - 1, y]) && is_valid([x - 2, y]) && board.is_unmoved_pawn(board.is_white_move, x) && board.field[x - 1][y] == .nothing && board.field[x - 2][y] == .nothing {results << [[x - 2, y]]}
			if is_valid([x - 1, y - 1]) && board.field[x - 1][y - 1].is_enemy(self)  {results << [[x - 1, y - 1]]}
			if is_valid([x - 1, y + 1]) && board.field[x - 1][y + 1].is_enemy(self)  {results << [[x - 1, y + 1]]}
			if board.last_en_passant != '-' {
				if is_valid([x, y - 1]) && cords.en_passant2xy(board.last_en_passant, board.is_white_move).reverse() == [x, y - 1]  {results << [[x - 1, y - 1]]}
				if is_valid([x, y + 1]) && cords.en_passant2xy(board.last_en_passant, board.is_white_move).reverse() == [x, y + 1]  {results << [[x - 1, y + 1]]}
			}
		} else {
			if is_valid([x - 1, y]) && board.field[x + 1][y] == .nothing {results << [[x + 1, y]]}
			if is_valid([x + 1, y]) && is_valid([x + 2, y]) && board.is_unmoved_pawn(board.is_white_move, x) && board.field[x + 1][y] == .nothing  && board.field[x + 2][y] == .nothing {results << [[x + 2, y]]}
			if is_valid([x + 1, y - 1]) && board.field[x + 1][y - 1].is_enemy(self)  {results << [[x + 1, y - 1]]}
			if is_valid([x + 1, y + 1]) && board.field[x + 1][y + 1].is_enemy(self)  {results << [[x + 1, y + 1]]}
			if board.last_en_passant != '-' {
				if is_valid([x, y - 1]) && cords.en_passant2xy(board.last_en_passant, board.is_white_move).reverse() == [x, y - 1]  {results << [[x + 1, y - 1]]}
				if is_valid([x, y + 1]) && cords.en_passant2xy(board.last_en_passant, board.is_white_move).reverse() == [x, y + 1]  {results << [[x + 1, y + 1]]}
			}
		}
	}

	else if field.is_knight() {
		println(y)
		if !(field.is_black() && x == 0) {
			results << [[x - 2, y + 1]]
			results << [[x - 2, y - 1]]
		}
		results << [[x + 2, y + 1]]
		results << [[x + 2, y - 1]]
		results << [[x - 1, y + 2]]
		results << [[x - 1, y - 2]]
		results << [[x + 1, y + 2]]
		results << [[x + 1, y - 2]]
	}

	else if field.is_king() {
		results << [[x + 1, y]]
		results << [[x - 1, y]]
		results << [[x, y + 1]]
		results << [[x, y - 1]]
		results << [[x + 1, y + 1]]
		results << [[x - 1, y + 1]]
		results << [[x + 1, y - 1]]
		results << [[x - 1, y - 1]]
		if field.is_white() {
			if x == 7 && y == 4 {
				unsafe_fields := board.get_reachable_fields(true)
				is_safe_short := !([7, 5] in unsafe_fields || [7, 6] in unsafe_fields)
				is_safe_long := !([7, 3] in unsafe_fields || [7, 2] in unsafe_fields || [7, 1] in unsafe_fields)
				if (board.field[7][3] == .nothing && board.field[7][2] == .nothing && board.field[7][1] == .nothing) && board.field[7][0] == .rook_white && board.white_long_castle_allowed && is_safe_long && is_valid([x, y - 2]) {results << [[x, y - 2]]}
				if (board.field[7][5] == .nothing && board.field[7][6] == .nothing && board.field[7][7] == .rook_white) && board.white_short_castle_allowed && is_safe_short && is_valid([x, y + 2]) {results << [[x, y + 2]]}
			}
		} else {
			if x == 0 && y == 4 {
				unsafe_fields := board.get_reachable_fields(true)
				is_safe_short := !([0, 5] in unsafe_fields || [0, 6] in unsafe_fields)
				is_safe_long := !([0, 3] in unsafe_fields || [0, 2] in unsafe_fields || [0, 1] in unsafe_fields)
				if (board.field[0][3] == .nothing && board.field[0][2] == .nothing && board.field[0][1] == .nothing && board.field[0][0] == .rook_black) && board.black_long_castle_allowed && is_safe_long && is_valid([x, y - 2]) {results << [[x, y - 2]]}
				if (board.field[0][5] == .nothing && board.field[0][6] == .nothing && board.field[0][7] == .rook_black) && board.black_short_castle_allowed && is_safe_short && is_valid([x, y + 2]) {results << [[x, y + 2]]}
			}
		}
	}

	else if field.is_rook() {
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
			else {if board.field[x][ny].is_enemy(self) {results << [[x, ny]]}
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

	else if field.is_bishop() {
		self := board.field[x][y]
		mut nx := x
		mut ny := y
		for nx < 7 && ny < 7 {
			nx++
			ny++
			if board.field[nx][ny] == .nothing {results << [[nx, ny]]}
			else { if board.field[nx][ny].is_enemy(self) {results << [[nx, ny]]}
				break}
		}
		nx, ny = x, y
		for nx < 7 && ny > 0 {
			nx++
			ny--
			if board.field[nx][ny] == .nothing {results << [[nx, ny]]}
			else { if board.field[nx][ny].is_enemy(self) {results << [[nx, ny]]}
				break}
		}
		nx, ny = x, y
		for nx > 0 && ny > 0 {
			nx--
			ny--
			if board.field[nx][ny] == .nothing {results << [[nx, ny]]}
			else { if board.field[nx][ny].is_enemy(self) {results << [[nx, ny]]}
				break}
		}
		nx, ny = x, y
		for nx > 0 && ny < 7 {
			nx--
			ny++
			if board.field[nx][ny] == .nothing {results << [[nx, ny]]}
			else { if board.field[nx][ny].is_enemy(self) {results << [[nx, ny]]}
				break}
		}
	}

	else if field.is_queen() {
		self := board.field[x][y]
		mut nx := x
		mut ny := y
		for nx < 7 && ny < 7 {
			nx++
			ny++
			if board.field[nx][ny] == .nothing {results << [[nx, ny]]}
			else { if board.field[nx][ny].is_enemy(self) {results << [[nx, ny]]}
				break}
		}
		nx, ny = x, y
		for nx < 7 && ny > 0 {
			nx++
			ny--
			if board.field[nx][ny] == .nothing {results << [[nx, ny]]}
			else { if board.field[nx][ny].is_enemy(self) {results << [[nx, ny]]}
				break}
		}
		nx, ny = x, y
		for nx > 0 && ny > 0 {
			nx--
			ny--
			if board.field[nx][ny] == .nothing {results << [[nx, ny]]}
			else { if board.field[nx][ny].is_enemy(self) {results << [[nx, ny]]}
				break}
		}
		nx, ny = x, y
		for nx > 0 && ny < 7 {
			nx--
			ny++
			if board.field[nx][ny] == .nothing {results << [[nx, ny]]}
			else { if board.field[nx][ny].is_enemy(self) {results << [[nx, ny]]}
				break}
		}
		nx, ny = x, y
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
		for ny < 7 {
			ny++
			if board.field[x][ny] == .nothing {results << [[x, ny]]}
			else { if board.field[x][ny].is_enemy(self) {results << [[x, ny]]}
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
	for i in results {if is_valid(i) {final << cords.xy2chessboard(i[0], i[1])}}
	return final
}
