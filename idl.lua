local idl = {}

local mods = {}

idl.mods = mods

local function add_method(t)
    for id, m in pairs(t) do
       m.id=id
       local id_t = idl.int "id" "ID"
       id_t.default=id
       if m.req then
       table.insert( m.req, 1,id_t)
       end
       if m.res then
        table.insert( m.res, 1,id_t)
       end
       mods.methods[#mods.methods+1] = m
    end
  end

function idl.mod(modname)
    mods.modname = modname
    mods.methods = {}
    return function (v)
        mods.comment = v
      return add_method
    end
  end

function idl.comment (str)
    return {type = "comment",value = str}
end

function idl.api(funcname)
    local f = {name = funcname}
    local function add_val(t)
      for _,v in ipairs(t) do
        if v.type == "req" then
          f.req = v.value
        elseif v.type == "res" then
          f.res = v.value
        elseif v.type == "comment" then
          f.comment = v.value
        end
      end
      return f
    end
    return function (t)
      f.comment = t
      return add_val
    end
end

function idl.req(t)
    return {type = "req",value = t}
end

function idl.res(t)
    return {type = "res",value = t}
end

function idl.int(val)
    local t = {type = "int",value = val}
    return function(str)
      t.comment = str
      return t
    end
end

function idl.long(val)
    local t = {type = "long",value = val}
    return function(str)
      t.comment = str
      return t
    end
  end

function idl.string(val)
    local t = {type = "String",value = val}
    return function(str)
      t.comment = str
      return t
    end
end

local clz = {}

idl.clz = clz

local function class(_, methodname)
  local function def(val)
    local t = {type = clz[methodname].name,value = val}
    return function(str)
      clz[methodname].comment=str
      t.comment = str
      return t
    end
  end
  return def
end

idl.class = setmetatable({}, {__index = class})

function idl.classdef(name)
  local t = {type = "classdef", name = name}
  return function(value)
        t.value = value
        clz[t.name] = t
  end
end

return idl