local lgi = require 'lgi'
local GObject = lgi.GObject
local Gtk = lgi.require('Gtk', '3.0')
local db=require("db")
db:new()
local sugCategory = Gtk.ListStore.new { GObject.Type.STRING }
local sugTask = Gtk.ListStore.new { GObject.Type.STRING }
local sugComment = Gtk.ListStore.new { GObject.Type.STRING }
-----------------------------------------------

local windowMain = Gtk.Window {
    --  modal='true',
    --type= 'POPUP',
    title='PomodoroTasks Main',
    resizable='false',
    can_focus='true',
    window_position='CENTER',
    on_destroy=Gtk.main_quit,
    default_width=498,
    default_height=166
}


local vbox = Gtk.VBox()
local statusBar=Gtk.Statusbar()
local ctx=statusBar:get_context_id('default')
statusBar:push(ctx,"Write new in a field to add one.")
local gridMain = Gtk.Grid { column_homogeneous='true' }
local title=Gtk.Label {label="pomodoroTasks"}
vbox:pack_start(title, false, false, 0)
vbox:pack_start(gridMain, false, false, 0)
gridMain:add(Gtk.Label {label="Categoria"}, { top_attach=0,left_attach=0})
gridMain:add(Gtk.Label {label="Tarea"}, { top_attach=0,left_attach=1})
gridMain:add(Gtk.Label {label="Comentarios"}, { top_attach=0,left_attach=2})


local cbCategory=Gtk.ComboBoxText{id="cbCategory",has_entry=true}
local cbTask=Gtk.ComboBoxText{id="cbTask",has_entry=true}
local cbComment=Gtk.ComboBoxText{id="cbComment",has_entry=true}
gridMain:add(cbCategory, { top_attach=1,left_attach=0})
gridMain:add(cbTask, { top_attach=1,left_attach=1})
gridMain:add(cbComment, { top_attach=1,left_attach=2})


--To get autocompletion in the comboboxes
function setCompletion(cb,sug)
    local entry=cb:get_child()
    entry.completion = Gtk.EntryCompletion { model = sug, text_column = 0}
end

--Set all comboboxes
setCompletion(cbCategory,sugCategory)
setCompletion(cbTask,sugTask)
setCompletion(cbComment,sugComment)



--Buttons
-------------------------
local gridButtons = Gtk.Grid {margin_left=40,margin_right=40,margin_top=44,column_homogeneous=true }

local botonCommand=Gtk.Button{id="buttonCommand", width_request=40,halign=center,label="Start",sensitive=false}
function  botonCommand:on_clicked() addNew() end
gridButtons:add(botonCommand, { top_attach=2,left_attach=1})

local botonCancel=Gtk.Button{width_request=40,halign=center,label="Cancel"}
function  botonCancel:on_clicked() quit() end
gridButtons:add(botonCancel,{ top_attach=2,left_attach=2})

vbox:pack_start(gridButtons, false, false, 0)
vbox:pack_end(statusBar,false,false,0)


function getEntryText(cb)
    local entry= cb:get_child()
    return entry.text
end

function setEntryText(cb,text)
    local entry= cb:get_child()
    entry.text=text
end

function fillCbCategory()
    sugCategory:clear()
    for name in db:select("SELECT name from categoriesNd") do
        cbCategory:append_text(name)
        sugCategory:append{name}
    end
    --db:cur()
end

--Execute on start
fillCbCategory()

function addOnChange(cb,class)
    local entry=cb:get_child()
    function entry:on_changed() 
        statusBar:push(ctx,"Write new in a field to add one.")
        if self.text then
            if cb.id=="cbCategory" then
                genericFill(self.text,cbTask,sugTask)
            end
            if cb.id=="cbTask" then
                genericFill(self.text,cbComment,sugComment)
            end
            if cb.id=="cbComment" and self.text~="" and self.text~="new" then
                gridButtons.child.buttonCommand.label="Pomodoro it!"
                gridButtons.child.buttonCommand:set_sensitive(true)
            else
                gridButtons.child.buttonCommand.label="Filling..."
                gridButtons.child.buttonCommand:set_sensitive(false)
            end
            if self.text == "new" then 
                gridButtons.child.buttonCommand.label="Add New "..class
                gridButtons.child.buttonCommand:set_sensitive(true)
            end
        end
    end
end

addOnChange(gridMain.child.cbCategory,"Category")
addOnChange(gridMain.child.cbTask,"Task")
addOnChange(gridMain.child.cbComment,"Comment")


function genericFill(val,cb,sug)
    local sql=""
    if cb.id=="cbTask" then
        sql="SELECT task from tasksCategories where cat='"..val.."'"
    else --cbComment
        sql="SELECT comment from commentsTasksCategories where task='"..val.."'"
    end
    cb:remove_all()
    sug:clear()
    local entry=cb:get_child()
    entry.text=""
    for name in db:select(sql) do
        cb:append_text(name)
        sug:append{name}
    end
end

function activePomodoro(rowid)
    local sql="update comments set active=1 where rowid="..rowid
    db:sql(sql)
    setEntryText(cbCategory,"")
    setEntryText(cbComment,"")
    setEntryText(cbTask,"")
    cbCategory:grab_focus()
end

function addPomodoroWidget(rowid,name)
        for co,ta,ca in db:select("select co,ta,ca from getIcon where rowid="..rowid) do
            local image=""
            if co~="" then image=co
            elseif ta~="" then image=ta
            elseif ca~="" then image=ca
            else image="pomodoroDefault.png"
            end
            local cmd="echo 'addPomodoroWidget("..rowid..",\""..name.."\",\""..image.."\")' | awesome-client"
            os.execute(cmd)
        end
end


function addNew()
    local label=gridButtons.child.buttonCommand.label
    if label=="Pomodoro it!" then
        local comment=getEntryText(cbComment)
        local category=getEntryText(cbCategory)
        local task=getEntryText(cbTask)
        if (category~="new" and task~="new" and comment~="" and category~="" and task~="") then
            local sql="select rowid from comments where comment='"..comment.."' and nameCategory='"..category.."' and nameTask='"..task.."'"
            local res=db:select(sql)
            local rowid=res()
            if rowid then 
                print("PomodoroWidgets... ")
                activePomodoro(rowid)
                addPomodoroWidget(rowid,category.."|"..task.."|"..comment)
                --quit()
            else 
                statusBar:push(ctx,'All the fields must be have real values.')
            end
        else 
            statusBar:push(ctx,'All the fields must be filled properly.')
        end
    elseif label=="Add New Task" then 
        newObject("Task",sugTask)
    elseif label=="Add New Comment" then 
        newObject("Comment",sugComment)
    else -- Add New Category
        newObject("Category",sugCategory)
    end
end

--Insert a new type of category|task|Comment
function newObject(object,sug)
    wdialog = Gtk.Dialog {
        title = "New "..object,
        resizable = false,
        on_response = Gtk.Widget.destroy,
        buttons = {  { Gtk.STOCK_CLOSE, Gtk.ResponseType.NONE } },
        --on_destroy=Gtk.main_quit
    }
    content = Gtk.Box {
        id="content",
        orientation = 'VERTICAL',
        spacing = 5,
        border_width = 5,
        Gtk.Label {
            label ="The "..object.." must be new.Can't use recently used to get the icon (bug).",
            use_markup = true,
        },
        Gtk.Entry {
            id = 'entryNew',
            completion = Gtk.EntryCompletion { model = sug, text_column = 0, }, 
        },
        Gtk.FileChooserButton {
            id='iconChooser',
            title = "PomodoroTasks Icon Chooser",
            action = 'OPEN',
        },
        Gtk.Button{
            id="newObject",
            height=30,
            width=30,
            label="Add new "..object
        },
    }
    --Maybe ugly
    local iconPath=os.getenv("HOME")..'/.config/awesome/pomodoroTasks/icons/'
    local iconChooser=content.child.iconChooser
    iconChooser:set_current_folder(iconPath)
    function content.child.newObject:on_clicked() 
        local currentFilename=iconChooser:get_filename()
        --If uses currently used this will fail
        local currentPath=iconChooser:get_current_folder().."/"
        if currentPath~=iconPath then
            local cmd="cp -v '"..currentFilename.."' '"..iconPath.."'"
            os.execute(cmd)
        end
        local filename=""
        if currentFilename then
            filename=string.sub(currentFilename,string.len(currentPath)+1) 
        end
        addNewObject(object,filename) 
        wdialog:destroy()  --Quit on insert
    end
    wdialog:get_content_area():add(content)
    wdialog:show_all()
end

function addNewObject(object,filename)
    local obj=content.child.entryNew.text
    local sql
    if obj then
        if object=="Category" then
            sql="insert into categories (name,icon) values ('"..obj.."','"..filename.."')"
            db:sql(sql)
            cbCategory:remove_all()
            fillCbCategory()
            cbCategory:grab_focus()
            setEntryText(cbCategory,obj) 
            --cbCategory:set_active(#sugCategory-1)
        elseif object=="Comment" then
            local category=getEntryText(cbCategory)
            local task=getEntryText(cbTask)
            sql="insert into comments (comment,nameCategory,nameTask,icon) values ('"..obj.."','"..category.."','"..task.."','"..filename.."')"
            db:sql(sql)
            cbComment:remove_all()
            genericFill(obj,cbComment,sugComment)
            cbComment:grab_focus()
            setEntryText(cbComment,obj) 
            --cbComment:set_active(#sugComment-1)
        else --tasks
            local cat=getEntryText(cbCategory)
            sql="insert into tasks (name,nameCategory,icon) values ('"..obj.."','"..cat.."','"..filename.."')"
            db:sql(sql)
            cbTask:remove_all()
            genericFill(obj,cbTask,sugTask)
            cbTask:grab_focus()
            setEntryText(cbTask,obj) 
            --cbTask:set_active(#sugTask-1)
        end
    end
end

--Main quit
function quit()
    windowMain:destroy()
end

--
--------------------------------------------------------------
--w.on_destroy = Gtk.main_quit

windowMain:add(vbox)
windowMain:show_all()
Gtk.main()

