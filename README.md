# Homebrew Portable
Formulae and tools to build versions of Ruby that can be installed and run from anywhere on the filesystem.

## How do I install these formulae?
Just `brew install homebrew/portable/<formula>`.

## How do I build packages for these formulae?
### macOS
Run `brew portable-package <formula>`. Ideally inside an OS X 10.5 VM so it is compatible with old macOS versions.

### Linux (x86_64)
Run `brew portable-package <formula>`. Ideally this should be run inside the CentOS 5 Docker container with:
```bash
docker build -f docker/Dockerfile.x86_64 -t homebrew-portable:x86_64 .
docker run -t -i homebrew-portable:x86_64 /bin/bash
brew portable-package <formula>
```

### Linux (32-bit ARM)
Run `brew portable-package <formula>`. Ideally this should be run inside the Raspbian Docker container with:
```bash
docker build -f docker/Dockerfile.arm -t homebrew-portable:arm .
docker run -t -i homebrew-portable:arm /bin/bash
brew portable-package <formula>
```

## Current Status

| Formula | macOS 10.12 | OS X 10.5 | OS X 10.4 | Linux (x86_64) | Linux (32-bit ARM) |
| :-: | :-: | :-: | :-: | :-: | :-: |
| zlib | N/A | N/A | N/A | :white_check_mark: | |
| ncurses | N/A | N/A | N/A | :white_check_mark: | |
| OpenSSL | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | |
| Readline | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | |
| libYAML | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | |
| Ruby 2.3 | :white_check_mark::warning: | :white_check_mark::warning: | :white_check_mark::warning: | :white_check_mark::warning:[1] | |

macOS/OS X builds on 10.6 and newer target 32-bit/64-bit Intel Macs. OS X builds on 10.4 and 10.5 target 32-bit PowerPC and Intel Macs.

Linux builds target x86_64 and 32-bit ARM (Raspberry Pi) platforms.

1. `irb` on Linux builds seems to fail to link to ncurses statically. If `portable-ncurses` is removed, `irb` will fail to handle left, right or backspace keystroke.


## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/Homebrew/homebrew-portable/blob/master/LICENSE.txt).
