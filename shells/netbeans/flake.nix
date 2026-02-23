{
  description = "NetBeans IDE development environment";

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
            # NetBeans IDE
            netbeans

            # Java development (required for NetBeans)
            jdk17

            # Optional: Additional build tools and utilities
            git
            maven
            gradle
            ant

          ];
        };
      }
    );
}
