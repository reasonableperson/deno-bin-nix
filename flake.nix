{
  description = "Pinned Deno binary flake for Linux x86_64 and aarch64";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deno-x86_64-linux = {
      url = "https://github.com/denoland/deno/releases/download/v2.8.2/deno-x86_64-unknown-linux-gnu.zip";
      flake = false;
    };
    deno-aarch64-linux = {
      url = "https://github.com/denoland/deno/releases/download/v2.8.2/deno-aarch64-unknown-linux-gnu.zip";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: builtins.listToAttrs (map (system: {
        name = system;
        value = f system;
      }) systems);
      mkPkgs =
        system:
        import inputs.nixpkgs {
          inherit system;
        };
      denoVersion = "v2.8.2";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          denoSrc =
            {
              x86_64-linux = inputs.deno-x86_64-linux;
              aarch64-linux = inputs.deno-aarch64-linux;
            }
            .${system};
          deno = pkgs.stdenvNoCC.mkDerivation {
            pname = "deno";
            version = pkgs.lib.removePrefix "v" denoVersion;
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
