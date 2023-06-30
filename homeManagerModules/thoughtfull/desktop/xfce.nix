{ config, lib, osConfig, pkgs, ... }: let
  cfg = config.xfconf;
  enable = config.thoughtfull.desktop.enable &&
           osConfig.services.xserver.desktopManager.xfce.enable;
in {
  options.xfconf.unsettings = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = { };
    example = lib.literalExpression ''
      {
        xfce4-keyboard-shortcuts = [ "commands/custom/<Primary><Alt>f" ];
      }
    '';
    description = ''
      Settings to remove from the Xfconf configuration system.
    '';
  };
  config = lib.mkIf enable {
    xfconf = {
      settings = {
        xfce4-panel = {
          "configver" = 2;
          "panels" = [ 1 ];
          "panels/dark-mode" = true;
          "panels/panel-1/icon-size" = 16;
          "panels/panel-1/length" = 100;
          "panels/panel-1/mode" = 0;
          "panels/panel-1/plugin-ids" = [ 1 3 5 6 9 10 11 12 13 14 ];
          "panels/panel-1/position" = "p=6;x=0;y=0";
          "panels/panel-1/position-locked" = true;
          "panels/panel-1/size" = 26;
          "plugins/plugin-1" = "applicationsmenu";
          "plugins/plugin-3" = "separator";
          "plugins/plugin-3/expand" = true;
          "plugins/plugin-3/style" = 0;
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
        xfce4-power-manager = {
          "xfce4-power-manager/show-panel-label" = 1;
        };
        xfce4-session = {
          "general/SaveOnExit" = false;
        };
      };
      unsettings = {
        "xfce4-keyboard-shortcuts" = [
          "commands/custom/<Alt>F1"
          "commands/custom/<Alt>F2"
          "commands/custom/<Alt>F2/startup-notify"
          "commands/custom/<Alt>F3"
          "commands/custom/<Alt>F3/startup-notify"
          "commands/custom/<Alt>Print"
          "commands/custom/<Alt><Super>s"
          "commands/custom/HomePage"
          "commands/custom/<Primary><Alt>Delete"
          "commands/custom/<Primary><Alt>Escape"
          "commands/custom/<Primary><Alt>f"
          "commands/custom/<Primary><Alt>l"
          "commands/custom/<Primary><Alt>t"
          "commands/custom/<Primary>Escape"
          "commands/custom/<Primary><Shift>Escape"
          "commands/custom/Print"
          "commands/custom/<Shift>Print"
          "commands/custom/<Super>e"
          "commands/custom/<Super>p"
          "commands/custom/<Super>r"
          "commands/custom/<Super>r/startup-notify"
          "commands/custom/XF86Display"
          "commands/custom/XF86Mail"
          "commands/custom/XF86WWW"
        ];
      };
    };
    home.activation.xfconfUnsettings = lib.hm.dag.entryAfter [ "installPackages" ]
      (let
        mkCommand = channel: property: ''
          $DRY_RUN_CMD ${pkgs.xfce.xfconf}/bin/xfconf-query \
            ${
              lib.escapeShellArgs
                ([ "-r" "-c" channel "-p" "/${property}" ])
            }
        '';

        commands = lib.mapAttrsToList
          (channel: properties: map (mkCommand channel) properties)
          cfg.unsettings;

        load = pkgs.writeShellScript "unset-xfconf"
          (lib.concatMapStrings lib.concatStrings commands);
      in ''
        if [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
          export DBUS_RUN_SESSION_CMD=""
        else
          export DBUS_RUN_SESSION_CMD="${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon"
        fi

        $DRY_RUN_CMD $DBUS_RUN_SESSION_CMD ${load}

        unset DBUS_RUN_SESSION_CMD
      '');
  };
}
