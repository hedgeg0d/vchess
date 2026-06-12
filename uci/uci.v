module uci

import os
import time

#include "stockfish_embed.h"
#flag -I lib
#flag -l stockfish
#flag -lc++_static
#flag -lc++abi
#flag -llog

pub struct Engine {
mut:
	in_fd   int = -1
	out_fd  int = -1
	pid     int = -1
	proc    &os.Process = unsafe { nil }
pub mut:
	path  string
	ready bool
}

fn C.pipe(fds &int) int
fn C.fork() int
fn C.close(fd int) int
fn C.read(fd int, buf voidptr, count usize) int
fn C.write(fd int, buf voidptr, count usize) int
fn C.waitpid(pid int, status &int, options int) int
fn C.kill(pid int, sig int) int

fn C.stockfish_start(stdin_fd int, stdout_fd int, stderr_fd int)

pub fn new_engine() !&Engine {
	mut pipes_in := [2]int{}
	mut pipes_out := [2]int{}
	if C.pipe(&pipes_in[0]) != 0 {
		return error('pipe failed')
	}
	if C.pipe(&pipes_out[0]) != 0 {
		C.close(pipes_in[0])
		C.close(pipes_in[1])
		return error('pipe failed')
	}
	pid := C.fork()
	if pid < 0 {
		C.close(pipes_in[0])
		C.close(pipes_in[1])
		C.close(pipes_out[0])
		C.close(pipes_out[1])
		return error('fork failed')
	}
	if pid == 0 {
		C.close(pipes_in[1])
		C.close(pipes_out[0])
		C.stockfish_start(pipes_in[0], pipes_out[1], pipes_out[1])
		C.close(pipes_in[0])
		C.close(pipes_out[1])
		C.exit(0)
	}
	C.close(pipes_in[0])
	C.close(pipes_out[1])
	mut e := &Engine{
		in_fd: pipes_in[1]
		out_fd: pipes_out[0]
		pid: pid
		path: 'stockfish'
	}
	// Send 'uci' to engine and drain startup messages
	e.send('uci')
	sw := time.new_stopwatch()
	mut buf := ''
	mut token := ''
	for sw.elapsed().milliseconds() < 10000 {
		chunk := e.read_available()
		if chunk.len == 0 {
			time.sleep(5 * time.millisecond)
			continue
		}
		buf += chunk
		for line in buf.split('\n') {
			line2 := line.trim_space()
			if line2.len == 0 { continue }
			eprintln('>> ${line2}')
			if line2.contains('uciok') { token = 'uciok'; break }
		}
		if token.len > 0 { break }
	}
	if token == '' {
		return error('engine init timeout waiting for uciok')
	}
	e.send('isready')
	e.wait_token('readyok', 5000)!
	e.ready = true
	return e
}

pub fn new_engine_ext(path string) !&Engine {
	mut cmd := path
	if !os.exists(cmd) {
		cmd = os.find_abs_path_of_executable(path) or { return error('engine not found: ${path}') }
	}
	mut p := os.new_process(cmd)
	p.set_redirect_stdio()
	p.run()
	mut e := &Engine{
		proc: p
		path: cmd
	}
	e.send('uci')
	e.wait_token('uciok', 5000)!
	e.send('isready')
	e.wait_token('readyok', 5000)!
	e.ready = true
	return e
}

fn (mut e Engine) send(cmd string) {
	if e.proc != unsafe { nil } {
		e.proc.stdin_write(cmd + '\n')
		return
	}
	if e.in_fd < 0 {
		return
	}
	data := cmd + '\n'
	C.write(e.in_fd, data.str, data.len)
}

fn (mut e Engine) read_available() string {
	if e.proc != unsafe { nil } {
		return e.proc.stdout_read()
	}
	if e.out_fd < 0 {
		return ''
	}
    mut buf := [4096]u8{}
	nr := C.read(e.out_fd, &buf[0], 4096)
	if nr <= 0 {
		return ''
	}
	return buf[..nr].bytestr()
}

fn (mut e Engine) wait_token(token string, timeout_ms int) ! {
	sw := time.new_stopwatch()
	mut buf := ''
	for sw.elapsed().milliseconds() < timeout_ms {
		chunk := e.read_available()
		if chunk.len == 0 {
			time.sleep(5 * time.millisecond)
			continue
		}
		buf += chunk
		if buf.contains(token) {
			return
		}
	}
	return error('timeout waiting for ${token}')
}

pub fn (mut e Engine) set_skill(level int) {
	mut lvl := level
	if lvl < 0 {
		lvl = 0
	}
	if lvl > 20 {
		lvl = 20
	}
	e.send('setoption name Skill Level value ${lvl}')
}

pub fn (mut e Engine) best_move(fen string, movetime_ms int) !string {
	e.send('position fen ${fen}')
	e.send('go movetime ${movetime_ms}')
	sw := time.new_stopwatch()
	timeout := movetime_ms + 5000
	mut buf := ''
	for sw.elapsed().milliseconds() < timeout {
		chunk := e.read_available()
		if chunk.len == 0 {
			time.sleep(5 * time.millisecond)
			continue
		}
		buf += chunk
		for line in buf.split_into_lines() {
			if line.starts_with('bestmove') {
				parts := line.split(' ')
				if parts.len >= 2 && parts[1].len >= 4 {
					return parts[1]
				}
			}
		}
	}
	return error('engine move timeout')
}

pub fn (mut e Engine) quit() {
	if e.proc != unsafe { nil } {
		e.send('quit')
		time.sleep(50 * time.millisecond)
		e.proc.signal_kill()
		e.proc.close()
		return
	}
	if e.in_fd >= 0 {
		e.send('quit')
		time.sleep(50 * time.millisecond)
		C.close(e.in_fd)
	}
	if e.out_fd >= 0 {
		C.close(e.out_fd)
	}
	if e.pid > 0 {
		C.kill(e.pid, 9)
		C.waitpid(e.pid, unsafe { nil }, 0)
	}
	e.in_fd = -1
	e.out_fd = -1
	e.pid = -1
}
