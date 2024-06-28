{
  description = "Base nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # To successfully flash the firmware of the onboard fingerprint reader on
    # Ryzen 7040 framework laptops, we need version 1.9.7 of fwupd. See
    # https://knowledgebase.frame.work/en_us/updating-fingerprint-reader-firmware-on-linux-for-13th-gen-and-amd-ryzen-7040-series-laptops-HJrvxv_za
    # for more info.
    nixpkgs-old-fwupd.url =
      "github:NixOS/nixpkgs/a845c1b2d62614f80de711d7cecbd0688c53429e";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
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
    nixosModules.default = { lib, pkgs, ... }:
      let
        fwupd-old =
          (import inputs.nixpkgs-old-fwupd { system = pkgs.system; }).fwupd;

        awsudo = pkgs.writeShellScriptBin "awsudo" ''
          exec ${pkgs.aws-vault}/bin/aws-vault exec \
            --duration="''${SUDO_DURATION:-1h}" "''${SUDO_ROLE:-sudo}" -- "$@"
        '';
      in {
        # Default settings
        boot.loader.systemd-boot.enable = true;
        boot.loader.systemd-boot.memtest86.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.networkmanager.enable = true;

        # Bit of an assumption, but overridable
        i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

        # Enable firmware upgrade and fingerprint services
        services.fwupd = {
          enable = true;
          package = fwupd-old;
        };
        services.fprintd.enable = true;

        # We want graphics!
        services.xserver = {
          enable = true;
          layout = lib.mkDefault "us";
          xkbVariant = lib.mkDefault "";
          videoDrivers = [ "amdgpu" ];
        };

        # Setup gnome, may want to make this configurable
        services.xserver.displayManager.gdm.enable = true;
        services.xserver.desktopManager.gnome.enable = true;

        # Printing is always nice
        services.printing.enable = true;

        # Sound, too
        sound.enable = true;
        hardware.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        environment.systemPackages = with pkgs; [
          # General tooling
          git
          vim # I mean, it's better than nano

          # Nix related tools
          nixfmt
          niv
          nix-tree
          comma
          cachix

          # AWS related tooling
          awscli2
          aws-vault
          awsudo
        ];

        # We use tailscale!
        services.tailscale = {
          enable = true;
          useRoutingFeatures = "client";
        };

        nix.settings = {
          experimental-features = [ "nix-command" "flakes" ];
          substituters = [ "https://cache.nixos.org" "https://nri.cachix.org" ];
          trusted-public-keys =
            [ "nri.cachix.org-1:9/BMj3Obc+uio3O5rYGT+egHzkBzDunAzlZZfhCGj6o=" ];
        };
      };

    # Module for 13-inch Ryzen 7040 framework hardware quirks
    nixosModules.framework-13-7040-amd =
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd;
  };
}
