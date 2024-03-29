{
  description =
    "AWKTC is a Tetris-like tile-matching puzzle game written in AWK.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = "1.2.1";
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "awktc";
          inherit version;
          src = pkgs.fetchFromGitHub {
            owner = "mikkun";
            repo = "AWKTC";
            rev = "v${version}";
            hash = "sha256-m6CsdtuUtUUtjhzs0rKXp+1A2KQgJtBaWnK2pK8L/rc=";
          };

          nativeBuildInputs =
            builtins.attrValues { inherit (pkgs) makeWrapper; };
          buildInputs = builtins.attrValues { inherit (pkgs) gawk; };

          installPhase = ''
            install -Dm 755 "awktc.awk" "$out/bin/awktc"
          '';

          postFixup = ''
            wrapProgram "$out/bin/awktc" \
              --set PATH ${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.gawk ]};
          '';
        };
      });
}
