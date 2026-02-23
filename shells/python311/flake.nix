{
  description = "Minimal Python ML environment - No Jupyter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python311
            python311Packages.numpy
            python311Packages.scipy
            python311Packages.scikit-learn
            python311Packages.matplotlib
            python311Packages.pandas
            python311Packages.seaborn
            python311Packages.ipython # Just IPython, no full Jupyter
            python311Packages.graphviz
          ];

          shellHook = ''
            	    echo ""
            	    echo "Python: $(python --version)"
                        echo ""
          '';
        };
      }
    );
}
