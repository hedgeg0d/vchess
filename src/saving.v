module saving

import os
import board
import fen_utils

pub struct Save {
	pub mut:
	main_name 	string
}

pub fn (save Save) writen2save(s string) {
	if os.exists(save.main_name) {os.rm(save.main_name) or {println(err)}}
	os.create(save.main_name) or {println(err)}
	mut file := os.open_append(save.main_name) or {exit(1)}
	file.writeln(s) or {println(err)}
	file.close()
}

pub fn (save Save) load_save(mut board_ board.Board) {
	if os.exists(save.main_name) {
		lines := os.read_lines(save.main_name) or {panic(err)}
		fen_utils.fen_2_board(mut board_, lines[0])
	}
}

pub fn (save Save) get_undoes() []string {
	mut result := []string{}
	if os.exists(save.main_name) {
		lines := os.read_lines(save.main_name) or {panic(err)}
		for i := 1; i < lines.len; i++ {
			result << lines[i]
		}
	}
	println(result)
	return result
}
