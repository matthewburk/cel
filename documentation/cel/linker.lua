export {
  typedef['linker'] {
    [[A linker is a function that defines the layout of a linked rectangle in a host
    rectangle.]];
    list {
      header=[[A linker must satisfy these conditions:]];
      'For a given set of input parameters the a linkers output will always be the same.';
      'A linker does not procduce any side effects.';
      'A linker returns four numbers defining a rectangle (x, y, w, h).';
    };


    functiondef['linker(hw, hh, x, y, w, h, xval, yval, minw, maxw, minh, maxh)'] {
      '';
      [[This is the common definition of a linker.  Linkers will vary in definition of
      xval and yval, and of course the result for a given set of input parameters.]];
      params = {
        param.number[[hw - width of the host rectangle.]];
        param.number[[hh - height of the host rectangle.]];
        param.number[[x - current x value of topleft corner of the rectangle.]];
        param.number[[y - current y value of topleft corner of the rectangle.]];
        param.number[[w - current width of the rectangle.]];
        param.number[[h - current height of the rectangle.]];
        param.any[[xval - the meaning of this parameter varies by linker.
        When a cel's linker is run cel.xval is passed for this parameter.]];
        param.any[[yval - the meaning of this parameter varies by linker.
        When a cel's linker is run cel.yval is passed for this parameter.]];
        param.number[[minw - the minimum width of the rectangle.  The linker
        may exceed this limit, the results of the linker truncated by the caller.]];
        param.number[[maxw - the maximum width of the rectangle.  The linker
        may exceed this limit, the results of the linker truncated by the caller.]];
        param.number[[minh - the minimum height of the rectangle.  The linker
        may exceed this limit, the results of the linker truncated by the caller.]];
        param.number[[maxh - the maximum height of the rectangle.  The linker
        may exceed this limit, the results of the linker truncated by the caller.]];
      };

      returns = {
        param.number[[new x value of topleft corner of the rectangle.]];
        param.number[[new y value of topleft corner of the rectangle.]];
        param.number[[new width of the rectangle.]];
        param.number[[new height of the rectangle.]];
      };
    };

    functiondef['fill'] {
      'The rectangle fills the host rectangle.';

      returns = {
        param.number[[x = 0]];
        param.number[[y = 0]];
        param.number[[w = hw]];
        param.number[[h = hh]];
      };
    };

    functiondef['fill.margin'] {
      'The rectangle fills the *padded* host rectangle.';

      params = {
        param.number[[xval - amount of padding between the vertical sides of the of
        rectangle and the host rectangle.]];
        param.number[[yval - amount of padding between the horizontal sides of the of
        rectangle and the host rectangle.  If not present defaults to xval.]];
      };

      returns = {
        param.number[[x = xval]];
        param.number[[y = yval]];
        param.number[[w = hw - (xval*2)]];
        param.number[[h = hh - (yval*2)]];
      };
    };

    functiondef['fill.leftmargin'] {
      [[The rectangle fills the host rectangle excluding a left margin.]];

      params = {
        param.number[[xval - the size of the left margin.]];
      };

      returns = {
        param.number[[x = margin]];
        param.number[[y = 0]];
        param.number[[w = hw-margin]];
        param.number[[h = hh]];
      };
    };

    functiondef['fill.topmargin'] {
      [[The rectangle fills the host rectangle excluding a top margin.]];

      params = {
        param.number[[xval - the size of the top margin.]];
      };

      returns = {
        param.number[[x = margin]];
        param.number[[y = 0]];
        param.number[[w = hw-margin]];
        param.number[[h = hh]];
      };
    };

    functiondef['fill.rightmargin'] {
      [[The rectangle fills the host rectangle excluding a right margin.]];

      params = {
        param.number[[xval - the size of the right margin.]];
      };

      returns = {
        param.number[[x = 0]];
        param.number[[y = 0]];
        param.number[[w = hw-margin]];
        param.number[[h = hh]];
      };
    };

    functiondef['fill.aspect'] {
      [[The rectangle aspect ratio as defined by xval is maintained and it will 
      fill the width or height of the host rectangle.]];

      params = {
        param.number[[xval - the aspect ratio of the rectangle (width/height).]];
      };

      returns = {
        param.number[[x = new]];
        param.number[[y = new]];
        param.number[[w = new]];
        param.number[[h = new]];
      };
    };

    functiondef['scroll'] {
      'The corners of the rectangle are kept outside the host rectangle area.';
      'If the h < hh then y is set to 0';
      'If the w < hw then x is set to 0';

      params = {
        param.number[[xval - if true then the width of the rectangle is set to hw.]];
        param.number[[yval - if true then the height of the rectangle is set to hh.]];
      };

      returns = {
        param.number[[x = new]];
        param.number[[y = new]];
        param.number[[w = xval and hw or w]];
        param.number[[h = yval and hh or h]];
      };
    };

    functiondef['fence'] {
      'The corners of the rectangle are kept inside the host rectangle area.';

      params = {
        param.number[[xval - minimal amount of padding between the vertical sides of the of
        rectangle and the host rectangle.]];
        param.number[[yval - minimal amount of padding between the horizontal sides of the of
        rectangle and the host rectangle.]];
      };

      returns = {
        param.number[[x = new]];
        param.number[[y = new]];
        param.number[[w = new]];
        param.number[[h = new]];
      };
    };

    functiondef['center'] {
      'Centers the rectangle, then adds xval and yval.';

      returns = {
        param.number[[x = (hw - w)/2 + xval]];
        param.number[[y = (hh - h)/2 + yval]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['left'] {
      'Aligns the rectangle to the left.';

      params = {
        param.number[[xval - amount of padding between the left of the rectangle
        and the left of the host rectangle.]];
      };

      returns = {
        param.number[[x = xval or 0]];
        param.number[[y]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['right'] {
      'Aligns the rectangle to the right.';

      params = {
        param.number[[xval - amount of padding between the right of the rectangle
        and the right of the host rectangle.]];
      };

      returns = {
        param.number[[x = hw - w - xval]];
        param.number[[y]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['top'] {
      'Aligns the rectangle to the top.';

      params = {
        param.number[[xval - amount of padding between the top of the rectangle
        and the top of the host rectangle.]];
      };

      returns = {
        param.number[[x]];
        param.number[[y = xval or y]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['bottom'] {
      'Aligns the rectangle to the bottom.';

      params = {
        param.number[[xval - amount of padding between the bottom of the rectangle
        and the bottom of the host rectangle.]];
      };

      returns = {
        param.number[[x]];
        param.number[[y = hh - h - yval]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['center.top'] {
      'Centered horizontal alignment and top vertical alignment.';

      params = {
        param.number[[xval - value added to x after centering.]];
        param.number[[yval - amount of padding added to the top of the rectangle.]];
      };

      returns = {
        param.number[[x = (hw - w)/2 + xval]];
        param.number[[y = yval]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['center.bottom'] {
      'Centered horizontal alignment and bottom vertical alignment.';

      params = {
        param.number[[xval - value added to x after centering.]];
        param.number[[yval - amount of padding added to the bottom of the rectangle.]];
      };

      returns = {
        param.number[[x = (hw - w)/2 + xval]];
        param.number[[y = yval]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['center.height'] {
      'Centered horizontal alignment and filled vertical alignment.';

      params = {
        param.number[[xval - the value added to x after centering.]];
        param.number[[yval - the amount of padding added to the top and bottom
        of the rectangle.]];
      };

      returns = {
        param.number[[x = (hw - w)/2 + xval]];
        param.number[[y = yval]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    --stopped here

    functiondef['right.top'] {
      'Aligns the rectangle to the right and top.';

      params = {
        param.number[[xval - amount of padding between the right of the rectangle
        and the right of the host rectangle.]];
        param.number[[yval - the top of the rectangle.]];
      };

      returns = {
        param.number[[x = hw - w - xval]];
        param.number[[y = yval]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['right.bottom'] {
      'Aligns the rectangle to the right and bottom.';

      params = {
        param.number[[xval - amount of padding between the right of the rectangle
        and the right of the host rectangle.]];
        param.number[[yval - amount of padding between the bottom of the rectangle
        and the bottom of the host rectangle.]];
      };

      returns = {
        param.number[[x = hw - w - xval]];
        param.number[[y = hh - h - yval]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['right.height'] {
      'Aligns the rectangle to right and fills the height.';

      params = {
        param.number[[xval - amount of padding between the right of the rectangle
        and the right of the host rectangle.]];
        param.number[[yval - amount of padding between the horizontal sides of the of
        rectangle and the host rectangle.]];
      };

      returns = {
        param.number[[x = hw - w - xval]];
        param.number[[y = yval]];
        param.number[[w]];
        param.number[[h = hh - (yval * 2)]];
      };
    };

    functiondef['right.center'] {
      'Aligns the rectangle to right and fills the height.';

      params = {
        param.number[[xval - amount of padding between the right of the rectangle
        and the right of the host rectangle.]];
        param.number[[yval - amount to vertically off-center.]];
      };

      returns = {
        param.number[[x = hw - w - xval]];
        param.number[[y = center.y]];
        param.number[[w]];
        param.number[[h]];
      };
    };
  };
};
