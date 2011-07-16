local pairs = pairs

return function(_ENV, M)
  setfenv(1, _ENV)

  keyboard = { 
    keys = {},
    keystates = {},

    [_focus] = {n = 0},
    [_keys] = {},
    [_keystates] = {}
  }
 
  do
    local modifiers = {shift = {'lshift', 'rshift'}, alt = {'lalt', 'ralt'}, ctrl = {'lctrl', 'rctrl'}}

    --was ispressed
    function keyboard:isdown(key)
      if self[_keys][key] then
        return true
      end

      if modifiers[key] then
        for k,v in pairs(modifiers[key]) do
          if self[_keys][v] then
            return true
          end
        end
      end
      return false
    end
  end

  return keyboard 
end

