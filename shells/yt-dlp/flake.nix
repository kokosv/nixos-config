{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          yt-dlp = pkgs.yt-dlp;

          yt-age = pkgs.writeShellApplication {
            name = "yt-age";
            runtimeInputs = [ yt-dlp ];
            text = ''
              set -euo pipefail

              COOKIE_FILE="''${PWD}/cookies.txt"
              DEST_DIR="''${PWD}/vid"
              mkdir -p "''${DEST_DIR}"

              ARGS=()
              if [ -f "''${COOKIE_FILE}" ]; then
                ARGS+=(--cookies "''${COOKIE_FILE}")
              else
                echo "WARN: cookies.txt not found at: ''${COOKIE_FILE}"
                echo "      Create cookies.txt from your logged-in browser first."
              fi

              exec yt-dlp \
                "''${ARGS[@]}" \
                --age-limit 18 \
                --paths "home:''${DEST_DIR}" \
                "$@"
            '';
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              yt-dlp
              yt-age
            ];
            shellHook = ''
              mkdir -p ./vid
              echo "Cookies: ./cookies.txt"
              echo "Downloads: ./vid"
            '';
          };
        }
      );
    };
}
