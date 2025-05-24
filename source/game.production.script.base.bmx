SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.logger.bmx"
Import "game.broadcast.audience.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx" 'to access type-constants
Import "game.gamerules.bmx"
Import "game.modifier.base.bmx"
Import "game.player.difficulty.bmx"

Type TScriptBase Extends TNamedGameObject
	Field title:TLocalizedString
	Field description:TLocalizedString
	Field scriptLicenceType:Int = 0
	Field scriptProductType:Int = 0
	Field mainGenre:Int
	Field subGenres:Int[]
	Field targetGroup:Int = -1
	'flags contains bitwise encoded things like xRated, paid, trash ...
	Field flags:Int = 0
	'remove tradeability on sell, refill limits, ...
	Field scriptFlags:Int = 0
	Field fixedLiveTime:Long = -1

	Field programmeDataModifiers:TData
	Field targetGroupAttractivityMod:TAudience = Null
	'effects both for scripts and the produced programme
	Field effects:TGameModifierGroup

	'scripts of series are parent of episode scripts
	Field parentScriptID:int = 0
	'all associated child scripts (episodes)
	Field subScripts:TScriptBase[]
	'ID of a programme produced with this script
	Field usedInProgrammeID:int
	'amount of times this script was used in productions
	Field usedInProductionsCount:int = 0

	'the maximum _current_ amount of productions with this script
	Field productionLimit:Int = 1
	'the maximum amount of productions possible for this script after reset
	Field productionLimitMax:Int = 1

	'flags for the created production
	Field productionBroadcastFlags:int = 0
	Field productionLicenceFlags:int = 0
	Field productionBroadcastLimit:int = 0
	Field productionTime:Int = -1
	Field productionTimeModBase:Float = 1.0
	'flags for the created broadcastmaterial
	Field broadcastTimeSlotStart:Int = -1
	Field broadcastTimeSlotEnd:Int = -1


	Method New()
		SetProductionLimit(1)
	End Method


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
		Return broadcastTimeSlotStart <> -1 And broadcastTimeSlotEnd <> -1
	End Method


	Method SetProductionLimit:Int(productionLimit:Int = -1)
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
		Return Self.productionLimit > 0
	End Method


	'this differs to "CanGetProduced()" as the latter one might include
	'other "reasons" for not being able to produce it anymore
	Method IsExceedingProductionLimit:Int() {_exposeToLua}
		Return CanGetProducedCount() <= 0
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
		Self.productionBroadcastLimit = productionBroadcastLimit

		return self.productionBroadcastLimit
	End Method


	Method GetProductionBroadcastLimit:int() {_exposeToLua}
		return self.productionBroadcastLimit
	End Method


	Method GetTitle:string()
		if title then return title.Get()
		return ""
	End Method


	Method GetDescription:string()
		if description then return description.Get()
		return ""
	End Method


	Method IsLive:int() {_exposeToLua}
		return HasFlag(TVTProgrammeDataFlag.LIVE)
	End Method

	Method IsAlwaysLive:int() {_exposeToLua}
		return HasProductionBroadcastFlag(TVTBroadcastMaterialSourceFlag.ALWAYS_LIVE)
	End Method

	Method IsAnimation:Int()
		return HasFlag(TVTProgrammeDataFlag.ANIMATION)
	End Method


	Method IsCulture:Int() {_exposeToLua}
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


	Method isSeries:int() {_exposeToLua}
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


	Method GetProductionTimeMod:Float()
		local result:Float = productionTimeModBase
		'live productions are done a bit faster
		if IsLive() then result :* 0.9
		'trash makes production way easier
		if IsTrash() then result :* 0.8
		'bmovies are done cheaper too
		if IsBMovie() then result :* 0.9
		'non-fiction-stuff (documentaries, sport shows...) are less advanced
		if not IsFictional() then result :* 0.9
		result :* GetPlayerDifficulty(owner).productionTimeMod

		Return result
	End Method
	
	
	Method GetBaseProductionDuration:Long()
		If self.productionTime >= 0
			Return self.productionTime
		Else
			Return GameRules.baseProductionTimeHours * TWorldTime.HOURLENGTH * GetProductionTimeMod()
		EndIf
	End Method


	Method GetBlocks:Int()
		Return 0
	End Method

	Method GetLiveTime:Long()
		return fixedLiveTime
	End Method

	Method GetLiveTimeText:String(nowTime:Long = -1)
		If IsLive()
			If Not IsSeries() And Not IsAlwaysLive()
				if nowTime = -1 then nowTime = GetWorldTime().GetTimeGone()
				Local liveTime:Long = GetLiveTime()
				Local liveDay:Int = GetWorldTime().GetDay(liveTime)
				Local nowDay:Int = GetWorldTime().GetDay(nowTime)
				If liveDay = nowDay
					Return GetLocale("PLANNED_LIVE_TIME_TODAY_FROM_X_OCLOCK").Replace("%X%", GetWorldTime().GetDayHour( liveTime ))
				ElseIf liveDay = nowDay + 1
					Return GetLocale("PLANNED_LIVE_TIME_TOMORROW_FROM_X_OCLOCK").Replace("%X%", GetWorldTime().GetDayHour( liveTime ))
				Else
					Return GetLocale("PLANNED_LIVE_TIME_IN_Y_DAYS_FROM_X_OCLOCK").Replace("%X%", GetWorldTime().GetDayHour( liveTime )).Replace("%Y%", (liveDay - nowDay))
				EndIf
			End If
			Return GetLocale("MOVIE_LIVESHOW")
		End If
		Return ""
	End Method


	'returns whether a new production could be done with this script
	'or if a limit is already reached
	'For series this only returns true if ALL episodes can be produced
	'at least once!
	Method CanGetProduced:int() {_exposeToLua}
		Return CanGetProducedCount() > 0
	End Method


	'returns how often a script can be produced.
	'For series it returns how often ALL episodes can at least be
	'produced (so minimum value of all episodes)
	Method CanGetProducedCount:int()
		local res:int = GetProductionLimit() - usedInProductionsCount

		if GetSubScriptCount() > 0
			For local sub:TScriptBase = EachIn subScripts
				res = Min(res, sub.CanGetProducedCount())
			Next
		endif

		'return a high number when there is no limit
		if GetProductionLimit() <= 0 then res = 1000

		return res
	End Method


	'returns how many elements can be produced
	'for movies this results in 1 (or 0)
	'for series it returns the amount of not yet produced episodes
	Method GetCanGetProducedElementsCount:Int()
		If GetSubScriptCount() > 0
			Return GetSubScriptCount() - GetProductionsCount()
		Else
			'1 or 0
			Return (CanGetProducedCount() > 0)
		EndIf
	End Method


	'returns amount of productions done with this script
	'
	'For series it returns the amount of episodes of a current "series
	'production" (like a "season"). So 2 of 5 produced will return 2
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