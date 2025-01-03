{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ags,
    astal,
  }: let
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
      "aarch64-linux"
    ];
    forEachSystem = nixpkgs.lib.genAttrs systems;

    mkExtraPackages = system: pkgs: [
      ags.packages.${system}.agsFull
      astal.packages.${system}.tray
      astal.packages.${system}.hyprland
      astal.packages.${system}.io
      astal.packages.${system}.apps
      astal.packages.${system}.battery
      astal.packages.${system}.bluetooth
      astal.packages.${system}.mpris
      astal.packages.${system}.network
      astal.packages.${system}.notifd
      astal.packages.${system}.powerprofiles
      astal.packages.${system}.wireplumber
      pkgs.fish
      pkgs.typescript
      pkgs.libnotify
      pkgs.dart-sass
      pkgs.fd
      pkgs.btop
      pkgs.bluez
      pkgs.libgtop
      pkgs.gobject-introspection
      pkgs.glib
      pkgs.bluez-tools
      pkgs.grimblast
      pkgs.gpu-screen-recorder
      pkgs.brightnessctl
      pkgs.gnome-bluetooth
      (pkgs.python3.withPackages (python-pkgs:
        with python-pkgs; [
          gpustat
          dbus-python
          pygobject3
        ]))
      pkgs.matugen
      pkgs.hyprpicker
      pkgs.hyprsunset
      pkgs.hypridle
      pkgs.wireplumber
      pkgs.networkmanager
      pkgs.upower
      pkgs.gvfs
      pkgs.swww
      pkgs.pywal
    ];
  in {
    devShells = forEachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        nativeBuildInputs =
          [
            pkgs.just
            pkgs.nix-output-monitor
          ]
          ++ (mkExtraPackages system pkgs);
      };
    });

    packages = forEachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      default = hyprpanel;

      hyprpanel-ags = ags.lib.bundle {
        inherit pkgs;
        src = self;
        name = "hyprpanel";
        entry = "app.ts";

        # Additional libraries and executables to add to the GJS runtime
        extraPackages = mkExtraPackages system pkgs;
      };

      hyprpanel = pkgs.writeShellScriptBin "hyprpanel" ''
        if [ "$#" -eq 0 ]; then
            exec ${hyprpanel-ags}/bin/hyprpanel
        else
            exec ${astal.packages.${system}.io}/bin/astal -i hyprpanel "$@"
        fi
      '';
    });

    # Define .overlay to expose the package as pkgs.hyprpanel based on the system
    overlay = final: _prev: {
      inherit (self.packages.${final.stdenv.system}) hyprpanel;
    };
  };
}
