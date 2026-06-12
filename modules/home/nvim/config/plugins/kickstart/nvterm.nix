{ pkgs, ... }:

{
  config.programs.nixvim = {

    extraPlugins = with pkgs.vimPlugins; [
      nvterm
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>th";
        action.__raw = ''
          function()
            require("nvterm.terminal").new("horizontal")
          end
        '';
        options = {
          desc = "New terminal (horizontal split)";
        };
      }
      {
        mode = "n";
        key = "<leader>tv";
        action.__raw = ''
          function()
            require("nvterm.terminal").new("vertical")
          end
        '';
        options = {
          desc = "New terminal (vertical split)";
        };
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<leader>oh";
        action.__raw = ''
          function()
            require("nvterm.terminal").toggle("horizontal")
          end
        '';
        options = {
          desc = "Toggle horizontal terminal";
        };
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<leader>ov";
        action.__raw = ''
          function()
            require("nvterm.terminal").toggle("vertical")
          end
        '';
        options = {
          desc = "Toggle vertical terminal";
        };
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<A-i>";
        action.__raw = ''
          function()
            require("nvterm.terminal").toggle("float")
          end
        '';
        options = {
          desc = "Toggle floating terminal";
        };
      }
    ];

    # nvterm configuration
    extraConfigLua = ''
      require("nvterm").setup({
        terminals = {
          shell = vim.o.shell,
          list = {},
          type_opts = {
            horizontal = { 
              location = "rightbelow", 
              split_ratio = 0.2 
            },
            vertical = { 
              location = "rightbelow", 
              split_ratio = 0.3 
            },
            float = {
              relative = 'editor',
              row = 0.25,
              col = 0.25,
              width = 0.5,
              height = 0.5,
              border = "single",
            }
          }
        },
        behavior = {
          autoclose_on_quit = {
            enabled = false,
            confirm = true,
          },
          close_on_exit = true,
          auto_insert = true,
        }
      })
    '';
  };
}
