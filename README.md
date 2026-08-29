# ungoogled-chromium-macos

macOS packaging for [ungoogled-chromium](//github.com/ungoogled-software/ungoogled-chromium).

## Downloads
[Download binaries from GitHub Releases](//github.com/ungoogled-software/ungoogled-chromium-macos/releases).

Also available in [Homebrew](https://brew.sh/) as [ungoogled-chromium](https://formulae.brew.sh/cask/ungoogled-chromium). Just run `brew install --cask ungoogled-chromium`. Chromium will appear in your /Applications directory.

**Source Code**: It is recommended to use a tag via `git checkout` (see building instructions below). You may also use `master`, but it is for development and may not be stable.

## Announcements

[Depot](https://depot.dev) is now sponsoring us and providing GitHub Action runners for building and packaging releases. This allows us to dramatically accelerate the release cycle. A huge thanks to them.

---

Ungoogled-Chromium macOS builds are now notarized (signed) with an Apple Developer ID! Notarized builds will be provided at least till the end of our 2025-2026 Apple Developer Program membership year, which ends on October 14th 2026.

The notarized binaries distributed in the ungoogled-software/ungoogled-chromium-macos repository are signed with the Apple Developer ID certificate `Developer ID Application: Qian Qian (B9A88FL5XJ)`. You should be able to verify the signature of the binaries after downloading the `.dmg` file, extracting the `.app` file, and running the following command in Terminal:

```sh
spctl -a -vvv -t install path/to/Chromium.app
```

This output should show something like:

```sh
path/to/Chromium.app: accepted
source=Notarized Developer ID
origin=Developer ID Application: Qian Qian (B9A88FL5XJ)
```

that indicates the binary is correctly signed and notarized.

## Sponsorship

A huge thank you to [Depot](https://depot.dev) for sponsoring our macOS building action runners. Their high-performance infrastructure allows us to reduce build times from days to hours, and allows you to get the built binary as quick as other platforms.

Thanks to our 2025-2026 sponsors for their generous support:

- @brucehs (via GitHub Sponsors)
- @vinnysaj (via GitHub Sponsors)
- 3Onion (via By Me a Coffee)

You can also see sponsors for other Apple Membership years on the [issue #184](https://github.com/ungoogled-software/ungoogled-chromium-macos/issues/184).

These contributions made it possible for me to cover the cost of the Apple Developer Program membership and provide notarized builds of Ungoogled-Chromium macOS.

Some of the sponsors have chosen to remain anonymous, but regardless of whether they are listed here or not, all of these sponsorship contributions are greatly appreciated!

New sponsors are still very welcomed, as I am still relying on community sponsors to help me cover the cost of the Apple Developer Program fee for future membership years. The progress of the funding for current and next Apple Developer membership year can be tracked on [issue #184](https://github.com/ungoogled-software/ungoogled-chromium-macos/issues/184). Your support will also greatly encourage and motivate me to continue putting more effort into maintaining and improving Ungoogled-Chromium macOS.

> [!NOTE]
> The prioritized usage of the sponsorship contribution will always be the coverage/securing the Apple Developer Membership fee of the current and the following membership year. However, please acknowledge that, after the current and the next year's membership fees have been fully covered/secured, any donation I receive might be reallocated for other personal purpose.

So, please consider sponsoring me through [GitHub Sponsors](https://github.com/sponsors/Qubik65536) or [Buy me a Coffee](https://buymeacoffee.com/Qubik65536).

Note that these sponsorship accounts are under the name of `Qubik65536`. All sponsor records (i.e. who’s sponsoring) will be public unless you choose to make it private. When sponsoring, you can leave a message specifying that it is for Ungoogled-Chromium, so you will be able to be credited in a sponsor list in the future.

\- @Qubik65536, maintainer of Ungoogled-Chromium macOS

## Building

### Software requirements

* macOS 10.15+
* Xcode 12
* Homebrew
* Perl (for creating a `.dmg` package)
* Node.js

### Setting up the build environment

1. Install Python 3 via Homebrew: `brew install python@3.13` (Python 3.13 or earlier required for the depot_tools)
2. Install `PySocks` and `httplib2` via `pip3`: `pip3 install PySocks httplib2`, note that you might need to use `--break-system-packages` if you don't want to use a dedicated Python environment for building Ungoogled-Chromium.
3. Install Metal toolchain: `xcodebuild -downloadComponent MetalToolchain`
4. Install Ninja via Homebrew: `brew install ninja`
5. Install GNU coreutils and readline via Homebrew: `brew install coreutils readline`
6. Unlink binutils to use the one provided with Xcode: `brew unlink binutils`
7. Install Node.js via Homebrew: `brew install node`
8. Restart your terminal.

### Build

First, ensure the Xcode application is open.

If you want to notarize the build, you need to have an Apple Developer ID and a valid Apple Developer Program membership. You also need to set the following environment variables:

- `MACOS_CERTIFICATE_NAME`: The Full Name of the Developer ID Certificate you created (type `G2 Sub-CA (Xcode 11.4.1 or later)`) in Apple Developer portal, e.g.: Developer ID Application: Your Name (K1234567)
- `PROD_MACOS_NOTARIZATION_APPLE_ID`: The email you used to register your Apple Account and Apple Developer Program
- `PROD_MACOS_NOTARIZATION_TEAM_ID`: Your Apple Developer Team ID, which can be found in the Apple Developer membership page
- `PROD_MACOS_NOTARIZATION_PWD`: An app-specific password generated in the Apple ID account settings

Then, run the following:

```sh
git clone --recurse-submodules https://github.com/ungoogled-software/ungoogled-chromium-macos.git
cd ungoogled-chromium-macos
# Replace TAG_OR_BRANCH_HERE with a tag or branch name
git checkout --recurse-submodules TAG_OR_BRANCH_HERE
```

to switch to the desired release or development branch.

Finally, run the following (if you are building for the same architecture as your Mac, i.e. x86_64 for Intel Macs or arm64 for Apple Silicon Macs, or if you are building for arm64 on an Intel Mac and you set the appropriate build flag):

```sh
./build.sh
```

or, if you want to build for x86_64 on an Apple Silicon Mac:

```sh
./build.sh x86_64
```

If you don't have an Apple Developer ID, you can create an ad-hoc signed build by setting `MACOS_AD_HOC_SIGNING=1`:

```sh
MACOS_AD_HOC_SIGNING=1 ./build.sh
```

The resulting build is not notarized. The same environment variable can be used with `./build.sh x86_64`.

Once it's complete, a `.dmg` should appear in `build/`.

If compilation completed and only signing, notarization, or DMG creation failed,
restart packaging from the repository root without rebuilding Chromium:

```sh
./sign_and_package_app.sh
```

For an ad-hoc signed package, use:

```sh
MACOS_AD_HOC_SIGNING=1 ./sign_and_package_app.sh
```

The regular signing and notarization environment variables listed above must
still be set when creating a notarized package.

**NOTE**: If the build fails, you must take additional steps before re-running the build:

* If the build fails while downloading the Chromium source code, it can be fixed by removing `build/downloads_cache` and re-running the build instructions.
* If the build fails during source preparation or compilation, it can be fixed by removing `build/src` and re-running the build instructions.

## Developer info

### Updating

1. Start the process and set the environment variables

    ```sh
    ./devutils/update_patches.sh merge
    source devutils/set_quilt_vars.sh
    ```

2. Setup Chromium source

    ```sh
    mkdir -p build/{src,download_cache}
    ./retrieve_and_unpack_resource.py --all arm64  # For Apple Silicon Macs
    ./retrieve_and_unpack_resource.py --all x86_64  # For Intel Chip Macs
    ```

    `--all` retrieves both the generic Chromium source and platform-specific
    resources. Use `-g` or `-p` to run only the generic or platform-specific
    phase, respectively.

3. Update Rust toolchain (if necessary)
    1. Check the `RUST_REVISION` constant in file `src/tools/rust/update_rust.py` in build root.
        * As an example, the revision as of writing this guide is `22be76b7e259f27bf3e55eb931f354cd8b69d55f`.
    2. Get date for nightly Rust build from Rust's GitHub repository.
        * The page URL for our example is `https://github.com/rust-lang/rust/commit/22be76b7e259f27bf3e55eb931f354cd8b69d55f`
            1. In this case, the corresponding nightly build date is `2025-06-23`.
            2. Adapt the version number in `downloads-{arm64,x86-64}{,-rustlib}.ini` accordingly.
    3. Get the information of the latest nightly build and adapt configurations accordingly.
       1. Download the latest nightly build from the Rust website.
            * For our example, the download URL for Apple Silicon Macs is `https://static.rust-lang.org/dist/2025-06-23/rust-nightly-aarch64-apple-darwin.tar.gz`
            * For our example, the download URL for Intel Chip Macs is `https://static.rust-lang.org/dist/2025-06-23/rust-nightly-x86_64-apple-darwin.tar.gz`
       2. Extract the archive.
       3. Adapt the content of `patches/ungoogled-chromium/macos/fix-build-with-rust.patch` with the output of `rustc/bin/rustc -V | tr -dc '[:alnum:]'`
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
