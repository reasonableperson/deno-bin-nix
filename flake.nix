{
  description = "Pinned Deno binary flake for Linux and aarch64-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
      assets = metadata.assets;
      forAllSystems =
        systems: f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );
      denoVersion = metadata.version;
    in
    {
      packages = forAllSystems (builtins.attrNames assets) (
        system: with import nixpkgs { inherit system; }; {
          default = stdenvNoCC.mkDerivation {
            pname = "deno";
            version = denoVersion;
            src = fetchzip {
              url = "https://github.com/denoland/deno/releases/download/v${denoVersion}/${assets.${system}.name}";
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
