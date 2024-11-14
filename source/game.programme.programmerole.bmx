SuperStrict
Import Brl.LinkedList
Import Brl.StringBuilder
Import "game.gameobject.bmx"
Import "Dig/base.util.persongenerator.bmx"

Type TProgrammeRoleCollection Extends TGameObjectCollection
	Global _instance:TProgrammeRoleCollection


	Function GetInstance:TProgrammeRoleCollection()
		if not _instance then _instance = new TProgrammeRoleCollection
		return _instance
	End Function


	Method Initialize:TProgrammeRoleCollection()
		Super.Initialize()
		return self
	End Method


	Method GetByGUID:TProgrammeRole(GUID:String)
		return TProgrammeRole(Super.GetByGUID(GUID))
	End Method


	Method GetByID:TProgrammeRole(ID:Int)
		return TProgrammeRole(Super.GetByID(ID))
	End Method
	

	Method GetRandom:TProgrammeRole()
		Return TProgrammeRole(Super.GetRandom())
	End Method


	Method GetRandomOfArray:TProgrammeRole(array:TProgrammeRole[] = null)
		if array = Null or array.length = 0 then return Null
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetRandomByFilter:TProgrammeRole(filter:TProgrammeRoleFilter)
		if not filter then return GetRandom()

		Local roles:TProgrammeRole[]

		For local role:TProgrammeRole = EachIn entries.Values()
			if not filter.DoesFilter(role) then continue

			'add it to candidates list
			roles :+ [role]
		Next
		Return GetRandomOfArray(roles)
	End Method	
	
	
	Method CreateRandomRole:TProgrammeRole(countryCode:String, gender:Int)
		Local pg:TPersonGeneratorEntry = GetPersonGenerator().GetUniqueDataset(countryCode, gender)
		If Not pg Then Return Null

		Local pr:TProgrammeRole = New TProgrammeRole
		pr.firstName = pg.firstName
		pr.lastName = pg.lastName
		pr.gender = pg.gender
		pr.countryCode = pg.countryCode.ToUpper()
		pr.fictional = True

		'avoid others of same name
		GetPersonGenerator().ProtectDataset(pg)
		Add(pr)
		
		Return pr
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeRoleCollection:TProgrammeRoleCollection()
	Return TProgrammeRoleCollection.GetInstance()
End Function




'describes a character in a programme/series (the "role")
Type TProgrammeRole extends TGameObject {_exposeToLua}
	'name of the character 
	Field lastName:string
	Field firstName:string
	Field nickName:String = ""
	'title - like "Dr." or "Prof."
	Field title:string 
	Field gender:int
	Field countryCode:string = ""
	'is this a custom role not used in a real world movie
	Field fictional:int = False


	Method GenerateGUID:string()
		return "programmerole-"+id
	End Method


	Method Init:TProgrammeRole(firstName:string, lastName:string, nickName:String="", title:string="", countryCode:string="", gender:int=0, fictional:int = False)
		self.firstName = firstName
		self.lastName = lastName
		self.nickName = nickName
		self.title = title
		self.gender = gender
		self.countryCode = countryCode
		self.fictional = fictional
		return self
	End Method


	Method GetFirstName:String()
		return firstName
	End Method


	Method GetTitle:String()
		return title
	End Method


	Method GetLastName:String(includeTitle:Int = False)
		If includeTitle and title
			Return title + " " + lastName
		Else
			Return lastName
		EndIf
	End Method


	Method GetNickName:String()
		If nickName = "" Then Return firstName
		Return nickName
	End Method


	Method GetFullName:string(includeTitle:Int = True)
		Local sb:TStringBuilder = New TStringBuilder()
		If includeTitle and title 
			sb.Append(title)
		EndIf
		If firstName
			If sb.Length() > 0 Then sb.Append(" ")
			sb.Append(firstName)
		EndIf
		If lastName
			If sb.Length() > 0 then sb.Append(" ")
			sb.Append(lastName)
		EndIf
		Return sb.ToString()
	End Method
End Type




'a filter for programme roles
Type TProgrammeRoleFilter
	Field gender:int = -1
	Field allowedCountries:string[]

	Global filters:TList = CreateList()


	Function Add:TProgrammeRoleFilter(filter:TProgrammeRoleFilter)
		filters.AddLast(filter)

		return filter
	End Function


	Method SetGender:TProgrammeRoleFilter(gender:int = 0)
		self.gender = gender
		Return self
	End Method


	Method SetAllowedCountries:TProgrammeRoleFilter(countries:string[])
		self.allowedCountries = countries
		Return self
	End Method


	Function GetCount:Int()
		return filters.Count()
	End Function


	Function GetAtIndex:TProgrammeRoleFilter(index:int)
		return TProgrammeRoleFilter(filters.ValueAtIndex(index))
	End Function


	'checks if the given programme role fits into the filter criteria
	Method DoesFilter:Int(role:TProgrammeRole)
		if not role then return False

		if gender > 0 and role.gender <> gender then return False

		'limited to one of the defined countries?
		if allowedCountries and allowedCountries.length > 0
			For local countryCode:string = EachIn allowedCountries
				if role.countryCode = countryCode then return True
			Next
			return False
		endif

		return True
	End Method
End Type
