CREATE TABLE "categories" ("name" TEXT PRIMARY KEY  NOT NULL ,"date" TEXT DEFAULT (CURRENT_TIMESTAMP) ,"deleted" INTEGER DEFAULT (0) ,"Icon" TEXT DEFAULT ('') ,"duration" TEXT);
CREATE TABLE "comments" ("comment" TEXT PRIMARY KEY  NOT NULL ,"nameCategory" TEXT TEXT NOT NULL ,"nameTask" TEXT NOT NULL ,"Date" TEXT DEFAULT (CURRENT_TIMESTAMP) ,"Duration" INTEGER DEFAULT (0) ,"deleted" INTEGER DEFAULT (0) ,"active" INTEGER DEFAULT (0) ,"tags" TEXT,"ICON" TEXT DEFAULT ('') );
CREATE TABLE "logs" ("id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , "rowidComments" INTEGER NOT NULL , "duration" INTEGER NOT NULL , "date" TEXT NOT NULL  DEFAULT CURRENT_TIMESTAMP, "tagName" VARCHAR NOT NULL );
CREATE TABLE "tags" ("id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , "name" VARCHAR NOT NULL , "date" TEXT NOT NULL  DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE "tasks" ("name" TEXT PRIMARY KEY  NOT NULL ,"nameCategory" TEXT NOT NULL ,"date" TEXT DEFAULT (CURRENT_TIMESTAMP) ,"deleted" INTEGER DEFAULT (0) ,"Icon" TEXT DEFAULT ('') ,"duration" TEXT);
CREATE VIEW "categoriesNd" AS select * from categories where deleted=0;
CREATE VIEW "commentsNd" AS    select * from comments where deleted=0 and active=0;
CREATE VIEW "commentsTasksCategories" AS   SELECT co.comment as comment, t.name as task from commentsNd as co
inner join tasksNd as t on co.nameTask=t.name 
inner join categoriesNd as c on co.nameCategory=c.name;
CREATE VIEW "getActives" AS select gi.co,gi.ta,gi.ca,c.nameCategory,c.nameTask,c.comment,c.rowid  from comments c
inner join getIcon gi on c.rowid=gi.rowid 
where c.active=1 and c.deleted=0;
CREATE VIEW "getIcon" AS select co.icon co,ta.icon ta,ca.icon ca,co.rowid
from comments co 
inner join categories ca on co.nameCategory=ca.name
inner join tasks ta on co.nameTask=ta.name;
CREATE VIEW "resumen" AS SELECT l.rowidComments,c.nameTask,c.nameCategory,c.comment,sum(l.duration)/3600 as horas FROM logs l
inner join comments c on c.rowid=l.rowidComments
group by l.rowidComments 
order by sum(l.duration)/3600 DESC;
CREATE VIEW "tasksCategories" AS     SELECT t.name as task,c.name as cat from tasksNd as t 
inner join categoriesNd as c on t.nameCategory=c.name;
CREATE VIEW "tasksNd" AS select * from tasks where deleted=0;
