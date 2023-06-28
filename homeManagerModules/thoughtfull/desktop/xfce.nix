{ config, lib, osConfig, ... }: let
  enable = config.thoughtfull.desktop.enable &&
           osConfig.services.xserver.desktopManager.xfce.enable;
in lib.mkIf enable {
  xfconf.settings = {
    xfce4-panel = {
      "configver" = 2;
      "panels" = [ 1 ];
      "panels/dark-mode" = true;
      "panels/panel-1/icon-size" = 16;
      "panels/panel-1/length" = 100;
      "panels/panel-1/mode" = 0;
      "panels/panel-1/plugin-ids" = [ 1 2 3 4 5 6 9 10 11 12 13 14 ];
      "panels/panel-1/position" = "p=6;x=0;y=0";
      "panels/panel-1/position-locked" = true;
      "panels/panel-1/size" = 26;
      "plugins/plugin-1" = "applicationsmenu";
      "plugins/plugin-2" = "tasklist";
      "plugins/plugin-2/grouping" = 1;
      "plugins/plugin-3" = "separator";
      "plugins/plugin-3/expand" = true;
      "plugins/plugin-3/style" = 0;
      "plugins/plugin-4" = "pager";
      "plugins/plugin-5" = "separator";
      "plugins/plugin-5/style" = 0;
      "plugins/plugin-6" = "systray";
      "plugins/plugin-6/known-legacy-items" = [
        "networkmanager applet"
        "xfce4-power-manager"
        "ethernet network connection \"wired connection 1\" active"
      ];
      "plugins/plugin-6/square-icons" = true;
      "plugins/plugin-8" = "pulseaudio";
      "plugins/plugin-8/enable-keyboard-shortcuts" = true;
      "plugins/plugin-8/show-notifications" = true;
      "plugins/plugin-9" = "power-manager-plugin";
      "plugins/plugin-10" = "notification-plugin";
      "plugins/plugin-11" = "separator";
      "plugins/plugin-11/style" = 0;
      "plugins/plugin-12" = "clock";
      "plugins/plugin-12/mode" = 2;
      "plugins/plugin-13" = "separator";
      "plugins/plugin-13/style" = 0;
      "plugins/plugin-14" = "actions";
    };
  };
}
