{
  description = "Arkenfox user.js home-manager module";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";

  inputs.arkenfox-userjs = {
    url = "github:arkenfox/user.js/119.0";
    flake = false;
  };

  outputs = { self, nixpkgs, arkenfox-userjs }@inputs:
    let
      # System types to support.
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });

    in {
      # A Nixpkgs overlay.
      overlay = final: prev: {

        prefsCleaner = with final;
          stdenv.mkDerivation rec {
            pname = "prefsCleaner";

            version = "1.6";

            src = arkenfox-userjs;

            patches =
              [ ./do-not-auto-update.patch ./do-not-change-directory.patch ];

            installPhase = ''
              mkdir -p $out/bin
              cp prefsCleaner.sh $out/bin/prefsCleaner
              chmod +x $out/bin/prefsCleaner
            '';
          };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems
        (system: { inherit (nixpkgsFor.${system}) prefsCleaner; });

      hmModule = import ./hm.nix inputs;
    };
}
