namespace('D:/projects/cel-reactor/cel/test/document/testns.lua')

local cel = require 'cel'

export['testdoc'] {
  row {
    section {
      list.bulleted {
        'hello',
        'hello',
        'hello',

        list.bulleted {
          'goodbye',
          'goodbye',
          'goodbye',
        };
      };
      list {
        text.h1 { [[listbox]] };
        list {
          'a nother list',
          'a nother list',
          'a nother list',
          'a nother list',
        };
        text.h2 { [[listbox]]; };
        text.h3 { [[listbox]]; };
      };
      paragraph [[This is a test doc]];
      paragraph [[This is a test doc]];
    };
    section {
      paragraph [[This is a test doc]];
      paragraph [[This is a test doc]];
    };
  }

}

