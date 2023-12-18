{
  description = "Base nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    # To successfully flash the firmware of the onboard fingerprint reader on
    # Ryzen 7040 framework laptops, we need version 1.9.7 of fwupd. See
    # https://knowledgebase.frame.work/en_us/updating-fingerprint-reader-firmware-on-linux-for-13th-gen-and-amd-ryzen-7040-series-laptops-HJrvxv_za
    # for more info.
    nixpkgs-old-fwupd.url =
      "github:NixOS/nixpkgs/a845c1b2d62614f80de711d7cecbd0688c53429e";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware quirks
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosModules.default = { pkgs, ... }:
      let
        fwupd-old =
          (import inputs.nixpkgs-old-fwupd { system = pkgs.system; }).fwupd;
      in {
        # Default settings
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        networking.networkmanager.enable = true;

        # Enable firmware upgrade and fingerprint services
        services.fwupd.enable = true;
        services.fwupd.package = fwupd-old;

        services.fprintd.enable = true;

        environment.systemPackages = [
          # General tooling
          pkgs.git
          pkgs.nixfmt
          pkgs.vim # I mean, it's better than nano
        ];
      };

    # Module for 13-inch Ryzen 7040 framework hardware quirks
    nixosModules.framework-13-7040-amd =
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd;
  };
}
