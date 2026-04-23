module cords

pub fn xy2chessboard(x int, y int) string {
	mut final_cord := ''
	final_cord += match y {
		0 { 'a' }
		1 { 'b' }
		2 { 'c' }
		3 { 'd' }
		4 { 'e' }
		5 { 'f' }
		6 { 'g' }
		7 { 'h' }
		else { ' ' }
	}
	final_cord += (9 - (x + 1)).str()
	return final_cord
}

pub fn chessboard2xy(cord string) []int {
	parts := cord.split('')
	if parts.len < 2 {
	}
	x := match parts[0] {
		'a' { 0 }
		'b' { 1 }
		'c' { 2 }
		'd' { 3 }
		'e' { 4 }
		'f' { 5 }
		'g' { 6 }
		'h' { 7 }
		else { -1 }
	}
	y := 8 - (parts[1].int())
	return [y, x]
}

@[inline]
pub fn en_passant2xy(en_passant string, is_white_move bool) []int {
	coordinates := chessboard2xy(en_passant)
	if coordinates.len < 2 {
		exit(1)
	}
	mut x := coordinates[0]
	y := coordinates[1]
	if !is_white_move {
		x--
	} else {
		x++
	}
	return [y, x]
}
