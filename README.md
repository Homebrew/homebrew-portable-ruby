# Homebrew Portable
Formulae and tools to build versions of Ruby, Git and Curl that can be installed and run from anywhere on the filesystem.

## How do I install these formulae?
Just `brew install homebrew/portable/<formula>`.

## How do I build packages for these formulae?
### macOS
Run `brew portable-package <formula>` (ideally inside an OS X 10.5 VM so it is compatible with old macOS versions.

### Linux
Run `brew portable-package <formula>`. Ideally this should be run inside the CentOS 5 Docker container with:
```bash
docker build -f docker/Dockerfile -t homebrew-portable:latest .
docker run -t -i homebrew-portable /bin/bash
brew portable-package <formula>
```

## Current status

| Formula | macOS 10.12 | OS X 10.5 | OS X 10.4 | Linuxbrew[0] |
| :-: | :-: | :-: | :-: | :-: |
| zlib | N/A | N/A | N/A | :white_check_mark: |
| ncurses | N/A | N/A | N/A | :white_check_mark: |
| expat | N/A | N/A | :white_check_mark: | :white_check_mark: |
| OpenSSL | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| Readline | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| libYAML | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| Ruby | :white_check_mark::warning: (64 bit only)[1] | :white_check_mark::warning: (32/64 bit only)[1] | :white_check_mark: (Single arch only)[1] | :white_check_mark::warning: [3] |
| Curl | :white_check_mark: | :white_check_mark: | :white_check_mark: | :x: [2] |
| Git | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |

macOS/OS X builds on 10.6 and newer target 32-bit/64-bit Intel Macs. OS X builds on 10.4 and 10.5 target 32-bit PowerPC and Intel Macs.

* [0]: Linuxbrew is 64 bit only, which should be built in CentOS docker using system libraries and compiler.
* [1]: Fail on universal build. https://gist.github.com/cb5e6b142c39116dbe0b954885f1054e. It appears to be Ruby's bug, as it's fixed for Ruby 2.1.
* [2]: Binary files report segment fault when running on CentOS 6(work fine on CentOS 5)
* [3]: Linux build `irb` seems to fail to link staticly to ncurses. If `portable-ncurses` is removed, `irb` will fail to handle left, right or backspace keystroke.


## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/Homebrew/homebrew-portable/blob/master/LICENSE.txt).
