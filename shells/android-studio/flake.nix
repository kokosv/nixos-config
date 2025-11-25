{
  description = "Android Studio + SDK (Studio manages SDK)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        androidCmdline = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "9.0";
          includeEmulator = false;
          includeSources = false;
          includeSystemImages = false;
        };

        androidFhs = pkgs.buildFHSEnv {
          name = "android-fhs";
          targetPkgs = pkgs: with pkgs; [
            jdk21
            zlib
            ncurses5
            glib
            dbus
            udev
            # GUI deps
            libGL
            libxkbcommon
            fontconfig
            freetype
          ];
          runScript = "bash";
          profile = ''
            # set SDK path at runtime
          '';
        };

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            android-studio
            androidCmdline.androidsdk 
	    androidFhs
          ];

          SDK_DIR = "${placeholder "out"}/sdk";

          shellHook = ''
            SDK_PATH="$PWD/.android-sdk"

            # Create if missing
            [ ! -d "$SDK_PATH" ] && mkdir -p "$SDK_PATH"

	    export ANDROID_SDK_ROOT="$PWD/.android-sdk"
	    export ANDROID_HOME="$PWD/.android-sdk"
            export ANDROID_AVD_HOME="$PWD/.android-avd"

            # Pre-populate cmdline-tools (optional, speeds up first run)
            if [ ! -d "$SDK_PATH/cmdline-tools" ]; then
              echo "Copying cmdline-tools to SDK..."
              cp -r ${androidCmdline.androidsdk}/libexec/android-sdk/cmdline-tools "$SDK_PATH/"
              chmod -R u+w "$SDK_PATH/cmdline-tools"
            fi

            echo " "
            echo "SDK will be in: $SDK_PATH"
            echo " "
            echo "Run: android-studio &"
            echo "Or in FHS (if GUI fails): ${androidFhs}/bin/android-fhs -c 'android-studio &'"
            echo " "
	  '';
        };
      });
}
