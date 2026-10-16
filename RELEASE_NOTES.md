Patched Wine 11.17 for running IRCAM Thermal Viewer (OpenRMH-IRCAM) on Linux with live thermal camera support.

You don't need to download this file yourself: clone the repository and run `./install.sh`, which fetches and
verifies it. See the [README](https://github.com/bigtimer-dev/openrmh-ircam-linux#readme).

**Contents:** [Kron4ek's portable vanilla Wine 11.17](https://github.com/Kron4ek/Wine-Builds/releases/tag/11.17)
with `qcap.so`, `avicap32.so` and `opengl32.dll` rebuilt from the official Wine 11.17 source with
[`patches/wine-11.17-openrmh.patch`](https://github.com/bigtimer-dev/openrmh-ircam-linux/blob/main/patches/wine-11.17-openrmh.patch)
applied (camera name, raw YUY2 passthrough, all video modes listed, two OpenGL text fixes). Wine is LGPL 2.1.

Tested with an InfiRay / Thermal Master P2 Pro.
