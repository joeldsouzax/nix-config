{
  scheme = rec {

    default = catppuccin;
    catppuccin = {
      scheme = "Catppuccin Mocha";
      hex = {
        bg = "1e1e2e";
        fg = "cdd6f4";
        red = "f38ba8";
        orange = "fab387";
        yellow = "f9e2af";
        green = "a6e3a1";
        cyan = "94e2d5";
        blue = "89b4fa";
        purple = "cba6f7";
        white = "bac2de";
        black = "11111b";
        gray = "585b70";
        highlight = "f5c2e7";
        comment = "585b70";
        active = "cba6f7";
        inactive = "313244";
        text = "cdd6f4";
      };

      # Used by SwayNC / CSS for transparency (rgba)
      rgb = {
        bg = "30, 30, 46"; # 1e1e2e
        fg = "205, 214, 244"; # cdd6f4
        red = "243, 139, 168";
        orange = "250, 179, 135";
        yellow = "249, 226, 175";
        green = "166, 227, 161";
        cyan = "148, 226, 213";
        blue = "137, 180, 250";
        purple = "203, 166, 247";
        white = "186, 194, 222";
        black = "17, 17, 27";
        gray = "88, 91, 112";
        highlight = "245, 194, 231";
        comment = "88, 91, 112";
        active = "203, 166, 247"; # cba6f7
        inactive = "49, 50, 68"; # 313244
        text = "205, 214, 244";
      };
    };

    solarized = {
      scheme = "Solarized Dark";
      hex = {
        bg = "002b36";
        fg = "839496";
        red = "dc322f";
        orange = "cb4b16";
        yellow = "b58900";
        green = "859900";
        cyan = "2aa198";
        blue = "268bd2";
        purple = "6c71c4";
        white = "93a1a1";
        black = "073642";
        gray = "586e75";
        highlight = "b58900";
        comment = "657b83";
        active = "d33682";
        inactive = "586e75";
        text = "839496";
      };

      rgb = {
        bg = "0, 43, 54";
        fg = "131, 148, 150";
        red = "220, 50, 47";
        orange = "203, 75, 22";
        yellow = "181, 137, 0";
        green = "133, 153, 0";
        cyan = "42, 161, 152";
        blue = "38, 139, 210";
        purple = "108, 113, 196";
        white = "147, 161, 161";
        black = "7, 54, 66";
        gray = "88, 110, 117";
        highlight = "181, 137, 0";
        comment = "101, 123, 131";
        active = "211, 54, 130";
        inactive = "88, 110, 117";
        text = "131, 148, 150";
      };
    };
  };
}
