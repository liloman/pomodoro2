local beautiful = require("beautiful")
local naughty   = require("naughty")
local wibox     = require("wibox")
local awful     = require("awful")
local ipairs    = ipairs
local timer     = timer
local os        = os


local pomodoro_image_path = awful.util.getdir("config") .."/icons/widgets/pomodoro.png"
-- pomodoro timer widget
local pomodoro = {}
pomodoro.working     = false
pomodoro.pause       = false
pomodoro.widget      = wibox.widget.textbox()
pomodoro.icon_widget = wibox.widget.imagebox()

local function setColor(text,state)
    if not text then
        text=os.date("%M:%S", pomodoro.left)
    end
    local style
    if state=="start" then
        style= "<b>"..text.."</b>"
    elseif state=="stop" then
        style= "<s>"..text.."</s>"
    else -- Pause
        style= "<span foreground='red'>"..text.."</span>"
    end
    pomodoro.widget:set_markup(style)
end

local function togglePomodoroWidgets(start)
    for i,k in ipairs(pomodoroLayout.widgets) do  
        if k.isWidget then --It's an authentic pomodoroWidget
            if start==true then
                k.timer:start() 
                k.working=true
            else
                k.timer:stop() 
                k.working=false
            end
        end 
    end
end

--
function pomodoro.enterPause()
    togglePomodoroWidgets(false)
    pomodoro.pause=true
    pomodoro.last_time = os.time() 
    pomodoro.timer:start()
    setColor(nil,"pause")
end

function pomodoro.finishPause()
    pomodoro.pause=false
    pomodoro.Working=false
end

-- Callbacks to be called when the pomodoro finishes or the rest time finishes
pomodoro.on_work_pomodoro_finish_callbacks = { pomodoro.enterPause }
pomodoro.on_pause_pomodoro_finish_callbacks ={ pomodoro.finishPause }

function pomodoro:settime(t)
    if t >= 3600 then -- more than one hour!
        t = os.date("%X", t-3600)
    else
        t = os.date("%M:%S", t)
    end
    setColor(t,"start")
end

function pomodoro:notify(title, text, duration, working)
    naughty.notify {
        bg = beautiful.bg_urgent,
        fg = beautiful.fg_urgent,
        title = title,
        text  = text,
        timeout = pomodoro.pause_duration,
        hover_timeout=pomodoro.pause_duration,
        height=300,
        width=800,
        font="Terminus 28",
        position="top_left"
    }

    pomodoro.left = duration
    pomodoro.working = working
    pomodoro:settime(duration)
end


local function getButtonsTextMaster()
    --Tengo que recorrer los widgets del layout y comprobar si contienen working
    return awful.util.table.join(
    awful.button({ }, 1, function()
        if pomodoro.working then --pause
            pomodoro.timer:stop()
            setColor(nil,"stop")
            pomodoro.working = false
            togglePomodoroWidgets(false)
        else -- start
            pomodoro.last_time = os.time()
            pomodoro.timer:start()
            setColor(nil,"start")
            pomodoro.working = true
            togglePomodoroWidgets(true)
        end
    end),
    awful.button({ }, 3, function()
        if not pomodoro.working then --reset
            pomodoro.left = pomodoro.work_duration
            pomodoro:settime(pomodoro.work_duration)
        end
    end)
    )
end


local function getButtonsIconMaster()
    return awful.util.table.join(
    awful.button({ }, 1, function()
        local path = awful.util.getdir("config") .. "/pomodoroTasks/"
        os.execute('cd '..path..'; lua view.lua &')
    end)
    )
end


function pomodoro:init()
    -- Initial values that depend on the values that can be set by the user
    pomodoro.left = pomodoro.work_duration
    pomodoro.icon_widget:set_image(pomodoro_image_path)
    -- Timer configuration
    --
    pomodoro.timer:connect_signal("timeout", function()
        local now = os.time()
        pomodoro.left = pomodoro.left - (now - pomodoro.last_time)
        pomodoro.last_time = now
        if pomodoro.left > 0 then
            if pomodoro.pause==false then
                setColor(nil,"start")
                --pomodoro:settime(pomodoro.left)
            else
                setColor(nil,"pause")
            end
        else
            pomodoro.timer:stop()
            if pomodoro.working then
                pomodoro:notify(pomodoro.work_title, pomodoro.work_text,pomodoro.pause_duration,false)
                for _, value in ipairs(pomodoro.on_work_pomodoro_finish_callbacks) do
                    value()
                end
            else
                pomodoro:notify(pomodoro.pause_title, pomodoro.pause_text,pomodoro.work_duration,true)
                for _, value in ipairs(pomodoro.on_pause_pomodoro_finish_callbacks) do
                    value()
                end
            end
        end
    end)
    pomodoro:settime(pomodoro.work_duration)
    setColor(nil,"stop")
    pomodoro.widget:buttons(getButtonsTextMaster())
    pomodoro.icon_widget:buttons(getButtonsIconMaster())
    awful.tooltip({
        objects = { pomodoro.widget, pomodoro.icon_widget},
        timer_function = function()
            if pomodoro.timer.started then
                if pomodoro.working then
                    return 'Left ' .. os.date("%M:%S", pomodoro.left)
                else
                    return 'Keep on relaxing for ' .. os.date("%M:%S", pomodoro.left)
                end
            else
                return 'Stopped'
            end
            return 'Bad tooltip'
        end })
end

return pomodoro
