module saving

import os

pub struct Save {
	pub mut:
	main_name 	string
}

pub fn (save Save) writen2save(s string) {
	if os.exists(save.main_name) {os.rm(save.main_name) or {println(err)}}
	os.create(save.main_name) or {println(err)}
	mut file := os.open(save.main_name) or {exit(1)}
	file.writeln(s) or {println(err)}
	file.close()
}
