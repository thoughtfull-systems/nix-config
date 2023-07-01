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
        pointers = {
          "ELAN067600_04F33195_Touchpad/Properties/libinput_Tapping_Enabled" = 0;
        };
        xfce4-panel = {
          "configver" = 2;
          "panels" = [ 1 ];
          "panels/dark-mode" = true;
          "panels/panel-1/icon-size" = 16;
          "panels/panel-1/length" = 100;
          "panels/panel-1/mode" = 0;
          "panels/panel-1/plugin-ids" = [ 1 3 5 6 8 9 10 11 12 13 14 ];
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
            "ethernet network connection \"wired connection 1\" active"
            "networkmanager applet"
            "xfce4-power-manager"
          ];
          "plugins/plugin-6/square-icons" = true;
          "plugins/plugin-8" = "pulseaudio";
          "plugins/plugin-8/enable-keyboard-shortcuts" = true;
          "plugins/plugin-8/play-sound" = true;
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
        xfce4-notifyd = {
          "do-fadeout" = true;
          "do-slideout" = true;
          "expire-timeout" = 5;
          "expire-timeout-allow-override" = true;
          "expire-timeout-enabled" = true;
          "gauge-ignores-dnd" = true; # show volume changes even with DnD
          "initial-opacity" = 0.8;
          "notification-display-fields" = "icon-summary-body";
          "notify-location" = 1; # show bottom left corner
          "primary-monitor" = 0; # show on monitor with mouse pointer
          "show-text-with-gauge" = true; # show percentage with volume change
          "theme"  = "Default";
        };
        xfce4-power-manager = {
          "xfce4-power-manager/battery-button-action" = 0; # nothing
          "xfce4-power-manager/blank-on-ac" = 0; # never
          "xfce4-power-manager/blank-on-battery" = 0;
          "xfce4-power-manager/brightness-level-on-ac" = 100;
          "xfce4-power-manager/brightness-level-on-battery" = 100;
          "xfce4-power-manager/brightness-on-ac" = 9; # never
          "xfce4-power-manager/brightness-on-battery" = 9; # never
          "xfce4-power-manager/critical-power-action" = 2; # hibernate
          "xfce4-power-manager/critical-power-level" = 10;
          "xfce4-power-manager/dpms-enabled" = true; # sleep display after inactivity?
          "xfce4-power-manager/dpms-on-ac-off" = 0; # never
          "xfce4-power-manager/dpms-on-ac-sleep" = 0; # never
          "xfce4-power-manager/dpms-on-battery-off" = 0;
          "xfce4-power-manager/dpms-on-battery-sleep" = 10;
          "xfce4-power-manager/general-notification" = false;
          "xfce4-power-manager/handle-brightness-keys" = true;
          "xfce4-power-manager/hibernate-button-action" = 2; # hibernate
          "xfce4-power-manager/inactivity-on-ac" = 14; # never
          "xfce4-power-manager/inactivity-on-battery" = 20;
          "xfce4-power-manager/inactivity-sleep-mode-on-ac" = 1; # suspend
          "xfce4-power-manager/inactivity-sleep-mode-on-battery" = 1; # suspend
          "xfce4-power-manager/lock-screen-suspend-hibernate" = true;
          # xfce4-power-manager does not seem to support hybrid-sleep, so let logind handle the lid
          # switch
          #
          # https://forum.xfce.org/viewtopic.php?id=13918
          # https://gitlab.xfce.org/xfce/xfce4-power-manager/-/issues/7
          "xfce4-power-manager/logind-handle-lid-switch" = true;
          "xfce4-power-manager/power-button-action" = 2; # hibernate
          "xfce4-power-manager/show-panel-label" = 1;
          "xfce4-power-manager/show-tray-icon" = false;
          "xfce4-power-manager/sleep-button-action" = 1; # suspend
        };
        xfce4-screensaver = {
          "lock/embedded-keyboard/enabled" = false;
          "lock/enabled" = true;
          "lock/logout/enabled" = false;
          "lock/saver-activation/enabled" = false;
          "lock/status-messages/enabled" = true;
          "lock/user-switching/enabled" = true;
          "saver/enabled" = false;
        };
        xfce4-session = {
          "general/SaveOnExit" = false;
        };
      };
      unsettings = {
        "xfce4-keyboard-shortcuts" = [
          "commands/custom/<Alt><Super>s"
          "commands/custom/<Alt>F1"
          "commands/custom/<Alt>F2"
          "commands/custom/<Alt>F2/startup-notify"
          "commands/custom/<Alt>F3"
          "commands/custom/<Alt>F3/startup-notify"
          "commands/custom/<Alt>Print"
          "commands/custom/<Primary><Alt>Delete"
          "commands/custom/<Primary><Alt>Escape"
          "commands/custom/<Primary><Alt>f"
          "commands/custom/<Primary><Alt>l"
          "commands/custom/<Primary><Alt>t"
          "commands/custom/<Primary><Shift>Escape"
          "commands/custom/<Primary>Escape"
          "commands/custom/<Shift>Print"
          "commands/custom/<Super>e"
          "commands/custom/<Super>p"
          "commands/custom/<Super>r"
          "commands/custom/<Super>r/startup-notify"
          "commands/custom/HomePage"
          "commands/custom/Print"
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
