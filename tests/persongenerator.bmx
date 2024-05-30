SuperStrict
Framework Brl.StandardIO
Import "../source/Dig/base.util.persongenerator.bmx"

SeedRand(Millisecs())
For local i:int = 0 to 10000
	local f:string = GetPersonGenerator().GetProvider("de").GetFirstName(1)
	if f.Trim() = "" then Throw "failed"
Next


local countries:string[] = ["de", "aut", "uk", "cn", "ru", "tr", "us" , "dk", "gr", "ug", "es"]
For local c:string = EachIn countries
	print "=== Country: " + LSet(c, 3) +" ===" 
	For local i:int = 0 to 5
		local line:string = ""
		for local gender:int = 1 to 2
			local p:TPersonGeneratorEntry = GetPersonGenerator().GetUniqueDataset(c, gender)
			line :+ LSet(p.firstName + " " + p.lastName, 30)
			'advoid dublettes
			GetPersonGenerator().ProtectDataset(p)
		Next
		print line
	Next
Next

