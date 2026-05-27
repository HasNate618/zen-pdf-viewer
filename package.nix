{
  lib,
  stdenv,
  python3,
  curl,
  xdg-utils,
  makeWrapper,
  src,
  version ? "unstable",
}:

let
  runtimeInputs =
    with lib;
    [ python3 curl ]
    ++ optional stdenv.isLinux xdg-utils;
in

stdenv.mkDerivation {
  pname = "zen-pdf-viewer";
  inherit version src;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = runtimeInputs;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/zen-pdf-viewer" "$out/bin"
    cp viewer.html "$out/share/zen-pdf-viewer/"
    cp launch.sh "$out/bin/zen-pdf-viewer"

    wrapProgram "$out/bin/zen-pdf-viewer" \
      --set ZEN_PDF_VIEWER_DATA_DIR "$out/share/zen-pdf-viewer" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Keyboard-first PDF viewer built on PDF.js";
    homepage = "https://github.com/HasNate618/zen-pdf-viewer";
    license = licenses.free;
    platforms = platforms.unix;
    mainProgram = "zen-pdf-viewer";
  };
}
