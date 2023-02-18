module figure_kind

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
pub fn (figure FigureKind) is_white() bool {
	white_pieces := [FigureKind.pawn_white, FigureKind.knight_white, FigureKind.bishop_white, FigureKind.rook_white, FigureKind.queen_white, FigureKind.king_white]

	if figure == .nothing {return false}
	return figure in white_pieces
}

pub fn (figure FigureKind) is_black() bool {
	black_pieces := [FigureKind.pawn_black, FigureKind.knight_black, FigureKind.bishop_black, FigureKind.rook_black, FigureKind.queen_black, FigureKind.king_black]

	if figure == .nothing {return false}
	return figure in black_pieces
}

[inline]
pub fn (figure FigureKind) is_pawn() bool {
	return figure == .pawn_black || figure == .pawn_white
}

[inline]
pub fn (figure FigureKind) is_knight() bool {
	return figure == .knight_black || figure == .knight_white
}

[inline]
pub fn (figure FigureKind) is_bishop() bool {
	return figure == .bishop_black || figure == .bishop_white
}

[inline]
pub fn (figure FigureKind) is_rook() bool {
	return figure == .rook_black || figure == .rook_white
}

[inline]
pub fn (figure FigureKind) is_queen() bool {
	return figure == .queen_black || figure == .queen_white
}

[inline]
pub fn (figure FigureKind) is_king() bool {
	return figure == .king_black || figure == .king_white
}

[inline]
pub fn (figure FigureKind) is_enemy(piece FigureKind) bool {
	if piece == .nothing || figure == .nothing {return false}
	return figure.is_white() == piece.is_black()
}
