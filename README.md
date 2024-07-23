# ungoogled-chromium-macos

macOS packaging for [ungoogled-chromium](//github.com/Eloston/ungoogled-chromium).

## Downloads

[Download binaries from the Contributor Binaries website](//ungoogled-software.github.io/ungoogled-chromium-binaries/).

**Source Code**: It is recommended to use a tag via `git checkout` (see building instructions below). You may also use `master`, but it is for development and may not be stable.

## Building

### Software requirements

* macOS 10.15+
* Xcode 12
* Homebrew
* Perl (for creating a `.dmg` package)
* Node.js

### Setting up the build environment

1. Install Ninja via Homebrew: `brew install ninja`
2. Install GNU coreutils (for `greadlink` in packaging script): `brew install coreutils`
3. Install GNU readline: `brew install readline`
4. Install the data compression tools xz and zlib: `brew install xz zlib`
5. Unlink binutils to use the one provided with Xcode: `brew unlink binutils`
6. Install Node.js: `brew install node`
7. Restart your Terminal

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
* If the build fails at any other point after downloading, it can be fixed by removing `build/src` and re-running the build instructions.

## Developer info

### Updating

1. Start the process and set the environment variables

    ```sh
    ./devutils/update_patches.sh merge
    bash
    source devutils/set_quilt_vars.sh
    ```

2. Setup Chromium source

    ```sh
    mkdir -p build/{src,download_cache}
    ./retrieve_and_unpack_resource.sh -g -p
    ```

3. Update Rust toolchain (if necessary)
    1. Check the `RUST_VERSION` constant in file `src/tools/rust/update_rust.py` in build root.
        * As an example, the revision as of writing this guide is `340bb19fea20fd5f9357bbfac542fad84fc7ea2b`.
    2. Get date for nightly Rust build from Rust's GitHub repository.
        * The page URL for our example is `https://github.com/rust-lang/rust/commit/340bb19fea20fd5f9357bbfac542fad84fc7ea2b`
            1. In this case, the corresponding nightly build date is `2024-02-14`.
            2. Adapt the version number in `downloads-arm64.ini` and `downloads-x86_64.ini` accordingly.
    3. Get the information of the latest nightly build and adapt configurations accordingly.
       1. Download the latest nightly build from the Rust website.
            * For our example, the download URL for Apple Silicon Macs is `https://static.rust-lang.org/dist/2024-02-14/rust-nightly-aarch64-apple-darwin.tar.gz`
            * For our example, the download URL for Intel Chip Macs is `https://static.rust-lang.org/dist/2024-02-14/rust-nightly-x86_64-apple-darwin.tar.gz`
       2. Extract the archive.
       3. Execute `rustc/bin/rustc -V` in the extracted directory to get Rust version string.
            * For our example, the version string is `rustc 1.78.0-nightly (a84bb95a1 2024-02-13)`.
       4. Adapt the content of `retrieve_and_unpack_resource.sh` and `patches/ungoogled-chromium/macos/fix-build-with-rust.patch` accordingly.
4. Switch to src directory

    ```sh
    cd build/src
    ```

5. Use `quilt` to refresh all patches: `quilt push -a --refresh`
   * If an error occurs, go to the next step. Otherwise, skip to Step 7.
6. Use `quilt` to fix the broken patch:
    1. Run `quilt push -f`
    2. Edit the broken files as necessary by adding (`quilt edit ...` or `quilt add ...`) or removing (`quilt remove ...`) files as necessary
        * When removing large chunks of code, remove each line instead of using language features to hide or remove the code. This makes the patches less susceptible to breakages when using quilt's refresh command (e.g. quilt refresh updates the line numbers based on the patch context, so it's possible for new but desirable code in the middle of the block comment to be excluded.). It also helps with readability when someone wants to see the changes made based on the patch alone.
    3. Refresh the patch: `quilt refresh`
    4. Go back to Step 5.
7. Run `../../ungoogled-chromium/devutils/validate_config.py`
8. Run `quilt pop -a`
9. Validate that patches are applied correctly

    ```sh
    cd ../..
    ./ungoogled-chromium/devutils/validate_patches.py -l build/src -s patches/series.merged
    ```

10. Remove all patches introduced by ungoogled-chromium: `./devutils/update_patches.sh unmerge`
11. Ensure patches/series is formatted correctly, e.g. blank lines
12. Sanity checking for consistency in series file: `./devutils/check_patch_files.sh`
13. Use git to add changes and commit

## License

See [LICENSE](LICENSE)
