# System Themes
#

{
  scheme = {
    default = {
      scheme = "Solarized Dark (Adapted for Joel Oslo Dark Types)";
      hex = {
        bg = "002b36"; # base03 (Original: bg)
        fg = "839496"; # base0 (Original: fg)
        red = "dc322f"; # red (Original: red)
        orange = "cb4b16"; # orange (Original: orange)
        yellow = "b58900"; # yellow (Original: yellow)
        green = "859900"; # green (Original: green)
        cyan = "2aa198"; # cyan (Original: cyan)
        blue = "268bd2"; # blue (Original: blue)
        purple = "6c71c4"; # violet (Original: purple) - Closest match
        white = "93a1a1"; # base1 (Original: white)
        black =
          "073642"; # base02 (Original: black) - For a slightly lighter black
        gray = "586e75"; # base01 (Original: gray)
        highlight =
          "b58900"; # yellow (Original: highlight) - Could also be orange or base2
        comment = "657b83"; # base00 (Original: comment)
        active =
          "d33682"; # magenta (Original: active) - No perfect match, magenta is a possibility
        inactive =
          "586e75"; # base01 (Original: inactive) - Using gray as a muted color
        text = "839496"; # base0 (Original: text)
      };
      rgb = {
        bg = "0, 43, 54"; # base03 (Original: bg)
        fg = "131, 148, 150"; # base0 (Original: fg)
        red = "220, 50, 47"; # red (Original: red)
        orange = "203, 75, 22"; # orange (Original: orange)
        yellow = "181, 137, 0"; # yellow (Original: yellow)
        green = "133, 153, 0"; # green (Original: green)
        cyan = "42, 161, 152"; # cyan (Original: cyan)
        blue = "38, 139, 210"; # blue (Original: blue)
        purple = "108, 113, 196"; # violet (Original: purple) - Closest match
        white = "147, 161, 161"; # base1 (Original: white)
        black =
          "7, 54, 66"; # base02 (Original: black) - For a slightly lighter black
        gray = "88, 110, 117"; # base01 (Original: gray)
        highlight =
          "181, 137, 0"; # yellow (Original: highlight) - Could also be orange or base2
        comment = "101, 123, 131"; # base00 (Original: comment)
        active =
          "211, 54, 130"; # magenta (Original: active) - No perfect match, magenta is a possibility
        inactive =
          "88, 110, 117"; # base01 (Original: inactive) - Using gray as a muted color
        text = "131, 148, 150"; # base0 (Original: text)
      };
    };

    onedark = {
      scheme = "One Dark Pro";
      hex = {
        bg = "111111"; # 283c34
        fg = "abb2bf";
        red = "e06c75";
        orange = "d19a66";
        yellow = "e5c07b";
        green = "98c379";
        cyan = "56b6c2";
        blue = "61afef";
        purple = "c678dd";
        white = "abb2bf";
        black = "282c34";
        gray = "5c6370";
        highlight = "e2be7d";
        comment = "7f848e";
        active = "005577";
        inactive = "333333";
        text = "999999";
      };
      rgb = {
        bg = "17, 17, 17";
        fg = "171, 178, 191";
        red = "224, 108, 118";
        orange = "209, 154, 102";
        yellow = "229, 192, 123";
        green = "152, 195, 121";
        cyan = "86, 181, 194";
        blue = "97, 175, 223";
        purple = "197, 120, 221";
        white = "171, 178, 191";
        black = "40, 44, 52";
        gray = "92, 99, 112";
        highlight = "226, 191, 125";
        comment = "127, 132, 142";
        active = "0, 85, 119";
        inactive = "51, 51, 51";
        text = "153, 153, 153";
      };
    };

    doom = {
      scheme = "Doom One Dark";
      black = "000000";
      red = "ff6c6b";
      orange = "da8548";
      yellow = "ecbe7b";
      green = "95be65";
      teal = "4db5bd";
      blue = "6eaafb";
      dark-blue = "2257a0";
      magenta = "c678dd";
      violet = "a9a1e1";
      cyan = "6cdcf7";
      dark-cyan = "5699af";
      emphasis = "50536b";
      text = "dfdfdf";
      text-alt = "b2b2b2";
      fg = "abb2bf";
      bg = "282c34";
    };

    dracula = {
      scheme = "Drsacula";
      base00 = "282936"; # background
      base01 = "3a3c4e";
      base02 = "4d4f68";
      base03 = "626483";
      base04 = "62d6e8";
      base05 = "e9e9f4"; # foreground
      base06 = "f1f2f8";
      base07 = "f7f7fb";
      base08 = "ea51b2";
      base09 = "b45bcf";
      base0A = "00f769";
      base0B = "ebff87";
      base0C = "a1efe4";
      base0D = "62d6e8";
      base0E = "b45bcf";
      base0F = "00f769";
    };
  };
}
