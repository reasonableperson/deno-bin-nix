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

Then add it to your NixOS (or Home Manager or nix-darwin) configuration:

```nix
({ pkgs, inputs, ... }: {
  environment.systemPackages = [
    inputs.deno-bin.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
})
```

Or use the overlay:

```nix
({ pkgs, inputs, ... }: {
  inputs.nixpkgs.overlays = [ inputs.deno-bin.overlays.default ];
  environment.systemPackages = [ pkgs.deno ];
})
```
