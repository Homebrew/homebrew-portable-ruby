# Homebrew Portable
Formulae and tools to build versions of Ruby, Git and Curl that can be installed and run from anywhere on the filesystem.

## How do I install these formulae?
Just `brew install homebrew/portable/<formula>`.

## How do I build packages for these formulae?
### OS X
Run `brew portable-package <formula>` (ideally inside a OS X 10.5 VM so it is compatible with old OS X versions.

### Linux
Run `brew portable-package <formula>`. Ideally this should be run inside the CentOS 5 Docker container with:
```bash
docker build -f docker/Dockerfile -t homebrew-portable:latest .
docker run -t -i homebrew-portable /bin/bash
brew portable-package <formula>
```

## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/Homebrew/homebrew-portable/blob/master/LICENSE.txt).
