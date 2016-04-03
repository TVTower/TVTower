SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.string.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx" 'to access type-constants

Type TScriptBase Extends TNamedGameObject
	Field title:TLocalizedString
	Field description:TLocalizedString
	Field customTitle:string = ""
	Field customDescription:string = ""
	Field scriptLicenceType:Int = 0
	Field scriptProductType:Int = 0
	Field mainGenre:Int
	Field subGenres:Int[]
	'flags contains bitwise encoded things like xRated, paid, trash ...
	Field flags:Int = 0
	'is the live time fixed?
	Field liveTime:int =  -1
	'is the script title/description editable?
	Field textsEditable:int = False
	'scripts of series are parent of episode scripts
	Field parentScriptGUID:string = ""
	'all associated child scripts (episodes)
	Field subScripts:TScriptBase[]


	'override to add another generic naming
	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "scriptbase-"+id
		self.GUID = GUID
	End Method


	'override default method to add sub scripts
	Method SetOwner:int(owner:int=0)
		self.owner = owner

		'do the same for all children
		For local child:TScriptBase = eachin subScripts
			child.SetOwner(owner)
		Next
		return TRUE
	End Method


	Method hasFlag:Int(flag:Int)
		Return flags & flag
	End Method


	Method setFlag(flag:Int, enable:Int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method


	Method GetTitle:string()
		if customTitle then return customTitle
		if title then return title.Get()
		return ""
	End Method


	Method GetDescription:string()
		if customDescription then return customDescription
		if description then return description.Get()
		return ""
	End Method


	Method SetCustomTitle(value:string)
		customTitle = value
	End Method


	Method SetCustomDescription(value:string)
		customDescription = value
	End Method


	Method IsLive:int()
		return HasFlag(TVTProgrammeDataFlag.LIVE)
	End Method


	Method IsAnimation:Int()
		return HasFlag(TVTProgrammeDataFlag.ANIMATION)
	End Method
	
	
	Method IsCulture:Int()
		return HasFlag(TVTProgrammeDataFlag.CULTURE)
	End Method	
		
	
	Method IsCult:Int()
		return HasFlag(TVTProgrammeDataFlag.CULT)
	End Method
	
	
	Method IsTrash:Int()
		return HasFlag(TVTProgrammeDataFlag.TRASH)
	End Method
	
	
	Method IsBMovie:Int()
		return HasFlag(TVTProgrammeDataFlag.BMOVIE)
	End Method
	
	
	Method IsXRated:int()
		return HasFlag(TVTProgrammeDataFlag.XRATED)
	End Method


	Method IsPaid:int()
		return HasFlag(TVTProgrammeDataFlag.PAID)
	End Method


	Method isSeries:int()
		return scriptLicenceType = TVTProgrammeLicenceType.SERIES
	End Method


	Method isEpisode:int()
		return scriptLicenceType = TVTProgrammeLicenceType.EPISODE
	End Method


	Method isFictional:int()
		if scriptProductType = TVTProgrammeProductType.MOVIE then return True
		if scriptProductType = TVTProgrammeProductType.SERIES then return True
		return False
	End Method


	'returns the genre of a script - if a group, the one used the most
	'often is returned
	Method GetMainGenre:int()
		if GetSubScriptCount() = 0 then return mainGenre

		local genres:int[]
		local bestGenre:int=0
		For local scriptBase:TScriptBase = eachin subScripts
			local genre:int = scriptBase.GetMainGenre()
			if genre > genres.length-1 then genres = genres[..genre+1]
			genres[genre]:+1
		Next
		For local i:int = 0 to genres.length-1
			if genres[i] > bestGenre then bestGenre = i
		Next

		return bestGenre
	End Method


	Method GetMainGenreString:String(_genre:Int=-1)
		If _genre < 0 Then _genre = self.mainGenre
		Return _GetGenreString(_genre)
	End Method


	Function _GetGenreString:string(_genre:Int)
		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(_genre))
	End Function


	Method GetProductionTypeString:String(_productionType:Int=-1)
		If _productionType < 0 Then _productionType = self.scriptProductType
		return _GetProductionTypeString(_productionType)
	End Method


	Function _GetProductionTypeString:string(_productionType:Int)
		Return GetLocale("PROGRAMME_PRODUCT_" + TVTProgrammeProductType.GetAsString(_productionType))
	End Function


	Method GetSubScriptCount:int()
		return subScripts.length
	End Method


	Method GetSubScriptAtIndex:TScriptBase(arrayIndex:int=1)
		if arrayIndex > subScripts.length or arrayIndex < 0 then return null
		return subScripts[arrayIndex]
	End Method


	Method GetParentScript:TScriptBase()
		return self
	End Method


	Method GetSubScriptPosition:int(scriptBase:TScriptBase)
		'find my position and add 1
		For local i:int = 0 to GetSubScriptCount() - 1
			if GetSubScriptAtIndex(i) = scriptBase then return i
		Next
		return 0
	End Method


	'returns the next scriptBase of a scriptBases parent subScripts
	Method GetNextSubScript:TScriptBase()
		if not parentScriptGUID then return Null

		'find my position and add 1
		local nextArrayIndex:int = GetParentScript().GetSubScriptPosition(self) + 1
		'if we are at the last position, return the first one
		if nextArrayIndex >= GetParentScript().GetSubScriptCount() then nextArrayIndex = 0

		return GetParentScript().GetSubScriptAtIndex(nextArrayIndex)
	End Method


	Method AddSubScript:int(scriptBase:TScriptBase)
		'=== ADJUST SCRIPT TYPES ===

		'so subScriptTemplates can ask for sibling scripts
		scriptBase.parentScriptGUID = self.GetGUID()

		'add to array of subScriptTemplates
		subScripts :+ [scriptBase]
		Return TRUE
	End Method
End Type