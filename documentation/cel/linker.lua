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
        param.number[[x - current x value of topleft corner of the linked rectangle.]];
        param.number[[y - current y value of topleft corner of the linked rectangle.]];
        param.number[[w - current width of the linked rectangle.]];
        param.number[[h - current height of the linked rectangle.]];
        param.any[[xval - the meaning of this parameter varies by linker.
        When a cel's linker is run cel.xval is passed for this parameter.]];
        param.any[[yval - the meaning of this parameter varies by linker.
        When a cel's linker is run cel.yval is passed for this parameter.]];
        param.number[[minw - the minimum width of the linked rectangle.  The linker
        may exceed this limit, the results of the linker truncated by the caller.]];
        param.number[[maxw - the maximum width of the linked rectangle.  The linker
        may exceed this limit, the results of the linker truncated by the caller.]];
        param.number[[minh - the minimum height of the linked rectangle.  The linker
        may exceed this limit, the results of the linker truncated by the caller.]];
        param.number[[maxh - the maximum height of the linked rectangle.  The linker
        may exceed this limit, the results of the linker truncated by the caller.]];
      };

      returns = {
        param.number[[new x value of topleft corner of linked the rectangle.]];
        param.number[[new y value of topleft corner of linked the rectangle.]];
        param.number[[new width of the linked rectangle.]];
        param.number[[new height of the linked rectangle.]];
      };
    };


    functiondef['right'] {
      'Aligns the rectangle to the right.';

      params = {
        param.number[[xval - amount of padding between the right of the linked rectangle
        and the right of the host rectangle.]];
      };

      returns = {
        param.number[[x = hw - w - xval]];
        param.number[[y]];
        param.number[[w]];
        param.number[[h]];
      };
    };

    functiondef['right.top'] {
      'Aligns the rectangle to the right and top.';

      params = {
        param.number[[xval - amount of padding between the right of the linked rectangle
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
        param.number[[xval - amount of padding between the right of the linked rectangle
        and the right of the host rectangle.]];
        param.number[[yval - amount of padding between the bottom of the linked rectangle
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
        param.number[[xval - amount of padding between the right of the linked rectangle
        and the right of the host rectangle.]];
        param.number[[yval - amount of padding between the horizontal sides of the of
        linked rectangle and the host rectangle.]];
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
        param.number[[xval - amount of padding between the right of the linked rectangle
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
