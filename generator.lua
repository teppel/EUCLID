

rnd=math.random
lines = {}
startTable = {day=13, month=2, year=2015, hour=0}
--endTable = {day=31,month=12,year=2018,hour=0}

--Datum;Uhrzeit;Messwert;Einheit;Temperaturwarnung;Außerhalb Zielbereich;Sonstiges;Vor Mahlzeit;Nach Mahlzeit;Nüchtern;Schlafenszeit;Funktionskontrolle
-- 10.10.2016;13:15;91;mg/dl; ; ; ;X; ; ; ; ;
function addEntry (day,month,year,hour,min,BZ,markReadable)
	if day < 10 then day="0"..day end
	if month < 10 then month="0"..month end
	if hour < 10 then hour="0"..hour end
	if min < 10 then min="0"..min end
	local s = day.."."..month.."."..year..";"..hour..":"..min..";"..BZ..";".."mg/dl".."; "..markCoded(markReadable)
	print (s)
	table.insert (lines,s)	
end

function markCoded (s)
	local strings = {
		["other"]=	"; ;X; ; ; ; ; ;",
		["pre"]=	"; ; ;X; ; ; ; ;",
		["after"]=	"; ; ; ;X; ; ; ;",
		["fast"]=	"; ; ; ; ;X; ; ;",
		["sleep"]=	"; ; ; ; ; ;X; ;"
		}
	return strings[s] or "; ; ; ; ; ; ; ;"
end



--##############
t = os.time (startTable)
file = io.open ("fakediary.csv","w")

file:write("Seriennummer;Datum Download;Uhrzeit Download;;;;;;;".."\n")
file:write("12345678;31.08.2016;09:59;;;;;;;".."\n")
file:write("Datum;Uhrzeit;Messwert;Einheit;Temperaturwarnung;Außerhalb Zielbereich;Sonstiges;Vor Mahlzeit;Nach Mahlzeit;Nüchtern;Schlafenszeit;Funktionskontrolle    ")
for i=1,200,1 do
	temp = os.date("*t", t)
	day=temp.day
	month=temp.month
	year=temp.year
	wday=temp.wday
	
	local l = 90	
	if i < 45 then
		if rnd (1,10) > 3 then l = 35 end
	else
		if rnd (1,10) > 9 then l = 60 end
	end
	
	if rnd (1,10)>8 then addEntry (day,month,year,2,rnd(22,25), rnd(l,90)+(rnd(0,1)*80), "") end
	
	local n = 80+ (math.sin (i/10)*30)
	if wday==1 then --sunday
		addEntry (day,month,year, 8,rnd(0,59), rnd(100,120), "fast")
	else		
		addEntry (day,month,year, 6,rnd(20,40), rnd(n,130), "fast")
	end
	if rnd (1,10) > 5 then addEntry (day,month,year, 10,rnd(0,59), rnd(l,200), "after") end
	addEntry (day,month,year, 13,rnd(0,59), rnd(l,100), "pre")
	addEntry (day,month,year, rnd(14,16),rnd(0,59), rnd(120,(140+(rnd(0,2)*50) )), "after")
	if rnd (1,10) > 3 then
		x=l
		if wday==4 then x=180 end
		addEntry (day,month,year, 18,rnd(30,59), rnd(x,200), "other")
		addEntry (day,month,year, 19,rnd(0,59), rnd(x,300), "other")
	end
	
	addEntry (day,month,year, 22,rnd(0,59), rnd(40,200), "sleep")	
	
	t=t+(60*60*24) -- +24 hours, next day
	
	print "----"
end

for i=#lines,1,-1 do
	file:write ("\n"..lines[i])
end

file.close()
