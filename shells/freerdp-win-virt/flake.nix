{
  description = "Mrezhovi infrastrukturi lab access (RDP jump host)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Windows Server 2012's RDP stack needs these relaxed vs. xfreerdp's
      # modern defaults: /tls:seclevel:0 (its TLS handshake fails the default
      # OpenSSL security level) and /cert:ignore (self-signed cert). The
      # Kerberos "Cannot find KDC for realm LOCALHOST" errors xfreerdp logs
      # are harmless -- NLA falls back to NTLM and still succeeds.
      kmk-rdp = pkgs.writeShellScriptBin "kmk-rdp" ''
        exec ${pkgs.freerdp}/bin/xfreerdp \
          /v:kmk.cs.tu-varna.bg /d:localhost /u:kaloyan /p:'Alabala1!' \
          /tls:seclevel:0 /cert:ignore /auth-pkg-list:ntlm \
          +f +dynamic-resolution "$@"
      '';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.freerdp # xfreerdp CLI, used by kmk-rdp below
          kmk-rdp
        ];

        shellHook = ''
          echo "Mrezhovi infrastrukturi lab tools ready."
          echo ""
          echo "RDP jump host: run  kmk-rdp"
          echo "  server:   kmk.cs.tu-varna.bg"
          echo "  domain:   localhost   (prepend if username alone is rejected)"
          echo "  username: kaloyan"
          echo "  password: Alabala1! (baked into the command)"
          echo ""
          echo "Ctrl+Alt+Enter toggles fullscreen on/off in xfreerdp"
        '';
      };
    };
}
