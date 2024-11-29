SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.person.base.bmx"
Import "game.programme.programmerole.bmx"

Type TDatabaseLocalizer
	Global _instance:TDatabaseLocalizer
	Global _eventListeners:TEventListenerBase[]

	Field globalVariables:TIntMap
	Field persons:TIntMap
	Field roles:TIntMap
	Field englishLanguageId:Int

	Method New()
		Reset()
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]
		'localize person names / roles
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.App_OnSetLanguage, onSetLanguage ) ]
	End Method

	Method Reset()
		globalVariables = new TIntMap'CreateMap()
		persons =  new TIntMap'CreateMap()
		roles =  new TIntMap'CreteMap()
		englishLanguageId = TLocalization.GetLanguageId("en")
		If englishLanguageId < 0
			throw "TDatabaseLocalizer.Reset: unable to determine id of default language English" 
		EndIf
	End Method

	Method getGlobalVariable:String(languageId:Int, key:String, isKeyLowerCase:Int= False, fallback:Int=True)
		Local l:TLocalizationLanguage = getGlobalVariables(languageId)
		If Not isKeyLowerCase Then key=key.ToLower()
		If l And l.Has(key) Then Return l.Get(key)
		If fallback
			Return getGlobalVariable(englishLanguageId, key, True, False)
		EndIf
		Return Null
	End Method

	Method getGlobalVariables:TLocalizationLanguage(languageId:Int)
		Return TLocalizationLanguage(globalVariables.ValueForKey(languageId))
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
		Local languageId:Int = TLocalization.GetLanguageId(lang)
		If languageID < 0 Then Return
		Local person:TPersonBase
		For Local pl:TPersonLocalization = EachIn TPersonLocalization[](persons.valueForKey(languageId))
			person = personCollection.GetById(pl.id)
			If person
				If pl.flags & TPersonLocalization.FLAG_FIRSTNAME Then person.firstName = pl.firstName
				If pl.flags & TPersonLocalization.FLAG_LASTTNAME Then person.lastName = pl.lastName
				If pl.flags & TPersonLocalization.FLAG_TITLE Then person.title = pl.title
				If pl.flags & TPersonLocalization.FLAG_NICKTNAME Then person.nickName = pl.nickName
			EndIf
		Next
		Local roleCollection:TProgrammeRoleCollection = GetProgrammeRoleCollection()
		Local role:TProgrammeRole
		For Local pl:TPersonLocalization = EachIn TPersonLocalization[](roles.valueForKey(languageId))
			role = roleCollection.GetById(pl.id)
			If role
				If pl.flags & TPersonLocalization.FLAG_FIRSTNAME Then role.firstName = pl.firstName
				If pl.flags & TPersonLocalization.FLAG_LASTTNAME Then role.lastName = pl.lastName
				If pl.flags & TPersonLocalization.FLAG_TITLE Then role.title = pl.title
				If pl.flags & TPersonLocalization.FLAG_NICKTNAME Then role.nickName = pl.nickName
			EndIf
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return instance
Function GetDatabaseLocalizer:TDatabaseLocalizer()
	Return TDatabaseLocalizer.GetInstance()
End Function


Type TPersonLocalization
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

