# deno-bin-nix

The Deno in `nixos-unstable` is a few weeks behind upstream, and compiling
Deno from source takes a long time. This Nix flake defines a fixed-output
derivation for the latest binary release. It is updated daily by a GitHub
Action.

## Usage

Add the flake as an input:

```nix
{
  inputs.deno-bin.url = "github:reasonableperson/deno-bin";
}
```

Then consume its package:

```nix
{
  outputs = { self, nixpkgs, deno-bin, ... }: {
    packages.x86_64-linux.default = deno-bin.packages.x86_64-linux.deno;
  };
}
```
