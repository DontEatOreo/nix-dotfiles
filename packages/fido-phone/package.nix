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
    root = ./src;
    fileset = ./src;
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
    data = ./deps.json;
    pkg = finalAttrs.finalPackage;
  };
  __darwinAllowLocalNetworking = true;

  gradleUpdateScript = ''
    export ANDROID_USER_HOME="$TMPDIR/android"
    mkdir -p "$ANDROID_USER_HOME"
    gradle \
      --no-daemon \
      --console=plain \
      -p android \
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
      macos/FidoPhone.swift

    export ANDROID_USER_HOME="$TMPDIR/android"
    mkdir -p "$ANDROID_USER_HOME"
    gradle \
      --no-daemon \
      --console=plain \
      -p android \
      :app:assembleRelease

    ${lib.getExe openssl} pkey \
      -in ${./signing/personal-signing-key.pem} \
      -outform DER \
      -out fido-phone-signing-key.der
    "$ANDROID_HOME/build-tools/36.0.0/apksigner" sign \
      --key fido-phone-signing-key.der \
      --cert ${./signing/certificate.pem} \
      --out fido-phone.apk \
      android/app/build/outputs/apk/release/app-release-unsigned.apk

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 fido-phone-helper $out/libexec/fido-phone-helper
    install -Dm644 fido-phone.apk $out/share/fido-phone/fido-phone.apk
    install -Dm755 bin/fido-phone $out/bin/fido-phone
    install -Dm755 \
      bin/fido-phone-install-android \
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
    homepage = "https://github.com/4evy/dotfiles";
    license = lib.licenses.mit;
    mainProgram = "fido-phone";
    maintainers = [ lib.maintainers._4evy ];
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode
    ];
  };
})
