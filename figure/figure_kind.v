module figure

pub enum FigureKind {
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

pub fn (fig FigureKind) is_white() bool {
	white_pieces := [FigureKind.pawn_white, FigureKind.knight_white, FigureKind.bishop_white,
		FigureKind.rook_white, FigureKind.queen_white, FigureKind.king_white]

	if fig == .nothing {
		return false
	}
	return fig in white_pieces
}

pub fn (fig FigureKind) is_black() bool {
	black_pieces := [FigureKind.pawn_black, FigureKind.knight_black, FigureKind.bishop_black,
		FigureKind.rook_black, FigureKind.queen_black, FigureKind.king_black]

	if fig == .nothing {
		return false
	}
	return fig in black_pieces
}

@[inline]
pub fn (fig FigureKind) is_pawn() bool {
	return fig == .pawn_black || fig == .pawn_white
}

@[inline]
pub fn (fig FigureKind) is_knight() bool {
	return fig == .knight_black || fig == .knight_white
}

@[inline]
pub fn (fig FigureKind) is_bishop() bool {
	return fig == .bishop_black || fig == .bishop_white
}

@[inline]
pub fn (fig FigureKind) is_rook() bool {
	return fig == .rook_black || fig == .rook_white
}

@[inline]
pub fn (fig FigureKind) is_queen() bool {
	return fig == .queen_black || fig == .queen_white
}

@[inline]
pub fn (fig FigureKind) is_king() bool {
	return fig == .king_black || fig == .king_white
}

@[inline]
pub fn (fig FigureKind) is_enemy(piece FigureKind) bool {
	if piece == .nothing || fig == .nothing {
		return false
	}
	return fig.is_white() == piece.is_black()
}

@[inline]
pub fn (mut fig FigureKind) promote(choice int) {
	match choice {
		1 {
			fig = if fig.is_white() {
				FigureKind.bishop_white
			} else {
				FigureKind.bishop_black
			}
		}
		2 {
			fig = if fig.is_white() {
				FigureKind.knight_white
			} else {
				FigureKind.knight_black
			}
		}
		3 {
			fig = if fig.is_white() { FigureKind.rook_white } else { FigureKind.rook_black }
		}
		else {
			fig = if fig.is_white() {
				FigureKind.queen_white
			} else {
				FigureKind.queen_black
			}
		}
	}
}
