{
  ".." = "cd ..";
  "..." = "cd ../..";

  r = "ranger";
  c = "clear";

  ssh = "kitten ssh";

  l = "eza";
  ll = "eza -l";
  la = "eza -a";
  lal = "eza -a -l";
  lt = "eza -T -L ";
  lta = "eza -T -a -L ";
  ltl = "eza -T -l -L ";
  ltla = "eza -T -l -a -L ";

  nixreb = "sudo nixos-rebuild --flake ~/.nixos-config#kt480 switch";
  nixbld = "sudo nixos-rebuild build --flake ~/.nixos-config#kt480";
  nixtst = "sudo nixos-rebuild test --flake ~/.nixos-config#kt480";

  kys = "sudo shutdown -h now";

  hdmiup = "xrandr --output HDMI-2 --mode 1920x1080 --above eDP-1";
  hdmir = "xrandr --output HDMI-2 --mode 1920x1080 --right-of eDP-1";
  hdmil = "xrandr --output HDMI-2 --mode 1920x1080 --left-of eDP-1";
}
