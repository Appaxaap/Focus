Install dependencies for Linux AppImage
======================================

Symptom
-------

When running the AppImage you might see an error like:

/tmp/.mount_focus.MjCbpJ/focus: error while loading shared libraries: libkeybinder-3.0.so.0: cannot open shared object file: No such file or directory

This means a system library required by the binary is not installed on the user's distribution.

Quick fix
---------

Install the package that provides the missing library for your distribution.

Debian / Ubuntu / Mint

```bash
sudo apt update
sudo apt install libkeybinder-3.0-0 libgdk-pixbuf2.0-0 libgtk-3-0 libnotify4
```

Fedora

```bash
sudo dnf install keybinder3 gdk-pixbuf2 gtk3 libnotify
```

Arch Linux / Manjaro

```bash
sudo pacman -S keybinder gdk-pixbuf2 gtk3 libnotify
```

Notes
-----
- Package names vary between distros and versions. If a package name above is not found, search which package provides the missing library, for example:
  - Debian/Ubuntu: `apt-file search libkeybinder-3.0.so.0` (install `apt-file` if needed)
  - Fedora: `dnf provides "*/libkeybinder-3.0.so.0"`
  - Arch: `pkgfile libkeybinder-3.0.so.0` (install `pkgfile` and run `sudo pkgfile --update` first)

- You can inspect the AppImage to find which binary is failing and check its shared libraries:

```bash
# extract the AppImage (creates squashfs-root/)
./Focus.AppImage --appimage-extract
# inspect the binary (path may vary) and look for missing libs
ldd squashfs-root/usr/bin/focus | grep "not found\|keybinder"
```

What to include in releases / docs
---------------------------------
- Add a short note to the release description and README pointing users to this file when distributing AppImages.
- Optionally provide a simple dependency list in the release notes so packagers can bundle or statically link missing libraries.

If you want, I can:
- Add this file to the repo (done) and commit/push it.
- Add a short section to the `README.md` and the release template.
- Open a PR that updates the Release Notes with the dependency list.

Tell me which of the above you'd like me to do next.