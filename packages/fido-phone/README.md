# Fido Phone

Fido Phone is Evy's personal macOS-to-Android bridge for FIDO hybrid
authentication. The package builds the native macOS helper and Android APK,
then wraps the user commands so they consume those packaged artifacts instead
of compiling source from the home directory.

The local workstation setup installs `.#fido-phone` into the macOS Nix profile.
Run `fido-phone-install-android` once to install the receiver and provision its
shared token, then invoke `fido-phone` through the configured Kanata binding.

The application is personal software rather than a distributable security
product. Its authorization boundary is the separately generated shared token
and personally controlled delivery path. See
[`signing/README.md`](signing/README.md) for the deliberately public APK-signing
policy and its tradeoff.
