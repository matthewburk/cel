local cel = require 'cel'

return function(root)
  cel.face {
    metacel = 'sequence.y',
    fillcolor = cel.color.rgb(244, 0, 0),
  }

  root {
    cel.window {
      w = 400, h = 400,
      cel.scroll {
        link = {'edges'},
        subjectfillx = true,
        subject = cel.sequence.y {
          link = {'width'},
          cel.window.new(300, 300),
          function(self)
            local new = cel.label.new
            for i = 1, 100 do
              new('This'):link(self)
              new('Is '):link(self)
              new('Just'):link(self)
              new('a'):link(self)
              new('bunch of labels'):link(self)
              new('put into a sequence'):link(self)
              new('and then'):link(self)
              new('put then we put the sequence'):link(self)
              new('into a scroll and wrapped it all'):link(self)
              new('in a window'):link(self)
              new(tostring(self:len())):link(self)
            end
          end,
        },
      }
    }
  }
end

