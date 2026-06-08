{
  description = "Pinned Deno binary flake for Linux and aarch64-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      assets = {
        x86_64-linux = {
          hash = "0mp2fj07vyac1psgzhfrfwib7vzszpjy44rcg1xl4hqsh3x2rb38";
          name = "deno-x86_64-unknown-linux-gnu.zip";
        };
        aarch64-linux = {
          hash = "14iwhaq3idhaidf47zxg012fgbl8s6fd97bk613zylg2a3bxggmy";
          name = "deno-aarch64-unknown-linux-gnu.zip";
        };
        aarch64-darwin = {
          hash = "0y5d1im0wn8fxmyqif170yqrrprlv0wh0ncb562353jn2dwvj7iz";
          name = "deno-aarch64-apple-darwin.zip";
        };
      };
      forAllSystems =
        systems: f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );
      denoVersion = "2.8.2";
    in
    {
      packages = forAllSystems (builtins.attrNames assets) (
        system: with import nixpkgs { inherit system; }; rec {
          deno = stdenvNoCC.mkDerivation {
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
          default = deno;
        }
      );
    };
}
