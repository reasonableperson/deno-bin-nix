{
  description = "Pinned Deno binary flake for Linux x86_64 and aarch64";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
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
      denoX64Hash = "sha256-GE2npSZ6tkm8CIIbO8POaAXY5phfuCcHy41en9ZTU2I=";
      denoArm64Hash = "sha256-SGRxia7mRU7ZuYUvpwCnf5KzlGXATGJZAdFlvI6Tevw=";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          denoAssetName =
            {
              x86_64-linux = "deno-x86_64-unknown-linux-gnu.zip";
              aarch64-linux = "deno-aarch64-unknown-linux-gnu.zip";
            }
            .${system};
          denoHash = if system == "aarch64-linux" then denoArm64Hash else denoX64Hash;
          denoSrc = pkgs.fetchurl {
            url = "https://github.com/denoland/deno/releases/download/v${denoVersion}/${denoAssetName}";
            hash = denoHash;
          };
          deno = pkgs.stdenvNoCC.mkDerivation {
            pname = "deno";
            version = denoVersion;
            src = denoSrc;
            nativeBuildInputs = [ pkgs.autoPatchelfHook ];
            buildInputs = [
              pkgs.glibc
              pkgs.stdenv.cc.cc.lib
            ];
            dontUnpack = true;
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
