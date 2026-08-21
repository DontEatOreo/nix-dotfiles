{
  android-tools,
  androidenv,
  coreutils,
  gawk,
  gradle_9,
  jdk21,
  lib,
  makeWrapper,
  openssl,
  swiftPackages,
}:

let
  inherit (swiftPackages) stdenv swift;
  gradle = gradle_9.override { java = jdk21; };
  androidSdk =
    (androidenv.composeAndroidPackages {
      buildToolsVersions = [ "36.0.0" ];
      includeCmake = false;
      includeEmulator = false;
      includeNDK = false;
      includeSystemImages = false;
      platformVersions = [ "36" ];
    }).androidsdk;
  runtimePath = lib.makeBinPath [
    android-tools
    coreutils
    gawk
    openssl
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "fido-phone";
  version = "1";

  src = lib.fileset.toSource {
    root = ../dotfiles/dot_local;
    fileset = lib.fileset.unions [
      ../dotfiles/dot_local/bin/executable_fido-phone
      ../dotfiles/dot_local/bin/executable_fido-phone-install-android
      ../dotfiles/dot_local/libexec/fido-phone
      ../dotfiles/dot_local/share/fido-phone
    ];
  };

  strictDeps = true;

  nativeBuildInputs = [
    gradle
    jdk21
    makeWrapper
    swift
  ];

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    data = ./fido-phone-deps.json;
    pkg = finalAttrs.finalPackage;
  };
  __darwinAllowLocalNetworking = true;

  gradleUpdateScript = ''
    export ANDROID_USER_HOME="$TMPDIR/android"
    mkdir -p "$ANDROID_USER_HOME"
    gradle \
      --no-daemon \
      --console=plain \
      -p share/fido-phone/android \
      :app:assembleRelease
  '';

  ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
  JAVA_HOME = jdk21;

  buildPhase = ''
    runHook preBuild

    swiftc \
      -O \
      -parse-as-library \
      -swift-version 5 \
      -warnings-as-errors \
      -framework AppKit \
      -framework ImageIO \
      -framework Network \
      -framework ScreenCaptureKit \
      -framework Vision \
      -o fido-phone-helper \
      libexec/fido-phone/FidoPhone.swift

    export ANDROID_USER_HOME="$TMPDIR/android"
    mkdir -p "$ANDROID_USER_HOME"
    gradle \
      --no-daemon \
      --console=plain \
      -p share/fido-phone/android \
      :app:assembleRelease

    ${lib.getExe openssl} pkey \
      -in ${./fido-phone-signing-key.pem} \
      -outform DER \
      -out fido-phone-signing-key.der
    "$ANDROID_HOME/build-tools/36.0.0/apksigner" sign \
      --key fido-phone-signing-key.der \
      --cert ${./fido-phone-signing-cert.pem} \
      --out fido-phone.apk \
      share/fido-phone/android/app/build/outputs/apk/release/app-release-unsigned.apk

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 fido-phone-helper $out/libexec/fido-phone-helper
    install -Dm644 fido-phone.apk $out/share/fido-phone/fido-phone.apk
    install -Dm755 bin/executable_fido-phone $out/bin/fido-phone
    install -Dm755 \
      bin/executable_fido-phone-install-android \
      $out/bin/fido-phone-install-android

    wrapProgram $out/bin/fido-phone \
      --set FIDO_PHONE_HELPER $out/libexec/fido-phone-helper \
      --prefix PATH : ${runtimePath}
    wrapProgram $out/bin/fido-phone-install-android \
      --set FIDO_PHONE_APK $out/share/fido-phone/fido-phone.apk \
      --prefix PATH : ${runtimePath}

    runHook postInstall
  '';

  meta = {
    description = "macOS-to-Android bridge for FIDO hybrid-authentication QR codes";
    license = lib.licenses.mit;
    mainProgram = "fido-phone";
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode
    ];
  };
})
