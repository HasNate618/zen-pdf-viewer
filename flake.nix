{
  description = "Keyboard-first PDF viewer built on PDF.js";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      version = self.shortRev or self.dirtyShortRev or "unstable";
      src = nixpkgs.lib.cleanSourceWith {
        src = self;
        filter =
          path: type:
          let
            name = baseNameOf path;
            str = toString path;
          in
          type == "directory"
          || name == "viewer.html"
          || name == "launch.sh"
          || name == "zen-server.py"
          || name == "vendor"
          || nixpkgs.lib.hasInfix "/vendor/" str;
      };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./package.nix {
            inherit src version;
          };
          zen-pdf-viewer = pkgs.callPackage ./package.nix {
            inherit src version;
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          pkg = self.packages.${system}.default;
        in
        {
          default = {
            type = "app";
            program = "${pkg}/bin/zen-pdf-viewer";
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.python3
              pkgs.curl
            ];
            shellHook = ''
              echo "Run: python3 -m http.server 8000 --bind 127.0.0.1"
              echo "Open: http://127.0.0.1:8000/viewer.html?file=/tmp/doc.pdf"
            '';
          };
        }
      );
    };
}
