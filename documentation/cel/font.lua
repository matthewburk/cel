export {
  typedef['font'] {
    [[A font is a driver object representing a fontface and size]];
    [[Cel is only concerned with font metrics, how to render the font is not specified.]];
    [[The driver is required to implement font.bbox, font.lineheight, font.ascent, font.descent, and font.metrics]];
    [[Cel provides convenience functions to measure strings, if the driver implements any of these functions the
    drivers version will be used.  To implement kerning for example the driver would have to implement all
    of the font functions becuase kerning pairs are not part of the metrics.]];

    tabledef.bbox {
      [[a table describing a tight bounding box around the inked portion of all glyphs in the font.]];
      key.xmin[[distance from the pen origin to the left-most inked portion of any glyph in the font]];
      key.xmax[[distance from the pen origin to the right-most inked portion of any glyph in the font]];
      key.ymin[[distance from the pen origin to the bottom-most inked portion of any glyph in the
                font(usually negative)]];
      key.ymax[[distance from the pen origin to the top-most inked portion of any glyph in the font]];
    };

    key.lineheight[[See freetype FT_Face.height]];
    key.ascent[[See freetype FT_Face.ascender]];
    key.descent[[See freetype FT_Face.descender]];

    tabledef.metrics {
      [[a table with an entry for each glyph in the font (in a future version this will be a unicode value,
      for now it is implemented as the value of string.byte('a') where 'a' is the charater the glyph represents.]];
      [[The metrics table is indexed by string.byte('A') where 'A' is the the string.char() value]];
      key.glyph[[the value of string.byte() for the corresponding char]];
      key.char[[the value of string.char() for the corresponding glyph]];
      key.advance[[the horizontal advance of the pen when this glyph is drawn]];
      key.xmin[[distance from the pen origin to the left-most inked portion of the glyph]];
      key.xmax[[distance from the pen origin to the right-most inked portion of the glyph]];
      key.ymin[[distance from the pen origin to the bottom-most inked portion of the glyph]];
      key.ymax[[distance from the pen origin to the top-most inked portion of the glyph]];
    };

    functiondef['font:height()'] {
      [[Returns the height of the font (font.bbox.ymax - font.bbox.ymin)]];
    };

    functiondef['font:measure(text, i, j)'] {
      [[Measures a string of text returning horizontal advance, font:height(), xmin, xmax, ymin, ymax]];
      [[i and j are used to indicate a substring of the text to measure]];
      [[Driver note: does not depend on other font functions]];
      params = {
        param.string[[text - the source text to measure]];
        param.integer[[i - same behaviour as string.sub(text, i, j), a new string is not created however]];
        param.integer[[j - same behaviour as string.sub(text, i, j), a new string is not created however]];
      };

      returns = {
        param.integer[[(horizontal advance) horizontal advance of the pen]];
        param.integer[[(font height) font.bbox.ymax - font.bbox.ymin]];
        param.integer[[(xmin)distance from the pen origin to the left-most inked portion of the text]];
        param.integer[[(xmax)distance from the pen origin to the right-most inked portion of the text]];
        param.integer[[(ymin)distance from the pen origin to the bottom-most inked portion of the text]];
        param.integer[[(ymax)distance from the pen origin to the top-most inked portion of the text]];
      };
    };

    functiondef['font:measurebbox(text, i, j)'] {
      [[Measures a string of text returning xmin, xmax, ymin, ymax]];
      [[i and j are used to indicate a substring of the text to measure]];
      [[Driver note: does not depend on other font functions]];
      params = {
        param.string[[text - the source text to measure]];
        param.integer[[i - same behaviour as string.sub(text, i, j), a new string is not created however]];
        param.integer[[j - same behaviour as string.sub(text, i, j), a new string is not created however]];
      };

      returns = {
        param.integer[[(xmin)distance from the pen origin to the left-most inked portion of the text]];
        param.integer[[(xmax)distance from the pen origin to the right-most inked portion of the text]];
        param.integer[[(ymin)distance from the pen origin to the bottom-most inked portion of the text]];
        param.integer[[(ymax)distance from the pen origin to the top-most inked portion of the text]];
      };
    };

    functiondef['font:measureadvance(text, i, j)'] {
      [[Measures a string of text returning horizontal advance of the pen]];
      [[i and j are used to indicate a substring of the text to measure]];
      [[Driver note: does not depend on other font functions]];
      params = {
        param.string[[text - the source text to measure]];
        param.integer[[i - same behaviour as string.sub(text, i, j), a new string is not created however]];
        param.integer[[j - same behaviour as string.sub(text, i, j), a new string is not created however]];
      };

      returns = {
        param.integer[[horizontal advance of the pen]];
      };
    };

    --TODO rename to font:wrap in source
    functiondef['font:wrap(text, maxadvance, mode)'] {
      [[Returns an iterator that returns a begin and end values of the the substring of text that does not
      extend past maxadvance]];
      --TODO be more specific

      --TODO make maxadvance a function
      --TODO iterator should also return advance of current line
      --TODO enable a preserve whitespace option
      params = {
        param.string[[text - the source text to measure]];
        param.integer[[maxadvance - maximum advance width for a line]];
        param.string[[mode - 'word' will preserve words, 'line' will only wrap at newlines.]];
      };

      returns = {
        param['function'][[iterator function]];
      };
    };

    functiondef['font:pickpen(text, i, j, x)'] {
      [[Returns the index, and horizontal advance of the penx nearest to x]];
      [[The pen index starts at 1 and advance starts at 0]];
      params = {
        param.string[[text - the source text to measure]];
        param.integer[[i - same behaviour as string.sub(text, i, j), a new string is not created however]];
        param.integer[[j - same behaviour as string.sub(text, i, j), a new string is not created however]];
        param.integer[[x - horizontal distance from pen origin]];
      };

      returns = {
        param.integer[[pen index of the penx nearest to x]];
        param.integer[[penx nearest to x]];
      };
    };

    functiondef['font:pad(padding, w, h, xmin, xmax, ymin, ymax)'] {
      [[Applies padding to text measurements, and returns penx, peny, w, h]];
      [[The values returned by font:measure() correspond to w, h, xmin, xmax, ymin, ymax.]];
      [[Driver note: do not reimplement]];

      params = {
        param.table {
          name = 'padding';
          tabledef.padding {
            [[A table with instructions on how to pad the measurements.]];
            key.fit[[Can be nil, 'default' or 'bbox', this will be used for fitx if it is nil and for fity 
            if it is nil.]];
            key.fitx[[If this is 'bbox' the padding is applied to a tight bounding box around the inked
            portion of the glyphs (horizontally).
            If this 'default' the padding is applied to a bounding box that includes the horizontal
            advance and 0.]]; 
            key.fity[[If this is 'bbox' the padding is applied to a tight bounding box around the inked
            portion of the glyphs (vertically).
            If this is 'default' the padding is applied to a bounding box that includes font.bbox.ymin 
            and font.bbox.ymax.]]; 
            key.l[[The amount of left padding to apply. If this is a number the value is added to the width
              and penx returned.  If it is a function, then the padding is calculated by 
              l = math.floor(l(w,h) + .5) where w and h are the w and h (adjusted by fitx and fity) passed
              into font:pad()]];
            key.t[[The amount of top padding to apply. If this is a number the value is added to the height 
              and peny returned.  If it is a function, then the padding is calculated by 
              t = math.floor(t(w,h) + .5) where w and h are the w and h (adjusted by fitx and fity) passed
              into font:pad()]];
            key.r[[The amount of right padding to apply. If the is nil, then it will use the same value
              as padding.l.  If this is a number the value is added to the width
              returned.  If it is a function, then the padding is calculated by 
              r = math.floor(r(w,h) + .5) where w and h are the w and h (adjusted by fitx and fity) passed
              into font:pad()]];
            key.b[[The amount of bottom padding to apply. If the is nil, then it will use the same value
              as padding.t.  If this is a number the value is added to the height
              returned.  If it is a function, then the padding is calculated by 
              b = math.floor(b(w,h) + .5) where w and h are the w and h (adjusted by fitx and fity) passed
              into font:pad()]];
          };
        };
        param.integer[[w - (horizontal advance) horizontal advance of the pen]];
        param.integer[[h - (font height) font.bbox.ymax - font.bbox.ymin]];
        param.integer[[xmin - distance from the pen origin to the left-most inked portion of the text]];
        param.integer[[xmax - distance from the pen origin to the right-most inked portion of the text]];
        param.integer[[ymin - distance from the pen origin to the bottom-most inked portion of the text]];
        param.integer[[ymax - distance from the pen origin to the top-most inked portion of the text]];
      };

      returns = {
        param.integer[[x coordinate of pen origin to use when drawing the text]];
        param.integer[[y coordinate of pen origin to use when drawing the text]];
        param.integer[[width of the bounding box with left and right padding applied]];
        param.integer[[height of the bounding box with top and bottom padding applied]];
        param.integer[[the amount of left padding added to bounding box.]];
        param.integer[[the amount of top padding added to bounding box.]];
        param.integer[[the amount of right padding added to bounding box.]];
        param.integer[[the amount of bottom padding added to bounding box.]];
      };
    };
  };
}

