# Homebrew Portable Ruby

Formulae and tools to build versions of Ruby that can be installed and run from anywhere on the filesystem.

## How do I install these formulae

Just `brew install homebrew/portable-ruby/<formula>`.

## How do I build packages for these formulae

Homebrew Portable Ruby is designed only for usage internally to Homebrew. If Portable Ruby isn't available for your platform, it is recommended you instead use Ruby from your system's package manager (if available) or rbenv/ruby-build. Usage of Portable Ruby outside of Homebrew, such as embedding into your own apps, is not a goal for this project.

## How do I issue a new release

[An automated release workflow is available to use](https://github.com/Homebrew/homebrew-portable-ruby/actions/workflows/release.yml).
Dispatch the workflow and all steps of building, tagging and uploading should be handled automatically.

<details>
<summary>Manual steps are documented below.</summary>

### Build

Run `brew portable-package ruby`. For macOS, this should ideally be inside an OS X 10.11 VM (so it is compatible with all working Homebrew macOS versions).

### Upload

Copy the bottle `bottle*.tar.gz` and `bottle*.json` files into a directory on your local machine.

Upload these files to GitHub Packages with:

```sh
brew pr-upload --upload-only --root-url=https://ghcr.io/v2/homebrew/portable-ruby
```

And to GitHub releases:

```sh
brew pr-upload --upload-only --root-url=https://github.com/Homebrew/homebrew-portable-ruby/releases/download/$VERSION
```

where `$VERSION` is the new package version.
</details>

## Current Status

Used in production for Homebrew/brew.

## License

Code is under the [BSD 2-Clause "Simplified" License](https://github.com/Homebrew/homebrew-portable-ruby/blob/HEAD/LICENSE.txt).
