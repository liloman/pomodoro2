-- Create the class
local Db={}

function Db:new(globalPath)
    local obj={}
    local path
    setmetatable(obj,self)
    self.__index=self
    require "luasql.sqlite3"
    -- create environment object
    env = assert (luasql.sqlite3())
    -- connect to data source
    if globalPath then 
        path=globalPath.."/pomodoroTasks.sqlite"
    else
        path=os.getenv("PWD").."/pomodoroTasks.sqlite"
    end
    con = assert(env:connect(path))
    return obj
end



function Db:sql(str)
    cur = assert(con:execute(str))
end 

function Db:select(str)
    print("Select ".. str)
    cur = assert(con:execute(str))
    return function() return cur:fetch() end
end

function Db:close()
    con:close()
    env:close()
end
return Db
