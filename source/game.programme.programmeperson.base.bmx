SuperStrict
Import Brl.Map
Import Brl.Math
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.event.bmx"
Import "basefunctions.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx"
Import "game.programme.programmerole.bmx"




Type TProgrammePersonBaseCollection
	Field insignificant:TMap = CreateMap()
	Field celebrities:TMap = CreateMap()
	Field insignificantCount:int = -1 {nosave}
	Field celebritiesCount:int = -1 {nosave}
	Global _instance:TProgrammePersonBaseCollection


	Function GetInstance:TProgrammePersonBaseCollection()
		if not _instance then _instance = new TProgrammePersonBaseCollection
		return _instance
	End Function


	Method Initialize:TProgrammePersonBaseCollection()
		insignificant.Clear()
		insignificantCount = -1

		celebrities.Clear()
		celebritiesCount = -1

		return self
	End Method


	Method GetByGUID:TProgrammePersonBase(GUID:String)
		local result:TProgrammePersonBase
		result = TProgrammePersonBase(insignificant.ValueForKey(GUID))
		if not result
			result = TProgrammePersonBase(celebrities.ValueForKey(GUID))
		endif
		return result
	End Method


	Method GetInsignificantByGUID:TProgrammePersonBase(GUID:String)
		Return TProgrammePersonBase(insignificant.ValueForKey(GUID))
	End Method


	Method GetCelebrityByGUID:TProgrammePersonBase(GUID:String)
		Return TProgrammePersonBase(celebrities.ValueForKey(GUID))
	End Method


	'deprecated - used for v2-database
	Method GetCelebrityByName:TProgrammePersonBase(firstName:string, lastName:string)
		firstName = firstName.toLower()
		lastName = lastName.toLower()

		For local person:TProgrammePersonBase = eachin celebrities.Values()
			if person.firstName.toLower() <> firstName then continue
			if person.lastName.toLower() <> lastName then continue
			return person
		Next
		return Null
	End Method


	'useful to fetch a random "amateur" (aka "layman")
	Method GetRandomInsignificant:TProgrammePersonBase(array:TProgrammePersonBase[] = null, onlyFictional:int = False, onlyBookable:int = False, job:int=0, gender:int=-1)
		if array = Null or array.length = 0 then array = GetAllInsignificantAsArray(onlyFictional, onlyBookable, job)
		If array.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetRandomCelebrity:TProgrammePersonBase(array:TProgrammePersonBase[] = null, onlyFictional:int = False, onlyBookable:int = False, job:int=0, gender:int=-1)
		if array = Null or array.length = 0 then array = GetAllCelebritiesAsArray(onlyFictional, onlyBookable, job)
		If array.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetAllInsignificantAsArray:TProgrammePersonBase[](onlyFictional:int = False, onlyBookable:int = False, job:int=0, gender:int=-1)
		local array:TProgrammePersonBase[]
		'create a full array containing all elements
		For local obj:TProgrammePersonBase = EachIn insignificant.Values()
			if onlyFictional and not obj.fictional then continue
			if onlyBookable and not obj.bookable then continue
			if job>0 and obj.job & job = 0 then continue
			if gender>=0 and obj.gender <> gender then continue
			array :+ [obj]
		Next
		return array
	End Method


	Method GetAllCelebritiesAsArray:TProgrammePersonBase[](onlyFictional:int = False, onlyBookable:int = False, job:int=0, gender:int=-1)
		local array:TProgrammePersonBase[]
		'create a full array containing all elements
		For local obj:TProgrammePersonBase = EachIn celebrities.Values()
			if onlyFictional and not obj.fictional then continue
			if onlyBookable and not obj.bookable then continue
			if job>0 and obj.job & job = 0 then continue
			if gender>=0 and obj.gender <> gender then continue
			array :+ [obj]
		Next
		return array
	End Method


	Method GetInsignificantCount:Int()
		if insignificantCount >= 0 then return insignificantCount

		insignificantCount = 0
		For Local person:TProgrammePersonBase = EachIn insignificant.Values()
			insignificantCount :+1
		Next
		return insignificantCount
	End Method


	Method GetCelebrityCount:Int()
		if celebritiesCount >= 0 then return celebritiesCount

		celebritiesCount = 0
		For Local person:TProgrammePersonBase = EachIn celebrities.Values()
			celebritiesCount :+1
		Next
		return celebritiesCount
	End Method


	Method RemoveInsignificant:int(person:TProgrammePersonBase)
		if person.GetGuid() and insignificant.Remove(person.GetGUID())
			'invalidate count
			insignificantCount = -1

			return True
		endif

		return False
	End Method


	Method RemoveCelebrity:int(person:TProgrammePersonBase)
		if person.GetGuid() and celebrities.Remove(person.GetGUID())
			'invalidate count
			celebritiesCount = -1

			return True
		endif

		return False
	End Method


	Method AddInsignificant:int(person:TProgrammePersonBase)
		insignificant.Insert(person.GetGUID(), person)
		'invalidate count
		insignificantCount = -1

		return TRUE
	End Method


	Method AddCelebrity:int(person:TProgrammePersonBase)
		celebrities.Insert(person.GetGUID(), person)
		'invalidate count
		celebritiesCount = -1

		return TRUE
	End Method


	Function SortByName:Int(o1:Object, o2:Object)
		Local p1:TProgrammePersonBase = TProgrammePersonBase(o1)
		Local p2:TProgrammePersonBase = TProgrammePersonBase(o2)
		If Not p2 Then Return 1
		if p1.GetFullName() = p2.GetFullName()
			return p1.GetGUID() > p2.GetGUID()
		endif
        If p1.GetFullName().ToLower() > p2.GetFullName().ToLower()
			return 1
        elseif p1.GetFullName().ToLower() < p2.GetFullName().ToLower()
			return -1
		endif
		return 0
	End Function
End Type
'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammePersonBaseCollection:TProgrammePersonBaseCollection()
	Return TProgrammePersonBaseCollection.GetInstance()
End Function

Function GetProgrammePersonBase:TProgrammePersonBase(guid:string)
	Return TProgrammePersonBaseCollection.GetInstance().GetByGUID(guid)
End Function




Type TProgrammePersonBase extends TGameObject
	field lastName:String = ""
	field firstName:String = ""
	field nickName:String = ""
	field job:int = 0
	'indicator for potential "upgrades" to become a celebrity
	field jobsDone:int
	field jobsDoneTotal:int[]
	field canLevelUp:int = True
	field countryCode:string = ""
	field gender:int = 0
	'a text code representing the config for the figure generator
	field faceCode:string
	'can this person _theoretically_ be booked for a production
	'(this allows disabling show-guests like "the queen" - which might
	' be guest in an older show)
	field bookable:int = True
	'is this an real existing person or someone we imaginated for the game?
	field fictional:int = False
	'is the person currently filming something?
	field producingGUIDs:string[]


	Method New()
		'increase array so 0 (all) + all jobs fit into it
		jobsDoneTotal = jobsDoneTotal[.. TVTProgrammePersonJob.count + 1]
	End Method


	Method GenerateGUID:string()
		return "programmeperson-base-"+id
	End Method


	Method SerializeTProgrammePersonBaseToString:string()
		local jobsDoneString:string = string(jobsDone)
		For local i:int = eachin jobsDoneTotal
			if jobsDoneString <> "" then jobsDoneString :+","
			jobsDoneString :+ string(i)
		Next
		return StringHelper.EscapeString(lastName, ":") + "::" + ..
		       StringHelper.EscapeString(firstName, ":") + "::" + ..
		       StringHelper.EscapeString(nickName, ":") + "::" + ..
		       job + "::" + ..
		       jobsDoneString + "::" + ..
		       canLevelUp + "::" + ..
		       fictional + "::" + ..
		       StringHelper.EscapeString(",".Join(producingGUIDs), ":") + "::" + ..
		       id + "::" + ..
		       StringHelper.EscapeString(GUID, ":") + "::" + ..
		       bookable
	End Method


	Method DeSerializeTProgrammePersonBaseFromString(text:String)
		local vars:string[] = text.split("::")
		if vars.length > 0 then lastName = StringHelper.UnEscapeString(vars[0])
		if vars.length > 1 then firstName = StringHelper.UnEscapeString(vars[1])
		if vars.length > 2 then nickName = StringHelper.UnEscapeString(vars[2])
		if vars.length > 3 then job = int(vars[3])
		if vars.length > 4
			local jD:string[] = vars[4].split(",")
			jobsDone = int(jD[0])
			For local i:int = 1 until jD.length
				jobsDoneTotal[i-1] = int(jD[i-1])
			Next
		endif
		if vars.length > 5 then canLevelUp = int(vars[5])
		if vars.length > 6 then fictional = int(vars[6])
		if vars.length > 7 then producingGUIDs = StringHelper.UnEscapeString(vars[7]).split(",")
		if vars.length > 8 then id = int(vars[8])
		if vars.length > 9 then GUID = StringHelper.UnEscapeString(vars[9])
		if vars.length > 10 then bookable = int(vars[10])
	End Method


	Method Compare:Int(o2:Object)
		if o2 = self then return 0

		Local p2:TProgrammePersonBase = TProgrammePersonBase(o2)
		If p2
			if GetFullName() = p2.GetFullName()
				if GetAge() > p2.GetAge() then return 1
				if GetAge() < p2.GetAge() then return -1
			else
				if GetFullName().ToLower() > p2.GetFullName().ToLower() then return 1
				if GetFullName().ToLower() < p2.GetFullName().ToLower() then return -1
			endif
		EndIf
		Return Super.Compare(o2)
	End Method


	Method GetTopGenre:Int()
		'base persons does not have top genres (-> unspecified)
		return TVTProgrammeGenre.undefined
	End Method


	Method GetProducedGenreCount:Int(genre:int)
		return 0
	End Method


	'base implementation: nobody knows the person
	Method GetPopularityValue:Float()
		return 0.0
	End Method


	Method GetAttribute:float(attributeID:int)
		return 0
	End Method


	Method SetJob(job:Int, enable:Int=True)
		If enable
			self.job :| job
		Else
			self.job :& ~job
		EndIf
	End Method


	Method HasJob:int(job:int)
		return (self.job & job) > 0
	End Method


	Method GetJobsDone:int(job:int)
		local jobIndex:int = TVTProgrammePersonJob.GetIndex(job)
		if jobIndex = 0 and job <> 0
			TLogger.Log("GetJobsDone()", "unsupported job-param.", LOG_ERROR)
		endif

		return self.jobsDoneTotal[jobIndex]
	End Method


	Method SetFirstName:Int(firstName:string)
		self.firstName = firstName
	End Method


	Method SetLastName:Int(lastName:string)
		self.lastName = lastName
	End Method


	Method SetNickName:Int(nickName:string)
		self.nickName = nickName
	End Method


	Method GetNickName:String()
		if nickName = "" then return firstName
		return nickName
	End Method


	Method GetFirstName:String()
		return firstName
	End Method


	Method GetLastName:String()
		return lastName
	End Method


	Method GetFullName:string()
		if self.lastName<>"" then return self.firstName + " " + self.lastName
		return self.firstName
	End Method


	Method GetAge:int()
		return -1
	End Method


	Method IsAlive:int()
		return True
	End Method


	Method IsBorn:int()
		return True
	End Method


	Method GetBaseFee:Int(jobID:int, blocks:int, channel:int=-1)
		'1 = 1, 2 = 1.75, 3 = 2.5, 4 = 3.25, 5 = 4 ...
		local blocksMod:Float = 0.25 + blocks * 0.75
		local baseFee:int

		Select jobID
			case TVTProgrammePersonJob.ACTOR
				baseFee = 7000
			case TVTProgrammePersonJob.SUPPORTINGACTOR
				baseFee = 3000
			case TVTProgrammePersonJob.HOST
				baseFee = 2500
			case TVTProgrammePersonJob.DIRECTOR
				baseFee = 6000
			case TVTProgrammePersonJob.SCRIPTWRITER
				baseFee = 3000
			case TVTProgrammePersonJob.MUSICIAN
				baseFee = 3500
			case TVTProgrammePersonJob.REPORTER
				baseFee = 2500
			case TVTProgrammePersonJob.GUEST
				baseFee = 1000
			default
				baseFee = 1000
		End Select

		return TFunctions.RoundToBeautifulValue(baseFee * blocksMod)
	End Method


	Method IsProducing:int(programmeDataGUID:string)
		For local guid:string = EachIn producingGUIDs
			if guid = programmeDataGUID then return True
		Next
		return False
	End Method


	Method StartProduction:int(programmeDataGUID:string)
		if not IsProducing(programmeDataGUID)
			producingGUIDs :+ [programmeDataGUID]
		endif

		'emit event so eg. news agency could react to it ("bla has a new job")
		'-> or to set them on the "scandals" list
		EventManager.triggerEvent(TEventSimple.Create("programmepersonbase.onStartProduction", New TData.addString("programmeDataGUID", programmeDataGUID), Self))
	End Method


	Method FinishProduction:int(programmeDataGUID:string, job:int)
		jobsDone :+ 1
		jobsDoneTotal[0] :+ 1
		For local jobIndex:int = 1 to TVTProgrammePersonJob.count
			if (job & TVTProgrammePersonJob.GetAtIndex(jobIndex)) > 0
				jobsDoneTotal[jobIndex] :+ 1
			endif
		Next

		local newProducingGUIDs:string[]
		For local guid:string = EachIn producingGUIDs
			if guid = programmeDataGUID then continue
			newProducingGUIDs :+ [guid]
		Next
		producingGUIDs = newProducingGUIDs

		'emit event so eg. news agency could react to it ("bla goes on holiday")
		EventManager.triggerEvent(TEventSimple.Create("programmepersonbase.onFinishProduction", New TData.addString("programmeDataGUID", programmeDataGUID), Self))
	End Method
End Type




'role/function a person had in a movie/series
Type TProgrammePersonJob
	'the person having done this job
	'using the GUID instead of "TProgrammePersonBase" allows to upgrade
	'a "normal" person to a "celebrity"
	Field personGUID:string

	'job is a bitmask for values defined in TVTProgrammePersonJob
	Field job:int = 0
	'maybe only female directors are allowed?
	Field gender:int = 0
	'allows limiting the job to specific heritages
	Field country:string = ""

	'only valid for actors
	Field roleGUID:string = ""


	Method Init:TProgrammePersonJob(personGUID:string, job:int, gender:int=0, country:string="", roleGUID:string="")
		self.personGUID = personGUID
		self.job = job
		self.gender = gender
		self.country = country

		self.roleGUID = roleGUID

		return self
	End Method


	Method SerializeTProgrammePersonJobToString:string()
		return StringHelper.EscapeString(personGUID, ":") + "::" +..
		       job + "::" +..
		       gender + "::" +..
		       StringHelper.EscapeString(country, ":") + "::" + ..
		       StringHelper.EscapeString(roleGUID, ":")
	End Method


	Method DeSerializeTProgrammePersonJobFromString(text:String)
		local vars:string[] = text.split("::")
		if vars.length > 0 then personGUID = StringHelper.UnEscapeString(vars[0])
		if vars.length > 1 then job = int(vars[1])
		if vars.length > 2 then gender = int(vars[2])
		if vars.length > 3 then country = StringHelper.UnEscapeString(vars[3])
		if vars.length > 4 then roleGUID = StringHelper.UnEscapeString(vars[4])
	End Method


	Method IsSimilar:int(otherJob:TProgrammePersonJob)
		if job <> otherJob.job then return False
		if personGUID <> otherJob.personGUID then return False
		if roleGUID <> otherJob.roleGUID then return False
		if gender <> otherJob.gender then return False
		if country <> otherJob.country then return False
		return True
	End Method
End Type

