
function jtdb_run_tests()
    minetest.after(10, function()
        minetest.chat_send_all("jtdb test 01:")
        local mybase01 = jtdb:new(minetest.get_worldpath() .. "/testfile01")
        mybase01:write("123", "apple")
        mybase01:write("234", "pear")
        mybase01:write("345", "banana")
        mybase01:delete("234")
        for key, _ in pairs(mybase01.id) do
            minetest.chat_send_all(mybase01:read(key))
        end
        minetest.chat_send_all("jtdb test 01 done. "..#(mybase01.id).." records in table.")

        minetest.chat_send_all("jtdb test 02:")
        local mybase02 = jtdb:new(minetest.get_worldpath() .. "/testfile02")
        mybase02.escape_value = true
        mybase02.escape_v = function(value, key)
            assert(type(value) == "table")
            return value.name..":"..value.type
        end
        mybase02.unescape_v = function(value, key)
            local name, type = string.match(value, "([^:]*):([^:]*)")
            return {name=name, type=type}
        end
        mybase02:write_array({
            ["123"] = {name = "apple", type = "fruit"},
            ["234"] = {name = "pear", type = "fruit"},
            ["345"] = {name = "banana", type = "fruit"},
        })
        mybase02:write("234", {name = "carrot", type = "vegetable"})
        for key, _ in pairs(mybase02.id) do
            minetest.chat_send_all(mybase02:read(key).name)
        end
        minetest.chat_send_all("jtdb test 02 done. "..#(mybase02.id).." records in table.")

        minetest.chat_send_all("jtdb test 03:")
        local mybase03 = jtdb:new(minetest.get_worldpath() .. "/testfile03")
        mybase03.escape_value = true
        mybase03.use_cache = true
        mybase03.escape_v = function(value, key)
            assert(type(value) == "table")
            return value.name..":"..value.type
        end
        mybase03.unescape_v = function(value, key)
            local name, type = string.match(value, "([^:]*):([^:]*)")
            return {name=name, type=type}
        end
        mybase03:write_array({
            ["123"] = {name = "apple", type = "fruit"},
            ["234"] = {name = "pear", type = "fruit"},
            ["345"] = {name = "banana", type = "fruit"},
        })
        mybase03:write("234", {name = "carrot", type = "vegetable"})
        for key, _ in pairs(mybase03.id) do
            minetest.chat_send_all(mybase03:read(key).name)
        end
        minetest.chat_send_all("jtdb test 03 done. "..#mybase03.id.." records in table.")

        local time1 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 04:")
        local mybase04 = jtdb:new(minetest.get_worldpath() .. "/testfile04")
        for i=1,1000 do
            mybase04:write(tostring(math.random(1, 10000)), tostring(math.random(1, 10000000000000000)))
        end
        local time2 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 04 done. Time for 1000 writes "..((time2-time1)/1000000).." seconds")

        time1 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 05:")
        local mybase04 = jtdb:new(minetest.get_worldpath() .. "/testfile04")
        local myarray = {}
        for i=1,10000 do
            myarray[tostring(math.random(1, 10000))] = tostring(math.random(1, 10000000000000000))
        end
        mybase04:write_array(myarray)
        time2 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 05 done. Time for 10000 writes (in one chunk) "..((time2-time1)/1000000).." seconds")

        time1 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 06:")
        for i=1,100000 do
            local value = mybase04:read(tostring(math.random(1, 10000)))
        end
        time2 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 06 done. Time for 100000 reads "..((time2-time1)/1000000).." seconds")

        time1 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 07:")
        local mybase04 = jtdb:new(minetest.get_worldpath() .. "/testfile04")
        for i=1,1000 do
            mybase04:write(tostring(math.random(1, 10000)), tostring(math.random(1, 10000000000000000)))
        end
        time2 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 07 done. Time for 1000 writes "..((time2-time1)/1000000).." seconds")

        time1 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 08:")
        local mybase04 = jtdb:new(minetest.get_worldpath() .. "/testfile04")
        for i=1,100 do
            mybase04:delete(tostring(math.random(1, 10000)))
        end
        time2 = minetest.get_us_time()
        minetest.chat_send_all("jtdb test 08 done. Time for 100 deletes "..((time2-time1)/1000000).." seconds")
    end)
end
jtdb_run_tests()
