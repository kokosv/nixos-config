# In your main NixVim configuration file
{ ... }:

{
  programs.nixvim = {
    plugins.lazygit = {
      enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>LazyGit<CR>";
        options = {
          desc = "Open LazyGit";
          noremap = true;
          silent = true;
        };
      }
    ];
  };
}
