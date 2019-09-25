# ungoogled-chromium-macos

macOS packaging for [ungoogled-chromium](//github.com/Eloston/ungoogled-chromium).

## Downloads

[Download binaries from the Contributor Binaries website](//ungoogled-software.github.io/ungoogled-chromium-binaries/).

**Source Code**: It is recommended to use a tag via `git checkout` (see building instructions below). You may also use `master`, but it is for development and may not be stable.

**Snapshots**: Binaries snapshots are also available via [Github CI](https://github.com/actions/upload-artifact).

## Building

### Software requirements

* macOS 10.12+
* Xcode 8-9
* Homebrew
* Perl (for creating a `.dmg` package)
* Python 2, specifically 2.7.13 or newer, as `python` in PATH
* Python 3.5 or newer as `python3` in PATH

### Setting up the build environment

1. Install Ninja via Homebrew: `brew install ninja`
2. Install GNU coreutils (for `greadlink` in packaging script): `brew install coreutils`
3. Install GNU readline: `brew install readline`
4. Install the data compression tools xz and zlib: `brew install xz zlib`
5. Install Python 3.x: `brew install python`
6. Install Python's pyenv to manage python version: `brew install pyenv`
7. Install Python 2.7.13: `pyenv install 2.7.13`
**Note**: in some cases you might get `Build failed: "ERROR: The Python zlib extension was not compiled. Missing the zlib?"` during Python 2.7.13 installation, this can be fixed by running `CPPFLAGS="-I$(brew --prefix zlib)/include" pyenv install 2.7.13`. 
8. Unlink binutils to use the one provided with Xcode: `brew unlink binutils`
9. Setup `pyenv`:
```sh
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bash_profile
```
8. Set global `python` command to use Python 2.7.13: `pyenv global 2.7.13`.
9. Restart your Terminal

### Build

First, ensure the Xcode application is open. Then, run the following:

```sh
git clone --recurse-submodules https://github.com/ungoogled-software/ungoogled-chromium-macos.git
cd ungoogled-chromium-macos
# Replace TAG_OR_BRANCH_HERE with a tag or branch name
git checkout --recurse-submodules TAG_OR_BRANCH_HERE
./build.sh
```

A `.dmg` should appear in `build/`

**NOTE**: If the build fails, you must take additional steps before re-running the build:

* If the build fails while downloading the Chromium source code, it can be fixed by removing `build/downloads_cache` and re-running the build instructions.
* If the build fails at any other point after downloading, it can be fixed by removing `build/src` and re-running the build instructions. This will clear out all the code used by the build, and any files generated by the build.

## Developer info

### Updating patches

1. Start the process and set the environment variables
```sh
./devutils/update_patches.sh merge
source devutils/set_quilt_vars.sh
```

2. Setup Chromium source
```sh
mkdir -p build/{src,download_cache}
./ungoogled-chromium/utils/downloads.py retrieve -i ungoogled-chromium/downloads.ini downloads.ini -c build/download_cache
./ungoogled-chromium/utils/downloads.py unpack -i ungoogled-chromium/downloads.ini downloads.ini -c build/download_cache build/src
cd build/src
```

3. Use `quilt` to refresh all patches: `while quilt push; do quilt refresh; done`
	* If an error occurs, go to the next step. Otherwise, skip to Step 5.
4. Use `quilt` to fix the broken patch:
    1. Run `quilt push -f`
    2. Edit the broken files as necessary by adding (`quilt edit ...` or `quilt add ...`) or removing (`quilt remove ...`) files as necessary
        * When removing large chunks of code, remove each line instead of using language features to hide or remove the code. This makes the patches less susceptible to breakages when using quilt's refresh command (e.g. quilt refresh updates the line numbers based on the patch context, so it's possible for new but desirable code in the middle of the block comment to be excluded.). It also helps with readability when someone wants to see the changes made based on the patch alone.
    3. Refresh the patch: `quilt refresh`
    4. Go back to Step 3.
5. Run `../../ungoogled-chromium/devutils/validate_config.py`
6. Run `quilt pop -a`

7. Validate that patches are applied correctly
```sh
cd ../..
./ungoogled-chromium/devutils/validate_patches.py -l build/src -s patches/series.merged
```

8. Remove all patches introduced by ungoogled-chromium: `./devutils/update_patches.sh unmerge`

9. Ensure patches/series is formatted correctly, e.g. blank lines

10. Sanity checking for consistency in series file: `./devutils/check_patch_files.sh`

11. Use git to add changes and commit

## License

See [LICENSE](LICENSE)
