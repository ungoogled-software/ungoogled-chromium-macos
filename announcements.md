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
