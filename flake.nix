{
  description = "Dev environment for 'coreblocks' development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # riscv-none-elf toolchain
        riscvPkgs = pkgs.pkgsCross.riscv64-embedded;

        riscvGcc = riscvPkgs.buildPackages.gcc;
        riscvBinutils = riscvPkgs.buildPackages.binutils;

        riscvCompat = pkgs.runCommand "riscv64-unknown-elf-compat" { } ''
          mkdir -p $out/bin
          for pkg in ${riscvGcc} ${riscvBinutils}; do
            for bin in "$pkg"/bin/riscv64-none-elf-*; do
              if [ -e "$bin" ]; then
                base="$(basename "$bin")"
                alias_name="$(echo "$base" | sed 's/riscv64-none-elf-/riscv64-unknown-elf-/')"
                ln -sf "$bin" "$out/bin/$alias_name" || true
              fi
            done
          done
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cmake
            llvmPackages_22.clang-tools

            python313
            python313Packages.pip
          ];

          nativeBuildInputs = [
            riscvGcc
            riscvBinutils
            riscvCompat
          ];

          shellHook = ''
            if [ ! -d ".venv" ]; then
              echo "Setting up Python virtual environment..."
              python3 -m venv .venv
            fi

            source .venv/bin/activate
          '';
        };
      }
    );
}
