#ifndef STOCKFISH_EMBED_H
#define STOCKFISH_EMBED_H

#ifdef __cplusplus
extern "C" {
#endif

void stockfish_start(int stdin_fd, int stdout_fd, int stderr_fd);

#ifdef __cplusplus
}
#endif

#endif
