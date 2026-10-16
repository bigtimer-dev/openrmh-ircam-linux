# OpenRMH-IRCAM for Linux

Run **[IRCAM Thermal Viewer (OpenRMH-IRCAM)](https://github.com/Cyclotronic/OpenRMH-IRCAM)**, the open-source viewer and
analysis tool for low-cost USB thermal cameras, on Linux, **including live view with correct radiometric
temperatures**.

The program is a Windows (.NET / C++/CLI) application. This project runs it under its own copy of
[Wine](https://www.winehq.org/), with a few small patches that make USB thermal cameras work. Without them the camera
is "not found", and if it were found the temperature data would be destroyed before the program sees it.

> **Status:** works with an **InfiRay / Thermal Master P2 Pro**. Other UVC cameras on the program's supported list
> (TOPDON TC001, InfiRay P2, Tiny1C, UNI-T UTi260M, …) use the same path and should work too, but are untested. Reports
> are welcome, see [Issues](../../issues). The Thermal Master P3 (WinUSB, not UVC) is **not** expected to work.

## Install

Requirements: x86_64 Linux, plus `curl tar xz unzip winetricks cabextract`.

```bash
# Arch:          sudo pacman -S --needed curl tar xz unzip winetricks cabextract
# Debian/Ubuntu: sudo apt install curl tar xz-utils unzip winetricks cabextract
# Fedora:        sudo dnf install curl tar xz unzip winetricks cabextract

git clone https://github.com/bigtimer-dev/openrmh-ircam-linux.git
cd openrmh-ircam-linux
./install.sh
```

The installer needs no root and puts everything in your home directory:

| What | Where |
|---|---|
| Patched Wine 11.17 (separate from any system Wine, so updates never touch it) | `~/.local/share/openrmh-ircam/wine` |
| Wine prefix with .NET Framework 4.8, VC++ runtime and core fonts | `~/.local/share/openrmh-ircam/prefix` |
| The program, downloaded from the [official release](https://github.com/Cyclotronic/OpenRMH-IRCAM/releases) and checksum-verified | `~/.local/share/openrmh-ircam/app` |
| Launcher and app-menu entry | `~/.local/bin/openrmh-ircam`, `~/.local/share/applications/` |

Installing .NET takes 10-20 minutes. Running `./install.sh` again later reuses the prefix, so it's quick.

Your user must be in the `video` group to access the camera (`sudo usermod -aG video "$USER"`, then log out and back in).

## Use

Start **IRCAM Thermal Viewer** from your app menu, or run `openrmh-ircam`. Then go to **Settings**, choose your **exact
camera model** in the list (P2 Pro: *"InfiRay Or Thermal Master P2Pro"*) and press **Connect**.

The program's own manual is included: use the **User Guide** button, or open
`~/.local/share/openrmh-ircam/app/IRCAMSoftwareManual.pdf`.

## Uninstall

```bash
./uninstall.sh
```

## What the Wine patches do

All in [`patches/wine-11.17-openrmh.patch`](patches/wine-11.17-openrmh.patch):

1. **Camera name** (`dlls/avicap32/v4l.c`). Linux's UVC driver names the camera `USB Camera: USB Camera`; Windows calls
   it `USB Camera`, and the program looks for that exact name.
2. **Raw video passthrough** (`dlls/qcap/v4l.c`). Stock Wine converts all webcam video to RGB, which destroys the
   temperature data these cameras pack into their YUYV frames. The patched Wine offers the camera's native YUYV format
   as DirectShow YUY2 and passes frames through byte-for-byte.
3. **All video modes listed** (`dlls/qcap/v4l.c`). Stock Wine only lists the camera's default mode (256x192) until
   one is chosen; the thermal data is in the 256x384 mode.
4. **OpenGL text fix** (`dlls/opengl32/thunks.c`). Wine 11 translated `glListBase` as if it were a display-list
   name, shifting all OpenGL text by 30 characters (`MAX` came out as `k_v`).
5. **OpenGL per-window font lists** (`dlls/opengl32/thunks.c`). `glCallLists` now resolves names in the current
   context's own list table, so characters a window has no glyph for draw nothing (as on Windows) instead of hitting
   another window's font (`°C` came out as `PC`).

Fixes 4 and 5 are general Wine 11 bugs; fixes 2 and 3 make this Wine suited only to raw-data apps like this one, which
is why it lives in its own folder instead of replacing your system Wine.

The patched Wine is built by [GitHub Actions](.github/workflows/build.yml): the three patched files are compiled from
the official Wine 11.17 source and dropped into [Kron4ek's portable vanilla Wine 11.17 build](https://github.com/Kron4ek/Wine-Builds).

## Troubleshooting

- **"Camera Not Found!"**: check that the camera shows up (`ls /dev/video*`, `v4l2-ctl --list-devices`), that you're
  in the `video` group, and that the right model is selected.
- **Debug output**: run `WINEDEBUG=err+all,+quartz openrmh-ircam` from a terminal.

## Credits and licences

- **IRCAM Thermal Viewer** by **Rune Mark Hansen** (<https://rmg-engineering.com/>), released as
  [OpenRMH-IRCAM](https://github.com/Cyclotronic/OpenRMH-IRCAM) under the MIT licence. This project doesn't
  redistribute the program; the installer downloads the official release.
- **Wine** is licensed under the LGPL 2.1. The patch here is under the same licence; the modified binaries are built
  in public by this repository's GitHub Actions.
- Portable Wine base build by [Kron4ek/Wine-Builds](https://github.com/Kron4ek/Wine-Builds).
- .NET Framework, the VC++ runtime and fonts are downloaded by [winetricks](https://github.com/Winetricks/winetricks)
  from Microsoft on your machine and are not redistributed here.
- The installer scripts in this repository are MIT-licensed (see [LICENSE](LICENSE)).

This is an unofficial community project, not affiliated with the program's author, WineHQ or the camera makers.
