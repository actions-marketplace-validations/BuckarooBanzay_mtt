
-- test emerge helper
mtt.emerge_area({x=0,y=0,z=0}, {x=32,y=32,z=32})

mtt.register("my func", function(callback)
    assert(true)
    callback()
end)