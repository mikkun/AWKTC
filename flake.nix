{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    eachSystem allSystems (system:
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
