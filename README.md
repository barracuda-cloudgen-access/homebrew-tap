# homebrew-tap

Third-party [Homebrew](https://brew.sh/) tap providing formulae for Barracuda CloudGen Access software.

## Installation and usage

To use this tap, install Homebrew on macOS or Linux.

Then, to install, for instance, [access-cli](https://github.com/barracuda-cloudgen-access/access-cli), use the following:

```
brew tap barracuda-cloudgen-access/tap
brew install barracuda-cloudgen-access/tap/access-cli
```

### Updates

Updates can be performed as follows:

```
brew update
brew upgrade barracuda-cloudgen-access/tap/access-cli
```

### Installing the latest development version

To install the `HEAD` of the `develop` branch, pass the `--HEAD` option:

```
brew install barracuda-cloudgen-access/tap/access-cli --HEAD
```

This will download and install any dependencies necessary for compiling the program from source.

## Development

When developing in this repository, any changes that are merged to `master` will be considered "official".

Development process is as simple as follows:
- Create a fork from this repo
- Do modifications as needed
- Create a PR against `master`
- Merge the PR
