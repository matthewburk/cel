local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local listbox = cel.getmetaface('listbox')

  listbox.layout = {
    gap = 1,
    slotface = cel.getmetaface('cel'),
  }

  setmetatable(listbox.layout, {__index=cel.getmetaface('scroll').layout})

end
