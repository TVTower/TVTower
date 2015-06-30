SuperStrict
Import Brl.Map
Import Brl.Math
Import "Dig/base.util.mersenne.bmx"
Import "game.gameobject.bmx"
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


	Method GetRandomCelebrity:TProgrammePersonBase(array:TProgrammePersonBase[] = null, onlyFictional:int = False)
		if array = Null or array.length = 0 then array = GetAllCelebritiesAsArray(onlyFictional)
		If array.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetAllCelebritiesAsArray:TProgrammePersonBase[](onlyFictional:int = False)
		local array:TProgrammePersonBase[]
		'create a full array containing all elements
		For local obj:TProgrammePersonBase = EachIn celebrities.Values()
			if onlyFictional and not obj.fictional then continue
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
	field jobsDone:int = 0
	field canLevelUp:int = True
	'is this an real existing person or someone we imaginated for the game?
	field fictional:int = False
	'id of the creating user
	Field creator:Int = 0
	'name of the creating user
	Field createdBy:String = ""


	'override to add another generic naming
	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "programmeperson-"+id
		self.GUID = GUID
	End Method


	Method AddJob:int(job:int)
		'already done?
		if self.job & job then return FALSE

		'add job
		self.job :| job
	End Method


	Method HasJob:int(job:int)
		return self.job & job
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


	Method FinishProduction:int(programmeDataGUID:string)
		jobsDone :+ 1
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


	Method IsSimilar:int(otherJob:TProgrammePersonJob)
		if job <> otherJob.job then return False
		if personGUID <> otherJob.personGUID then return False 
		if roleGUID <> otherJob.roleGUID then return False
		if gender <> otherJob.gender then return False
		if country <> otherJob.country then return False
		return True
	End Method
End Type

