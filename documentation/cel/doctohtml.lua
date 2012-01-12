do --string interpolation via % operator 
  local function dostring(w, t)
    local s = 'setfenv(1, ...); return ' .. w
    local f = assert(loadstring(s))
    local ok, r = pcall(f, t)
    if ok then
      return r;
    end
  end

  local function psub(p, t)
    local w = p:sub(3, -2)
    return t[w] or dostring(w, t) or p
  end

  getmetatable('').__mod = function(s, t)
    return (s:gsub('($%b{})', function(p) return tostring(psub(p, t)) end))
  end
end


local navigation
do
  local f = io.open('navigation.html')
  navigation = f:read('*a')
  f:close()
end

local function tconcat(t, context, n)
  local tc = {}
  for i, v in ipairs(t) do
    if type(v) == 'function' then 
      tc[i]=v(context, n) 
    else
      tc[i]=v
    end
  end
  return table.concat(tc, ' ')
end

do
  local function newfactory(name, t)
    local brief = 'module'
    if type(t[1]) == 'string' then brief = t[1] end
      local html = [[
      <html>
      <head>
        <link rel="stylesheet" type="text/css" href="cel.css" />
      </head>
      <body>
        <div id="navigation">
        ${navigation}
        </div>
        <div id="content">
        <h1>${name}<p class="factorydesc">(module)<br><br>${brief}</p></h1>
        ${content}
        </div>
      </body></html>]] % {content=tconcat(t, 'factory', 2), name=name, brief=brief,
      navigation = navigation,
      }
      _writefile(html)
  end

  local function newpage(t)
    local html = [[
      <html>
      <head>
        <link rel="stylesheet" type="text/css" href="cel.css" />
      </head>
      <body>
        <div id="navigation">
        ${navigation}
        </div>
        <div id="content">
        ${content}
        </div>
      </body></html>]] % {content=tconcat(t, 'page'), navigation = navigation,}
      _writefile(html)
  end

  export = setmetatable({}, {
    __call = function(_, t) 
       return newpage(t)
    end;

    __index = function(t, k)
      return function(t)
        return newfactory(k, t);
      end
    end
  })
end

do
  local function newtypedef(name, t)
    return function(context)
      if not context then return 'typedef' end
      local brief = ''
      if type(t[1]) == 'string' then brief = t[1] end
      return [[<div class="typedef">
      <h1>${name}<p class="typedefdesc">(type)<br><br>${brief}</p></h1>
      ${content}
      </div>]] % { 
        name = name or '',
        content=tconcat(t, 'typedef') or '',
        brief = brief or '',
      }
    end
  end
  typedef = setmetatable({}, {
    __index = function(t, k)
      return function(t)
        return newtypedef(k, t);
      end
    end
  })
end

do
  objectdef = setmetatable({}, {
    __index = function(t, k)
      return function(t)
        --return newobjectdef(k, t);
        return '<h3>objectdef ' .. k .. '</h3>'
      end
    end
  })
end

do
  local function newpropertydef(name, t)
    return function(context)
      if not context then return 'propertydef' end
      local brief = ''
      if type(t[1]) == 'string' then brief = t[1] end

      return [[
      <div class="propertydef">
      <p class="propertydefheader">property</p>
        <h3 class="propertydefname">
          ${name}&nbsp;
          <span class="propertydefdesc">${brief}</span>
        </h3>
        <div class="propertydeffulldesc">
        <p>${content}</p>
        </div>
      </div>
      ]] % { 
        name = name or '',
        brief = brief or '',
        content=tconcat(t, 'propertydef') or '',
      }
    end
  end
  propertydef = setmetatable({}, {
    __index = function(t, k)
      return function(t)
        return newpropertydef(k, t);
      end
    end
  })
end

do
  local function newmetaceldef(name, t)
    return function(context)
      if not context then return 'metaceldef' end
      local brief = ''
      if type(t[1]) == 'string' then brief = t[1] end

      local composition
      local description
      local layout

      if t.composition then
        local t = t.composition
        local params
        if t.params then
          for k, v in ipairs(t.params) do
            t.params[k] = v('argument')
          end
          params = [[
            <div class="arguments">
              <span class="arguments">cels</span>
              <dl class="arguments">${arguments}</dl>
            </div>]] % {arguments=tconcat(t.params, 'params')}
        end

        composition = [[
        <div class="metacelcomposition">
          <dt class="metacelcomposition">composition</dt>
          <dd>
          ${content}
          ${params}
          </dd>
        </div>]] % {content=tconcat(t, 'composition') or '', params=params or ''}
      end

      if t.description then
        local t = t.description
        local params
        if t.params then
          for k, v in ipairs(t.params) do
            t.params[k] = v('argument')
          end
          params = [[
            <div class="arguments">
              <span class="arguments">entries</span>
              <dl class="arguments">${arguments}</dl>
            </div>]] % {arguments=tconcat(t.params, 'params')}
        end

        description = [[
        <div class="metaceldescription">
          <dt class="metaceldescription">description</dt>
          <dd>
          ${content}
          ${params}
          </dd>
        </div>]] % {content=tconcat(t, 'description') or '', params=params or ''}
      end

      if t.layout then
        local t = t.layout
        local params
        if t.params then
          for k, v in ipairs(t.params) do
            t.params[k] = v('argument')
          end
          params = [[
            <div class="arguments">
              <span class="arguments">entries</span>
              <dl class="arguments">${arguments}</dl>
            </div>]] % {arguments=tconcat(t.params, 'params')}
        end
        layout = [[
        <div class="metacellayout">
          <dt class="metacellayout">layout</dt>
          <dd>
          ${content}
          ${params}
          </dd>
        </div>]] % {content=tconcat(t, 'layout') or '', params=params or ''}
      end

      return [[
      <div class="metaceldef">
      <p class="metaceldefheader">metacel</p>
        <h3 class="metaceldefname">
          ${name}&nbsp;
          <span class="metaceldefdesc">${brief}</span>
        </h3>
        <div class="metaceldeffulldesc">
        <p>${content}</p>
        <dl>
        ${composition}
        ${description}
        ${layout}
        </dl>
        </div>
      </div>
      ]] % { 
        name = name or '',
        brief = brief or '',
        content=tconcat(t, 'metaceldef') or '',
        composition = composition or '',
        description = description or '',
        layout = layout or '',
      }
    end
  end
  metaceldef = setmetatable({}, {
    __index = function(t, k)
      return function(t)
        return newmetaceldef(k, t);
      end
    end
  })
end

do
  local function neweventdef(signature, t)
    return function(context)
      if not context then return 'eventdef' end
      local sinterp = { 
        signature = signature,
        params = '',
        returns = '',
        content = tconcat(t, 'eventdef') or '',
        brief = '',
      }

      if type(t[1]) == 'string' then
        sinterp.brief = t[1]
      end

      if t.params then
        for k, v in ipairs(t.params) do
          t.params[k] = v('argument')
        end
        sinterp.params = [[
        <div class="arguments">
          <span class="arguments">arguments</span>
          <dl class="arguments">${arguments}</dl>
        </div>]] % {arguments=tconcat(t.params, 'params')}
      end

      if t.returns then
        for k, v in ipairs(t.returns) do
          t.returns[k] = v('returns')
        end
        sinterp.returns = [[
        <div class="returns">
          <span class="returns">returns</span>
          <dl class="returns">${returns}</dl>
          </div>
        ]] % {returns=tconcat(t.returns, 'returns')}
      end

      return [[
      <div class="eventdef">
        <p class="eventdefheader">event</p>
        <h3 class="eventsig">
          ${signature}&nbsp;
          <span class="eventdesc">${brief}</span>
        </h3>
        <div class="eventfulldesc">
        <p>${content}</p>
        ${params}
        ${returns}
        </div>
      </div>
      ]] % sinterp
    end
  end
  eventdef = setmetatable({}, {
    __index = function(t, k)
      return function(t)
        return neweventdef(k, t);
      end
    end
  })
end

do
  local function newceldef(name, t)
    return function(context)
      if not context then return 'celdef' end

      local __link = ''

      if t.__link then
        __link = [[<div class="linkopt">
         <p class="divtitle">behavior</p>
          <h3 class="linkopt">link options</h3>
          <div class="linkoptfulldesc">
          <p>${content}</p>
          </div>
        </div>]] % { content=tconcat(t.__link, '__link') }
      end

      local brief = ''
      if type(t[1]) == 'string' then brief = t[1] end
      return [[<div class="celdef">
      <h1>${name}<p class="celdefdesc">(cel)<br><br>${brief}</p></h1>
      ${content}
      ${__link}
      </div>]] % { 
        name = name or '',
        content=tconcat(t, 'celdef') or '',
        brief = brief or '',
        __link = __link,
      }
    end
  end
  celdef = setmetatable({}, {
    __index = function(t, k)
      return function(t)
        return newceldef(k, t);
      end
    end
  })
end

do
  local function newtabledef(name, t)
    return function(context)
      if not context then return 'tabldef' end
      local content = {}
      local header = {}
      for i, v in ipairs(t) do
        if type(v) == 'string' then
          content[#content + 1] = v
        else
          content[#content + 1] = v('tabledef')
        end
      end

      return [[
      <div class="tabledef">
        <p class="tabledefname">${name}</p>
        <dl class="tabledef">
          ${content}
        </dl>
      </div>]] % { 
        name = name or '',
        header = table.concat(header) or '',
        content=table.concat(content) or '',
      }
    end
  end
  tabledef = setmetatable({}, {
    __call = function(_, v) 
      return newtabledef(nil, v)
    end;

    __index = function(t, k)
      return function(t)
        return newtabledef(k, t);
      end
    end
  })
end

do
  local function newkvlist(t)
    return function(context)
      if not context then return 'list' end
      local content = {}
      for k, v in ipairs(t) do
        if type(v) == 'function' then v = v('kvlist') end
        content[k] = v
      end

      return [[<div class="kvlist">
      ${header}
      <dl>
      ${content}
      </dl>
      </div>]] % { 
        header=t.header or '',
        content=table.concat(content),
      }
    end
  end
  kvlist = function(t) 
    return newkvlist(t)
  end
end

do
  local function newfunctiondef(signature, t)
    return function(context)
      if not context then return 'functiondef' end

      local sinterp = { 
        signature = signature,
        params = '',
        returns = '',
        content = tconcat(t, 'functiondef') or '',
        brief = '',
      }

      if type(t[1]) == 'string' then
        sinterp.brief = t[1]
      end

      if t.params then
        for k, v in ipairs(t.params) do
          t.params[k] = v('argument')
        end
        sinterp.params = [[
        <div class="arguments">
          <span class="arguments">arguments</span>
          <dl class="arguments">${arguments}</dl>
        </div>]] % {arguments=tconcat(t.params, 'params')}
      end

      if t.returns then
        for k, v in ipairs(t.returns) do
          t.returns[k] = v('returns')
        end
        sinterp.returns = [[
        <div class="returns">
          <span class="returns">returns</span>
          <dl class="returns">${returns}</dl>
          </div>
        ]] % {returns=tconcat(t.returns, 'returns') }
      end

      return [[
      <div title="function" class="functiondef">
        <p class="functiondefheader">function</p>
        <h3 class="functionsig">
          ${signature}&nbsp;
          <span class="functiondesc">${brief}</span>
        </h3>
        <div class="functionfulldesc">
        <p>${content}</p>
        ${params}
        ${returns}
        </div>
      </div>
      ]] % sinterp
    end
  end
  functiondef = setmetatable({}, {
    __index = function(t, k)
      return function(t)
        return newfunctiondef(k, t);
      end
    end
  })
end

do
  local function newcallbackdef(signature, t)
    return function(context)
      if not context then return 'callbackdef' end
      local sinterp = { 
        signature = signature,
        params = '',
        returns = '',
        content = tconcat(t, 'callbackdef') or '',
        brief = '',
      }

      if type(t[1]) == 'string' then
        sinterp.brief = t[1]
      end

      if t.params then
        for k, v in ipairs(t.params) do
          t.params[k] = v('argument')
        end
        sinterp.params = [[
        <div class="arguments">
          <span class="arguments">arguments</span>
          <dl class="arguments">${arguments}</dl>
        </div>]] % {arguments=tconcat(t.params, 'params')}
      end

      if t.returns then
        for k, v in ipairs(t.returns) do
          t.returns[k] = v('returns')
        end
        sinterp.returns = [[
        <div class="returns">
          <span class="returns">returns</span>
          <dl class="returns">${returns}</dl>
          </div>
        ]] % {returns=tconcat(t.returns, 'returns')}
      end

      return [[
      <div class="callbackdef">
        <h4 class="callbacksig">
          ${signature}&nbsp;
          <span class="callbackdesc">${brief}</span>
        </h4>
        <div class="callbackfulldesc">
        <p>${content}</p>
        ${params}
        ${returns}
        </div>
      </div>
      ]] % sinterp
    end
  end
  callbackdef = setmetatable({}, {
    __index = function(t, k)
      return function(t)
        return newcallbackdef(k, t);
      end
    end
  })
end

do
  local function newparam(paramtype, param)
    return function(context)
      if not context then return 'param' end
      if context == 'returns' then
        if type(param) == 'string' then
          local content = param
          return[[
          <dt><code>${type}</code></dt> 
          <dd>${content}</dd>
          ]] % {type=paramtype, content=content}
        else
          local content = tconcat(param, 'param')
          return[[
          <dt><code>${type}</code></dt> 
          <dd>${content}</dd>
          ]] % {type=paramtype, content=content}
        end 
      else
        if type(param) == 'string' then
          local name, content = param:match('(%S+)%s+.%s+(.*)')
          return[[
          <dt><code><span class="paramname">${name}</span>&nbsp;<span class="paramtype">${type}</span></code></dt> 
          <dd>${content}</dd>
          ]] % {type=paramtype, name=name, content=content}
        else
          local name = param.name
          local content = tconcat(param, 'param')
          return[[
          <dt><code><span class="paramname">${name}</span>&nbsp;<span class="paramtype">${type}</span></code></dt> 
          <dd>${content}</dd>
          ]] % {type=paramtype, name=name, content=content}
        end
      end
    end
  end
  param = setmetatable({}, {
    __index = function(t, k)
      return function(v)
        return newparam(k, v)
      end
    end
  })
end

do
  local function newlist(t)
    return function(context)
      if not context then return 'list' end
      local content = {}
      for k, v in ipairs(t) do
        if type(v) == 'function' then v = v('list') end
        content[k] = '<li>' .. v .. '</li>'
      end

      return [[<div class="list">
      ${header}
      <ul>
      ${content}
      </ul>
      </div>]] % { 
        header=t.header or '',
        content=table.concat(content),
      }
    end
  end
  list = function(t) 
    return newlist(t)
  end
end



do
  local function newkey(name, s)
    if type(s) == 'table' then 
      return function(context)
        return [[
          <dt class="key">${name}</dt>
          <dd class="value">
            <dl class="innertabledef">
              ${content}
            </dl>
          </dd>]] % {
          name=name,
          content=tconcat(s, 'innertabledef') or '',
        }
      end
    else
      return function(context) 
        if not context then return 'key' end
        return [[<dt class="key">${name}</dt><dd class="value">${content}</dd>]] % {
          name=name,
          content=s,
        }
      end
    end
  end
  key = setmetatable({}, {
    __index = function(t, k)
      return function(v)
        return newkey(k, v)
      end
    end
  })
end

do
  local function newcode(s)
    return function(context)
      if not context then return 'code' end
      local content = {}
      local line = s:match('(.-)\r?\n') or s
      local spaces = #(line:match('^(%s+)') or '')
      local pattern = '\r?\n' .. string.rep(' ', spaces)
      s = s:gsub(pattern, '\n'):sub(1 + spaces)
      
      for line in s:gmatch('(.-)\n') do
        content[#content +1] = '<code>' .. line .. '</code>'
      end

      return '<div class="code"><pre>' .. table.concat(content, '\n') .. '</pre></div>'
    end
  end
  code = function(s) 
    return newcode(s)
  end
end

do
  local function newdescriptiondef(signature, t)
    return function(context)
      if not context then return 'descriptiondef' end
      local sinterp = { 
        signature = signature,
        params = '',
        returns = '',
        content = tconcat(t, 'descriptiondef') or '',
        brief = '',
      }

      if type(t[1]) == 'string' then
        sinterp.brief = t[1]
      end

      if t.params then
        for k, v in ipairs(t.params) do
          t.params[k] = v('argument')
        end
        sinterp.params = [[
        <div class="arguments">
          <span class="arguments">entries</span>
          <dl class="arguments">${arguments}</dl>
        </div>]] % {arguments=tconcat(t.params, 'params')}
      end

      return [[
      <div class="descriptiondef">
        <p class="descriptiondefheader">description</p>
        <h3 class="descriptiondefsig">
          ${signature}&nbsp;
          <span class="descriptiondefdesc">${brief}</span>
        </h3>
        <div class="descriptiondeffulldesc">
        <p>${content}</p>
        ${params}
        </div>
      </div>
      ]] % sinterp
    end
  end
  descriptiondef = setmetatable({}, {
    __index = function(t, k)
      return function(t)
        return newdescriptiondef(k, t);
      end
    end
  })
end

do
  local _inputs = require '_inputs'
  local fout
  function _writefile(text)
    fout:write(text)
  end

  for i, name in ipairs(_inputs) do
    fout = io.open(name .. '.html', 'w')

    print(name) io.flush()
    require(name)

    fout:close()
  end
end
