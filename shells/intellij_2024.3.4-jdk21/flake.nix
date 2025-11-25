{
  description = "Java development with IntelliJ IDEA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { 
        inherit system; 
        config = {
          allowUnfree = true;
        };
      };
      
      idea = pkgs.jetbrains.idea-ultimate.overrideAttrs (old: rec {
        version = "2024.3.4";
        name = "idea-ultimate-${version}";
        src = pkgs.fetchurl {
          url = "https://download.jetbrains.com/idea/ideaIU-${version}.tar.gz";
          #hash = "sha256-+OjoZPT+3d8dNmp9sj/EEyGSw6YCnGFKOCGG/1ZKeKE="; 
	  hash = "sha256-N2X0YZ96uMKKbVI/dBpEktMdfX2ayPXn2CEt0qcf35w=";
        };
      });

      jdk = pkgs.jdk21;

      ideaFhs = pkgs.buildFHSEnv {
        name = "idea-fhs";
        targetPkgs = pkgs: with pkgs; [
          glibc
          zlib
          openssl
          nss
          # Basic GUI dependencies
          fontconfig
          freetype
        ];
        runScript = "idea-ultimate";
      };

    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          jdk
          maven
          gradle
          idea
          ideaFhs
        ];

        shellHook = ''
          export JAVA_HOME=${jdk}
          export PATH=${jdk}/bin:$PATH

          echo " "
          echo "Java dev environment ready!"
          echo " "
          echo "JAVA_HOME=$JAVA_HOME"
          echo "Java version: $(${jdk}/bin/java -version 2>&1 | head -1)"
          echo " "
          echo "Maven: $(mvn --version | grep Apache)"
          echo "Gradle: $(gradle --version | grep Gradle)"
          echo " "
          echo "Run IntelliJ with FHS (Copilot compatible): idea-fhs &"
          echo "Or direct (Copilot may fail): idea-ultimate &"
	  echo " "
        '';
      };

      # Make the FHS-wrapped IDEA the default package
      packages.default = ideaFhs;
      
      # Also provide the unwrapped version
      packages.idea-unwrapped = idea;

    });
}
