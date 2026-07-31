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
        key = "<leader>bd";
        action.__raw = ''
          function()
            vim.cmd('BufferLinePickClose')
          end
        '';
        options = {
          desc = "Close buffer (pick)";
        };
      }
      {
        mode = "n";
        key = "<leader>bc";
        action.__raw = ''
          function()
            vim.cmd('bd')
          end
        '';
        options = {
          desc = "Close current buffer";
        };
      }
      # Close all buffers except current
      {
        mode = "n";
        key = "<leader>bo";
        action.__raw = ''
          function()
            vim.cmd('BufferLineCloseOthers')
          end
        '';
        options = {
          desc = "Close other buffers";
        };
      }
      {
        mode = "n";
        key = "<leader>b<";
        action.__raw = ''
          function()
            vim.cmd('BufferLineCloseLeft')
          end
        '';
        options = {
          desc = "Close buffers to left";
        };
      }
      {
        mode = "n";
        key = "<leader>b>";
        action.__raw = ''
          function()
            vim.cmd('BufferLineCloseRight')
          end
        '';
        options = {
          desc = "Close buffers to right";
        };
      }
      {
        mode = "n";
        key = "<leader>ba";
        action.__raw = ''
          function()
            vim.cmd('BufferLineCloseOthers')
            vim.cmd('bd')
          end
        '';
        options = {
          desc = "Close all buffers";
        };
      }
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
