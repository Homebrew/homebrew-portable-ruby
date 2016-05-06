# Homebrew Portable

Portable edition tools.

## How to build?

### OS X

* It is recommended to build formulae on Leopard VM.
* Set `HOMEBREW_PREFER_64_BIT` for Tigerbrew.
* `brew tap xu-cheng/portable`
* `brew install portable-<tool>`.
* `brew test portable-<tool>`.
* Check the linkage using `brew linkage portable-<tool>`.
* `brew portable-package portable-<tool>`.

### Linux

* Build docker images from `docker/Dockerfile`.
* `brew install portable-<tool>`.
* `brew test portable-<tool>`.
* Check the linkage using `ldd`.
* `brew portable-package portable-<tool>`.
