{
  description = "GoToSocial binary release";
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ... }:
  let
    version = "0.5.2";
  in {
    packages."x86_64-linux".default = with import nixpkgs { system="x86_64-linux"; };
    stdenv.mkDerivation {
        name = "gotosocial-bin";
        version = version;
        src = fetchurl {
            url = "https://github.com/superseriousbusiness/gotosocial/releases/download/v${version}/gotosocial_${version}_linux_amd64.tar.gz";
            sha256 = "sha256-RPk75QVkbhsUSJYDK+03mErPHcOgQ1s7t7vINUoGNps=";
        };
        sourceRoot = ".";

        buildPhase = ""; # nothing

        installPhase = ''
            mkdir -p $out/bin
            install -t $out/bin gotosocial
            mkdir -p $out/web
            cp -R web/* $out/web
        '';
    };

    nixosModules.default = (import ./nixosModule.nix self);
  };

}
