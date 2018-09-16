-- Script for storing key/value data in file
-- LGPL v2.1
-- Disk I/O and RAM usage much smaller than serialized file approach
-- By default, keys and values must not contain carriage returns!

jtdb = {}
-- jtdb.mutual_table = {} -- this table is mutual to all jtdb instances

-- when new instance is created, open two files filenamebase.jtdb and filenamebase.jtid
-- file handles are open until script end.
function jtdb:new(filenamebase)
    local o = {}
    setmetatable(o, self)   -- something for overloading.
    self.__index = self
    o.filenamebase = filenamebase
    o.id = {}
    o.id_lowercase = {}  -- For case insensitive serach
    o.use_cache = false  -- cache to avoid repeated read (+escaping) operations.
    o.do_flush = true   -- without flush is faster but risk of loosing data
    o.cache = {}
    o.escape_value = false
    o.empty_value = nil -- what to return when no value is found. "" or {} may be useful
    o.dbfile = io.open(o.filenamebase .. ".jtdb", "a+")
    o.idfile = io.open(o.filenamebase .. ".jtid", "a+")
    assert(o.dbfile, "Cannot open/create "..o.filenamebase .. ".jtdb")
    assert(o.idfile, "Cannot open/create "..o.filenamebase .. ".jtid")
    if o.dbfile:seek("end") > 0 then
        o:idfile_read()
    end
    return o
end

function jtdb:read(key)
    if self.use_cache and self.cache[key] then
        return self.cache[key]
    end
    if self.id[key] ~= nil then
        self.dbfile:seek("set", self.id[key])
        local value = self.dbfile:read("*line")
        if self.escape_value then
            value = self.unescape_v(value)
        end
        if self.use_cache then
            self.cache[key] = value
        end
        return value
    else
        if type(self.empty_value) == "table" then
            return {}   -- temporary solution! Need to clone table here!
        else
            return self.empty_value
        end
    end

end

function jtdb:write(key, value)
    local is_update = false
    if self.id[key] ~= nil then
        is_update = true
    end
    self.id[key] = self.dbfile:seek("end")
    self.id_lowercase[string.lower(key)] = self.id[key]
    if self.use_cache then
        self.cache[key] = value
    end
    if self.escape_value then
        value = self.escape_v(value, key)
    end
    self.dbfile:write(value .. "\n")    -- only append, no deletions or updates for now
    if self.do_flush then
        self.dbfile:flush()
    end
    if is_update and math.random(1, 10000) <= 1 then
        self:idfile_write()
        if math.random(1, 10) <= 1 then
            self:mantain()
        end
    else
        self:idfile_append(key)
    end
end

function jtdb:delete(key)
    local is_update = false
    if self.id[key] ~= nil then
        is_update = true
    end
    self.id[key] = nil
    self.id_lowercase[string.lower(key)] = nil
    if self.use_cache then
        self.cache[key] = nil
    end
    if is_update then
        self:idfile_write()
        if math.random(1, 10000) <= 1 then
            self:mantain()
        end
    end
end

function jtdb:write_array(many_pairs, mantain)
    for key, value in pairs(many_pairs) do
        self.id[key] = self.dbfile:seek("end")
        self.id_lowercase[string.lower(key)] = self.id[key]
        if self.use_cache then
            self.cache[key] = value
        end
        if self.escape_value then
            value = self.escape_v(value, key)
        end
        self.dbfile:write(value .. "\n")    -- only append, no deletions or updates for now
        if self.do_flush then
            self.dbfile:flush()
        end
    end
    self:idfile_write() -- write id file only once!
    if mantain then
        self:mantain()
    end
end

function jtdb:delete_array(many_keys, mantain)
    for _, key in pairs(many_keys) do
        self.id[key] = nil
        self.id_lowercase[string.lower(key)] = nil
        if self.use_cache then
            self.cache[key] = nil
        end
    end
    self:idfile_write()
    if mantain then
        self:mantain()
    end
end

-- only for end of execution!
function jtdb:close()
    self:mantain()
    self.dbfile:close()
    self.idfile:close()
end

function jtdb.escape_v(value, key)
    assert(type(value) == "string",
        "By default only strings without carriage returns will work! Override jtdb escape_v() and unescape_v() if really needet.")
    return value
end
function jtdb.unescape_v(value, key)
    return value
end

function jtdb:idfile_read()
    self.id = {}
    local is_key = true
    local key = nil
    for line in self.idfile:lines() do
        if is_key then
            key = line
            is_key = false
        else
            self.id[key] = tonumber(line)
            is_key = true
        end
    end
    for k, v in pairs(self.id) do
        self.id_lowercase[string.lower(k)] = v
    end
end

function jtdb:idfile_append(key)
    self.idfile:write(key, "\n", self.id[key], "\n")
    if self.do_flush then
        self.idfile:flush()
    end
end

function jtdb:idfile_write()
    self.idfile:close()
    self.idfile = io.open(self.filenamebase .. ".jtid", "w")
    local tostring_buffer = {}
    for key, value in pairs(self.id) do
        table.insert(tostring_buffer, key)
        table.insert(tostring_buffer, value)
    end
    if #tostring_buffer > 0 then
        table.insert(tostring_buffer, "")    -- add "\n" to the end of resulting string
    end
    self.idfile:write(table.concat(tostring_buffer, "\n"))
    self.idfile:close()
    self.idfile = io.open(self.filenamebase .. ".jtid", "a+")
end

-- use temporaty file and leave old file as filenamebase.jtdbbk
-- read all actual lines and write them to new file
-- running this from time to time will keep base file size small
function jtdb:mantain()
    local tmpfile = io.open(self.filenamebase .. ".jtdbtmp", "w")
    local tmpid = {}
    local tmpid_lowercase = {}
    for key, val in pairs(self.id) do
        self.dbfile:seek("set", val)
        local value = self.dbfile:read("*line")
        tmpid[key] = tmpfile:seek("end")
        tmpid_lowercase[string.lower(key)] = tmpid[key]
        tmpfile:write(value .. "\n")
    end
    tmpfile:close()
    self.dbfile:close()
    os.rename(self.filenamebase .. ".jtdb", self.filenamebase .. ".jtdbbk")
    assert(os.rename(self.filenamebase .. ".jtdbtmp", self.filenamebase .. ".jtdb"), "Mod jtdb maintenance failed, cannot write "..self.filenamebase .. ".jtdb".." file")
    self.id = tmpid
    self.id_lowercase = tmpid_lowercase
    self:idfile_write()
    self.dbfile = io.open(self.filenamebase .. ".jtdb", "a+")
end

-- tests
-- dofile(minetest.get_modpath(minetest.get_current_modname()).."/tests.lua")

-- file operations
-- https://www.lua.org/pil/contents.html#21
