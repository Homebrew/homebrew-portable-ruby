# Homebrew Portable
Formulae and tools to build versions of Ruby, Git and Curl that can be installed and run from anywhere on the filesystem.

## How do I install these formulae?
Just `brew install homebrew/portable/<formula>`.

## How do I build packages for these formulae?
### OS X
Build formulae inside a OS X 10.5 VM (to be compatible with old OS X versions) with:
```bash
HOMEBREW_PREFER_64_BIT=1 brew test-bot --skip-relocation --tap=homebrew/portable <formula>
```

Noted that the above command should be run from Homebrew/brew instead of Tigerbrew.

### Linux
Build formulae inside the CentOS 5 Docker container with:
```bash
docker build -f docker/Dockerfile -t homebrew-portable:latest .
docker run -t -i homebrew-portable /bin/bash
brew test-bot --skip-relocation --tap=homebrew/portable <formula>
```

## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/Homebrew/homebrew-portable/blob/master/LICENSE.txt).
