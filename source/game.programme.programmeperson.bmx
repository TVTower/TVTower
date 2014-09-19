SuperStrict
Import Brl.Map
Import "Dig/base.util.mersenne.bmx"
Import "game.gameobject.bmx"


Type TProgrammePersonCollection
	Field insignificant:TMap = CreateMap()
	Field celebrities:TMap = CreateMap()
	Field insignificantCount:int = -1 {nosave}
	Field celebritiesCount:int = -1 {nosave}
	Global _instance:TProgrammePersonCollection


	Function GetInstance:TProgrammePersonCollection()
		if not _instance then _instance = new TProgrammePersonCollection
		return _instance
	End Function


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

	Method GetCelebrityByGUID:TProgrammePerson(GUID:String)
		Return TProgrammePerson(celebrities.ValueForKey(GUID))
	End Method


	'deprecated - used for v2-database
	Method GetCelebrityByName:TProgrammePerson(firstName:string, lastName:string)
		firstName = firstName.toLower()
		lastName = lastName.toLower()

		For local person:TProgrammePerson = eachin celebrities.Values()
			if person.firstName.toLower() <> firstName then continue
			if person.lastName.toLower() <> lastName then continue
			return person
		Next
		return Null
	End Method


	Method GetRandomCelebrity:TProgrammePerson(array:TProgrammePerson[] = null)
		if array = Null or array.length = 0 then array = GetAllCelebritiesAsArray()
		If array.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetAllCelebritiesAsArray:TProgrammePerson[]()
		local array:TProgrammePerson[]
		'create a full array containing all elements
		For local obj:TProgrammePerson = EachIn celebrities.Values()
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
Function GetProgrammePersonCollection:TProgrammePersonCollection()
	Return TProgrammePersonCollection.GetInstance()
End Function




Type TProgrammePersonBase extends TGameObject
	field lastName:String = ""
	field firstName:String = ""
	field nickName:String = ""
	field job:int = 0
	field realPerson:int = False


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
End Type



'a person connected to a programme - directors, writers, actors...
Type TProgrammePerson extends TProgrammePersonBase
	field dayOfBirth:string	= "0000-00-00"
	field dayOfDeath:string	= "0000-00-00"
	field gender:int = 0
	field country:string = ""
	'how prominent is a person 0-1.0 = 0-100%
	field prominence:float = 0.0
	field skill:float = 0.0
	field fame:float = 0.0
	field priceModifier:Float = 1.0
	field scandalizing:float = 0.0
	field power:float = 0.0
	field humor:float = 0.0
	field charisma:float = 0.0
	field appearance:float = 0.0
	'at which genres this person is doing his best job
	'TODO: maybe change this later to a general genreExperience-Container
	'which increases over time
	field topGenre1:Int = -1
	field topGenre2:Int = -1
	

	'don't feel attacked by this naming! "UNKNOWN" includes
	'transgenders, maybe transsexuals, unknown lifeforms ... just
	'everything which is not called by a male or female pronoun
	Const GENDER_UNKNOWN:int = 0
	Const GENDER_MALE:int = 1
	Const GENDER_FEMALE:int = 2
	


	Method SetDayOfBirth:Int(date:String="")
		if date = "" then date = "0000-00-00"
		self.dayOfBirth = date
	End Method


	Method SetDayOfDeath:Int(date:String="")
		if date = "" then date = "0000-00-00"
		self.dayOfDeath = date
	End Method
End Type




'role/function a person had in a movie/series
Type TProgrammePersonJob
	Field person:TProgrammePersonBase
	Field job:int = 0
	Field characterName:String 'only valid for actors

	'one person could have multiple jobs: use bitmask values
	Const JOB_UNKNOWN:int = 0
	Const JOB_DIRECTOR:int = 1
	Const JOB_ACTOR:int = 2
	Const JOB_WRITER:int = 4


	Method Init:TProgrammePersonJob(person:TProgrammePersonBase, job:int, characterName:string="")
		self.person = person
		self.job = job
		self.characterName = characterName
		
		return self
	End Method

End Type