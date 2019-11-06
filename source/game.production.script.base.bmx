SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.logger.bmx"
Import "game.world.worldtime.bmx"
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
	'flags which _might_ be enabled during production
	Field flagsOptional:int = 0
	'remove tradeability on sell, refill limits, ...
	Field scriptFlags:Int = 0
	'is the live time fixed?
	Field liveTime:int =  -1
	Field liveDateCode:String
	'is the script title/description editable?
	Field textsEditable:int = False
	'scripts of series are parent of episode scripts
	Field parentScriptID:int = 0
	'all associated child scripts (episodes)
	Field subScripts:TScriptBase[]
	'ID of a programme produced with this script
	Field usedInProgrammeID:int
	'amount of times this script was used in productions
	Field usedInProductionsCount:int = 0
	'limit (for shows - this limits how often it - and its script-clones
	'could get produced)
	Field usedInProductionsLimit:int = 1

	'the maximum _current_ amount of productions with this script
	Field productionLimit:Int = 0
	'the maximum amount of productions possible for this script after reset
	Field productionLimitMax:Int = 0

	'flags for the created production
	Field productionBroadcastFlags:int = 0
	Field productionLicenceFlags:int = 0
	Field productionBroadcastLimit:int = 0
	Field productionTime:Int = -1
	Field productionTimeMod:Float = 1.0
	'flags for the created broadcastmaterial
	Field broadcastTimeSlotStart:Int = -1
	Field broadcastTimeSlotEnd:Int = -1


	Method GenerateGUID:string()
		return "scriptbase-"+id
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


	Method hasScriptFlag:Int(flag:Int)
		Return scriptFlags & flag
	End Method


	Method setScriptFlag(flag:Int, enable:Int=True)
		If enable
			scriptFlags :| flag
		Else
			scriptFlags :& ~flag
		EndIf
	End Method


	Method isAvailable:int() {_exposeToLua}
		return True
	End Method


	Method IsTradeable:int()
		if GetSubScriptCount() = 0
			if not HasScriptFlag(TVTScriptFlag.TRADEABLE) then return False

		else
			'if script is a series-script: ask subs
			For local script:TScriptBase = eachin subScripts
				if not script.IsTradeable() then return FALSE
			Next
		endif

		return True
	End Method


	Method GetBroadcastTimeSlotStart:Int() {_exposeToLua}
		Return Self.broadcastTimeSlotStart
	End Method


	Method GetBroadcastTimeSlotEnd:Int() {_exposeToLua}
		Return Self.broadcastTimeSlotEnd
	End Method


	Method HasBroadcastTimeSlot:Int()
		Return broadcastTimeSlotStart <> -1 Or broadcastTimeSlotEnd <> -1
	End Method


	Method SetProductionLimit:Int(productionLimit:Int = -1)
		SetScriptFlag(TVTScriptFlag.HAS_PRODUCTION_LIMIT, productionLimit > 0)

		Self.productionLimitMax = productionLimit
		Self.productionLimit = productionLimit
	End Method


	Method GetProductionLimitMax:Int() {_exposeToLua}
		Return Self.productionLimitMax
	End Method


	Method GetProductionLimit:Int() {_exposeToLua}
		Return Self.productionLimit
	End Method


	Method HasProductionLimit:Int() {_exposeToLua}
		Return HasScriptFlag(TVTScriptFlag.HAS_PRODUCTION_LIMIT)
	End Method


	Method IsExceedingProductionLimit:Int() {_exposeToLua}
		Return GetProductionLimit() <= 0 And HasProductionLimit()
	End Method


	Method HasProductionBroadcastFlag:Int(flag:Int) {_exposeToLua}
		Return productionBroadcastFlags & flag
	End Method


	Method SetProductionBroadcastFlag(flag:Int, enable:Int=True)
		If enable
			productionBroadcastFlags :| flag
		Else
			productionBroadcastFlags :& ~flag
		EndIf
	End Method


	Method SetProductionBroadcastLimit:int(productionBroadcastLimit:Int = -1)
		SetProductionBroadcastFlag(TVTBroadcastMaterialSourceFlag.HAS_BROADCAST_LIMIT, productionBroadcastLimit > 0)

		Self.productionBroadcastLimit = productionBroadcastLimit

		return self.productionBroadcastLimit
	End Method


	Method HasProductionBroadcastLimit:int() {_exposeToLua}
		return HasProductionBroadcastFlag(TVTBroadcastMaterialSourceFlag.HAS_BROADCAST_LIMIT)
	End Method


	Method GetProductionBroadcastLimit:int() {_exposeToLua}
		return self.productionBroadcastLimit
	End Method


	Method IsExceedingProductionBroadcastLimit:Int() {_exposeToLua}
		Return GetProductionBroadcastLimit() <= 0 And HasProductionBroadcastLimit()
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


	Method FinishProduction(programmeLicenceID:int)
		if not programmeLicenceID
			TLogger.Log("FinishProduction", "Cannot set production of script finished, programmeLicenceID is empty.", LOG_ERROR)
			return
		endif

		'series header? - check if children were produced +1 than the
		'header
		'So if series is produced 2 times and there are some episodes
		'produced 4 times and one only 1 time, it does not increase
		'the production count for the series (while the episodes still
		'have this information)
		if GetSubScriptCount() > 0
			local allEpisodesProduced:int = True

			for local sub:TScriptBase = EachIn subScripts
				if sub.usedInProductionsCount <= usedInProductionsCount
					allEpisodesProduced = False
					exit
				endif
			Next
			if allEpisodesProduced
				usedInProductionsCount :+ 1
			endif
		else
			usedInProductionsCount :+ 1
		endif

		usedInProgrammeID = programmeLicenceID
	End Method


	Method GetEpisodeNumber:Int() {_exposeToLua}
		return 0
	End Method


	Method GetLiveTime:Long(nowTime:Long=-1, productionTime:Int = 0)
		If not IsLive() then return -1

		if nowTime = -1 then nowTime = GetWorldTime().GetTimeGone()

		Local releaseTime:Long = nowTime + productionTime

		'use the defined liveHour, the production is then ready on the
		'next day
		local nowDay:int = GetWorldTime().GetDay( releaseTime )
		'move to next day if live show is in less than 2 hours
		if GetWorldTime().GetTimeGone() - releaseTime < 2*3600
			releaseTime = GetWorldTime().MakeTime(0, nowDay +1, self.liveTime, 5, 0)
		else
			releaseTime = GetWorldTime().MakeTime(0, nowDay, self.liveTime, 5, 0)
		endif


		if self.liveDateCode
			Local liveDateCodeParams:Int[] = StringHelper.StringToIntArray(self.liveDateCode, ",")
			If liveDateCodeParams.length > 0
				If liveDateCodeParams[0] > 0
					Local useParams:Int[] = [-1,-1,-1,-1,-1,-1,-1,-1]
					For Local i:Int = 1 Until liveDateCodeParams.length
						useParams[i-1] = liveDateCodeParams[i]
					Next
					local t:long = GetWorldTime().CalcTime_Auto(releaseTime, liveDateCodeParams[0], useParams )
					'fix to not use any minutes except ":05"
					releaseTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(t), GetWorldTime().GetDayHour(t), 5, 0)


					'override "hour" with a custom time ?
					'this allows to have "liveDateCode" to define a general
					'day - and the liveTime to define the exact hour that day
					if liveTime >= 0
						local releaseDay:int = GetWorldTime().GetDay( releaseTime )
						releaseTime = GetWorldTime().MakeTime(0, releaseDay, liveTime, 5, 0)
						'move to next day if live hour is in the past is
						if GetWorldTime().GetTimeGone() > releaseTime
							releaseTime = GetWorldTime().MakeTime(0, releaseDay + 1, liveTime, 5, 0)
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		Return releaseTime
	End Method



	'returns whether a new production could be done with this script
	'or if a limit is already reached
	Method CanGetProduced:int()
		Return CanGetProducedCount() > 0
	End Method


	Method CanGetProducedCount:int()
		local res:int = usedInProductionsLimit - usedInProductionsCount

		if GetSubScriptCount() > 0
			For local sub:TScriptBase = EachIn subScripts
				res = Min(res, sub.CanGetProducedCount())
			Next
		endif

		'return a high number when there is no limit
		if usedInProductionsLimit <= 0 then res = 1000

		return res
	End Method


	'returns amount of productions done with this script
	'
	'For series it returns the amount of episodes of a current "series
	'production" (like a in a "season")
	Method GetProductionsCount:int()
		if GetSubScriptCount() > 0
			local res:int = 0
			'for series we check for episodes with a lower production
			'count than the series header
			for local sub:TScriptBase = EachIn subScripts
				if usedInProductionsCount < sub.usedInProductionsCount
					res :+1
				endif
			next
			return res
		else
			'for non-series we just use the production count of this
			'script
			return usedInProductionsCount
		endif
	End Method


	Method IsProduced:int()
		if isSeries()
			'check if there is at least one episode script which is not
			'produced yet
			for local subScript:TScriptBase = EachIn subScripts
				if not subScript.IsProduced() then return False
			Next
			return True
		else
			return usedInProgrammeID > 0
		endif
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
		if arrayIndex >= subScripts.length or arrayIndex < 0 then return null
		return subScripts[arrayIndex]
	End Method


	Method HasParentScript:int()
		return False
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
		if not parentScriptID then return Null

		'find my position and add 1
		local nextArrayIndex:int = GetParentScript().GetSubScriptPosition(self) + 1
		'if we are at the last position, return the first one
		if nextArrayIndex >= GetParentScript().GetSubScriptCount() then nextArrayIndex = 0

		return GetParentScript().GetSubScriptAtIndex(nextArrayIndex)
	End Method


	Method AddSubScript:int(scriptBase:TScriptBase)
		'=== ADJUST SCRIPT TYPES ===

		'so subScriptTemplates can ask for sibling scripts
		scriptBase.parentScriptID = self.GetID()

		'add to array of subScriptTemplates
		subScripts :+ [scriptBase]
		Return TRUE
	End Method
End Type