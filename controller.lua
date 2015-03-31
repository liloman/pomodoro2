local wibox=require("wibox")
local naughty=require("naughty")
local awful=require("awful")
local pomodoroMaster = require("pomodoroTasks.pomodoroMaster")
local db = require("pomodoroTasks.db")
db:new(awful.util.getdir("config") .. "/pomodoroTasks")

--Global table
pomodoroWidgets={}
pomodoroWidgets.IconPath=awful.util.getdir("config") .."/pomodoroTasks/icons/"

--Get floating style all the apps 
shifty.config.apps = {
   { match = { name = { "PomodoroTasks*" } }, float = true }
}

-- tweak these values in seconds to your liking
pomodoroMaster.work_duration = 60 * 25
pomodoroMaster.pause_duration = 60 * 5
pomodoroMaster.timeOutMaster=60 * 2.5
pomodoroWidgets.timeOut= 1 * 60

-- Messages
pomodoroMaster.pause_title = "Everything comes to an end."
pomodoroMaster.pause_text = "Back to work!"
pomodoroMaster.work_title = "Go for beer."
pomodoroMaster.work_text = "Time to have some fun."
pomodoroMaster.timer = timer { timeout = pomodoroMaster.timeOutMaster }

--Start Master up
pomodoroMaster.init()
pomodoroLayout:add(pomodoroMaster.icon_widget)
pomodoroLayout:add(pomodoroMaster.widget)

----------------------------------------
--POMODOROTASKS WIDGETS

local function getButtonsWidget(widget)
    return awful.util.table.join(
    awful.button({},1,function() 
        if widget.working then
            widget.working=false
            widget.timer:stop()
        else
            widget.working=true
            widget.timer:start()
        end
    end),
    awful.button({},3,function()         
       delPomodoroWidget(widget.rowid)
    end)
    )
end

function addPomodoroWidget(rowid,desc,image)
    local imagePath=pomodoroWidgets.IconPath..image
    local timeOut=pomodoroWidgets.timeOut
    --Need to be careful...
    _G["pomodoroWidget"..rowid]= wibox.widget.imagebox(imagePath)
    local pmWidget=_G["pomodoroWidget"..rowid]
    pomodoroWidgets["pomodoroWidget"..rowid]=pmWidget
    pmWidget.desc=desc
    pmWidget.name="pomodoroWidget"..rowid
    pmWidget:buttons(getButtonsWidget(pmWidget))
    pmWidget.isWidget=true
    pmWidget.rowid=rowid
    pmWidget.timer = timer { timeout = timeOut }
    pmWidget.timer:connect_signal("timeout", function() 
        if pomodoroMaster.working then
            db:sql("insert into logs(rowidComments,duration,tagName) values("..rowid..","..timeOut..",'timeout')")
        end
    end)
    pmWidget.working=pomodoroMaster.working
    if pomodoroMaster.working==true then
        pmWidget.timer:start()
    end
    pomodoroLayout:add(pmWidget)
    awful.tooltip({
        objects = {pmWidget},
        timer_function = function()
            local active="No"
            if pmWidget.working==true then active="Yes" end
            local msg=pmWidget.desc.."\nStarted:"..active
               return msg
        end })
    end

    function delPomodoroWidget(rowid)
        local pomodoroWidget=_G["pomodoroWidget"..rowid]
        for i,k in ipairs(pomodoroLayout.widgets) do
            if k==pomodoroWidget then
                table.remove(pomodoroLayout.widgets,i)
                --Need some fixing. Not a neat way to clean the stuff...
                pomodoroWidget.timer:disconnect_signal("timeout",function() return  end)
                pomodoroWidget.timer:stop()
                pomodoroWidget.timer=nil
                pomodoroWiget=nil
                db:sql("update comments set active=0 where rowid="..rowid)
            end
        end
    end

    --Set on startup the actives one
    local function getActives()
        --While doesn't implement nested iterators...
        for co,ta,ca,cat,task,comment,rowid in db:select("select co,ta,ca,nameCategory,nameTask,comment,rowid from getActives") do
            local name=cat.."|"..task.."|"..comment
            local image=""
            if co~="" then image=co
                elseif ta~="" then image=ta
                elseif ca~="" then image=ca
                else image="pomodoroDefault.png"
            end
            addPomodoroWidget(rowid,name,image)
        end
    end

    --Set the actives 
    getActives()
    -------POMODOROTASKS WIDGETS
    ----------------------------------------
