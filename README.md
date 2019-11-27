# homebrew-tap

Third-party [Homebrew](https://brew.sh/) tap providing formulae for Fyde software.

## Installation and usage

To use this tap, install Homebrew on macOS or Linux.

Then, to install, for instance, [fyde-cli](https://github.com/fyde/fyde-cli), use the following:

```
brew tap fyde/tap
brew install fyde/tap/fyde-cli
```

### Updates

Updates can be performed as follows:

```
brew update
brew upgrade fyde/tap/fyde-cli
```

### Installing the latest development version

To install the `HEAD` of the `develop` branch, pass the `--HEAD` option:

```
brew install fyde/tap/fyde-cli --HEAD
```

This will download and install any dependencies necessary for compiling the program from source.