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
    cp zen-server.py "$out/share/zen-pdf-viewer/"
    cp -r vendor "$out/share/zen-pdf-viewer/"
    cp launch.sh "$out/bin/zen-pdf-viewer"
    chmod +x "$out/bin/zen-pdf-viewer"

    wrapProgram "$out/bin/zen-pdf-viewer" \
      --set ZEN_PDF_VIEWER_DATA_DIR "$out/share/zen-pdf-viewer" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}

    # Desktop entry (Linux)
    mkdir -p "$out/share/applications"
    cat > "$out/share/applications/zen-pdf-viewer.desktop" <<EOF
[Desktop Entry]
Name=Zen PDF Viewer
Exec=$out/bin/zen-pdf-viewer %U
Terminal=false
Type=Application
MimeType=application/pdf;
Categories=Office;Viewer;Utility;
EOF

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
