local idl = require "idl"
local etlua = require "etlua"
local inspect = require("inspect")


local env = {}
env.mod = idl.mod
env.api = idl.api
env.comment = idl.comment
env.req = idl.req
env.res = idl.res
env.int = idl.int
env.long = idl.long
env.string = idl.string
env.classdef = idl.classdef
env.class = idl.class
env.list = idl.list
env.require = require

local proto = arg[1]
loadfile(proto,"t",env)()

local mod = idl.mods
local clz = idl.clz

local ROOT_PATH = "../../"
local conf_path = ROOT_PATH.."game-"..mod.modname.."-parent/config.lua"

local function file_exists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

if not file_exists(conf_path) then
  ROOT_PATH = "./"
  conf_path = ROOT_PATH.."config.lua"
end

local conf = loadfile(conf_path,"t")()

local PROJECT_NAME = conf.PROJECT_NAME
local TEMPLATES_PATH = ROOT_PATH..conf.TEMPLATES_PATH
local MESSAGE_PATH = ROOT_PATH..conf.MESSAGE_PATH
local CLASS_PATH = ROOT_PATH..conf.CLASS_PATH
local HANDLER_PATH = ROOT_PATH..conf.HANDLER_PATH
local MSGID_PATH = ROOT_PATH..conf.MSGID_PATH
local MARKDOWN_PATH = ROOT_PATH..conf.MARKDOWN_PATH



local function snake(s)
  return s:gsub('%f[^%l]%u','_%1'):gsub('%f[^%a]%d','_%1'):gsub('%f[^%d]%a','_%1'):gsub('(%u)(%u%l)','%1_%2'):lower()
end

local function create_file(typ,temp_file_path,parameter)
  local template_file = assert(io.open(temp_file_path))
  local template = template_file:read("*a")
  template_file:close()

  local str = etlua.compile(template)
  local file = str(parameter)

  local file_path
  local file_name
  if typ == "Class" then
    file_path = CLASS_PATH
    file_name = file_path..parameter.name:gsub("%a", string.upper, 1)..".java"
  elseif typ == "Handler" then
    file_path = HANDLER_PATH
    file_name = file_path.."Req"..parameter.name:gsub("%a", string.upper, 1)..typ..".java"
  elseif typ == "Msgid" then
    file_path = MSGID_PATH
    file_name = file_path..parameter.modname:gsub("%a", string.upper, 1).."ModuleMsgIdConstant.java"
  elseif typ == "Markdown" then
    file_path = MARKDOWN_PATH
    file_name = file_path..parameter.modname..".md"
  else
    file_path = MESSAGE_PATH
    file_name = file_path..typ..parameter.name:gsub("%a", string.upper, 1).."Msg.java"
  end

  if not file_exists(file_path) then
    os.execute("mkdir "..file_path)
  end

  if typ == "Handler" and file_exists(file_name) then
    return
  end


  local code = assert(io.open(file_name, 'w'))
  code:write(file)
  code:close()
end


local class_pkg_path = "import com."..PROJECT_NAME..".game.games."..mod.modname..".dto."

local function get_pkgs(args)
  local pkgs = {}
  for _,a in ipairs(args) do
   if clz[a.type] then
      pkgs[class_pkg_path..a.type] = class_pkg_path..a.type
   end
   if a.fieldType then
    pkgs["import com.baidu.bjf.remoting.protobuf.FieldType"] = "import com.baidu.bjf.remoting.protobuf.FieldType"
 end
   if string.sub(a.type,1,4) == "List" then
    pkgs["import java.util.List"] = "import java.util.List"
    if clz[a.innertype] then
      pkgs[class_pkg_path..a.innertype] = class_pkg_path..a.innertype
    end
   end
  end
  local sort_pkgs = {}
  for _,p in pairs(pkgs) do
    sort_pkgs[#sort_pkgs+1] = p
  end
  table.sort(sort_pkgs)
  return sort_pkgs
end

local parameter = {}

parameter.projectname = PROJECT_NAME
parameter.modname = mod.modname
parameter.comment = mod.comment
parameter.methods = mod.methods
parameter.snake = snake
create_file("Msgid",TEMPLATES_PATH.."msgid.etlua",parameter)
parameter.clz = clz
create_file("Markdown",TEMPLATES_PATH.."markdown.etlua",parameter)

parameter = {}
parameter.projectname = PROJECT_NAME
parameter.modname = mod.modname
for _,m in ipairs(mod.methods) do
    parameter.name = m.name
    parameter.comment = m.comment
    parameter.req = m.req
    parameter.res = m.res
    parameter.snake = snake
    if parameter.req then
    parameter.pkgs = get_pkgs(parameter.req)
    create_file("Req",TEMPLATES_PATH.."req.etlua",parameter)
    create_file("Handler",TEMPLATES_PATH.."handler.etlua",parameter)
    end
    if parameter.res then
    parameter.pkgs = get_pkgs(parameter.res)
    create_file("Res",TEMPLATES_PATH.."/res.etlua",parameter)
    end
end



parameter = {}
parameter.projectname = PROJECT_NAME
parameter.modname = mod.modname
for _,c in pairs(clz) do
  parameter.name = c.name
  parameter.comment = c.comment
  parameter.value = c.value
  parameter.pkgs = get_pkgs(c.value)
  create_file("Class",TEMPLATES_PATH.."class.etlua",parameter)
end






