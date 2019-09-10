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
	Field insignificantCount:Int = -1 {nosave}
	Field celebritiesCount:Int = -1 {nosave}
	Global _instance:TProgrammePersonBaseCollection


	Function GetInstance:TProgrammePersonBaseCollection()
		If Not _instance Then _instance = New TProgrammePersonBaseCollection
		Return _instance
	End Function


	Method Initialize:TProgrammePersonBaseCollection()
		insignificant.Clear()
		insignificantCount = -1

		celebrities.Clear()
		celebritiesCount = -1

		Return Self
	End Method


	Method GetByGUID:TProgrammePersonBase(GUID:String)
		Local result:TProgrammePersonBase
		result = TProgrammePersonBase(insignificant.ValueForKey(GUID))
		If Not result
			result = TProgrammePersonBase(celebrities.ValueForKey(GUID))
		EndIf
		Return result
	End Method


	Method GetInsignificantByGUID:TProgrammePersonBase(GUID:String)
		Return TProgrammePersonBase(insignificant.ValueForKey(GUID))
	End Method


	Method GetCelebrityByGUID:TProgrammePersonBase(GUID:String)
		Return TProgrammePersonBase(celebrities.ValueForKey(GUID))
	End Method


	'deprecated - used for v2-database
	Method GetCelebrityByName:TProgrammePersonBase(firstName:String, lastName:String)
		firstName = firstName.toLower()
		lastName = lastName.toLower()

		For Local person:TProgrammePersonBase = EachIn celebrities.Values()
			If person.firstName.toLower() <> firstName Then Continue
			If person.lastName.toLower() <> lastName Then Continue
			Return person
		Next
		Return Null
	End Method


	Function FilterArray:TProgrammePersonBase[](array:TProgrammePersonBase[], onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null)
		If Not array Or array.length = 0 Then Return Null

		Local result:TProgrammePersonBase[] = New TProgrammePersonBase[Min(10, array.length)]
		Local found:Int = 0
		For Local p:TProgrammePersonBase = EachIn array
			If onlyFictional And Not p.fictional Then Continue
			If onlyBookable And Not p.bookable Then Continue
			If job>0 And p.job & job = 0 Then Continue
			If gender>=0 And p.gender <> gender Then Continue
			If forbiddenGUIDs And StringHelper.InArray(p.GetGUID(), forbiddenGUIDs) Then Continue

			result[found] = p
			found :+ 1
		Next
		If found <> result.length Then result = result[.. found]

		Return result
	End Function


	Method GetRandomFromArray:TProgrammePersonBase(array:TProgrammePersonBase[], onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null)
		If Not array Or array.length = 0 Then Return Null

		Local effectiveArray:TProgrammePersonBase[] = FilterArray(array, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs)
		If effectiveArray.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return effectiveArray[(randRange(0, effectiveArray.length-1))]
	End Method


	'useful to fetch a random "amateur" (aka "layman")
	Method GetRandomInsignificant:TProgrammePersonBase(array:TProgrammePersonBase[] = Null, onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null)
		If array = Null Or array.length = 0 Then array = GetAllInsignificantAsArray(onlyFictional, onlyBookable, job, gender, forbiddenGUIDs)
		If array.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetRandomCelebrity:TProgrammePersonBase(array:TProgrammePersonBase[] = Null, onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null)
		If array = Null Or array.length = 0 Then array = GetAllCelebritiesAsArray(onlyFictional, onlyBookable, job, gender, forbiddenGUIDs)
		If array.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetAllInsignificantAsArray:TProgrammePersonBase[](onlyFictional:Int = False, onlyBookable:Int = False, job:Int=0, gender:Int=-1, forbiddenGUIDs:String[] = Null)
		Local array:TProgrammePersonBase[]
		'create a full array containing all elements
		For Local obj:TProgrammePersonBase = EachIn insignificant.Values()
			If onlyFictional And Not obj.fictional Then Continue
			If onlyBookable And Not obj.bookable Then Continue
			If job>0 And obj.job & job = 0 Then Continue
			If gender>=0 And obj.gender <> gender Then Continue
			If forbiddenGUIDs And StringHelper.InArray(obj.GetGUID(), forbiddenGUIDs) Then Continue

			array :+ [obj]
		Next
		Return array
	End Method


	Method GetAllCelebritiesAsArray:TProgrammePersonBase[](onlyFictional:Int = False, onlyBookable:Int = False, job:Int=0, gender:Int=-1, forbiddenGUIDs:String[] = Null)
		Local array:TProgrammePersonBase[]
		'create a full array containing all elements
		For Local obj:TProgrammePersonBase = EachIn celebrities.Values()
			If onlyFictional And Not obj.fictional Then Continue
			If onlyBookable And Not obj.bookable Then Continue
			If job>0 And obj.job & job = 0 Then Continue
			If gender>=0 And obj.gender <> gender Then Continue
			If forbiddenGUIDs And StringHelper.InArray(obj.GetGUID(), forbiddenGUIDs) Then Continue

			array :+ [obj]
		Next
		Return array
	End Method


	Method GetInsignificantCount:Int()
		If insignificantCount >= 0 Then Return insignificantCount

		insignificantCount = 0
		For Local person:TProgrammePersonBase = EachIn insignificant.Values()
			insignificantCount :+1
		Next
		Return insignificantCount
	End Method


	Method GetCelebrityCount:Int()
		If celebritiesCount >= 0 Then Return celebritiesCount

		celebritiesCount = 0
		For Local person:TProgrammePersonBase = EachIn celebrities.Values()
			celebritiesCount :+1
		Next
		Return celebritiesCount
	End Method


	Method RemoveInsignificant:Int(person:TProgrammePersonBase)
		If person.GetGuid() And insignificant.Remove(person.GetGUID())
			'invalidate count
			insignificantCount = -1

			Return True
		EndIf

		Return False
	End Method


	Method RemoveCelebrity:Int(person:TProgrammePersonBase)
		If person.GetGuid() And celebrities.Remove(person.GetGUID())
			'invalidate count
			celebritiesCount = -1

			Return True
		EndIf

		Return False
	End Method


	Method AddInsignificant:Int(person:TProgrammePersonBase)
		insignificant.Insert(person.GetGUID(), person)
		'invalidate count
		insignificantCount = -1

		Return True
	End Method


	Method AddCelebrity:Int(person:TProgrammePersonBase)
		celebrities.Insert(person.GetGUID(), person)
		'invalidate count
		celebritiesCount = -1

		Return True
	End Method


	Function SortByName:Int(o1:Object, o2:Object)
		Local p1:TProgrammePersonBase = TProgrammePersonBase(o1)
		Local p2:TProgrammePersonBase = TProgrammePersonBase(o2)
		If Not p2 Then Return 1
		If p1.GetFullName() = p2.GetFullName()
			Return p1.GetGUID() > p2.GetGUID()
		EndIf
        If p1.GetFullName().ToLower() > p2.GetFullName().ToLower()
			Return 1
        ElseIf p1.GetFullName().ToLower() < p2.GetFullName().ToLower()
			Return -1
		EndIf
		Return 0
	End Function
End Type
'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammePersonBaseCollection:TProgrammePersonBaseCollection()
	Return TProgrammePersonBaseCollection.GetInstance()
End Function

Function GetProgrammePersonBase:TProgrammePersonBase(guid:String)
	Return TProgrammePersonBaseCollection.GetInstance().GetByGUID(guid)
End Function




Type TProgrammePersonBase Extends TGameObject
	Field lastName:String = ""
	Field firstName:String = ""
	Field nickName:String = ""
	Field job:Int = 0
	'indicator for potential "upgrades" to become a celebrity
	Field jobsDone:Int
	Field jobsDoneTotal:Int[]
	Field canLevelUp:Int = True
	Field countryCode:String = ""
	Field gender:Int = 0
	'a text code representing the config for the figure generator
	Field faceCode:String
	'can this person _theoretically_ be booked for a production
	'(this allows disabling show-guests like "the queen" - which might
	' be guest in an older show)
	Field bookable:Int = True
	'is this an real existing person or someone we imaginated for the game?
	Field fictional:Int = False
	'is the person currently filming something?
	Field producingGUIDs:String[]


	Method New()
		'increase array so 0 (all) + all jobs fit into it
		jobsDoneTotal = jobsDoneTotal[.. TVTProgrammePersonJob.count + 1]
	End Method


	Method GenerateGUID:String()
		Return "programmeperson-base-"+id
	End Method


	Method SerializeTProgrammePersonBaseToString:String()
		Local jobsDoneString:String = String(jobsDone)
		For Local i:Int = EachIn jobsDoneTotal
			If jobsDoneString <> "" Then jobsDoneString :+","
			jobsDoneString :+ String(i)
		Next
		Return StringHelper.EscapeString(lastName, ":") + "::" + ..
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
		Local vars:String[] = text.split("::")
		If vars.length > 0 Then lastName = StringHelper.UnEscapeString(vars[0])
		If vars.length > 1 Then firstName = StringHelper.UnEscapeString(vars[1])
		If vars.length > 2 Then nickName = StringHelper.UnEscapeString(vars[2])
		If vars.length > 3 Then job = Int(vars[3])
		If vars.length > 4
			Local jD:String[] = vars[4].split(",")
			jobsDone = Int(jD[0])
			For Local i:Int = 1 Until jD.length
				jobsDoneTotal[i-1] = Int(jD[i-1])
			Next
		EndIf
		If vars.length > 5 Then canLevelUp = Int(vars[5])
		If vars.length > 6 Then fictional = Int(vars[6])
		If vars.length > 7 Then producingGUIDs = StringHelper.UnEscapeString(vars[7]).split(",")
		If vars.length > 8 Then id = Int(vars[8])
		If vars.length > 9 Then GUID = StringHelper.UnEscapeString(vars[9])
		If vars.length > 10 Then bookable = Int(vars[10])
	End Method


	Method Compare:Int(o2:Object)
		If o2 = Self Then Return 0

		Local p2:TProgrammePersonBase = TProgrammePersonBase(o2)
		If p2
			If GetFullName() = p2.GetFullName()
				If GetAge() > p2.GetAge() Then Return 1
				If GetAge() < p2.GetAge() Then Return -1
			Else
				If GetFullName().ToLower() > p2.GetFullName().ToLower() Then Return 1
				If GetFullName().ToLower() < p2.GetFullName().ToLower() Then Return -1
			EndIf
		EndIf
		Return Super.Compare(o2)
	End Method


	Method GetTopGenre:Int()
		'base persons does not have top genres (-> unspecified)
		Return TVTProgrammeGenre.undefined
	End Method


	Method GetProducedGenreCount:Int(genre:Int)
		Return 0
	End Method


	'base implementation: nobody knows the person
	Method GetPopularityValue:Float()
		Return 0.0
	End Method


	Method GetAttribute:Float(attributeID:Int)
		Return 0
	End Method


	Method SetJob(job:Int, enable:Int=True)
		If enable
			Self.job :| job
		Else
			Self.job :& ~job
		EndIf
	End Method


	Method HasJob:Int(job:Int)
		Return (Self.job & job) > 0
	End Method


	Method GetJobsDone:Int(job:Int)
		Local jobIndex:Int = TVTProgrammePersonJob.GetIndex(job)
		If jobIndex = 0 And job <> 0
			TLogger.Log("GetJobsDone()", "unsupported job-param.", LOG_ERROR)
		EndIf

		Return Self.jobsDoneTotal[jobIndex]
	End Method


	Method SetFirstName:Int(firstName:String)
		Self.firstName = firstName
	End Method


	Method SetLastName:Int(lastName:String)
		Self.lastName = lastName
	End Method


	Method SetNickName:Int(nickName:String)
		Self.nickName = nickName
	End Method


	Method GetNickName:String()
		If nickName = "" Then Return firstName
		Return nickName
	End Method


	Method GetFirstName:String()
		Return firstName
	End Method


	Method GetLastName:String()
		Return lastName
	End Method


	Method GetFullName:String()
		If Self.lastName<>""
			If Self.firstName <> "" Then Return Self.firstName + " " + Self.lastName
			Return Self.lastName
		EndIf
		Return Self.firstName
	End Method


	Method GetAge:Int()
		Return -1
	End Method


	Method IsAlive:Int()
		Return True
	End Method


	Method IsBorn:Int()
		Return True
	End Method


	Method GetBaseFee:Int(jobID:Int, blocks:Int, channel:Int=-1)
		'1 = 1, 2 = 1.75, 3 = 2.5, 4 = 3.25, 5 = 4 ...
		Local blocksMod:Float = 0.25 + blocks * 0.75
		Local baseFee:Int

		Select jobID
			Case TVTProgrammePersonJob.ACTOR
				baseFee = 7000
			Case TVTProgrammePersonJob.SUPPORTINGACTOR
				baseFee = 3000
			Case TVTProgrammePersonJob.HOST
				baseFee = 2500
			Case TVTProgrammePersonJob.DIRECTOR
				baseFee = 6000
			Case TVTProgrammePersonJob.SCRIPTWRITER
				baseFee = 3000
			Case TVTProgrammePersonJob.MUSICIAN
				baseFee = 3500
			Case TVTProgrammePersonJob.REPORTER
				baseFee = 2500
			Case TVTProgrammePersonJob.GUEST
				baseFee = 1000
			Default
				baseFee = 1000
		End Select

		Return TFunctions.RoundToBeautifulValue(baseFee * blocksMod)
	End Method


	Method IsProducing:Int(programmeDataGUID:String)
		For Local guid:String = EachIn producingGUIDs
			If guid = programmeDataGUID Then Return True
		Next
		Return False
	End Method


	Method StartProduction:Int(programmeDataGUID:String)
		If Not IsProducing(programmeDataGUID)
			producingGUIDs :+ [programmeDataGUID]
		EndIf

		'emit event so eg. news agency could react to it ("bla has a new job")
		'-> or to set them on the "scandals" list
		EventManager.triggerEvent(TEventSimple.Create("programmepersonbase.onStartProduction", New TData.addString("programmeDataGUID", programmeDataGUID), Self))
	End Method


	Method FinishProduction:Int(programmeDataGUID:String, job:Int)
		jobsDone :+ 1
		jobsDoneTotal[0] :+ 1
		For Local jobIndex:Int = 1 To TVTProgrammePersonJob.count
			If (job & TVTProgrammePersonJob.GetAtIndex(jobIndex)) > 0
				jobsDoneTotal[jobIndex] :+ 1
			EndIf
		Next

		Local newProducingGUIDs:String[]
		For Local guid:String = EachIn producingGUIDs
			If guid = programmeDataGUID Then Continue
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
	Field personGUID:String

	'job is a bitmask for values defined in TVTProgrammePersonJob
	Field job:Int = 0
	'maybe only female directors are allowed?
	Field gender:Int = 0
	'allows limiting the job to specific heritages
	Field country:String = ""

	'only valid for actors
	Field roleGUID:String = ""


	Method Init:TProgrammePersonJob(personGUID:String, job:Int, gender:Int=0, country:String="", roleGUID:String="")
		Self.personGUID = personGUID
		Self.job = job
		Self.gender = gender
		Self.country = country

		Self.roleGUID = roleGUID

		Return Self
	End Method


	Method SerializeTProgrammePersonJobToString:String()
		Return StringHelper.EscapeString(personGUID, ":") + "::" +..
		       job + "::" +..
		       gender + "::" +..
		       StringHelper.EscapeString(country, ":") + "::" + ..
		       StringHelper.EscapeString(roleGUID, ":")
	End Method


	Method DeSerializeTProgrammePersonJobFromString(text:String)
		Local vars:String[] = text.split("::")
		If vars.length > 0 Then personGUID = StringHelper.UnEscapeString(vars[0])
		If vars.length > 1 Then job = Int(vars[1])
		If vars.length > 2 Then gender = Int(vars[2])
		If vars.length > 3 Then country = StringHelper.UnEscapeString(vars[3])
		If vars.length > 4 Then roleGUID = StringHelper.UnEscapeString(vars[4])
	End Method


	Method IsSimilar:Int(otherJob:TProgrammePersonJob)
		If job <> otherJob.job Then Return False
		If personGUID <> otherJob.personGUID Then Return False
		If roleGUID <> otherJob.roleGUID Then Return False
		If gender <> otherJob.gender Then Return False
		If country <> otherJob.country Then Return False
		Return True
	End Method
End Type

