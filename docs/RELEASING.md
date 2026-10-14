# Releasing

## Build an installer

On a Mac with the documented development toolchain:

```sh
zsh scripts/test.sh
zsh scripts/build-dmg.sh
```

The script builds arm64 and x86_64 executables, combines them into a universal app, and packages `dist/EasyRec-<version>-universal.dmg`. The version comes from `Resources/Info.plist`. The disk image contains the app, an Applications shortcut, installation instructions, and the MIT license.

`build-app.sh --universal` builds each architecture in its own SwiftPM scratch directory to keep the products separate. The ordinary development command remains `zsh scripts/build-app.sh`.

## Signing status

The current DMG script ad-hoc signs its staged application and checks that the bundle signature is valid. This is not a Developer ID signature or Apple notarization. The release notes and download documentation must state that limitation. See [Apple's guidance](https://support.apple.com/102445) for the first-launch behavior.

A future notarized release requires a Developer ID Application certificate and access to Apple's notary service. The current script does not perform notarization.

## Publish to GitHub

Update the version, build number, changelog, and download links for each release. Build the DMG and check installation before publishing. Commit the release changes, create the matching `v<version>` tag, and push both.

Write release notes that include the macOS requirement, supported architectures, installation steps, signing status, and relevant test limits. Publish the tagged version with GitHub CLI:

```sh
gh release create v0.1.0 dist/EasyRec-0.1.0-universal.dmg \
    --verify-tag --title "EasyRec 0.1.0" --notes-file release-notes.md
```

After publication, confirm that the release asset is uploaded and the README download link points to it. Generated apps and installers stay out of Git.
