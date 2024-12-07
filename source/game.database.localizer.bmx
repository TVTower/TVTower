SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.person.base.bmx"
Import "game.programme.programmerole.bmx"

Type TDatabaseLocalizer
	Global _instance:TDatabaseLocalizer
	Global _eventListeners:TEventListenerBase[]

	'persisted map language->array of variables
	Field globalVariables:TMap
	'persisted map language->array of TPersonLocalization for persons
	Field persons:TMap
	'persisted map language->array of TPersonLocalization for roles
	Field roles:TMap

	'caches for personbase per language
	Field personsById:TIntMap[] {nosave}
	'which persons have a localization
	Field localizedPersonIds:TIntMap {nosave}
	'caches for roles per language
	Field rolesById:TIntMap[] {nosave}
	'which rols have a localization
	Field localizedRoleIds:TIntMap {nosave}
	Field enId:Int {nosave}

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
		personsById = Null
		localizedPersonIds = Null
		rolesById = Null
		localizedRoleIds = Null
		enId = -1
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

	Method getPersonNames:TPersonBase(id:Int, languageId:Int)
		If Not personsById Then personsById = new TIntMap[TLocalization.languages.length]
		If Not personsById[languageId]
			_ensureCaches(languageId)
		EndIf

		If Not localizedPersonIds.Contains(id) Then Return Null
		Local result:TPersonBase = TPersonBase(personsById[languageId].valueForKey(id))
		If Not result Then result = TPersonBase(personsById[enId].valueForKey(id))
		return result
	EndMethod

	Method getRoleNames:TProgrammeRole(id:Int, languageId:Int)
		If Not rolesById Then rolesById = new TIntMap[TLocalization.languages.length]
		If Not rolesById[languageId]
			_ensureCaches(languageId)
		EndIf

		If Not localizedRoleIds.Contains(id) Then Return Null
		Local result:TProgrammeRole = TProgrammeRole(rolesById[languageId].valueForKey(id))
		If Not result Then result = TProgrammeRole(rolesById[enId].valueForKey(id))
		return result
	EndMethod

	Method _ensureCaches(languageID:Int)
		If Not personsById Then personsById = new TIntMap[TLocalization.languages.length]
		If Not rolesById Then rolesById = new TIntMap[TLocalization.languages.length]
		If Not localizedPersonIds Then localizedPersonIds = new TIntMap()
		If Not localizedRoleIds Then localizedRoleIds = new TIntMap()

		Local personmap:TIntMap = new TIntMap()
		personsById[languageId] = personmap
		Local code:String = TLocalization.GetLanguageCode(languageId)
		For Local pl:TPersonLocalization = EachIn TPersonLocalization[](persons.valueForKey(code))
			personmap.insert(pl.id, pl.toPersonBase())
			localizedPersonIds.insert(pl.id, "")
		Next

		Local rolemap:TIntMap = new TIntMap()
		rolesById[languageId] = rolemap
		For Local pl:TPersonLocalization = EachIn TPersonLocalization[](roles.valueForKey(code))
			rolemap.insert(pl.id, pl.toRole())
			localizedRoleIds.insert(pl.id, "")
		Next

		enId = TLocalization.GetLanguageID("en")
		If languageId <> enId And Not personsById[enId] Then _ensureCaches(enId)
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
		For Local pl:TPersonLocalization = EachIn TPersonLocalization[](persons.valueForKey(lang))
			person = personCollection.GetById(pl.id)
			If person
				pl.setValues(person)
			EndIf
		Next
		Local roleCollection:TProgrammeRoleCollection = GetProgrammeRoleCollection()
		Local role:TProgrammeRole
		For Local pl:TPersonLocalization = EachIn TPersonLocalization[](roles.valueForKey(lang))
			role = roleCollection.GetById(pl.id)
			If role
				pl.setValues(role)
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
	Field firstName:String
	Field lastName:String
	Field title:String
	Field nickName:String

	Method toPersonBase:TPersonBase()
		Local p:TPersonBase = new TPersonBase
		setValues(p)
		return p
	End Method

	Method toRole:TProgrammeRole()
		Local r:TProgrammeRole = new TProgrammeRole
		setValues(r)
		return r
	End Method

	Method setValues(p:TPersonBase)
		p.firstName = firstName
		p.lastName = lastName
		p.nickName = nickName
		p.title = title
	End Method

	Method setValues(r:TProgrammeRole)
		r.firstName = firstName
		r.lastName = lastName
		r.nickName = nickName
		r.title = title
	End Method
End Type

