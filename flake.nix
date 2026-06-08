{
  description = "Pinned Deno binary flake for Linux and aarch64-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
      forAllSystems =
        systems: f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );
    in
    {
      packages = forAllSystems (builtins.attrNames metadata.assets) (
        system: with import nixpkgs { inherit system; }; {
          default =
            with metadata;
            stdenvNoCC.mkDerivation {
              pname = "deno";
              version = version;
              src = fetchurl {
                url = assets.${system}.url;
                sha256 = assets.${system}.hash;
              };
              nativeBuildInputs = [ unzip ] ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
              buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
                glibc
                stdenv.cc.cc.lib
              ];
              dontUnpack = true;
              installPhase = ''
                mkdir -p $out/bin
                unzip "$src" deno
                mv deno $out/bin/deno
                chmod +x $out/bin/deno
              '';
            };
        }
      );
    };
}
