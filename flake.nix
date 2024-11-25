{
  description = "Development shell for peregrine";

  # Nixpkgs version to use
  inputs.nixpkgs.url = "nixpkgs/nixos-24.05";
  outputs = {
    self,
    nixpkgs,
  }: let
    # System types to support.
    # I have only ever tested this on x86_64-linux, so we limit to that.
    supportedSystems = ["x86_64-linux"]; # "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    # This flake does not provide any packages
    packages = {
    };

    # This flake does not provide any packages, so it cannot have apps
    # either.
    # apps is meant to play with the "nix run" command.
    apps = {};

    # What we really want
    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};


      peregrineNativeBuildInputs = with pkgs; [
        # ChipYard Dependencies
        binutils
        cmake
        wget
        git
        bash
        gcc
        unittest-cpp
        (python311.withPackages (ps: [
          ps.jsonschema
          ps.numpy
        ]))

      ];
    in {
      default = pkgs.mkShell {
        nativeBuildInputs = peregrineNativeBuildInputs;
        modules = [
        ];
        buildInputs = with pkgs; [
          bashInteractive
          zlib
          #"llvmPackages_${llvmVersion}".clang-tools
          #"llvmPackages_${llvmVersion}".libstdcxxClang
          #"llvm_${llvmVersion}"

          llvmPackages.clang-tools
          llvmPackages.libstdcxxClang
          llvm

        ];

        # Ensure locales are present
        LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";

        hardeningDisable = ["all"];

        shellHook = ''
          # Unset $OBJCOPY for compiling glibc-based RISC-V toolchain
          unset OBJCOPY
          unset OBJDUMP
        '';
      };
    });
  };
}
