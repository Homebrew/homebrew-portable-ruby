# Homebrew Portable Ruby

Formulae and tools to build versions of Ruby that can be installed and run from anywhere on the filesystem.

## How do I install these formulae

Just `brew install homebrew/portable-ruby/<formula>`.

## How do I build packages for these formulae

### macOS

Run `brew portable-package ruby` inside an OS X 10.9 VM (so it is compatible with all working Homebrew macOS versions).

### Linux

Build a Docker image for your architecture by running one of the following commands.

- `docker build -f docker/Dockerfile.x86_64 -t homebrew-portable .`
- `docker build -f docker/Dockerfile.arm -t homebrew-portable .`
- `docker build -f docker/Dockerfile.arm64 -t homebrew-portable .`

Build the `portable-ruby` package using that Docker image.

```sh
docker run --name=homebrew-portable-ruby -w /bottle homebrew-portable brew portable-package ruby
docker cp homebrew-portable-ruby:/bottle .
```

## Current Status

Used in production for Homebrew/brew.

### Linux

1. `irb` on Linux builds seems to fail to link to ncurses statically. If `portable-ncurses` is removed, `irb` will fail to handle left, right or backspace keystroke.

## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/Homebrew/homebrew-portable-ruby/blob/master/LICENSE.txt).
