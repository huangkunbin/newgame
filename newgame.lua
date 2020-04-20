local idl = require "idl"
local etlua = require "etlua"
-- local inspect = require("inspect")

local PROJECT_NAME = "demo"
local TEMPLATES_PATH = "templates/default"
local MESSAGE_PATH = "message/"
local CLASS_PATH = "class/"
local HANDLER_PATH = "handler/"



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
env.require = require

local proto = arg[1]
loadfile(proto,"t",env)()

local function file_exists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

local function create_file(type,temp_file_path,parameter)
  local template_file = assert(io.open(temp_file_path))
  local template = template_file:read("*a")
  template_file:close()

  local str = etlua.compile(template)
  local file = str(parameter)

  local file_path
  local file_name
  if type=="Class" then
    file_path = CLASS_PATH
    file_name =file_path..parameter.name:gsub("%a", string.upper, 1)..".java"
  elseif type == "Handler" then
    file_path = HANDLER_PATH
    file_name =file_path.."Req"..parameter.name:gsub("%a", string.upper, 1)..type..".java"
  else
    file_path = MESSAGE_PATH
    file_name =file_path..type..parameter.name:gsub("%a", string.upper, 1).."Class.java"
  end

  if not file_exists(file_path) then
    os.execute("mkdir "..file_path)
  end

  if type=="Req" or type=="Res" then
    file_name = file_name.."Class.java"
  end

  local code = assert(io.open(file_name, 'w'))
  code:write(file)
  code:close()
end

local module = idl.mods

local parameter = {}
parameter.projectname = PROJECT_NAME
parameter.modname = module.modname
for _,m in ipairs(module.methods) do
    parameter.name = m.name
    parameter.comment = m.comment
    parameter.req = m.req
    parameter.res = m.res
    if parameter.req then
    create_file("Req",TEMPLATES_PATH.."/req.etlua",parameter)
    create_file("Handler",TEMPLATES_PATH.."/handler.etlua",parameter)
    end
    if parameter.res then
    create_file("Res",TEMPLATES_PATH.."/res.etlua",parameter)
    end
end

local clz = idl.clz

parameter = {}
parameter.projectname = PROJECT_NAME
parameter.modname = module.modname
for _,c in pairs(clz) do
  parameter.name = c.name
  parameter.comment = c.comment
  parameter.value = c.value
  create_file("Class",TEMPLATES_PATH.."/class.etlua",parameter)
end



