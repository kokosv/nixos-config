{
  description = "FreeCAD with DWG export/import support (ODA File Converter)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";

      # nixpkgs' odafileconverter pins a dead opendesign.com download URL
      # (ODA rotates/retires old release links, so the fixed URL 404s). This
      # overlay swaps in the locally downloaded current build (27.9.0.0)
      # sitting next to this flake instead of fetching over the network.
      #
      # To refresh when this breaks again: download the current .deb from
      # https://www.opendesign.com/guestfiles/oda_file_converter, replace
      # ./ODAFileConverter_QT6_lnxX64_11dll.deb, find the new version with
      # `dpkg-deb -I ./ODAFileConverter_QT6_lnxX64_11dll.deb | grep Version`,
      # and update the version string below (two places) to match.
      #
      # setup dwg export:
      # In FreeCAD: Edit > Preferences > Import-Export > DWG
      #  converter path: $(command -v ODAFileConverter)
      #  dropdown menu: ODA Converter
      overlays = [
        (final: prev: {
          odafileconverter = prev.odafileconverter.overrideAttrs (_old: {
            version = "27.9.0.0";
            src = ./ODAFileConverter_QT6_lnxX64_11dll.deb;
            installPhase = ''
              mkdir -p $out/bin $out/lib
              cp -vr usr/bin/ODAFileConverter_27.9.0.0 $out/libexec
              cp -vr usr/share $out/share
            '';
          });
        })
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.freecad
          pkgs.odafileconverter
        ];

        shellHook = ''
          echo "FreeCAD + ODA File Converter ready."
          echo ""
        '';
      };
    };
}
