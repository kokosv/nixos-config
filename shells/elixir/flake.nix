{
  description = "Elixir development environment";

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

        elixir = pkgs.elixir_1_17;
        erlang = pkgs.erlang_27;

        currentDir = builtins.getEnv "PWD";
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [

            erlang
            elixir

            rebar3 # For Erlang packages
            hex # Elixir package manager
          ];

          # Environment variables
          MIX_HOME = "$PWD/.nix-mix";
          HEX_HOME = "$PWD/.nix-hex";

          # Add local mix archives to PATH
          shellHook = ''

            export MIX_HOME="''${PWD}/.nix-mix"
            export HEX_HOME="''${PWD}/.nix-hex"

            # Create local directories for Mix and Hex
            mkdir -p $MIX_HOME $HEX_HOME

            # Add local mix to PATH
            export PATH=$MIX_HOME/bin:$PATH

            echo ""
            echo "Mix home: $MIX_HOME"
            echo "Hex home: $HEX_HOME"
            echo ""

            # Check if Hex is installed
            if [ ! -f "$MIX_HOME/bin/hex" ] && [ ! -d "$HEX_HOME/hex" ]; then
              echo "Hex not found! Run this command to install:"
              echo "   mix local.hex --force"
              echo ""
            fi

            # Check if rebar is installed
            if [ ! -f "$MIX_HOME/bin/rebar" ] && [ ! -f "$MIX_HOME/bin/rebar3" ]; then
              echo "Rebar not found! Run this command to install:"
              echo "   mix local.rebar --force"
              echo ""
            fi

            echo "   mix new my_project  - Create new project"
            echo "   mix deps.get        - Get dependencies"
            echo "   mix test            - Run tests"
            echo ""
          '';
        };

      }
    );
}
