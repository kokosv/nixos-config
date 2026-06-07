{ ... }:

{
  config.programs.nixvim = {

    plugins.bufferline = {
      enable = true;

      settings = {
        options = {
          indicator = {
            style = "underline";
          };
        };
      };

    };

    keymaps = [
      {
        mode = "n";
        key = "<Tab>";
        action.__raw = ''
          function()
            vim.cmd('BufferLineCycleNext')
          end
        '';
        options = {
          desc = "Next buffer";
        };
      }
      {
        mode = "n";
        key = "<S-Tab>";
        action.__raw = ''
          function()
            vim.cmd('BufferLineCyclePrev')
          end
        '';
        options = {
          desc = "Previous buffer";
        };
      }
    ];
  };
}
