require ("csvparser")

local diary = {}
local FSL = {}

----

function readDiaryFromFile (fn)
	local fh,err = io.open(fn)
	if err then print("readDiaryFromFile() could not open file"); return; end
	-- ersten 3 zeilen verwerfen
	line = fh:read()
	line = fh:read()
	line = fh:read()
	-- zeilenweise einlesen
	local linecount = 0
	while true do
		line = fh:read()
		if line == nil then break end
		linecount=linecount+1
		addDiaryEntryFromString (line)
	end
	print ("diary lines read:",linecount)
	fh:close()
end

-- 09.11.2016;19:52;127;mg/dl; ;X; ;X; ; ; ; ;
-- 12345678901234567890				   0987654321
function addDiaryEntryFromString (s)
	local r = ParseCSVLine (s,";")
	local dateString = r[1]
	if not dateString then print ("dateString was nil -  (empty line?) - line ignored") return end
	dr = ParseCSVLine (dateString,'%.')	--".%" statt "." damit der PUNKT gemeint ist und keine Kommazahl	
	local clockString = r[2]
	local cr = ParseCSVLine (clockString,':')
	local newEntry ={
	BZ = tonumber(r[3]),
	day = tonumber(dr[1]),
	month = tonumber(dr[2]),
	year = tonumber(dr[3]),
	hour = tonumber(cr[1]),
	min = tonumber(cr[2])
	}	
	newEntry.time = (os.time({year=newEntry.year, month=newEntry.month, day=newEntry.day, hour=newEntry.hour, min=newEntry.min}) )
	table.insert (diary, newEntry)
end

----

function readFSLFromFile (fn)
	local fh,err = io.open(fn)
	if err then print("readFSLFromFile() could not open file"); return; end
	-- ersten 3 zeilen verwerfen
	line = fh:read()
	line = fh:read()
	line = fh:read()
	-- zeilenweise einlesen
	local linecount = 0
	while true do
		line = fh:read()
		if line == nil then break end
		linecount=linecount+1
		addFSLEntryFromString (line)
	end
	print ("FSL lines read:",linecount)
	fh:close()
end

--ID	Uhrzeit	Art des Eintrags	Historische Glukose (mg/dL)	Gescannte Glukose (mg/dL)	Schnell wirkendes Insulin, nicht numerisch	Schnell wirkendes Insulin (Einheiten)	Lebensmittel, nicht numerisch	Kohlenhydrate (Gramm)	Lang wirkendes Insulin, nicht numerisch	Lang wirkendes Insulin (Einheiten)	Notizen	Teststreifen-Blutzucker (mg/dL)	Keton (mmol/L)	Mahlzeiten-Insulin (Einheiten)	Korrektur-Insulin (Einheiten)	Insulin-Änderung durch Anwender (Einheiten)	Vorherige Uhrzeit	Neue Uhrzeit
--176	2016.11.18 13:18	0	108															
function addFSLEntryFromString (s)
	local r = ParseCSVLine (s,"\t")	
	local artDesEintrags = r[3]
	if artDesEintrags ~= "0" then return end
	local  ID = r[1]
	local timeString = r[2]
		local rt = ParseCSVLine (timeString,' ')
		local dateString = rt[1]
		local clockString = rt[2]
		local cr = ParseCSVLine (clockString,':')
		local dr = ParseCSVLine (dateString,'%.')
		local newEntry ={
		BZ = tonumber(r[4]),
		day = tonumber(dr[3]),
		month = tonumber(dr[2]),
		year = tonumber(dr[1]),
		hour = tonumber(cr[1]),
		min = tonumber(cr[2]),
		artDesEintrags = artDesEintrags,
		originalTimeString = timeString
		}
		newEntry.time = (os.time({year=newEntry.year, month=newEntry.month, day=newEntry.day, hour=newEntry.hour, min=newEntry.min}) )
	table.insert (FSL, newEntry)
end

function printFSL ()
	for i = #FSL, 1,-1 do
		print (FSL[i].time .. "--" .. FSL[i].originalTimeString .. "--"..FSL[i].BZ)
	end
end

function findClosestFSLtime (t)	
	for i = #FSL, 1,-1 do
		
		tdiff =  (FSL[i].time - t)
		--print (FSL[i].originalTimeString, tdiff)
		if math.abs(tdiff) < (60*10) then return FSL[i+1] end
	end
end

function findMatches(fnOut)
	local f = io.open (fnOut,"w")	
	for i = #diary, 1,-1 do		
		local e = diary[i]		
		local FSLe = findClosestFSLtime (e.time)
		if FSLe then
			print ("AC :"..readableTime(e.time) .. "--"..e.BZ)
			print ("FSL:"..readableTime(FSLe.time) .. "--"..FSLe.BZ.."\n")
			f:write (e.BZ..";"..FSLe.BZ.."\r\n")
		end
	end
	--f:write ("\n")
	f:close()
end

function readableTime (time)
	if type (time) == "table" then
		--return time.day .."."..time.month.."."..time.year .." " ..time.hour..":"..time.min
		return os.date ("%d.%m.%Y (%a)  %H:%M ", os.time(time))
	else
		return os.date ("%d.%m.%Y (%a)  %H:%M ", time)
	end
end


function runGnuplot (scriptName, args)	
if false then return end
	local s = '"'
	for v,k in pairs (args) do
		s=s.. v .. "='" .. k .. "' ; "
	end
	s=s..'" ' .. scriptName
	print ("gnuplot with args:" .. s)
	os.execute ("gnuplot -e " .. s)
end
---
readDiaryFromFile ("diary.csv")
readFSLFromFile ("FSL_beide_sensoren.txt")
findMatches("temp.csv")

runGnuplot ("compareACFSL.gnuplot", {
		["Titel"] = "AC vs FSL 2x 2 Wochen",		
		["plotDateiName"] =  "AC-FSL.png",
		["MesswertDatei"] = "temp.csv",
		} )