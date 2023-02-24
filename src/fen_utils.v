module fen_utils

import figure_kind
import board


pub fn field_2_fen(field [8][8]figure_kind.FigureKind,
	is_white_move bool,
	white_long_castle_allowed bool,
	white_short_castle_allowed bool,
	black_long_castle_allowed bool,
	black_short_castle_allowed bool) string{
	mut final_fen := ''
	for y in 0 .. 8 {
		mut empty_count := u8(0)
		for x in 0 .. 8 {
			piece := field [y][x]
			final_fen += if piece == .nothing {
				empty_count ++
				''
			} else {
				if empty_count > 0 {
					final_fen += empty_count.str()
				}
				match piece {
					.pawn_white {'P'}
					.knight_white {'N'}
					.bishop_white {'B'}
					.rook_white {'R'}
					.queen_white {'Q'}
					.king_white {'K'}

					.pawn_black {'p'}
					.knight_black {'n'}
					.bishop_black {'b'}
					.rook_black {'r'}
					.queen_black {'q'}
					.king_black {'k'}

					else {''}
				}
			}
		}
		if empty_count >= 7 {
			final_fen += '8'
		}
		final_fen += '/'
	}

	if is_white_move {
		final_fen += ' w'
	} else {
		final_fen += ' b'
	}

	final_fen += ' '

	if white_long_castle_allowed {final_fen += 'Q'}
	if white_short_castle_allowed {final_fen += 'K'}
	if black_long_castle_allowed {final_fen += 'q'}
	if black_short_castle_allowed {final_fen += 'k'}
	if !(white_short_castle_allowed || white_long_castle_allowed || black_long_castle_allowed || black_short_castle_allowed) {
		final_fen += '-'
	}

	return final_fen
}

pub fn board_2_fen(board_ board.Board) string{
	field := board_.field
	is_white_move := board_.is_white_move
	white_long_castle_allowed := board_.white_long_castle_allowed
	white_short_castle_allowed := board_.white_short_castle_allowed
	black_long_castle_allowed := board_.black_long_castle_allowed
	black_short_castle_allowed := board_.black_short_castle_allowed
	mut final_fen := ''
	for y in 0 .. 8 {
		mut empty_count := u8(0)
		for x in 0 .. 8 {
			piece := field [y][x]
			final_fen += if piece == .nothing {
				empty_count ++
				''
			} else {
				if empty_count > 0 {
					final_fen += empty_count.str()
					empty_count = 0
				}
				match piece {
					.pawn_white {'P'}
					.knight_white {'N'}
					.bishop_white {'B'}
					.rook_white {'R'}
					.queen_white {'Q'}
					.king_white {'K'}

					.pawn_black {'p'}
					.knight_black {'n'}
					.bishop_black {'b'}
					.rook_black {'r'}
					.queen_black {'q'}
					.king_black {'k'}

					else {''}
				}
			}
		}
		if empty_count > 0 {
			final_fen += empty_count.str()
		}
		if y < 7 {
			final_fen += '/'
		}
	}

	if is_white_move {
		final_fen += ' w'
	} else {
		final_fen += ' b'
	}

	final_fen += ' '

	if white_short_castle_allowed {final_fen += 'K'}
	if white_long_castle_allowed {final_fen += 'Q'}
	if black_short_castle_allowed {final_fen += 'k'}
	if black_long_castle_allowed {final_fen += 'q'}
	if !(white_short_castle_allowed || white_long_castle_allowed || black_long_castle_allowed || black_short_castle_allowed) {
		final_fen += '-'
	}

	final_fen += ' '

	final_fen += board_.last_en_passant.str() + ' '
	final_fen += board_.halfmove_clock.str() + ' '
	final_fen += board_.fullmove_number.str()

	return final_fen
}

pub fn fen_2_board (mut board_ board.Board, fen string) {
	mut fen_parts := fen.split('/')
	tmp := fen_parts[7]
	fen_parts.delete(7)


	for i in tmp.split(' ') {
		fen_parts.insert(fen_parts.len, i)
	}

	if fen_parts.len < 12 {
		println('Invalid FEN')
		return
	}

	board_.clear()

	mut y := u8(0)
	mut x := u8(0)
	for i in fen_parts{
		tmp_parts := i.split('')
		for j in tmp_parts {
			if y > 7 {break}
			match j {

				'P' {board_.field[y][x] = .pawn_white}
				'N' {board_.field[y][x] = .knight_white}
				'B' {board_.field[y][x] = .bishop_white}
				'R' {board_.field[y][x] = .rook_white}
				'Q' {board_.field[y][x] = .queen_white}
				'K' {board_.field[y][x] = .king_white}

				'p' {board_.field[y][x] = .pawn_black}
				'n' {board_.field[y][x] = .knight_black}
				'b' {board_.field[y][x] = .bishop_black}
				'r' {board_.field[y][x] = .rook_black}
				'q' {board_.field[y][x] = .queen_black}
				'k' {board_.field[y][x] = .king_black}
				else{
					val := j.u8()
					match val {
						1 {}
						2 {x++}
						3 ... 7 {x += (val - 1)}
						else {}
					}
				}
			}
			x++
		}
		x = 0
		y++
	}

	if fen_parts[8] == 'w' {board_.is_white_move = true} else {board_.is_white_move = false}
	tmp_parts := fen_parts[9].split('')
	board_.black_short_castle_allowed = 'k' in tmp_parts
	board_.black_long_castle_allowed = 'q' in tmp_parts
	board_.white_short_castle_allowed = 'K' in tmp_parts
	board_.white_long_castle_allowed = 'Q' in tmp_parts
	board_.last_en_passant = fen_parts[10]
	board_.halfmove_clock = fen_parts[11].u16()
	board_.fullmove_number = fen[12]
}
