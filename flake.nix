{
  description = "Base nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
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
    nixosModules.default = { pkgs, ... }: {
      environment.systemPackages = [
        # General tooling
        pkgs.git
        pkgs.nixfmt
      ];
    };

    # Module for 13-inch Ryzen 7040 framework hardware quirks
    nixosModules.framework-13-7040-amd =
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd;
  };
}
