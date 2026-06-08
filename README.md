# deno-bin-nix

The Deno in `nixos-unstable` is a few weeks behind upstream, and compiling
Deno from source takes a long time. This Nix flake defines a fixed-output
derivation for the latest binary release. It is updated daily by a GitHub
Action.

## Usage

Add the flake as an input:

```nix
{
  inputs.deno-bin = {
    url = "github:reasonableperson/deno-bin";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then add it to a NixOS configuration:

```nix
{
  outputs = { self, nixpkgs, deno-bin, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = builtins.currentSystem;
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            deno-bin.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        })
      ];
    };
  };
}
```

Or add it to a Home Manager configuration:

```nix
{
  outputs = { self, nixpkgs, home-manager, deno-bin, ... }: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = builtins.currentSystem;
      };
      modules = [
        ({ pkgs, ... }: {
          home.packages = [
            deno-bin.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        })
      ];
    };
  };
}
```

Or use the overlay in either place:

```nix
{
  outputs = { self, nixpkgs, deno-bin, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = builtins.currentSystem;
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ deno-bin.overlays.default ];
          environment.systemPackages = [ pkgs.deno ];
        })
      ];
    };
  };
}
```
