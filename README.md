# vchess
Chess game written in V programming language(in development)
Thank you for your stars

## Disclaimer ⚠️
**The game is unfinished and unplayable now**

### Build🔨

You need Vlang installed to play: `https://vlang.io`

to build use:
```
# 1. Clone the repo
 git clone https://github.com/xn0px90/vchess/

# 2. Build project
 cd vchess && v .

# 3. Executable file named "vchess" will appear. Executable have to be in the same folder with assets/
 ./vchess
```

### Linux Troubleshooting 🐧

#### `LINUX_X11_QUERY_SYSTEM_DPI_FAILED` — DPI warning
This is a **non-fatal warning** emitted by the sokol graphics library when it
cannot query the system DPI from the display server (common in minimal X11
sessions, containers, or remote desktops).  The game continues with a default
scale of 96 DPI.

If the UI appears too small or too large you can override the DPI scale:
```bash
VCHESS_DPI_SCALE=1.5 ./vchess   # e.g. 1.5× scaling on a HiDPI display
```

To set a persistent Xft DPI value for your X11 session:
```bash
echo 'Xft.dpi: 96' >> ~/.Xresources
xrdb -merge ~/.Xresources
```

#### `LINUX_EGL_NO_CONFIGS` — EGL / GPU error
`eglChooseConfig() returned no configs` means the EGL driver found no matching
OpenGL framebuffer configuration.  This happens when:
- GPU drivers are missing, broken, or mismatched (Mesa vs NVIDIA).
- Running inside a container or remote session without `/dev/dri` access.
- Wayland / XWayland backend mismatch.

**Quick fix — force software (Mesa llvmpipe) rendering:**
```bash
./vchess --software
# or equivalently:
./vchess --disable-gpu
# or via environment variable:
LIBGL_ALWAYS_SOFTWARE=1 ./vchess
```

Software rendering works everywhere but is slower than GPU rendering.

**Verify your EGL / GL stack:**
```bash
echo "session=$XDG_SESSION_TYPE desktop=$XDG_CURRENT_DESKTOP"
glxinfo -B 2>/dev/null | head -20
eglinfo  2>/dev/null | head -40   # needs: sudo apt install mesa-utils-extra
ls -l /dev/dri
```

## Working on right now🔧
- ● Pieces displayed            ✅
- ● FEN support                 ✅
- ● Move rollback               ✅
- ● Workable on Android         ✅
- ● Properly resizable window   ✅
- ● All pieces movable          ✅
- ● Main menu & buttons         ✅
- ● Preffered color menu option ✅
- ● Theme switching             ✅
- ● Progress autosaves          ✅
- ● Icon sets switching         ❌
- ● Animations                  ❌
- ● Rules                       🕗
- ● Stockfish integration & UCI 🕗
- ● Bluetooth multiplayer       ❌

## Preview ✨
![image](https://user-images.githubusercontent.com/83360271/221190798-905c4632-a171-462f-9f60-eb088751c0c9.png)
![image](https://user-images.githubusercontent.com/83360271/221369701-d6d17790-4706-4c41-ae77-c721fcb1ca35.png)
![image](https://user-images.githubusercontent.com/83360271/221191050-430a21e7-f946-4a9e-bf5b-a98c8d285b38.png)

