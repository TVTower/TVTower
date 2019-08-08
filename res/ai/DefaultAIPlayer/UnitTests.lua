function SLFStringUnitTest()
	assert("abc" == string.left("abcdefg", 3), "SLFString1")
	assert("abcdefg" == string.left("abcdefg", 10), "SLFString2")
	assert("abcdefg   " == string.left("abcdefg", 10, true), "SLFString3")
	assert("efg" == string.right("abcdefg", 3), "SLFString4")
	assert("abcdefg" == string.right("abcdefg", 10), "SLFString5")
	assert("   abcdefg" == string.right("abcdefg", 10, true), "SLFString6")
end

SLFStringUnitTest()

function JobEmergencySchedule:UnitTest()
	local day = 1	
	local hour = 22	
	local rday = 0
	local rhour = 0
	--[[
	debugMsg("--> Start UnitTest JobEmergencySchedule")
	
	rday, rhour = self:FixDayAndHour(day, hour)
	assert(rday == 1, "a1")
	assert(rhour == 22, "a2")
	
	hour = 24	
	rday, rhour = self:FixDayAndHour(day, hour)
	assert(rday == 2, "b1")
	assert(rhour == 0, "b2")
	
	hour = 25	
	rday, rhour = self:FixDayAndHour(day, hour)
	assert(rday == 2, "c1")
	assert(rhour == 1, "c2")	
		
	hour = 47	
	rday, rhour = self:FixDayAndHour(day, hour)
	assert(rday == 2, "d1")
	assert(rhour == 23, "d2")		
	
	hour = 48
	rday, rhour = self:FixDayAndHour(day, hour)
	assert(rday == 3, "e1")
	assert(rhour == 0, "e2")			
	
	hour = 49
	rday, rhour = self:FixDayAndHour(day, hour)
	assert(rday == 3, "f1")
	assert(rhour == 1, "f2")
	
	debugMsg("--> End UnitTest JobEmergencySchedule")
	]]--
end