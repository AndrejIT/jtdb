jtdb - justtest database
===========

Helper library for Minetest game -
Persistent key-value data storage.

Small disk i/o and RAM memory usage.
Suitable for medium-size data sets(~100MB).

WARNINGS:
Editing files manually will break data!
Strings without carriage returns must be used for keys and values.
Not really useful if data is smaller then key.
"Delete" is much expensive operation then "read" and "write"


Functions:
local mybase = jtdb:new(<path to your folder> .. "/testfile")
mybase:write("123", "apple")
mybase:read("123")
mybase:write_array({["234"] = "pear", ["345"] = "banana"})
mybase:delete("123")
mybase:delete_array({"123", "234", "345"})

Advanced usage:
local mybase = jtdb:new(<path to your folder> .. "/testfile")
mybase.escape_value = true
mybase.use_cache = true
mybase.escape_v = function(value, key)
    assert(type(value) == "table")
    return value.name..":"..value.type
end
mybase.unescape_v = function(value, key)
    local name, type = string.match(value, "([^:]*):([^:]*)")
    return {name=name, type=type}
end
mybase:write_array({
    ["123"] = {name = "apple", type = "fruit"},
    ["234"] = {name = "pear", type = "fruit"},
    ["345"] = {name = "banana", type = "fruit"},
})
mybase:write("234", {name = "carrot", type = "vegetable"})
for key, _ in pairs(mybase.id) do
    print(mybase:read(key).name)
end
