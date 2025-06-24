# ungoogled-chromium-macos

macOS packaging for [ungoogled-chromium](//github.com/Eloston/ungoogled-chromium).

## Downloads

[Download binaries from the Contributor Binaries website](//ungoogled-software.github.io/ungoogled-chromium-binaries/).

**Source Code**: It is recommended to use a tag via `git checkout` (see building instructions below). You may also use `master`, but it is for development and may not be stable.

## Announcements

Ungoogled-Chromium macOS builds are now notarized (signed) with an Apple Developer ID! Notarized builds will be provided at least till the end of our 2024-2025 Apple Developer Program membership year, which ends on October 14th 2025.

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

Thanks to our 2024-2025 sponsors for their generous support:

- @pascal-giguere (via GitHub Sponsors)
- @kevingriffin (via GitHub Sponsors)
- BabyFn0rd (via By Me a Coffee)
- dasos (via By Me a Coffee)
- @vinnysaj (via GitHub Sponsors)

You can also see sponsors for other Apple Membership years on the [issue #184](https://github.com/ungoogled-software/ungoogled-chromium-macos/issues/184).

These contributions made it possible for me to cover the cost of the Apple Developer Program membership and provide notarized builds of Ungoogled-Chromium macOS.

Some of the sponsors have chosen to remain anonymous, but regardless of whether they are listed here or not, all of these sponsorship contributions are greatly appreciated!

New sponsors are still very welcomed, as I am still relying on community sponsors to help me cover the cost of the Apple Developer Program fee for future membership years. The progress of the funding for current and next Apple Developer membership year can be tracked on [issue #184](https://github.com/ungoogled-software/ungoogled-chromium-macos/issues/184). Your support will also greatly encourage and motivate me to continue putting more effort into maintaining and improving Ungoogled-Chromium macOS.

> [!NOTE]
> The prioritized usage of the sponsorship contribution will always be the coverage/securing the Apple Developer Membership fee of the current and the following membership year. However, please acknowledge that, after the current and the next year's membership fees have been fully covered/secured, any donation I receive might be reallocated for other personal purpose.

So, please consider sponsoring me through [GitHub Sponsors](https://github.com/sponsors/Cubik65536) or [Buy me a Coffee](https://buymeacoffee.com/cubik65536).

Note that these sponsorship accounts are under the name of `Cubik65536`. All sponsor records (i.e. who’s sponsoring) will be public unless you choose to make it private. When sponsoring, you can leave a message specifying that it is for Ungoogled-Chromium, so you will be able to be credited in a sponsor list in the future.

\- @Cubik65536, maintainer of Ungoogled-Chromium macOS

## Building

### Software requirements

* macOS 10.15+
* Xcode 12
* Homebrew
* Perl (for creating a `.dmg` package)
* Node.js

### Setting up the build environment

1. Install Python 3 via Homebrew: `brew install python@3`
2. Install `httplib2` via `pip3`: `pip3 install httplib2`, note that you might need to use `--break-system-packages` if you don't want to use a dedicated Python environment for building Ungoogled-Chromium.
3. Install LLVM via Homebrew: `brew install llvm`, and set `LDFLAGS` and `CPPFLAGS` environment variables according to the Homebrew prompt.
4. Install Ninja via Homebrew: `brew install ninja`
5. Install GNU coreutils and readline via Homebrew: `brew install coreutils readline`
6. Install the data compression tools xz and zlib via Homebrew: `brew install xz zlib`
7. Unlink binutils to use the one provided with Xcode: `brew unlink binutils`
8. Install Node.js via Homebrew: `brew install node`
9. Restart your terminal.

**NOTE**: If you are building for x86_64 Mac from an Apple Silicon (arm64) Mac, you might need to install Rosetta 2 and these tools from x86_64 Homebrew, as well as setting `PATH` variables to use the x86_64 tools.

### Build

First, ensure the Xcode application is open.

If you want to notarize the build, you need to have an Apple Developer ID and a valid Apple Developer Program membership. You also need to set the following environment variables:

- `MACOS_CERTIFICATE_NAME`: The Full Name of the Developer ID Certificate you created (type `G2 Sub-CA (Xcode 11.4.1 or later)`) in Apple Developer portal, e.g.: Developer ID Application: Your Name (K1234567)
- `PROD_MACOS_NOTARIZATION_APPLE_ID`: The email you used to register your Apple Account and Apple Developer Program
- `PROD_MACOS_NOTARIZATION_TEAM_ID`: Your Apple Developer Team ID, which can be found in the Apple Developer membership page
- `PROD_MACOS_NOTARIZATION_PWD`: An app-specific password generated in the Apple ID account settings

If you don't have an Apple Developer ID to sign the build (or you don't want to sign it), you can comment the following parts in `build.sh`:

```sh
# Sign the binary
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier chrome_crashpad_handler --options=restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/chrome_crashpad_handler
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.helper --options restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper.app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.helper.renderer --options restrict,kill,runtime --entitlements $_root_dir/entitlements/helper-renderer-entitlements.plist out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper\ \(Renderer\).app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.helper --options restrict,kill,runtime --entitlements $_root_dir/entitlements/helper-gpu-entitlements.plist out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper\ \(GPU\).app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.helper.plugin --options restrict,kill,runtime --entitlements $_root_dir/entitlements/helper-plugin-entitlements.plist out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper\ \(Plugin\).app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.framework.AlertNotificationService --options restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper\ \(Alerts\).app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier app_mode_loader --options restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/app_mode_loader
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier web_app_shortcut_copier --options restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/web_app_shortcut_copier
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier libEGL out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Libraries/libEGL.dylib
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier libGLESv2 out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Libraries/libGLESv2.dylib
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier libvk_swiftshader out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Libraries/libvk_swiftshader.dylib
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.framework out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium --options restrict,library,runtime,kill --entitlements $_root_dir/entitlements/app-entitlements.plist --requirements '=designated => identifier "io.ungoogled-software.ungoogled-chromium" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */' out/Default/Chromium.app

# Verify the binary signature
codesign --verify --deep --verbose=4 out/Default/Chromium.app

# Pepare app notarization
ditto -c -k --keepParent "out/Default/Chromium.app" "notarize.zip"

# Notarize the app
xcrun notarytool store-credentials "notarytool-profile" --apple-id "$PROD_MACOS_NOTARIZATION_APPLE_ID" --team-id "$PROD_MACOS_NOTARIZATION_TEAM_ID" --password "$PROD_MACOS_NOTARIZATION_PWD"
xcrun notarytool submit "notarize.zip" --keychain-profile "notarytool-profile" --wait
xcrun stapler staple "out/Default/Chromium.app"
```

and uncomment the following part:

```sh
# codesign --force --deep --sign - out/Default/Chromium.app
```

to use ad-hoc signing.

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

Once it's complete, a `.dmg` should appear in `build/`.

**NOTE**: If the build fails, you must take additional steps before re-running the build:

* If the build fails while downloading the Chromium source code, it can be fixed by removing `build/downloads_cache` and re-running the build instructions.
* If the build fails at any other point after downloading, it can be fixed by removing `build/src` and re-running the build instructions.

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
    ./retrieve_and_unpack_resource.sh -g arm64  # For Apple Silicon Macs
    ./retrieve_and_unpack_resource.sh -p arm64  # For Apple Silicon Macs
    ./retrieve_and_unpack_resource.sh -g x86_64  # For Intel Chip Macs
    ./retrieve_and_unpack_resource.sh -p x86_64  # For Intel Chip Macs
    ```

3. Update Rust toolchain (if necessary)
    1. Check the `RUST_REVISION` constant in file `src/tools/rust/update_rust.py` in build root.
        * As an example, the revision as of writing this guide is `4a0969e06dbeaaa43914d2d00b2e843d49aa3886`.
    2. Get date for nightly Rust build from Rust's GitHub repository.
        * The page URL for our example is `https://github.com/rust-lang/rust/commit/4a0969e06dbeaaa43914d2d00b2e843d49aa3886`
            1. In this case, the corresponding nightly build date is `2024-05-05`.
            2. Adapt the version number in `downloads-{arm64,x86-64}{,-rustlib}.ini` accordingly.
    3. Get the information of the latest nightly build and adapt configurations accordingly.
       1. Download the latest nightly build from the Rust website.
            * For our example, the download URL for Apple Silicon Macs is `https://static.rust-lang.org/dist/2024-05-05/rust-nightly-aarch64-apple-darwin.tar.gz`
            * For our example, the download URL for Intel Chip Macs is `https://static.rust-lang.org/dist/2024-05-05/rust-nightly-x86_64-apple-darwin.tar.gz`
       2. Extract the archive.
       3. Execute `rustc/bin/rustc -V` in the extracted directory to get Rust version string.
            * For our example, the version string is `rustc 1.88.0-nightly (13e879094 2025-05-04)`.
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
