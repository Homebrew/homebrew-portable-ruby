# Homebrew Portable

Portable edition tools.

## How to build?

### OS X

* It is recommended to build formulae on Leopard VM.
* `brew install ruby`
* Set following environment variables for Tigerbrew:
  * `export HOMEBREW_PREFER_64_BIT=1`
  * `export HOMEBREW_DEVELOPER=1`
  * `export HOMEBREW_RUBY_PATH="$(brew --prefix ruby)/bin/ruby"`
* `brew tap homebrew/portable`
* `brew install portable-<tool>`.
* `brew uninstall $(brew deps --include-build portable-<tool>)`
* `brew test portable-<tool>`.
* Check the linkage using `brew linkage portable-<tool>`.
* `brew portable-package portable-<tool>`.

### Linux

* Build docker image from `docker/Dockerfile`.
* `brew tap homebrew/portable`
* `brew install portable-<tool>`.
* `brew uninstall $(brew deps --include-build portable-<tool>)`
* `brew test portable-<tool>`.
* Check the linkage using `ldd`.
* `brew portable-package portable-<tool>`.

## License

MIT License.
