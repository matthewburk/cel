local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local listbox = cel.getface('listbox')

  listbox.layout = {
    gap = 1,
    slotface = cel.getface('cel'),
  }

  setmetatable(listbox.layout, {__index=cel.getface('scroll').layout})

end
