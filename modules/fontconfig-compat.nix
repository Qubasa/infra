{ pkgs, lib, ... }:
# fontconfig 2.18 introduced the `genericfamily` object and started shipping
# conf.d rules that use it: 48-guessfamily.conf, and five rules at the top of
# 49-sansserif.conf. Applications that link fontconfig statically at a pre-2.18
# version cannot parse those rules -- Chromium does exactly that, so Brave,
# Electron, Signal and VS Code are all affected. They log
#
#   Fontconfig warning: ".../48-guessfamily.conf", line 20: invalid constant used :
#
# and then render every family, page text and browser chrome alike, in a
# Courier-family fallback.
#
# Restore the pre-2.18 semantics: neutralise 48-guessfamily.conf and ship
# fontconfig 2.17's 49-sansserif.conf. Comparing fc-match 2.17 against 2.18 over
# every family installed here showed zero differences, so nothing is lost.
#
# Shadowing through confPackages keeps this cheap. fonts.fontconfig.confPackages
# is merged with buildEnv, which honours meta.priority when resolving collisions,
# so setPrio 0 beats the default 5 of the module's own conf package. Overriding
# pkgs.fontconfig instead would rebuild everything that links against it.
let
  guessFamily = pkgs.writeText "48-guessfamily.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <description>
        Intentionally empty. Upstream's version uses the fontconfig 2.18
        genericfamily object, which applications bundling an older fontconfig
        cannot parse. See modules/fontconfig-compat.nix.
      </description>
    </fontconfig>
  '';

  # Verbatim from fontconfig 2.17.1, minus the genericfamily rules 2.18 added.
  sansSerif = pkgs.writeText "49-sansserif.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <description>Add sans-serif to the family when no generic name</description>
    <!--
      If the font still has no generic name, add sans-serif
     -->
      <match target="pattern">
        <test qual="all" name="family" compare="not_eq">
          <string>sans-serif</string>
        </test>
        <test qual="all" name="family" compare="not_eq">
          <string>serif</string>
        </test>
        <test qual="all" name="family" compare="not_eq">
          <string>monospace</string>
        </test>
        <edit name="family" mode="append_last">
          <string>sans-serif</string>
        </edit>
      </match>
    </fontconfig>
  '';

  compat = pkgs.runCommand "fontconfig-genericfamily-compat" { } ''
    dst=$out/etc/fonts/conf.d
    mkdir -p $dst
    cp ${guessFamily} $dst/48-guessfamily.conf
    cp ${sansSerif} $dst/49-sansserif.conf
  '';
in
{
  fonts.fontconfig.confPackages = [ (lib.setPrio 0 compat) ];
}
