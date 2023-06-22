{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.thoughtfull.yabar;
  boolToString = b: if b then "true" else "false";
  mapExtraOption = key: val:
    "${key} = ${if (isBool val)
                then
                  boolToString val
                else
                  if isInt val || isFloat val
                  then
                    toString val
                  else
                    "\"${toString val}\""};";
  mapExtra = v: lib.concatStringsSep "\n" (mapAttrsToList mapExtraOption v);
  listStrings = s: concatStringsSep "," (map (n: "\"${n}\"") s);
  listKeys = r: (listStrings (attrNames r));
  maybeConfig = c: s:
    if isNull c
    then
      ""
    else
      s;
  blockConfig = cfg:
    ''
    ${cfg.name}: {
      ${maybeConfig cfg.exec "exec: \"${cfg.exec}\";"}
      ${maybeConfig cfg.align "align: \"${cfg.align}\";"}
      ${maybeConfig cfg.justify "justify: \"${cfg.justify}\";"}
      ${maybeConfig cfg.type "type: \"${cfg.type}\";"}
      ${maybeConfig cfg.interval "interval: ${toString cfg.interval};"}
      ${maybeConfig cfg.fixed-size "fixed-size: ${toString cfg.fixed-size};"}
      ${maybeConfig cfg.pango-markup
        "pango-markup: ${boolToString cfg.pango-markup};"}
      ${maybeConfig cfg.foreground-color-rgb
        "foreground-color-rgb: 0x${cfg.foreground-color-rgb};"}
      ${maybeConfig cfg.background-color-rgb
        "background-color-rgb: 0x${cfg.background-color-rgb};"}
      ${maybeConfig cfg.underline-color-rgb
        "underline-color-rgb: 0x${cfg.underline-color-rgb};"}
      ${maybeConfig cfg.overline-color-rgb
        "overline-color-rgb: 0x${cfg.overline-color-rgb};"}
      ${maybeConfig cfg.command-button1
        "command-button1: \"${cfg.command-button1}\";"}
      ${maybeConfig cfg.command-button2
        "command-button2: \"${cfg.command-button2}\";"}
      ${maybeConfig cfg.command-button3
        "command-button3: \"${cfg.command-button3}\";"}
      ${maybeConfig cfg.command-button4
        "command-button4: \"${cfg.command-button4}\";"}
      ${maybeConfig cfg.command-button5
        "command-button5: \"${cfg.command-button5}\";"}
      ${maybeConfig cfg."inherit" "inherit: \"${cfg."inherit"}\";"}
      ${maybeConfig cfg.image "image: \"${cfg.image}\";"}
      ${maybeConfig cfg.image-shift-x
        "image-shift-x: ${toString cfg.image-shift-x};"}
      ${maybeConfig cfg.image-shift-y
        "image-shift-y: ${toString cfg.image-shift-y};"}
      ${maybeConfig cfg.image-scale-width
        "image-scale-width: ${toString cfg.image-scale-width};"}
      ${maybeConfig cfg.image-scale-height
        "image-scale-height: ${toString cfg.image-scale-height};"}
      ${maybeConfig cfg.variable-size
        "variable-size: ${boolToString cfg.variable-size};"}
      ${maybeConfig cfg.internal-prefix
        "internal-prefix: \"${cfg.internal-prefix}\";"}
      ${maybeConfig cfg.internal-suffix
        "internal-suffix: \"${cfg.internal-suffix}\";"}
      ${maybeConfig cfg.internal-option1
        "internal-option1: \"${cfg.internal-option1}\";"}
      ${maybeConfig cfg.internal-option2
        "internal-option2: \"${cfg.internal-option2}\";"}
      ${maybeConfig cfg.internal-option3
        "internal-option3: \"${cfg.internal-option3}\";"}
      ${maybeConfig cfg.internal-spacing
        "internal-spacing: ${boolToString cfg.internal-spacing};"}
      ${mapExtra cfg.extra}
    };
    '';
  barConfig = cfg: let
    blocks = filter (block: block.enable) (map (block: cfg.blocks.${block}) cfg.block-list);
    block-list = map (block: block.name) blocks;
  in
    ''
    ${cfg.name}: {
      ${maybeConfig cfg.font "font: \"${cfg.font}\";"}
      ${maybeConfig cfg.position "position: \"${cfg.position}\";"}
      ${maybeConfig cfg.gap-horizontal
        "gap-horizontal: ${toString cfg.gap-horizontal};"}
      ${maybeConfig cfg.gap-vertical
        "gap-vertical: ${toString cfg.gap-vertical};"}
      ${maybeConfig cfg.height "height: ${toString cfg.height};"}
      ${maybeConfig cfg.width "width: ${toString cfg.width};"}
      ${maybeConfig cfg.monitor
        "monitor: \"${concatStringsSep " " cfg.monitor}\""}
      ${maybeConfig cfg.underline-size
        "underline-size: ${toString cfg.underline-size};"}
      ${maybeConfig cfg.overline-size
        "overline-size: ${toString cfg.overline-size};"}
      ${maybeConfig cfg.slack-size "slack-size: ${toString cfg.slack-size};"}
      ${maybeConfig cfg.border-size
        "border-size: ${toString cfg.border-size};"}
      ${maybeConfig cfg.border-color-rgb
        "border-color-rgb: 0x${toString cfg.border-color-rgb};"}
      ${maybeConfig cfg.background-color-nowindow-rgb
        "border-color-rgb: 0x${toString cfg.background-color-nowindow-rgb};"}
      ${maybeConfig cfg."inherit" "inherit: \"${cfg."inherit"}\";"}
      ${maybeConfig cfg.inherit-all "inherit-all: \"${cfg.inherit-all}\";"}
      ${maybeConfig cfg.command-button1
        "command-button1: \"${cfg.command-button1}\";"}
      ${maybeConfig cfg.command-button2
        "command-button2: \"${cfg.command-button2}\";"}
      ${maybeConfig cfg.command-button3
        "command-button3: \"${cfg.command-button3}\";"}
      ${maybeConfig cfg.command-button4
        "command-button4: \"${cfg.command-button4}\";"}
      ${maybeConfig cfg.command-button5
        "command-button5: \"${cfg.command-button5}\";"}

      ${mapExtra cfg.extra}

      block-list: [ ${listStrings block-list} ];

      ${concatStringsSep "\n" (map blockConfig blocks)}
    };
    '';
  configFile = let
    bars = filter (bar: bar.enable) (map (bar: cfg.bars.${bar}) cfg.bar-list);
    bar-list = map (bar: bar.name) bars;
  in
    pkgs.writeText "yabar.conf" ''
      bar-list = [${listStrings bar-list}];
      ${concatStringsSep "\n" (map barConfig bars)}
    '';
in
{
  options.thoughtfull.yabar = {
    enable = mkEnableOption "yabar";
    package = mkOption {
      default = pkgs.yabar-unstable;
      defaultText = literalExpression "pkgs.yabar-unstable";
      example = literalExpression "pkgs.yabar";
      type = types.package;
      # `yabar-stable` segfaults under certain conditions.
      apply = x: if x == pkgs.yabar-unstable then x else flip warn x ''
        It's not recommended to use `yabar' with `programs.yabar', the (old)
        stable release tends to segfault under certain circumstances:

          * https://github.com/geommer/yabar/issues/86
          * https://github.com/geommer/yabar/issues/68
          * https://github.com/geommer/yabar/issues/143

        Most of them don't occur on master anymore, until a new release is
        published, it's recommended to use `yabar-unstable'.
      '';
      description = ''
        The package which contains the `yabar` binary.

        Nixpkgs provides the `yabar` and `yabar-unstable` derivations since
        18.03, so it's possible to choose.
      '';
    };
    bar-list = mkOption {
      default = [];
      type = types.listOf(types.str);
    };
    bars = mkOption {
      default = [];
      type = types.attrsOf(types.submodule ({ name, ... }: {
        options = {
          name = mkOption {
            default = name;
            description = "The name of the bar.";
            example = "clock";
            type = types.str;
          };
          enable = mkOption {
            default = true;
            description = "Whether to enable the bar.";
            example = false;
            type = types.bool;
          };
          font = mkOption {
            default = null;
            description = "The font that will be used to draw the status bar.";
            example = "Droid Sans, FontAwesome Bold 9";
            type = types.nullOr types.str;
          };
          position = mkOption {
            default = null;
            description = "The position where the bar will be rendered.";
            example = "bottom";
            type = types.nullOr (types.enum [ "top" "bottom" ]);
          };
          gap-horizontal = mkOption {
            default = null;
            description = "The size of horizontal gap in pixels.";
            example = 20;
            type = types.nullOr types.ints.unsigned;
          };
          gap-vertical = mkOption {
            default = null;
            description = "The size of vertical gap in pixels.";
            example = 5;
            type = types.nullOr types.ints.unsigned;
          };
          height = mkOption {
            default = null;
            description = "The height of the bar.";
            example = 25;
            type = types.nullOr types.ints.unsigned;
          };
          width = mkOption {
            default = null;
            description = ''
              The width of the bar.  If unspecified the default is screen
              size - 2 * horizontal gap.
            '';
            example = 800;
            type = types.nullOr types.ints.unsigned;
          };
          monitor = mkOption {
            default = null;
            description = ''
              The monitor for the bar to be drawn on.  If unspecified the
              default is the first active monitor. Multiple fallback monitors
              can be provided if the first option is unavailable.
            '';
            example = [ "LVDS1" "VGA1" ];
            type = types.nullOr (types.listOf types.string);
          };
          underline-size = mkOption {
            default = null;
            description = "The thickness of underlines.";
            example = 2;
            type = types.nullOr types.ints.unsigned;
          };
          overline-size = mkOption {
            default = null;
            description = "The thickness of overlines.";
            example = 2;
            type = types.nullOr types.ints.unsigned;
          };
          slack-size = mkOption {
            default = null;
            description = ''
              The size of the slack (i.e. the unused space between blocks).
            '';
            example = 2;
            type = types.nullOr types.ints.unsigned;
          };
          border-size = mkOption {
            default = null;
            description = "The size for a border surrounding the bar.";
            example = 2;
            type = types.nullOr types.ints.unsigned;
          };
          border-color-rgb = mkOption {
            default = null;
            description = "The color of the border surrounding the bar.";
            example = "ffffff";
            type = types.nullOr types.str;
          };
          background-color-nowindow-rgb = mkOption {
            default = null;
            description = ''
              The fallback color for the bar when there is no active window.
            '';
            example = "ffffff";
            type = types.nullOr types.str;
          };
          "inherit" = mkOption {
            default = null;
            description = "The bar from which to inherit options.";
            example = "bar1";
            type = types.nullOr types.str;
          };
          inherit-all = mkOption {
            default = null;
            description = "The bar from which to inherit options and blocks.";
            example = "bar1";
            type = types.nullOr types.str;
          };
          command-button1 = mkOption {
            default = null;
            description = "The mouse button1 command to run for bar.";
            example = "pavucontrol || alsamixer";
            type = types.nullOr types.str;
          };
          command-button2 = mkOption {
            default = null;
            description = "The mouse button2 command to run for bar.";
            example = "pavucontrol || alsamixer";
            type = types.nullOr types.str;
          };
          command-button3 = mkOption {
            default = null;
            description = "The mouse button3 command to run for bar.";
            example = "pavucontrol || alsamixer";
            type = types.nullOr types.str;
          };
          command-button4 = mkOption {
            default = null;
            description = "The mouse button4 command to run for bar.";
            example = "xbacklight -inc 1";
            type = types.nullOr types.str;
          };
          command-button5 = mkOption {
            default = null;
            description = "The mouse button4 command to run for bar.";
            example = "xbacklight -dec 1";
            type = types.nullOr types.str;
          };
          extra = mkOption {
            default = {};
            description = ''
              An attribute set which contains further attributes of a bar.
            '';
            type = types.attrsOf (with types; oneOf [str int bool float]);
          };
          block-list = mkOption {
            default = [];
            type = types.listOf(types.str);
          };
          blocks = mkOption {
            default = [];
            type = types.attrsOf(types.submodule ({ name, ... }: {
              options = {
                name = mkOption {
                  default = name;
                  description = "The name of the block.";
                  example = "clock";
                  type = types.str;
                };
                enable = mkOption {
                  default = true;
                  description = "Whether to enable the block.";
                  example = false;
                  type = types.bool;
                };
                exec = mkOption {
                  default = null;
                  description = "The type of the block to be executed.";
                  example = "YABAR_DATE";
                  type = types.str;
                };
                align = mkOption {
                  default = null;
                  description = ''
                    Whether to align the block at the left or right of the bar.
                  '';
                  example = "right";
                  type = types.nullOr (types.enum [ "left" "center" "right" ]);
                };
                justify = mkOption {
                  default = null;
                  description = "Justification of text with in block.";
                  example = "left";
                  type = types.nullOr (types.enum [ "left" "center" "right" ]);
                };
                type = mkOption {
                  default = null;
                  description = ''
                    Block type can be periodic where the command is executed
                    within a fixed interval of time, persistent where the
                    command runs in a persistent way, or once where the command
                    is executed only once.
                  '';
                  example = "once";
                  type = types.nullOr (types.enum [ "periodic" "persist" "once" ]);
                };
                interval = mkOption {
                  default = null;
                  description = "Interval in seconds for periodic blocks.";
                  example = 3;
                  type = types.nullOr types.ints.unsigned;
                };
                fixed-size = mkOption {
                  default = null;
                  description = "Fixed width size of the block in pixels.";
                  example = 90;
                  type = types.nullOr types.ints.unsigned;
                };
                pango-markup = mkOption {
                  default = null;
                  description = "Enable Pango Markup.";
                  example = true;
                  type = types.nullOr types.bool;
                };
                foreground-color-rgb = mkOption {
                  default = null;
                  description = ''
                    Font color when Pango Markup is not used and the foreground
                    color when it is in hexadecimal RRGGBB format.
                  '';
                  example = "eeeeee";
                  type = types.nullOr types.str;
                };
                background-color-rgb = mkOption {
                  default = null;
                  description = ''
                    Background color in hexadecimal RRGGBB format.
                  '';
                  example = "1dc93582";
                  type = types.nullOr types.str;
                };
                underline-color-rgb = mkOption {
                  default = null;
                  description = "Underline color in hexadecimal RRGGBB format.";
                  example = "1d1d1d";
                  type = types.nullOr types.str;
                };
                overline-color-rgb = mkOption {
                  default = null;
                  description = "Overline color in hexadecimal RRGGBB format.";
                  example = "642356";
                  type = types.nullOr types.str;
                };
                command-button1 = mkOption {
                  default = null;
                  description = "The mouse button1 command to run for block.";
                  example = "pavucontrol || alsamixer";
                  type = types.nullOr types.str;
                };
                command-button2 = mkOption {
                  default = null;
                  description = "The mouse button2 command to run for block.";
                  example = "pavucontrol || alsamixer";
                  type = types.nullOr types.str;
                };
                command-button3 = mkOption {
                  default = null;
                  description = "The mouse button3 command to run for block.";
                  example = "pavucontrol || alsamixer";
                  type = types.nullOr types.str;
                };
                command-button4 = mkOption {
                  default = null;
                  description = "The mouse button4 command to run for block.";
                  example = "pactl set-sink-volume 0 +10%";
                  type = types.nullOr types.str;
                };
                command-button5 = mkOption {
                  default = null;
                  description = "The mouse button5 command to run for block.";
                  example = "pactl set-sink-volume 0 -10%";
                  type = types.nullOr types.str;
                };
                "inherit" = mkOption {
                  default = null;
                  description = "The block from which to inherit options.";
                  example = "bar1.block1";
                  type = types.nullOr types.str;
                };
                image = mkOption {
                  description = "Path to image to display.";
                  default = null;
                  type = types.nullOr types.str;
                };
                image-shift-x = mkOption {
                  default = null;
                  description = ''
                    Number of pixels to shift image on the x-axis.
                  '';
                  type = types.nullOr types.int;
                };
                image-shift-y = mkOption {
                  default = null;
                  description = ''
                    Number of pixels to shift image on the y-axis.
                  '';
                  type = types.nullOr types.int;
                };
                image-scale-width = mkOption {
                  default = null;
                  description = "Factor to scale image width.";
                  type = types.nullOr types.float;
                };
                image-scale-height = mkOption {
                  default = null;
                  description = "Factor to scale image height.";
                  type = types.nullOr types.float;
                };
                variable-size = mkOption {
                  default = null;
                  description = ''
                    Whether to fit the block width to the current text width.
                  '';
                  type = types.nullOr types.bool;
                };
                internal-prefix = mkOption {
                  default = null;
                  description = ''
                    Prefix string injected before the block output.
                  '';
                  type = types.nullOr types.str;
                };
                internal-suffix = mkOption {
                  default = null;
                  description = ''
                    Suffix string injected after the block output.
                  '';
                  type = types.nullOr types.str;
                };
                internal-option1 = mkOption {
                  default = null;
                  description = "Block specific option 1.";
                  type = types.nullOr types.str;
                };
                internal-option2 = mkOption {
                  default = null;
                  description = "Block specific option 2.";
                  type = types.nullOr types.str;
                };
                internal-option3 = mkOption {
                  default = null;
                  description = "Block specific option 3.";
                  type = types.nullOr types.str;
                };
                internal-spacing = mkOption {
                  default = null;
                  description = "Whether to add padding to block output.";
                  type = types.nullOr types.bool;
                };
                extra = mkOption {
                  default = {};
                  description = ''
                    An attribute set which contains further attributes of a
                    block.
                  '';
                  type = types.attrsOf (with types; oneOf [str int bool float]);
                };
              };
            }));
            description = "Blocks that should be rendered by yabar.";
          };
        };
      }));
      description = "List of bars that should be rendered by yabar.";
    };
  };
  config = mkIf cfg.enable {
    systemd.user.services.yabar = {
      Unit = {
        Description = "yabar service";
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = ''
          ${cfg.package}/bin/yabar -c ${configFile}
        '';
        Restart = "always";
      };
    };
  };
}
