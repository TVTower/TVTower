SuperStrict
Import "game.gameobject.bmx"

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
	

	Method GetRandom:TProgrammeRole()
		Return TProgrammeRole(Super.GetRandom())
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
	Field firstName:string
	Field lastName:string
	'title - like "Dr." or "Prof."
	Field title:string 
	Field gender:int
	'is this a custom role not used in a real world movie
	Field fictional:int = False


	Method Init:TProgrammeRole(firstName:string, lastName:string, title:string="", gender:int=0, fictional:int = False)
		self.firstName = firstName
		self.lastName = lastName
		self.title = title
		self.gender = gender
		self.fictional = fictional
		return self
	End Method


	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "programmerole-"+id
		self.GUID = GUID
	End Method	


	Method GetFirstName:String()
		return firstName
	End Method


	Method GetLastName:String()
		return lastName
	End Method


	Method GetFullName:string()
		if lastName <> ""
			if title <> ""
				return title + " " + firstName + " " + lastName
			else
				return firstName + " " + lastName
			endif
		else
			if title <> ""
				return title + " " + firstName
			else
				return firstName
			endif
		endif
	End Method
End Type