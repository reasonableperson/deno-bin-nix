{
  description = "Pinned Deno binary flake for Linux and aarch64-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      denoSystems = {
        x86_64-linux = {
          hash = "0mp2fj07vyac1psgzhfrfwib7vzszpjy44rcg1xl4hqsh3x2rb38";
          assetName = "deno-x86_64-unknown-linux-gnu.zip";
        };
        aarch64-linux = {
          hash = "14iwhaq3idhaidf47zxg012fgbl8s6fd97bk613zylg2a3bxggmy";
          assetName = "deno-aarch64-unknown-linux-gnu.zip";
        };
        aarch64-darwin = {
          hash = "0y5d1im0wn8fxmyqif170yqrrprlv0wh0ncb562353jn2dwvj7iz";
          assetName = "deno-aarch64-apple-darwin.zip";
        };
      };
      systems = builtins.attrNames denoSystems;
      forAllSystems =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
        };
      denoVersion = "2.8.2";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          denoSystem = denoSystems.${system};
          denoSrc = pkgs.fetchzip {
            url = "https://github.com/denoland/deno/releases/download/v${denoVersion}/${denoSystem.assetName}";
            hash = denoSystem.hash;
          };
          deno = pkgs.stdenvNoCC.mkDerivation {
            pname = "deno";
            version = denoVersion;
            src = denoSrc;
            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
            buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.glibc
              pkgs.stdenv.cc.cc.lib
            ];
            installPhase = ''
              mkdir -p $out/bin
              cp "$src/deno" $out/bin/deno
              chmod +x $out/bin/deno
            '';
          };
        in
        {
          inherit deno;
          default = deno;
        }
      );
    };
}
