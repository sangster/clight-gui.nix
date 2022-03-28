{
  description = "Qt GUI for clight";

  inputs = {
    flake-utils = {
      url = github:numtide/flake-utils?rev=74f7e4319258e287b0f9cb95426c9853b282730b;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    upstream = {
      url = github:nullobsi/clight-gui?rev=f60189909f5eb4ce2e2bcfea591ffa5e598d6668;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, upstream }:
    let
      pname = "clight-gui";
      version = "5.5-f601899";

      isLinux = nixpkgs.lib.hasSuffix "-linux";
      systems = builtins.filter isLinux nixpkgs.lib.platforms.all;

      overlay = final: prev: rec {
        clight-gui =
          let
            qt = final.qt5;
            desktop-entry = ''
              [Desktop Entry]
              Type=Application
              Icon=clight
              Name=Clight GUI
              Exec=$out/bin/clight-gui
              Terminal=false
              Hidden=false
              Categories=Utility
              Comment=Qt GUI for Clight
            '';
          in prev.stdenv.mkDerivation {
            inherit pname version;
            src = upstream;

            nativeBuildInputs = with final; with qt; [ cmake wrapQtAppsHook qttools ];
            buildInputs = with qt; [ qtbase qtcharts ];

            cmakeFlags = [
              "-S ../src"
              "-Wno-dev"
              "-DCMAKE_BUILD_TYPE=Release"
              "-DGENERATE_TRANSLATIONS=ON"
            ];

            postInstall = ''
              mkdir -p "$out/share/applications"
              cat >>"$out/share/applications/${pname}.desktop" <<_EOF
                ${desktop-entry}
              _EOF
            '';
          };
      };
    in
    { inherit overlay; } //
    flake-utils.lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
      in rec {
        defaultPackage = packages.clight-gui;
        packages.clight-gui = pkgs.clight-gui;
      }
    );
}
