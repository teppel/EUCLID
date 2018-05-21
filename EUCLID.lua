--config--
OUTPUT_PATH = "output"
DIARY_FILE = "input//fakediary.csv"
----------

require ("csvparser")
--                                                                                                              10       11              12                
--Datum;Uhrzeit;Messwert;Einheit;Temperaturwarnung;Außerhalb Zielbereich;Sonstiges;Vor Mahlzeit;Nach Mahlzeit;Nüchtern;Schlafenszeit;Funktionskontrolle
-- 10.10.2016;13:15;91;mg/dl; ; ; ;X; ; ; ; ;
-- 12345678901234567890				   0987654321


diary = {}
-- .entry[i]
---- .BZ				//aus diary.csv
---- .time (os.time)

zusatz = {}
-- .entry[i]
---- .BE
---- .bolus
---- .basal
---- .note
---- .time (os.time)

TB = {}

---- FUNCTIONS FOR zusatz.csv ----
function readZusatzFromFile (fn)
	local fh,err = io.open(fn)
	if err then print("readZusatzFromFile() could not open file"); return; end
	line = fh:read()	--skip first line
	local linecount = 0
	while true do
		line = fh:read()
		if line == nil then break end
		linecount=linecount+1
		addZusatzEntryFromString (line)
	end
	print ("zusatz file lines read:",linecount)
	fh:close()
end

-- DATUM     UHR   B I Basal 
-- 15.08.2016;14:15;4;5; ;Calcone Pizza;
-- 12345678901234567890				   0987654321
function addZusatzEntryFromString (s)
	local r = ParseCSVLine (s,";")
	local dateString = r[1]
	if not dateString then print ("addZusatzEntryFromString - dateString was nil -  (empty line?) - line ignored") return end
	dr = ParseCSVLine (dateString,'%.')	--".%" statt "." damit der PUNKT gemeint ist und keine Kommazahl	
	local clockString = r[2]
	local cr = ParseCSVLine (clockString,':')
	local newEntry ={
	BE = tonumber(r[3]),
	bolus = tonumber(r[4]),
	basal = tonumber(r[5]),
	note = r[6],
	day = tonumber(dr[1]),
	month = tonumber(dr[2]),
	year = tonumber(dr[3]),
	hour = tonumber(cr[1]),
	min = tonumber(cr[2])
	}	
	
	newEntry.time = (os.time({year=newEntry.year, month=newEntry.month, day=newEntry.day, hour=newEntry.hour, min=newEntry.min}) )
	table.insert (zusatz, newEntry)
	
end


--diary[] + zusatz[] = TB[]
function mergeDiaryAndZusatzIntoTB_v2 ()
	--erstmal TB bauen nur mit diary
	for d=1,#diary,1 do
		local e = diary[d]
		--e.BE=zusatz[z].BE
		--e.bolus=zusatz[z].bolus
		--e.basal=zusatz[z].basal
		--e.note=zusatz[z].note
		table.insert(TB, e)
	end
	--if 0 then return end

	-- etwas stumpf..egal
	for z=1,#zusatz,1 do	
		local e = zusatz[z]
		local zusatzTime = e.time
		for t=1,#TB,1 do
			if zusatzTime >= TB[t].time then
				if tonumber(zusatzTime) == tonumber(TB[t].time)	then --dann mergen
					TB[t].BE=e.BE
					TB[t].bolus=e.bolus
					TB[t].basal=e.basal
					TB[t].note=e.note
					break
				else
					table.insert (TB, t,e)
					break
				end
			end
		end
	end
end


function printTB ()
	local currentDay = 0
	local BEsum = 0
	local bolusSum = 0
	print ("-- printTB() --")
	for i = #TB, 1,-1 do		
		local e = TB[i]
		if tonumber(e.day) ~= tonumber(currentDay) then	--zusatz eintraege manchmal ohne fuehrende null: "05" vs "5"
			currentDay = e.day
			print ("Summe BE:" , BEsum)
			print ("Summe Bolus:" , bolusSum)
			print ".:.:.:.:."
			BEsum=0
			bolusSum=0
		end
		print (readableTime(e.time), "BZ="..(e.BZ or "---") , "\tBE:"..(e.BE or "---"),"\tIE:"..(e.bolus or "---"), "\tBAS:"..(e.basal or "---"), "//"..(e.note or ""))
		BEsum = BEsum + (e.BE or 0)
		bolusSum = bolusSum + (e.bolus or 0)
	end
end


----  FUNCTIONS FOR diary.csv ----
function readDiaryFromFile (fn)
	local fh,err = io.open(fn)
	if err then print("readDiaryFromFile() COULD NOT OPEN FILE:" ..fn); return; end
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

function printDiary ()
	print ("--- printDiary() START ---")
	print ("entries:" .. #diary)
	for i=1,#diary,1 do
		printEntry (diary[i])
	end
	print ("--- printDiary() ENDE ---")
end


-- 09.11.2016;19:52;127;mg/dl; ;X; ;X; ; ; ; ;
-- 12345678901234567890				   0987654321
function addDiaryEntryFromString (s)
	if s:sub(3,3) ~= "." then print ("expect '.' at 3 in",s) ; return end
	local newEntry = {
	day = tonumber(s:sub (1,2)),
	month = tonumber(s:sub (4,5)),
	year = tonumber(s:sub (7,10)),
	hour = tonumber(s:sub (12,13)),
	min = tonumber(s:sub (15,16)),
	}
	BZ = s:sub (18,19)
	BZ3 = s:sub (20,20) --eventuell dreistelliger BZ

	c = s:sub(-11,-11) --das ;X; fuer "vor Mahlzeit", gezaehlt rueckwaerts und -1 für den linebreak in der datei FIXME: geht besser FIXME: DAS FAILT WENN IN DER diary.csv noch andere Eintraege sind (zB korrigiertes datum mit hinweis!)
	if c=="X" then newEntry.preMeal = true end
	if BZ3 ~= ";" then BZ=BZ..BZ3 end
	newEntry.BZ = tonumber (BZ)
	newEntry.time = (os.time({year=newEntry.year, month=newEntry.month, day=newEntry.day, hour=newEntry.hour, min=newEntry.min}) )
	newEntry.weekday = os.date ("%w", newEntry.time) --[0-6 = Sunday-Saturday]
	newEntry.weekdayShortName = os.date ("%a", newEntry.time) --"Wed"
	newEntry.marker = markerTypeFromDiaryString (s)
	newEntry.originalString = s
	table.insert (diary, newEntry)
end

-- "30.03.2017;08:52;101;mg/dl; ; ; ; ; ;X; ; ;--datum im gerät stimmt wieder--"
-- 1    2          3       4          5             6                     7            8            9           10         11            12
--Datum;Uhrzeit;Messwert;Einheit;Temperaturwarnung;Außerhalb Zielbereich;Sonstiges;Vor Mahlzeit;Nach Mahlzeit;Nüchtern;Schlafenszeit;Funktionskontrolle
function markerTypeFromDiaryString (s)
	local r = ParseCSVLine (s,";")
	if r[7] == "X" then return "Sonstiges" end
	if r[8] == "X" then return "Vor Mahl" end
	if r[9] == "X" then return "Nach Mahl" end
	if r[10] == "X" then return "Nuechtern" end
	if r[11] == "X" then return "Schlaf" end
	return nil
end

function lastDiaryDay ()
	local e = diary[1]
	local t = {day=e.day, month=e.month, year=e.year}
	return t
end

function firstDiaryDay ()
	local e = diary[#diary]	
		--print ("e.day:",e.day)
	local t = {day=e.day, month=e.month, year=e.year}
		--print ("t.day:",t.day)
	return t
end

--- FUNCTIONS FOR FSL
--	ID								BZ
--	174	2016.11.18 13:24	1		104
-- vertauschte uhrzeiten bei manuell scannen:
-- 194	2016.11.18 15:00	1		100														
-- 196	2016.11.18 14:49	0	102															
-- 197	2016.11.18 15:04	1		100	
-- vertauschte Tage um mitternacht  26 - 25 - 26
-- 1908	2016.11.26 00:00	1		100
-- 1910	2016.11.25 23:47	0	116
-- 1911	2016.11.26 00:16	5
function FSLIntoDailyFiles (fn)
local fh,err = io.open(fn)
	if err then print("FSLIntoDailyFiles() could not open file"); return; end
	line = fh:read()
	line = fh:read()
	line = fh:read()
	-- zeilenweise einlesen
	local linecount = 0
	local lastDay = 0
	local outFileD --pro Tag eine Datei
	local outFileA --alles in eine grosse Datei
	outFileA = io.open ("FSL_total.csv", "w")
	while true do
		line = fh:read()
		if not line then fh:close() break end
		print ("original:",line)
		local r = ParseCSVLine (line,"\t")
		local time = r[2]
		local year = time:sub(1,4)
		local month = time:sub(6,7)
		local day = time:sub(9,10)
		local clock = time:sub (12,16)
		local BZ = r[4]
		local artDesEintrags = r[3]
		local BZmanualScan = r[5] or ""
		--if BZmanualScan ~= "" then print ("MANUAL SCAN:",BZmanualScan) end
		if (BZ and BZ ~= "") or (BZmanualScan and BZmanualScan ~="") then		--enthält nicht immer BZ werte
			local s = day.."."..month.."."..year..";"..clock..";"..BZ..";" .. BZmanualScan .. ";"
			if lastDay ~= tonumber(day) then
				fnOut = "days//FSL_"..day.."."..month.."."..year..".csv"
				if outFileD then outFileD:flush() outFileD:close() end
				outFileD = io.open (fnOut, "a")
				lastDay = tonumber(day)
			end		
			print ("AC-style:",s)
			outFileD:write(s.."\n")
			outFileA:write(s.."\n")			
		end	
	end
	outFileA:close()
end

function FSLIntoSeqBZFiles (fn, fnOut)
local fh,err = io.open(fn)
	if err then print("FSLIntoDailyFiles() could not open file"); return; end	
	line = fh:read()
	line = fh:read()
	line = fh:read()
	-- zeilenweise einlesen
	local linecount = 0
	local prevBZ = 0	
	local outFile = io.open (fnOut, "w")
	while true do
		line = fh:read()
		if not line then fh:close() break end
		print ("original:",line)
		local r = ParseCSVLine (line,"\t")
		local time = r[2]
		local year = time:sub(1,4)
		local month = time:sub(6,7)
		local day = time:sub(9,10)
		local clock = time:sub (12,16)
		local BZ = r[4]
		local artDesEintrags = r[3]
		local BZmanualScan = r[5] or ""		
		if (BZ and BZ ~= "") then
			local s = day.."."..month.."."..year..";"..clock..";"..BZ..";" .. BZmanualScan .. ";"
			outFile:write (prevBZ .. ";" .. BZ .. ";15" .. "\n") --FIXME: tatsächliche Zeitdifferenz anstelle 15min, falls mal lücken in den werten sind
			prevBZ = BZ
		end
	end
	outFile:close()
end

--zB für den 24h scattersplot
--wäre unnötig wenn man den zeitraum iwie in gnuplot begrenzen könnte. da gnuplot aber
--nur EIN timefmt gleichzeitig kann, also nicht datum & uhrzeit getrennt, ist das nicht möglich.
function diaryIntoMonthlyFiles (outFolder)
	print ("diaryIntoMonthlyFiles() - splitting diary into monthly files")
	local outFile
	local fn
	local linebreak = false
	local currentMonth = 0
	for i=#diary,1,-1 do
		local e = diary[i]		
		if currentMonth ~= e.month then			
			if (outFile) then outFile:close() end
			local m = e.month
			if m < 10 then m ="0"..m end
			fn = outFolder .. "month_".."01."..m .."."..e.year
			outFile = io.open (fn, "w")
			currentMonth = e.month
			linebreak = false
		end
		if linebreak then outFile:write ("\n") end
		outFile:write (e.originalString)		
		linebreak = true
	end
	outFile:close()
	print ("diaryIntoMonthlyFiles() - fertig")
end

function diaryIntoFileWithWeekday (outfn)
	print ("diaryIntoFileWithWeekday ( " .. outfn .. " )")
	local outFile = io.open (outfn, "w")
	local weekCounter = 0
	local currentCalenderWeek = -1
	for i=#diary,1,-1 do
		local e = diary[i]
		--FIXME: manchmal sind notizen im diary.csv (zB "combined -v") oder gefixtes datum
		if os.date ("%V",e.time) ~= currentCalenderWeek then
			currentCalenderWeek = os.date ("%V", e.time)
			weekCounter = weekCounter +1
		end
		
		local cutAt =string.find(e.originalString, ";[^;]*$")
		--string.gsub(e.originalString, "\r", "") --zeilenumbruch entfernen
		
		local originalStringWithoutMyNotes = string.sub (e.originalString,0,cutAt)
		
		local s = originalStringWithoutMyNotes..e.weekday..";"..weekCounter ..";".."\n"
		outFile:write (s)
	end
	outFile:close()
	print ("diaryIntoFileWithWeekday() - fertig")
end

function diaryIntoQuartalFiles (outfn)
	local Qmonths =
	{ [1]=1, [2]=1, [3]=1,
	  [4]=2, [5]=2, [6]=2,
	  [7]=3, [8]=3, [9]=3,
	 [10]=4,[11]=4,[12]=4}
		
	
	local currentQ = 1 --1,2,3,4
end
---

LO = 70
HI = 180

function printEntry (entry)
	io.write (asString(entry) .. "\n" )
	--print (asString(entry))
end

function asString (entry)
	local sBZ = ""
	if entry.BZ then
		sBZ ="BZ=" .. entry.BZ
		if entry.BZ < LO then sBZ=sBZ .. " LO!" end
		if entry.BZ > HI then sBZ=sBZ .. " HI!" end
	end
	local snote = ""
	if entry.note then snote = "  ((" .. entry.note .. ")) " end
	
	return ( readableTime (entry.time).. sBZ .. "\t" .. snote )
end

-- formatierung besser als css FIXME
function asStringHTML (entry)
	local sBZ = ""
	if entry.BZ then
		sBZ ="<b>BZ=" .. entry.BZ .. "</b> "
		if entry.BZ < 99 then sBZ=sBZ .. " " end
		if entry.BZ < LO then sBZ=sBZ .. " LO! " end
		if entry.BZ > HI then sBZ=sBZ .. " HI! " end
	end
	local snote, sBE,sbolus, sbasal = "","","",""
	if entry.note then snote = "  <i>" .. entry.note .. "</i> " end
	if entry.BE then sBE = "BE:"..entry.BE .. " " end
	if entry.bolus then sbolus = "BOL:"..entry.bolus .. " " end
	if entry.basal then sbasal = "BAS:"..entry.basal end
	return ( "<u>".. readableTime (entry.time).. "</u>\t"..
		sBZ..sBE..sbolus..sbasal.."   ||  " .. snote )
end

--wie asStringHTML aber als zeile einer html-tabelle
function asStringHTMLtableRow (entry)
	local sBZ = ""
	if entry.BZ then
		sBZ=entry.BZ
		--if entry.BZ > HI then sBZ="<b>"..sBZ.."</b>" end
		--if entry.BZ < LO then sBZ="<b>"..sBZ.."</b>" end
		if entry.BZ < LO then sBZ ='<div class="UZ">' .. entry.BZ .. "</div> " end
		if entry.BZ > HI then sBZ ='<div class="HI">' .. entry.BZ .. "</div> " end
	end
	local snote = '<div class="note">' .. (entry.note or "_") .. "</div> "
	local s= "<tr><td>"..readableTime(entry.time).. "</td>"..
	"<td>"..(sBZ or "_").."</td>"..
	"<td>"..(entry.marker or "_").."</td>"..
	"<td>"..(entry.BE or "_").."</td>"..
	"<td>"..(entry.bolus or "_") .."</td>"..
	"<td>"..(entry.basal or "_").."</td>"..	
	"<td>" ..snote..  "</td>" ..
	"</tr>\n"
	return s	
end

function readableTime (time)
	if type (time) == "table" then
		--return time.day .."."..time.month.."."..time.year .." " ..time.hour..":"..time.min
		return os.date ("%d.%m.%Y (%a)  %H:%M ", os.time(time))
	else
		return os.date ("%d.%m.%Y (%a)  %H:%M ", time)
	end
end


--returns: "24.12.2015"
function timeToDDMMYYYY (time)
	return os.date ("%d.%m.%Y", time)
end

function timeToMMYYYY (time)
	return os.date ("%m.%Y", time)
end


function timeDifference (entryA, entryB)	--in minutes
	return (entryA.time - entryB.time) / 60
end

function dateTableAsFileName (d)
	return d.day.."-"..d.month.."-"..d.year
end

function printLows (outfn)
	if outfn then plotFile = io.open(outfn, "w") end
	local writeDoubleLineBreak = false
	print ("--- printLows() START ---")
	lowcount = 0
	for i=1,#diary,1 do	
	---if dateIsInRange ( ...
		local	e = diary[i]
		if e.BZ < LO then
			lowcount = lowcount + 1
--			io.write (lowcount .. ") ")
--			printEntry (e)
			local before = diary[i+1]
			local after = diary[i-1]
			local minutesBefore = timeDifference (e, before)
			local minutesAfter = timeDifference (after, e)
--			io.write ("davor:")
			printEntry (before)
			io.write (minutesBefore .. " minutes\n")
			printEntry (e)
			io.write (minutesAfter .." minutes\n")
			printEntry (after)
			io.write ("\n")

			datablockTitle = asString (e)
			plotString = -minutesBefore ..";"..before.BZ .. "\n" ..
							"0" .. ";" .. e.BZ .. "\n" ..
							minutesAfter .. ";" .. after.BZ .. "\n"
			print (plotString)
			if outfn then 
				if writeDoubleLineBreak then plotFile:write("\n\n") end --weil gnuplot sich einkackt wenn am EOF zwei Leerzeilen stehen
				plotFile:write ('"'..datablockTitle ..'"'.. "\n")
				plotFile:write(plotString)
				writeDoubleLineBreak = true
			end
		end
	end
	
	io.write ("Messungen : ",#diary ," \t davon < "..LO .."mg/dl : ",lowcount ,"\n")
	print ("--- printLows() ENDE ---")
	if outfn then io.close (plotFile) end
end


function printHi ()
	plotFile = io.open("hi.csv", "w")

	print ("--- printHi() START ---")
	highcount = 0
	for i=1,#diary,1 do
		local	e = diary[i]
		if e.BZ > HI then
			highcount = highcount + 1
--			io.write (lowcount .. ") ")
--			printEntry (e)
			local before = diary[i+1]
			local after = diary[i-1]
			local minutesBefore = timeDifference (e, before)
			local minutesAfter = timeDifference (after, e)
--			io.write ("davor:")
			printEntry (before)
			io.write (minutesBefore .. " minutes\n")
			printEntry (e)
			io.write (minutesAfter .." minutes\n")
			printEntry (after)
			io.write ("\n")
			datablockTitle = asString (e)

			plotString = -minutesBefore ..";"..before.BZ .. "\n" ..
							"0" .. ";" .. e.BZ .. "\n" ..
							minutesAfter .. ";" .. after.BZ .. "\n\n"
			print (plotString)
			plotFile:write ('"'..datablockTitle ..'"'.. "\n")
			plotFile:write(plotString .. "\n\n")
		end
	end
	io.write ("Messungen : ",#diary ," \t davon > "..HI .."mg/dl : ",highcount ,"\n")
	print ("--- printHi() ENDE ---")
	io.close (plotFile)
end

--FIXME: 'nuechtern' kann auch eine mahlzeit sein
function printMeals ()
	plotFile = io.open("meals.csv", "w")

	print ("--- printMeals() START ---")
	local	mealcount = 0

	for i=1,#diary,1 do
		local	e = diary[i]

		if e.preMeal then
			print ("meal found:")
			local ppminutesSum = 0
			mealcount = mealcount + 1
			printEntry (e)
			local a = 1
			plotString = "0;"..e.BZ .. "\n"
			while (true) do
				local nextEntry = diary[i-a]
				if not nextEntry then break end
				printEntry (nextEntry)
				local ppminutes = timeDifference (nextEntry, e)
				ppminutesSum = ppminutesSum + ppminutes
				plotString = plotString .. ppminutes .. ";" ..nextEntry.BZ .. "\n"
				if nextEntry.preMeal then break end
				if not nextEntry then break end

				if ppminutesSum > (5*60) then break end
				a=a+1
			end


			io.write ("\n")
			print (plotString)
			plotFile:write(plotString.."\n")
		end
	end
--	io.write ("Messungen : ",#diary ," \t davon > "..HI .."mg/dl : ",highcount ,"\n")
	print ("--- printMeals() ENDE ---")
end



function printDay (day, month, year)
	io.write ("printDay() START ",day,".",month,".",year,"\n")
	for i=#diary,1,-1 do
		local e = diary[i]
		if (tonumber(e.day)==tonumber(day) 
		and tonumber(e.month)==tonumber(month)
		and tonumber(e.year)==tonumber(year)) then
			printEntry (e)			
		end	
	end
	io.write ("printDay() ENDE")
end


----
function htmlReport (startDay_table, endDay_table, outFN, diaryFN, zusatzFN)
	print ("htmlReport () start")
	print ("diaryFN:", diaryFN)
	startDay_table.hour = 0
	endDay_table.hour = 24
	local startDay_time = os.time (startDay_table)
	local endDay_time = os.time (endDay_table)
	
	runGnuplot ("timegraph.gnuplot", {
			["PlotZeitStart"] = timeToDDMMYYYY(startDay_time) .. ";00:00",
			["PlotZeitEnde"]  = timeToDDMMYYYY(endDay_time) .. ";00:00",
			["MesswertDatei"]  = diaryFN,
			["Titel"] = "gesamt von " .. readableTime(startDay_time) .. " bis " .. readableTime(endDay_time),
			["plotDateiName"] = OUTPUT_PATH.."//gesamt_" .. timeToDDMMYYYY(startDay_time) .."-to-"..timeToDDMMYYYY(endDay_time).. ".png"
			} )
	
	runGnuplot ("scatter24h.gnuplot", {
		["Titel"] = "24h Verteilung fuer " ..  diaryFN,
		["MesswertDatei"]  = diaryFN,
		["plotDateiName"] =  OUTPUT_PATH.."//gesamtscatter.png"
		} )
	
	--print ("startDay_time:",startDay_time,  timeToDDMMYYYY(startDay_time) )
	--print ("endDay_time:",endDay_time,  timeToDDMMYYYY(endDay_time) )
	
	--FSLIntoDailyFiles ("libre.csv")
	--readDiaryFromFile (diaryFN)
	--readZusatzFromFile (zusatzFN)
	
	--day plots
	--[[
	local plot_time = startDay_time	
	while (plot_time < endDay_time) do
		runGnuplot ("dayPNG.gnuplot", {
			["PlotZeitStart"] = timeToDDMMYYYY(plot_time) .. ";00:00",
			["PlotZeitEnde"]  = timeToDDMMYYYY(plot_time) .. ";23:59",
			["Titel"] = "Tag " .. readableTime(plot_time),
			["plotDateiName"] = OUTPUT_PATH.."//day//dayplot_" .. timeToDDMMYYYY(plot_time) .. ".png",
		--	["fslDatei"] = "days//FSL_" .. timeToDDMMYYYY(plot_time) .. ".csv"
			} )
		
		plot_time = plot_time + (60*60*24)
	end
	--]]
	
	--[[
	--week plots
	plot_time = startDay_time
	while (plot_time < endDay_time) do
		runGnuplot ("timegraph.gnuplot", {
			["PlotZeitStart"] = timeToDDMMYYYY(plot_time) .. ";00:00",
			["PlotZeitEnde"]  = timeToDDMMYYYY(plot_time + (60*60*24*7)) .. ";00:00",
			["Titel"] = "Wochenverlauf " .. readableTime(plot_time),
			["plotDateiName"] = OUTPUT_PATH.."week//weekplot_" .. timeToDDMMYYYY(plot_time) .. ".png"
			} )
		--plot_time = plot_time + (60*60*24*7)
		plot_time = os.time( addDays (os.date("*t", plot_time) , 7)	)
	end
	--]]
	
	--month plots	
	local startDay_table2 = startDay_table
	startDay_table2.day = 1 --egal wie der plotzeitraum ist, monatsübersicht beginnt immer am ersten tag im monat
	plot_time = os.time (startDay_table2)
	while (plot_time < endDay_time) do
		runGnuplot ("timegraph.gnuplot", {
			["PlotZeitStart"] = timeToDDMMYYYY(plot_time) .. ";00:00",
			["PlotZeitEnde"]  = timeToDDMMYYYY(os.time(nextMonth (startDay_table2))) .. ";00:00",
			["MesswertDatei"]  = diaryFN,
			["Titel"] = "Monatsverlauf " ..  os.date ("%m.%Y (%B)", plot_time),  --.. readableTime(plot_time),
			["plotDateiName"] = OUTPUT_PATH.."//month//monthplot_" .. timeToMMYYYY(plot_time) .. ".png"
			} )
		
		runGnuplot ("scatter24h.gnuplot", {
		["Titel"] = "24h Verteilung fuer" .. os.date ("%m.%Y (%B)", plot_time) ,
		["MesswertDatei"]  = OUTPUT_PATH.."//monthcsv//month_"..timeToDDMMYYYY(plot_time),
		["plotDateiName"] =  OUTPUT_PATH.."//month//monthscatter_" .. timeToMMYYYY(plot_time) .. ".png"
		} )
		
		startDay_table2 = nextMonth (startDay_table2)
		plot_time = os.time (startDay_table2)
	end
	
	html = io.open(OUTPUT_PATH.."//"..outFN, "w")
	html:write ([[<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Wie verhält es sich mit dem Aktienmarkt?</title>
	<link rel="stylesheet" href="format.css" type="text/css">	
  </head>
  
	<body>]])		
	
	--das funzte, schrieb aber nur das diary, nicht das TB mit den notizen zwischen den messungen:
	--[[	
	local currDay = 0
	for i=#diary,1,-1 do
		if (diary[i].time > startDay_time and diary[i].time < endDay_time) then
			if diary[i].day ~= currDay then
				currDay = diary[i].day
				html:write ("\n\n<h1>" .. readableTime (diary[i].time) .. "</h1>\n")
				html:write('<img src="day//dayplot_'..diary[i].day.."."..diary[i].month.."."..diary[i].year..'.png">\n')

				html:write ("<p>" .. asString (diary[i]) .. "</p>\n")
			else
				html:write ("<p>" .. asString (diary[i]) .. "</p>\n")
			end
		end
	end
	--]]

	
	local FULLNOTES = true
	local dailyBE, dailyBolus = 0,0
	local currDay = 0
	local currMonth = 0
	for i=#TB,1,-1 do
		if (TB[i].time > startDay_time and TB[i].time < endDay_time) then
			if TB[i].day ~= currDay then
				if currDay ~= 0 then					
					html:write ("</table>")
					html:write ('<div class="pagebreak"> </div>\n')
					--if FULLNOTES then
					--	html:write ("<p>Summen - BE:"..dailyBE .. " BOL:"..dailyBolus .."</p>\n")
					--end
					dailyBE, dailyBolus = 0,0
				end
				currDay = TB[i].day
				html:write ("\n\n<h1>" .. readableTime (TB[i].time) .. "</h1>\n")
				if (true == false) then
					local imgFN = "dayplot_" .. timeToDDMMYYYY(TB[i].time) .. ".png"  --'dayplot_'..TB[i].day.."."..TB[i].month.."."..TB[i].year..'.png
					html:write('<img src="day//'..imgFN..'">\n')
				end
				--html:write ("<p>" .. asStringHTML (TB[i]) .. "</p>\n")				
				if FULLNOTES then
					html:write ("<table> \n <tr><th>Zeit</th> <th>BZ</th> <th>MARK</th> <th>BE</th> <th>BOL</th> <th>BAS</th> <th>BLA</th> </tr> \n")
					html:write (asStringHTMLtableRow (TB[i]) )
				end
			else
				--html:write ("<p>" .. asStringHTML (TB[i]) .. "</p>\n")
				if FULLNOTES then
					html:write (asStringHTMLtableRow (TB[i]) )
				end
			end
			if TB[i].month ~= currMonth then
				currMonth = TB[i].month
				local imgFN = "monthplot_" .. timeToMMYYYY(TB[i].time) .. ".png"
				html:write('<img src="month//'..imgFN..'">\n')
				html:write ("<br>\n")
				imgFN = "monthscatter_" .. timeToMMYYYY(TB[i].time) .. ".png"
				html:write('<img src="month//'..imgFN..'">\n')				
			end
		dailyBE = dailyBE+(TB[i].BE or 0)
		dailyBolus = dailyBolus+(TB[i].bolus or 0)
		end
	end
	if FULLNOTES then
		html:write ("</table>")
	end

	
	html:write ("\n</body></html>")
	html:close()
	
	print ("htmlReport () fertig")
end

function runGnuplot (scriptName, args)	
if false then return end
	local s = '"'
	for v,k in pairs (args) do
		s=s.. v .. "='" .. k .. "' ; "
	end
	s=s..'" ' .. scriptName
	print ("gnuplot with args:" .. s)
	os.execute ("gnuplot -e " .. s)	--ubuntu
--	os.execute ("G://Programme//gnuplot//bin//gnuplot.exe -e " .. s)	--windows
	
end
----
-- "3" -> "03"
function lead0 (x)
	return string.format( "%02d", x)
end

--diary.csv einlesen und nur datum+uhrzeit + ;;; ausgeben so dass man nur noch BE,IE eintragen muss.
--ausserdem rückwärts, weil diary.csv falschrum sortiert ist
function diaryToEmptyZusatzTemplate(outFN)
	print ("diaryToEmptyZusatzTemplate() outFN=",outFN)
	zfile = io.open(outFN, "w")
	for i=#diary,1,-1 do
		local e = diary[i]													--BE IE BAS Notiz				
		local s = lead0(e.day) .. ".".. lead0(e.month).."."..e.year..";"..lead0(e.hour)..":"..lead0(e.min).."; ; ; ; ;"
		zfile:write (s.."\n")
	end
	zfile:close()
	print ("diaryToEmptyZusatzTemplate() - done")
end
---

--130
--70
--80
--150
-- -> BZ(t), BZ(t+1) , timeDiffInMinutes 	kann man jeweils auf x und y Achse plotten um Schwankungen zu sehen?
--130, 70
--70, 80
--80, 150
function sequencedBZpairsToFile (startDay_table, endDay_table, outFN)
	outfile = io.open(outFN, "w")
	local startDay_time = os.time (startDay_table)
	local endDay_time = os.time (endDay_table)
	for i=1,#diary-1,1 do
		local e1 = diary[i]
		if (e1.time > startDay_time) and (e1.time < endDay_time) then
			local e2 = diary[i+1]
			local s = e2.BZ .. ";" .. e1.BZ .. ";"..timeDifference(e1,e2) .. ";(" .. asString(e2) .. " zu ".. asString(e1) .. ")"
			outfile:write (s.."\n")
		end
	end
	outfile:close()
end


function addDays (d, daysToAdd)
--bei sommerzeit/winterzeit geht eine stunde verloren..dadurch wird ein tag zu wenig weitergezählt wenn d's uhrzeit "00:00" ist und man einfach 24h addieren will (springt zu 23:00)
--in allen tablen .isdt = false setzen änderte daran nichts!
	
	local newTime = os.time (d) + (daysToAdd*24*60*60)
	local newTime_t = os.date ("*t", newTime)
	if d.isdst and not newTime_t.isdst then newTime_t.hour=newTime_t.hour+1 end --erstes Datum Sommerzeit, zweites Datum Winterzeit? Lua zieht dann 1h ab. Wir addieren diese 1h wieder.
	return newTime_t
end


function nextMonth (d1)
	local d = {day=d1.day, month=d1.month, year=d1.year}
	d.month=d.month+1
	if d.month > 12 then
		d.month = 1
		d.year=d.year+1
	end
	return d
end

--TODO: sollte mit type (table) aber auch mit type(string) funzen
function dateIsInRange (d_table, startDate_table, endDate_table)
	local startDay_time = os.time (startDay_table)
	local endDay_time = os.time (endDay_table)
	local d_time = os.time (d_table)
	return ( (d_time > startDay_time) and (d_time < endDay_time) )
end

function DO_BZpairs ()
	local seqHTMLstring = "<h1>Schwanklichkeit BZ(t) vs BZ(t+1)</h1>"
	local startDate = {day=1,month=7,year=2016,hour=0}
	
	for i=1,11,1 do --FIXME
		local endDate = nextMonth(startDate)
		endDate = addDays (endDate,-1)
		endDate.hour = 24
		local fn = OUTPUT_PATH.."//seq//bla//" .. dateTableAsFileName (startDate) .. "-to-" .. dateTableAsFileName (endDate)
		sequencedBZpairsToFile (startDate , endDate, fn)

		runGnuplot ("seqBZpairs.gnuplot", {
			["Titel"] = "BZseq" .. fn,
			["seqFile"]  = fn,
			["plotDateiName"] =  fn .. ".png",
			} )
		seqHTMLstring = seqHTMLstring.. "<h1>" .. fn .. '</h1>\n<img src="' .. fn .. '.png">\n'
		seqHTMLstring = seqHTMLstring .. "\n<br><br><br>\n"
		startDate = nextMonth (startDate)
	end
	print ("\n\n\n" .. seqHTMLstring )
end

function dailyTestFrequency (tempCSV, outPNG)
	print ("dailyTestFrequency()")
	local f = io.open (tempCSV, "w")
	local i = #diary
	local currentDay = diary[i].day
	local date = diary[i].day.."."..diary[i].month.."."..diary[i].year
	local tests = 0
	local doubleTests = 0
	local doubleTestMinutes = 30
	local farOutRangeTests = 0
	local farOutLO = 60
	local farOutHI = 200
	for i=#diary,1,-1 do		
		--print ("oString:",diary[i].originalString)
		if (diary[i-1] and math.abs(timeDifference(diary[i],diary[i-1])) < doubleTestMinutes) then			
			doubleTests = doubleTests +1
		end
		if diary[i].BZ < farOutLO or diary[i].BZ > farOutHI then
			farOutRangeTests = farOutRangeTests +1
		end
		if currentDay == diary[i].day then
			tests = tests +1
		else			
			f:write (date .. ";" .. tests  ..";"..doubleTests..";"..farOutRangeTests.. "\n")
			date = diary[i].day.."."..diary[i].month.."."..diary[i].year
			tests = 1
			doubleTests = 0
			farOutRangeTests = 0
			currentDay=diary[i].day
		end
	end
	f:write (date .. ";" .. tests  ..";"..doubleTests..";"..farOutRangeTests)
	f:close()
	runGnuplot ("testFrequency.gnuplot", {
				["Titel"] = "Messungen pro Tag (Doppelmessung wenn innerhalb ".. doubleTestMinutes .. " Minuten)",
				["wertedatei"]  = tempCSV,
				["plotDateiName"] = outPNG,
				["farOutLO"] = farOutLO,
				["farOutHI"] = farOutHI,
				} )
end
	
----



--readDiaryFromFile ("diary_august.csv")
--readZusatzFromFile ("zusatz_august.csv")
--mergeDiaryAndZusatzIntoTB_v2()
--printTB()

--FSLIntoDailyFiles ("FSL_beide_sensoren.txt")

--printDay (23,9,2016)
--printEntry (diary[1])
--printDiary ()
--printLows()
--printHi()
--printMeals()


--[[
readZusatzFromFile ("zusatz_sensor2.csv")
mergeDiaryAndZusatzIntoTB_v2()
htmlReport ( {day=18,month=11,year=2016,hour=0} , {day=2,month=12,year=2016,hour=24} , "sensor1.html")
htmlReport ( {day=26,month=2,year=2017,hour=0} , {day=12,month=3,year=2017,hour=24} , "sensor2.html")
--]]

--os.execute ("firefox temp//htmlReport.html")


--readDiaryFromFile ("diary.csv")
--mergeDiaryAndZusatzIntoTB_v2()
--DO_BZpairs ()

--[[
readDiaryFromFile ("delmediary2017.csv")
fn = OUTPUT_PATH.."//busch2017//2017lows.csv"
	printLows (fn)
	runGnuplot ("plotLows.gnuplot", {
		["Titel"] = "lows 2017, BZ <" .. LO,
		["datafile"]  = fn,
		["plotDateiName"] =	fn .. ".png",
		} )
--]]


--[[
local fn = "csv_export_sensor2_12_3_2017.txt"
local fn2 = "temp//seq//seq_" .. fn
FSLIntoSeqBZFiles (fn, fn2)
	runGnuplot ("seqBZpairs.gnuplot", {
		["Titel"] = "FSL sensor2 ab 12.3.2017",
		["seqFile"]  = fn2,
		["plotDateiName"] =  fn2 .. "nl .png",
		["FSL"] = "yes",
		} )


local fn = "FSL_sensor1_18_11_2016.csv"
local fn2 = "temp//seq//seq_" .. fn
FSLIntoSeqBZFiles (fn, fn2)
	runGnuplot ("seqBZpairs.gnuplot", {
		["Titel"] = "FSL sensor1 ab 18.11.2016",
		["seqFile"]  = fn2,
		["plotDateiName"] =  fn2 .. "nl .png",
		["FSL"] = "yes",
		} )
--]]

--[[
--wochen durchzählen, start jeweils montag 00:00
local startDate = {day=4,month=7,year=2016,hour=0,min=0}
local d = startDate
for i=1,30 do
	print (readableTime (d))
	d = addDays (d,7)
end
--]]

----[[
--htmlreport - geht
readDiaryFromFile (DIARY_FILE)
mergeDiaryAndZusatzIntoTB_v2()
diaryIntoMonthlyFiles (OUTPUT_PATH.."//monthcsv//")
htmlReport ( firstDiaryDay()  , lastDiaryDay() , "report.html", DIARY_FILE)
dailyTestFrequency (OUTPUT_PATH.."//testfrequency.csv", OUTPUT_PATH.."//testfrequency.png")

diaryIntoFileWithWeekday ("temp//diarywithweekdays.csv")
runGnuplot ("weekrainbow.gnuplot", {
		["Titel"] = "Wochendings",
		["MesswertDatei"]  = "temp//diarywithweekdays.csv",
		["plotDateiName"] =  OUTPUT_PATH.."//weekrainbow.png",		
		} )

runGnuplot ("weekdays.gnuplot", {
		["Titel"] = "Wochentage",
		["MesswertDatei"]  = "temp//diarywithweekdays.csv",
		["plotDateiName"] =  OUTPUT_PATH.."//wochentage.png",		
		} )

--]]

--diaryIntoFileWithWeekday ("temp//diarywithweekdays.csv")


--[[
	runGnuplot ("scatter24h.gnuplot", {
		["Titel"] = "24h Verteilung test",
		["MesswertDatei"]  = "delmediary2017.csv",
		["plotDateiName"] =  "zzz24h.png",		
		} )
--]]


--quartal test
--[[
runGnuplot ("timegraph.gnuplot", {
			["PlotZeitStart"] = "1.12.2017;00:00",
			["PlotZeitEnde"]  = "1.04.2018;00:00",
			["Titel"] = "1 quartal",
			["plotDateiName"] = "temp//quartaltest.png"
			} )
--]]

print ("fertig")

answer=io.read()	--ende nach tastendruck
