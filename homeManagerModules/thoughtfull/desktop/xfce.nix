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
    services.picom.enable = true;
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
    xfconf = {
      settings = {
        pointers = {
          "ELAN067600_04F33195_Touchpad/Properties/libinput_Tapping_Enabled" = 0;
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
        xfce4-panel = {
          "configver" = 2;
          "panels" = [ 1 ];
          "panels/dark-mode" = false;
          "panels/panel-1/autohide-behavior" = 0; # never
          "panels/panel-1/background-style" = 0; # use system style
          "panels/panel-1/enable-struts" = true;
          "panels/panel-1/enter-opacity" = 100;
          "panels/panel-1/icon-size" = 16;
          "panels/panel-1/leave-opacity" = 100;
          "panels/panel-1/length" = 100.0;
          "panels/panel-1/length-adjust" = true;
          "panels/panel-1/mode" = 0;
          "panels/panel-1/nrows" = 1;
          "panels/panel-1/plugin-ids" = [ 1 15 16 3 17 6 8 9 10 12 14 ];
          "panels/panel-1/position" = "p=6;x=0;y=0";
          "panels/panel-1/position-locked" = true;
          "panels/panel-1/size" = 26;
          "plugin/after-menu-shown" = "mark-all-read";
          "plugin/hide-clear-prompt" = false;
          "plugin/hide-on-read" = false;
          "plugin/log-display-limit" = 10;
          "plugin/log-icon-size" = 16;
          "plugin/log-only-today" = false;
          "plugin/show-in-menu" = "show-all";
          "plugins/plugin-1" = "applicationsmenu";
          "plugins/plugin-1/button-icon" = "org.xfce.panel.applicationsmenu";
          "plugins/plugin-1/button-title" =  "Applications";
          "plugins/plugin-1/custom-menu" = false;
          "plugins/plugin-1/show-button-title" = false;
          "plugins/plugin-1/show-generic-names" = false;
          "plugins/plugin-1/show-menu-icons" = true;
          "plugins/plugin-1/show-tooltips" = false;
          "plugins/plugin-1/small" = true; # show on one line
          "plugins/plugin-3" = "separator";
          "plugins/plugin-3/expand" = true;
          "plugins/plugin-3/style" = 0; # transparent
          "plugins/plugin-6" = "systray";
          "plugins/plugin-6/hide-new-items" = false;
          "plugins/plugin-6/icon-size" = 16;
          "plugins/plugin-6/known-legacy-items" = [
            "ethernet network connection \"wired connection 1\" active"
            "networkmanager applet"
            "xfce4-power-manager"
          ];
          "plugins/plugin-6/menu-is-primary" = false; # must right click for menu
          "plugins/plugin-6/single-row" = false;
          "plugins/plugin-6/square-icons" = true;
          "plugins/plugin-6/symbolic-icons" = false;
          "plugins/plugin-8" = "pulseaudio";
          "plugins/plugin-8/enable-keyboard-shortcuts" = true; # volume keys
          "plugins/plugin-8/enable-mpris" = true; # control media players
          "plugins/plugin-8/enable-multimedia-keys" = true; # media player keys
          "plugins/plugin-8/mixer-command" =  "pavucontrol";
          "plugins/plugin-8/play-sound" = true; # play volume adjustment sound
          "plugins/plugin-8/show-notifications" = 1; # all
          "plugins/plugin-8/volume-step" = 5;
          "plugins/plugin-9" = "power-manager-plugin";
          "plugins/plugin-10" = "notification-plugin";
          "plugins/plugin-12" = "clock";
          "plugins/plugin-12/command" = "";
          "plugins/plugin-12/digital-layout" = 3; # full date
          "plugins/plugin-12/digital-time-font" = "B612 11";
          "plugins/plugin-12/digital-time-format" = "%R"; # hh:mm
          "plugins/plugin-12/mode" = 2; # digital
          "plugins/plugin-12/timezone" = "";
          "plugins/plugin-14" = "actions";
          "plugins/plugin-14/appearance" = 0; # action buttons
          "plugins/plugin-14/ask-confirmation" = false;
          "plugins/plugin-14/items" = [
            "+suspend"
            "+hybrid-sleep"
            "+logout"
            "-separator"
            "-switch-user"
            "-hibernate"
            "-shutdown"
            "-restart"
            "-logout-dialog"
            "-lock-screen"
          ];
          "plugins/plugin-15" = "separator";
          "plugins/plugin-15/expand" = false;
          "plugins/plugin-15/style" = 0; # transparent
          "plugins/plugin-16" = "directorymenu";
          "plugins/plugin-16/base-directory" = "/home/paul";
          "plugins/plugin-16/hidden-files" = false;
          "plugins/plugin-16/new-document" = false;
          "plugins/plugin-16/new-folder" = false;
          "plugins/plugin-16/open-in-terminal" = false;
          "plugins/plugin-17" = "xkb";
          "plugins/plugin-17/display-type" = 0; # image
          "plugins/plugin-17/display-name" = 0; # country
          "plugins/plugin-17/display-scale" = 80;
          "plugins/plugin-17/show-notifications" = false;
          "plugins/plugin-17/display-tooltip-icon" = false;
          "plugins/plugin-17/group-policy" = 0; # configure globally
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
          "xfce4-power-manager/power-button-action" = 2; # hibernate
          "xfce4-power-manager/show-panel-label" = 1;
          "xfce4-power-manager/show-presentation-indicator" = true;
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
        xsettings = {
          "Gdk/WindowScalingFactor" = 1;
          "Gtk/ButtonImages" = true;
          "Gtk/CanChangeAccels" = false;
          "Gtk/DialogsUseHeader" = false;
          "Gtk/FontName" = "B612 11";
          "Gtk/MenuImages" = true;
          "Gtk/MonospaceFontName" = "Source Code Pro 11";
          "Net/EnableEventSounds" = false;
          "Net/EnableInputFeedbackSounds" = false;
          "Net/IconThemeName" = "Adwaita";
          "Net/ThemeName" = "Adwaita";
          "Xfce/LastCustomDPI" = 96;
          "Xft/Antialias" = 1;
          "Xft/DPI" = 96;
          "Xft/HintStyle" = "hintfull";
          "Xft/RGBA" = "none";
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
  };
}
