{ lib, ... }: {
  options.homeManager.fetch = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.fetch = { pkgs, inputs, ... }: {
    home.packages = [ inputs.areofyl-fetch.packages.${pkgs.stdenv.hostPlatform.system}.default ];

    xdg.configFile."fetch/config".text = ''
      os
      host
      kernel
      ---
      displaymanager
      wm
      terminal
      shell
      ---
      theme
      icons
      font
      cursor
      ---
      display
      cpu
      gpu
      memory
      swap
      disk
      ---
      uptime
      colors

      label_color=green
      separator=─
      shading_mode=ascii
      shading=.,-~:;=!*#$@  
      box=1 

      light=top 
      spin=y
      speed=0.8
      size=1.5
      depth=3.0
      v_alignment=top
      h_alignment=left
    '';
  };
}
