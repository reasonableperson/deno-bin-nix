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
              src = fetchzip {
                url = "https://github.com/denoland/deno/releases/download/v${version}/${assets.${system}.name}";
                hash = assets.${system}.hash;
              };
              nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
              buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
                glibc
                stdenv.cc.cc.lib
              ];
              installPhase = ''
                mkdir -p $out/bin
                cp "$src/deno" $out/bin/deno
                chmod +x $out/bin/deno
              '';
            };
        }
      );
    };
}
