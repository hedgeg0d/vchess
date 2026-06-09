module uci

import os
import time

pub struct Engine {
mut:
	proc &os.Process = unsafe { nil }
pub mut:
	path  string
	ready bool
}

pub fn new_engine(path string) !&Engine {
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
	if e.proc == unsafe { nil } {
		return
	}
	e.proc.stdin_write(cmd + '\n')
}

fn (mut e Engine) read_available() string {
	if e.proc == unsafe { nil } {
		return ''
	}
	return e.proc.stdout_read()
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
	if e.proc == unsafe { nil } {
		return
	}
	e.send('quit')
	time.sleep(50 * time.millisecond)
	e.proc.signal_kill()
	e.proc.close()
}
