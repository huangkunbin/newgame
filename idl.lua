local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function sort_methods(a, b)
    return tonumber(a.id) < tonumber(b.id)
end

local function getinnertype(typ)
    if string.sub(typ, 1, 4) == "List" then
        return string.sub(typ, 6, #typ - 1)
    end
    return typ
end

local function addfieldtype(t)
    local innertype = getinnertype(t.type)
    if innertype == "Integer" then
        t.fieldType = "FieldType.INT32"
    elseif innertype == "Long" then
        t.fieldType = "FieldType.INT64"
    elseif innertype == "Boolean" then
        t.fieldType = "FieldType.BOOL"
    end
    return t
end

local function typedef(_, name)
    local t = { type = name }
    t = addfieldtype(t)
    local function def(self, val)
        self.value = val
        return function(str)
            self.comment = str
            local nt = {}
            nt.type = self.type
            nt.fieldType = self.fieldType
            nt.value = self.value
            nt.comment = self.comment
            return nt
        end
    end
    setmetatable(t, { __call = def })
    return t
end

local idl = setmetatable({}, { __index = typedef })

idl.getinnertype = getinnertype

local function add_comment(comments, str)
    comments[#comments + 1] = str
end

idl.comment = setmetatable({}, { __call = add_comment })

local function add_method(m, t)
    for id, method in pairs(t) do
        method.id = id
        local id_t = idl.int "id" "ID"
        id_t.default = id
        if method.req then
            table.insert(method.req, 1, id_t)
        end
        if method.res then
            table.insert(method.res, 1, id_t)
        end
        m.methods[#m.methods + 1] = method
    end
    table.sort(m.methods, sort_methods)
end

local function moddef(m, modname)
    m.modname = modname
    m.methods = {}
    return function(v)
        m.comment = v
        return function(t)
            add_method(m, t)
        end
    end
end

idl.mod = setmetatable({}, { __call = moddef })

local function apidef(_, funcname)
    local f = { name = funcname }
    local function add_val(t)
        for _, v in pairs(t) do
            if v.type == "req" then
                f.req = v.value
            elseif v.type == "res" then
                f.res = v.value
            else
                f.desc = v
            end
        end
        return f
    end
    return function(str)
        f.comment = str
        return add_val
    end
end

idl.api = setmetatable({}, { __call = apidef })

function idl.req(t)
    return { type = "req", value = t }
end

function idl.res(t)
    return { type = "res", value = t }
end

local clz = {}
idl.clz = clz

local function classdef(_, name)
    name = trim(name)
    local t = { type = "classdef", name = name }
    return function(value)
        t.value = value
        clz[t.name] = t
    end
end

local function classcreate(_, classname)
    local name = clz[classname].name
    return idl[name]
end

idl.class = setmetatable({}, { __index = classcreate, __call = classdef })

function idl.list(E)
    if type(E) == "table" then
        E.type = "List<" .. E.type .. ">"
        return E
    else
        E = trim(E)
        local name = "List<" .. E .. ">"
        return idl[name]
    end
end

return idl
