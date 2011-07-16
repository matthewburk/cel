local cel = require 'cel'

local metacel, metatable = cel.slot.newmetacel('border')

do
  local _new = metacel.new
  function metacel:new(l, t, r, b, face) --TODO don't need to define this, just let it pass to slot
    return _new(self, l, t, r, b, self:getface(face))
  end

  local _compile = metacel.compile
  function metacel:compile(t, border)
    return _compile(self, t, border or metacel:new(t.left, t.top, t.right, t.bottom, t.face))
  end
end

return metacel:newfactory()
