{
  description = "Node.js 20 + pnpm (via nodePackages)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_20
            nodePackages.pnpm 
          ];

          shellHook = ''
	    echo " "
            echo "Node.js: $(node --version)"
            echo "pnpm: $(pnpm --version)"
            echo "Run 'pnpm install' to set up your project"
            echo " "
	  '';
        };
      });
}
