{
  description = "Hello rust flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [(import rust-overlay)];
      pkgs = import nixpkgs {inherit system overlays;};
      rust = pkgs.rust-bin.stable.latest.default.override {
        extensions = ["rust-src" "llvm-tools-preview"];
        targets = ["x86_64-unknown-linux-musl"];
      };
      rustPlatform = pkgs.makeRustPlatform {
        rustc = rust;
        cargo = rust;
      };
    in {
      packages = rec {
        hello = rustPlatform.buildRustPackage rec {
          pname = "hello";
          version = "0.1.0";

          src = ./.;
          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          doCheck = true;

          env = {};
        };

        default = hello;
      };
      apps = rec {
        ip = flake-utils.lib.mkApp {
          drv = self.packages.${system}.hello;
          exePath = "/bin/flake-hello";
        };
        default = ip;
      };
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [rust];
        shellHook = ''
          export CARGO_HOME=$(pwd)/cargo
        '';
      };
    });
}
