{
  pkgs,
  lib,
  config,
  myLib,
  ...
}:
let
  inherit (myLib)
    mkTapHold
    mkTapHoldReleaseKeys
    mkMultiMod
    mkChord
    mkConfig
    ;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mapAttrsToList
    removeAttrs
    concatStringsSep
    pipe
    splitString
    ;

  inherit (lib.types)
    attrsOf
    either
    int
    listOf
    str
    submodule
    nullOr
    ;

  mkTimeout =
    timeoutType: override: fallback:
    if override != null then override else fallback;

  mkAliasName = override: fallback: if override != null then override else fallback;

  mkHomeRowModAlias =
    key: hrmCfg: defaultTimeouts:
    let
      aliasName = mkAliasName hrmCfg.aliasName key;
      tapTimeout = mkTimeout "tap" hrmCfg.timeoutTap defaultTimeouts.tap-timeout;
      holdTimeout = mkTimeout "hold" hrmCfg.timeoutHold defaultTimeouts.hold-timeout;
    in
    if hrmCfg.behavior == "tap-hold-release-keys" then
      mkTapHoldReleaseKeys aliasName key hrmCfg.mod holdTimeout tapTimeout hrmCfg.releaseKeys
    else
      mkTapHold aliasName key hrmCfg.mod holdTimeout tapTimeout;
in
{
  options.nixos.kanata = {
    enable = mkEnableOption "Kanata Key Remapper Service";

    config = {
      sourceKeys = mkOption {
        default = splitString " " "esc caps a s d f e h j k l scln o spc bksl";
        type = listOf str;
        description = "List of source keys to map from.";
      };

      localKeys = mkOption {
        default = { };
        type = attrsOf int;
        description = "Custom keycode definitions for keys not in the standard set.";
        example = {
          my_side_button = 275;
          my_extra_button = 276;
        };
      };

      variables = mkOption {
        default = {
          tap-timeout = 220;
          hold-timeout = 240;
          combo-timeout = 50;
        };
        type = attrsOf (either int (either str (listOf str)));
        description = "Variables used within the Kanata configuration.";
        example = {
          tap-timeout = 180;
          my-custom-timeout = 150;
          some-keys = splitString " " "a b c";
        };
      };

      aliases = mkOption {
        default = [ ];
        type = listOf str;
        description = "List of alias definitions. Use the mk* functions from the library to generate these.";
        example = [
          (mkTapHold "a-mod" "a" "lctl" 240 220)
          (mkMultiMod "hyper" "bksl" [ "lctl" "lalt" "lsft" "lmet" ] 240 220)
        ];
      };

      layers = mkOption {
        default = {
          base = [ ]; # Will be auto-generated from sourceKeys if empty
        };
        type = attrsOf (listOf str);
        description = "Layer definitions mapping layer names to key lists.";
        example = {
          base = [
            "@a-mod"
            "s"
            "d"
            "f"
          ];
          nav = [
            "left"
            "down"
            "up"
            "right"
          ];
        };
      };

      chords = mkOption {
        default = [ ];
        type = listOf str;
        description = "List of chord definitions. Use mkChord function to generate these.";
        example = [
          (mkChord [ "a" "s" ] "bspc" "$combo-timeout" "first-release" [ ])
          (mkChord [ "k" "l" ] "ret" "$combo-timeout" "first-release" [ ])
        ];
      };

      extraDefCfg = mkOption {
        default = [
          "danger-enable-cmd yes"
          "process-unmapped-keys yes"
        ];
        type = listOf str;
        description = "Extra defcfg options.";
      };

      helpers = {
        # Generate home row mods for given keys
        mkHomeRowMods = mkOption {
          default = { };
          type = attrsOf (submodule {
            options = {
              mod = mkOption {
                type = str;
                example = "lctl";
                description = "Modifier key (lctl, lalt, lsft, lmet, etc.)";
              };
              behavior = mkOption {
                default = "tap-hold";
                type = str;
                description = "tap-hold or tap-hold-release-keys";
              };
              releaseKeys = mkOption {
                default = [ ];
                type = listOf str;
                description = "Keys to release for tap-hold-release-keys behavior";
              };
              timeoutTap = mkOption {
                default = null;
                type = nullOr int;
                description = "Override tap timeout";
              };
              timeoutHold = mkOption {
                default = null;
                type = nullOr int;
                description = "Override hold timeout";
              };
              aliasName = mkOption {
                default = null;
                type = nullOr str;
                description = "Custom alias name (defaults to key name)";
              };
            };
          });
          description = "Configuration for home row modifier keys";
          example = {
            a = {
              mod = "lmet";
              behavior = "tap-hold-release-keys";
              releaseKeys = [
                "q"
                "w"
                "e"
                "r"
                "t"
              ];
            };
            s = {
              mod = "lalt";
            };
          };
        };
      };
    };
  };

  config = mkIf config.nixos.kanata.enable (
    let
      kcfg = config.nixos.kanata.config;

      hrmAliases = pipe kcfg.helpers.mkHomeRowMods [
        (mapAttrsToList (key: hrmCfg: mkHomeRowModAlias key hrmCfg kcfg.variables))
      ];

      allAliases = pipe [ kcfg.aliases hrmAliases ] [ (builtins.concatLists) ];

      baseLayers =
        lib.optionalAttrs (kcfg.layers.base == [ ]) {
          base = kcfg.sourceKeys; # Default: transparent mapping
        }
        // lib.optionalAttrs (kcfg.layers.base != [ ]) {
          base = kcfg.layers.base;
        };

      allLayers = pipe kcfg.layers [
        (layers: removeAttrs layers [ "base" ])
        (lib.recursiveUpdate baseLayers)
      ];

      kanataConfig = pipe {
        inherit (kcfg)
          sourceKeys
          variables
          chords
          localKeys
          ;
        aliases = allAliases;
        layers = allLayers;
      } [ mkConfig ];
    in
    {
      services.kanata = {
        enable = true;
        package = pkgs.kanata-with-cmd;
        keyboards.main = {
          config = kanataConfig;
          extraDefCfg = concatStringsSep " " kcfg.extraDefCfg;
        };
      };
    }
  );
}
