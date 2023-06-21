{ pkgs, unstable, ... }: {
  home.packages = with pkgs; [
    cinnamon.cinnamon-common
    pulseaudio
    thoughtfull.brightness
    thoughtfull.mic
    thoughtfull.keyboard
    thoughtfull.speaker
    xorg.xbacklight
  ];
  thoughtfull.yabar = {
    bar-list = [ "top" ];
    bars = {
      top = {
        name = "top";
        font = "Droid Sans, FontAwesome Bold 12";
        height = 24;
        block-list = [
          "wifi"
          "keyboard"
          "brightness"
          "mic-volume"
          "speaker-volume"
          "battery"
          "date"
        ];
        blocks = {
          wifi = {
            align = "left";
            command-button2 = "/usr/bin/env cinnamon-settings network";
            exec = "YABAR_WIFI";
            foreground-color-rgb = "eeeeee";
            internal-option1 = "wlp0s20f3";
            internal-prefix = "   ";
            internal-suffix = " ";
            name = "wifi";
            variable-size = true;
          };
          brightness = {
            align = "right";
            command-button1 = "/usr/bin/env xbacklight -set 40";
            command-button2 = "/usr/bin/env cinnamon-settings display";
            command-button3 = "/usr/bin/env xbacklight -set 100";
            exec = "/usr/bin/env brightness-status";
            fixed-size = 80;
            foreground-color-rgb = "eeeeee";
            interval = 1;
            name = "brightness";
            type = "periodic";
          };
          mic-volume = {
            align = "right";
            command-button1 = "/usr/bin/env pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            command-button2 = "/usr/bin/env cinnamon-settings sound -t 1";
            command-button3 = "/usr/bin/env pactl set-source-volume @DEFAULT_SOURCE@ 100%";
            exec = "/usr/bin/env mic-status";
            fixed-size = 80;
            foreground-color-rgb = "eeeeee";
            interval = 1;
            name = "mic-volume";
            type = "periodic";
          };
          speaker-volume = {
            align = "right";
            command-button1 = "/usr/bin/env pactl set-sink-mute @DEFAULT_SINK@ toggle";
            command-button2 = "/usr/bin/env cinnamon-settings sound -t 0";
            command-button3 = "/usr/bin/env pactl set-sink-volume @DEFAULT_SINK@ 100%";
            exec = "/usr/bin/env speaker-status";
            fixed-size = 80;
            foreground-color-rgb = "eeeeee";
            interval = 1;
            name = "speaker-volume";
            type = "periodic";
          };
          battery = {
            align = "right";
            exec = "YABAR_BATTERY";
            fixed-size = 90;
            foreground-color-rgb = "eeeeee";
            internal-option1 = "BAT0";
            internal-option2 = "    ";
            internal-suffix = "%";
            interval = 1;
            name = "battery";
          };
          date = {
            align = "right";
            exec = "YABAR_DATE";
            fixed-size = 200;
            foreground-color-rgb = "eeeeee";
            internal-option1 = "%a %b %d %H:%M";
            interval = 1;
            name = "date";
          };
          keyboard = {
            align = "right";
            command-button1 = "/usr/bin/env keyboard-toggle";
            command-button2 = "/usr/bin/env keyboard-toggle";
            command-button3 = "/usr/bin/env keyboard-toggle";
            exec = "/usr/bin/env keyboard-status";
            fixed-size = 65;
            foreground-color-rgb = "eeeeee";
            interval = 1;
            name = "keyboard";
            type = "periodic";
          };
        };
        monitor = [ "DP-3-1" "HDMI-1" "eDP-1" ];
        position = "top";
      };
    };
    enable = true;
    package = pkgs.unstable.yabar-unstable;
  };
}
