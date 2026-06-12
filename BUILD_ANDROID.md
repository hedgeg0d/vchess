# Building vChess for Android (with embedded Stockfish)

vChess plays against Stockfish. On desktop the engine is a normal external
process, but on Android (API 30+) SELinux blocks `execute_no_trans` on
`app_data_file` for `untrusted_app`, so an extracted binary in `/data/data/...`
cannot be `execve()`'d.

The solution: **embed Stockfish as a static library** inside the app's native
`.so`, and start it with `fork()` + a **direct C call** (no `execve`, so the
process keeps the app's SELinux domain). The forked child talks UCI to the
parent over pipes.

To keep the APK small we embed **only the small NNUE network** (~3.5 MB); the
big network is replaced by a 1‑byte placeholder (saves ~76 MB).

Result: a self-contained ~6.8 MB APK, no external engine binary.

---

## Toolchain / prerequisites

| Tool | Version used | Notes |
|------|--------------|-------|
| V | 0.5.1 | module name must match directory name |
| vab | 0.4.1 | `~/.vmodules/vab` |
| Android NDK | r27 (clang 18) | `/opt/android-ndk` |
| Stockfish | 17 | patched, see below |

NDK sysroot lib dir (where the static lib must be placed):

```
/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/
```

Target ABI: **arm64-v8a only** (the static lib is built for `aarch64`).

---

## 1. Patch Stockfish 17

Start from a clean Stockfish 17 checkout in `src/`. Apply these changes:

### a) Shrink the big network to a placeholder
The big net file (`EvalFileDefaultNameBig`, e.g. `nn-1111cefa1111.nnue`) is
truncated to a single zero byte so `INCBIN` embeds ~nothing instead of ~76 MB.
The small net (`nn-37f18f62d772.nnue`, ~3.5 MB) is left intact and is the only
network actually used.

```sh
printf '\0' > src/nn-1111cefa1111.nnue   # 1-byte placeholder
# leave src/nn-37f18f62d772.nnue untouched (the real small net)
```

`nnue/network.cpp` is left stock: `INCBIN` embeds both files (big = 1 byte
garbage, small = real).

### b) Always evaluate with the small network — `evaluate.cpp`
Both evaluate paths use `networks.small.evaluate(...)` (the big net is never
referenced).

### c) Never touch the (unloaded) big network — `engine.cpp`
```cpp
void Engine::load_big_network(const std::string&) {}          // no-op
void Engine::load_networks()   { /* only networks_.small.load(...) */ }
void Engine::verify_networks() const { networks->small.verify(...); }
```

### d) Skip clearing the big accumulator cache — `nnue/nnue_accumulator.h`
`AccumulatorCaches` is allocated per worker and `clear()` dereferences each
network's `featureTransformer`. The big network is never loaded, so its
`featureTransformer` is **null** → `big.clear()` would SIGSEGV. Skip it:

```cpp
template<typename Networks>
void clear(const Networks& networks) {
    // big.clear(networks.big);   // big net not embedded -> null FT -> SIGSEGV
    small.clear(networks.small);
}
```
> This was the final crash to fix. Symptom: child died in `Search::Worker`
> ctor right after thread spawn, before printing anything over the pipe.

### e) Add the embedded entry point
Two new files in `src/`:

`stockfish_embed.h`
```c
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
```

`stockfish_embed.cpp` — redirects std streams onto the pipe FDs, then runs the
normal `Bitboards::init()` → `Position::init()` → `UCIEngine` → `uci.loop()`
sequence (a copy of `main()`). No `execve`.

Add `stockfish_embed.cpp` to `SRCS` in the Makefile / build script.

---

## 2. Build the static library

`build_android.sh` (run with **zsh** — note `${=VAR}` word-splitting):

```sh
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/src"

TOOLCHAIN="/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64"
TARGET="aarch64-linux-android21"
CXX="$TOOLCHAIN/bin/${TARGET}-clang++"
AR="$TOOLCHAIN/bin/llvm-ar"
SYSROOT_LIB="$TOOLCHAIN/sysroot/usr/lib/aarch64-linux-android"

CXXFLAGS="-Wall -Wcast-qual -std=c++17 -fPIC -DUSE_PTHREADS -DNDEBUG -O3 \
-funroll-loops -DIS_64BIT -DUSE_POPCNT -DUSE_NEON=8 -DGIT_SHA=e0bfc4b6 \
-DGIT_DATE=20240906 -DARCH=armv8 -fno-lto"

SRCS="stockfish_embed.cpp benchmark.cpp bitboard.cpp evaluate.cpp main.cpp \
misc.cpp movegen.cpp movepick.cpp position.cpp search.cpp thread.cpp \
timeman.cpp tt.cpp uci.cpp ucioption.cpp tune.cpp syzygy/tbprobe.cpp \
nnue/nnue_misc.cpp nnue/features/half_ka_v2_hm.cpp nnue/network.cpp \
engine.cpp score.cpp memory.cpp"

find . -name "*.o" -delete
for src in ${=SRCS}; do "$CXX" ${=CXXFLAGS} -c -o "${src%.cpp}.o" "$src"; done
"$AR" rcs libstockfish.a *.o syzygy/*.o nnue/*.o nnue/features/*.o
```

Then place the lib where vab's linker can find it (vab cannot accept a raw
`.a` path via `#flag`, so copy it into the NDK sysroot — needs sudo):

```sh
sudo cp src/libstockfish.a \
  /opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/
```

> **zsh gotcha:** in bash `$VAR` word-splits, in zsh it does not. Use `${=VAR}`
> (or an array) or you get `R_AARCH64_LDST64_ABS_LO12_NC` PIC-relocation errors
> from passing the whole flag string as one argument.

---

## 3. V-side glue

`uci/uci.v` links the lib and provides the fork/pipe wrapper:

```v
#include "stockfish_embed.h"
#flag -I lib
#flag -l stockfish
#flag -lc++_static
#flag -lc++abi
```

- `#flag -I lib` — finds `stockfish_embed.h` (kept in `lib/`).
- `-lc++_static` + `-lc++abi` — vab 0.4.1 silently drops `-static-libstdc++`
  (only `-D/-I/-l` flags reach the linker), so request the static libc++
  explicitly. Without it: `UnsatisfiedLinkError: std::__ndk1::mutexD1Ev`.
- `liblog` is already a `NEEDED` lib from vab's template, so no `-llog` needed.

`game.v`: the engine is started from `think()` (in a spawned goroutine), **not**
from `start_game()` on the main thread — otherwise the fork/init stalls the UI
thread and triggers an ANR. On Android `resolve_engine_path()` returns `""`
(the engine is in-process, not a file).

---

## 4. Build the APK

```sh
vab run . \
  --package-id com.hedgegod.chessgame \
  --name vChess \
  --icon /path/to/icon.png \
  --archs arm64-v8a \
  -o vchess_arm8.apk
```

> **vab relink cache:** vab only recompiles the native `.so` when the
> V-generated C changes. Edits that live **only** in `libstockfish.a` (i.e. the
> Stockfish patches) will NOT trigger a relink — vab repackages the stale `.so`.
> After rebuilding the lib, wipe the cache first:
>
> ```sh
> rm -rf /tmp/vab
> ```

---

## 5. Test on a real device (adb)

```sh
adb install -r vchess_arm8.apk
adb logcat -c
adb shell monkey -p com.hedgegod.chessgame -c android.intent.category.LAUNCHER 1
# start a game vs the engine and make a move, then:
adb logcat -d | grep -E "uciok|bestmove|engine init"
```

Healthy startup ends with the engine emitting `uciok` (and `bestmove ...` once
you play). `engine init timeout waiting for uciok` means the forked child
crashed before handshake — check `adb logcat -d -s DEBUG` for the backtrace.

---

## Troubleshooting history

| Symptom | Cause | Fix |
|---|---|---|
| `R_AARCH64_LDST64_ABS_LO12_NC` | zsh didn't split `$CXXFLAGS` | use `${=CXXFLAGS}` |
| `UnsatisfiedLinkError ...mutexD1Ev` | dynamic libc++ missing | `-lc++_static -lc++abi` |
| `unknown type board.Board` | V 0.5.1 module≠dir name | rename `module xboard` → `module board` |
| `stockfish_embed.h not found` | include path | `#flag -I lib` |
| stale `.so`, old behaviour after lib rebuild | vab relink cache | `rm -rf /tmp/vab` |
| SIGSEGV in `Search::Worker` ctor | big net unloaded → null FT in `AccumulatorCaches::clear` | skip `big.clear()` |
