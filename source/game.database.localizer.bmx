SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.person.base.bmx"
Import "game.programme.programmerole.bmx"

Type TDatabaseLocalizer
	Global _instance:TDatabaseLocalizer
	Global _eventListeners:TEventListenerBase[]

	Field globalVariables:TMap
	Field persons:TMap
	Field roles:TMap
	Field personsById:TIntMap[] {nosave}

	Method New()
		Reset()
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]
		'localize person names / roles
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.App_OnSetLanguage, onSetLanguage ) ]
	End Method

	Method Reset()
		globalVariables = new TMap
		persons =  new TMap
		roles =  new TMap
	End Method

	Method getGlobalVariable:String(languageId:Int, key:String, isKeyLowerCase:Int= False, fallback:Int=True)
		Return getGlobalVariable(TLocalization.GetLanguageCode(languageId), key, isKeyLowerCase, fallback)
	End Method

	Method getGlobalVariable:String(languageCode:String, key:String, isKeyLowerCase:Int= False, fallback:Int=True)
		Local l:TLocalizationLanguage = getGlobalVariables(languageCode)
		If Not isKeyLowerCase Then key=key.ToLower()
		If l And l.Has(key) Then Return l.Get(key)
		If fallback
			Return getGlobalVariable("en", key, True, False)
		EndIf
		Return Null
	End Method

	Method getGlobalVariables:TLocalizationLanguage(languageCode:String)
		Return TLocalizationLanguage(globalVariables.ValueForKey(languageCode))
	End Method

	Method getPerson:TPersonLocalization(id:Int, languageId:Int)
		'TODO cache IDs that have a localization at all
		If Not personsById Then personsById = new TIntMap[TLocalization.languages.length]
		If Not personsById[languageId]
			Local map:TIntMap =  new TIntMap()
			personsById[languageId] = map
			Local code:String = TLocalization.GetLanguageCode(languageId)
			For Local pl:TPersonLocalization = EachIn TPersonLocalization[](persons.valueForKey(code))
				map.insert(pl.id, pl)
			Next
		EndIf
		'TODO fallback to default language
		return TPersonLocalization(personsById[languageId].valueForKey(id))
	EndMethod

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
		For Local pl:TPersonLocalization = EachIn TPersonLocalization[](persons.valueForKey(lang))
			person = personCollection.GetById(pl.id)
			If person
				person.firstName = pl.firstName
				person.lastName = pl.lastName
				person.title = pl.title
				person.nickName = pl.nickName
			EndIf
		Next
		Local roleCollection:TProgrammeRoleCollection = GetProgrammeRoleCollection()
		Local role:TProgrammeRole
		For Local pl:TPersonLocalization = EachIn TPersonLocalization[](roles.valueForKey(lang))
			role = roleCollection.GetById(pl.id)
			If role
				role.firstName = pl.firstName
				role.lastName = pl.lastName
				role.title = pl.title
				role.nickName = pl.nickName
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
	Field id:Int
	Field flags:Int
	Field firstName:String
	Field lastName:String
	Field title:String
	Field nickName:String
End Type

