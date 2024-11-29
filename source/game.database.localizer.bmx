SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.person.base.bmx"
Import "game.programme.programmerole.bmx"

Type TDatabaseLocalizer
	Global _instance:TDatabaseLocalizer

	Field globalVariables:TMap
	Field persons:TMap
	Field roles:TMap
	Field _eventListeners:TEventListenerBase[]

	Method New()
		Reset()
		'localize person names / roles
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.App_OnSetLanguage, onSetLanguage ) ]
	End Method

	Method Reset()
		globalVariables = new TMap'CreateMap()
		persons =  new TMap'CreateMap()
		roles =  new TMap'CreteMap()
	End Method

	Method getGlobalVariable:String(languageCode:String, key:String, fallback:Int=True)
		Local l:TLocalizationLanguage = getGlobalVariables(languageCode)
		Local lowerKey:String = key.toLower()
		If l And l.Has(lowerKey) Then Return l.Get(lowerKey)
		If fallback
			Return getGlobalVariable(TLocalization.GetDefaultLanguageCode(), lowerKey, False)
		EndIf
		Return lowerKey + " NOT FOUND"'exception?
	End Method

	Method getGlobalVariables:TLocalizationLanguage(languageCode:String)
		Return TLocalizationLanguage(globalVariables.ValueForKey(languageCode))
	End Method

	Function GetInstance:TDatabaseLocalizer()
		if not _instance then _instance = new TDatabaseLocalizer
		return _instance
	End Function

	Function onSetLanguage:Int(triggerEvent:TEventBase)
		Local lang:String = triggerEvent.GetData().GetString("languageCode", "en")
		If lang <> "en" Then GetInstance()._updateLocalization("en")
		GetInstance()._updateLocalization(lang)
	End Function

	Method _updateLocalization(lang:String)
		Local personCollection:TPersonBaseCollection = GetPersonBaseCollection()
		Local person:TPersonBase
		For Local pl:PersonLocalization = EachIn PersonLocalization[](persons.valueForKey(lang))
			person = personCollection.GetById(pl.id)
			If person
				If pl.flags & PersonLocalization.FLAG_FIRSTNAME Then person.firstName = pl.firstName
				If pl.flags & PersonLocalization.FLAG_LASTTNAME Then person.lastName = pl.lastName
				If pl.flags & PersonLocalization.FLAG_TITLE Then person.title = pl.title
				If pl.flags & PersonLocalization.FLAG_NICKTNAME Then person.nickName = pl.nickName
			EndIf
		Next
		Local roleCollection:TProgrammeRoleCollection = GetProgrammeRoleCollection()
		Local role:TProgrammeRole
		For Local pl:PersonLocalization = EachIn PersonLocalization[](roles.valueForKey(lang))
			role = roleCollection.GetById(pl.id)
			If role
				If pl.flags & PersonLocalization.FLAG_FIRSTNAME Then role.firstName = pl.firstName
				If pl.flags & PersonLocalization.FLAG_LASTTNAME Then role.lastName = pl.lastName
				If pl.flags & PersonLocalization.FLAG_TITLE Then role.title = pl.title
				If pl.flags & PersonLocalization.FLAG_NICKTNAME Then role.nickName = pl.nickName
			EndIf
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return instance
Function GetDatabaseLocalizer:TDatabaseLocalizer()
	Return TDatabaseLocalizer.GetInstance()
End Function


Type PersonLocalization
	Global FLAG_FIRSTNAME:Int = 1
	Global FLAG_LASTTNAME:Int = 2
	Global FLAG_TITLE:Int = 4
	Global FLAG_NICKTNAME:Int = 8

	Field id:Int
	Field flags:Int
	Field firstName:String
	Field lastName:String
	Field title:String
	Field nickName:String
End Type

