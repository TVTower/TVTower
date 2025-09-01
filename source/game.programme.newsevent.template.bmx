Rem
	====================================================================
	NewsEvent data - basic of broadcastable news
	====================================================================
EndRem
SuperStrict
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.math.bmx"
Import "game.gameconstants.bmx"
Import "game.modifier.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.player.base.bmx"
'to be able to evaluate scripts
Import "game.gamescriptexpression.base.bmx"

Import "common.misc.templatevariables.bmx"
Import "game.broadcast.genredefinition.news.bmx"



Type TNewsEventTemplateCollection
	'ID->object pairs
	'holding all news event templates ever created (for GetByID() )
	Field allTemplates:TIntMap = new TIntMap
	Field reuseableTemplates:TIntMap = new TIntMap
	Field unusedTemplates:TIntMap = new TIntMap
	'TLowerString-GUID->object pairs
	Field allTemplatesGUID:TMap = new TMap
	Field threadLastHappened:TStringMap = new TStringMap

	'CACHES (eg. for random accesses)
	'the *Count fields help to predefine an initial size of the arrays
	'when refilling while nothing had changed meanwhile
	Field _allCount:int = -1 {nosave}
	Field _unusedInitialTemplates:TNewsEventTemplate[][] {nosave}
	Field _unusedInitialTemplatesCount:int[] {nosave}
	Field _unusedAvailableInitialTemplates:TNewsEventTemplate[][] {nosave}
	Field _unusedAvailableInitialTemplatesCount:int[] {nosave}
'	Field _unusedInitialTemplates:TList[] {nosave}
'	Field _unusedAvailableInitialTemplates:TList[] {nosave}
	Global _instance:TNewsEventTemplateCollection


	Function GetInstance:TNewsEventTemplateCollection()
		if not _instance
			_instance = new TNewsEventTemplateCollection
			_instance.Initialize()
		endif
		return _instance
	End Function


	Method Initialize:TNewsEventTemplateCollection()
		allTemplates.Clear()
		allTemplatesGUID.Clear()
		threadLastHappened.Clear()

		unusedTemplates.Clear()
		reuseableTemplates.Clear()

		_InvalidateCaches()

		return self
	End Method


	Method _InvalidateCaches()
		_InvalidateUnusedAvailableInitialTemplates()
		_InvalidateUnusedInitialTemplates()

		_allCount = -1
	End Method


	Method _InvalidateUnusedAvailableInitialTemplates()
'		_unusedAvailableInitialTemplates = New TList[TVTNewsGenre.count + 1]
		'I know no (vanilla compatible) way to reset an "array of arrays"
		'_unusedAvailableInitialTemplates = New TNewsEventTemplate[TVTNewsGenre.count +1][0]

		'so this will have to do
		local empty:TNewsEventTemplate[][]
		_unusedAvailableInitialTemplates = empty
		_unusedAvailableInitialTemplates = _unusedAvailableInitialTemplates[.. TVTNewsGenre.count+1]

		_unusedAvailableInitialTemplatesCount = New Int[TVTNewsGenre.count+1]
	End Method


	Method _InvalidateUnusedInitialTemplates()
'		_unusedInitialTemplates = New TList[TVTNewsGenre.count + 1]
		'I know no (vanilla compatible) way to reset an "array of arrays"
		'_unusedInitialTemplates = New TNewsEventTemplate[TVTNewsGenre.count][]

		'so this will have to do
		local empty:TNewsEventTemplate[][]
		_unusedInitialTemplates = empty
		_unusedInitialTemplates = _unusedInitialTemplates[.. TVTNewsGenre.count+1]

		_unusedInitialTemplatesCount = New Int[TVTNewsGenre.count+1]
	End Method


	Method Add:int(obj:TNewsEventTemplate)
		'add to common maps
		'special lists get filled when using their Getters
		allTemplatesGUID.Insert(obj.GetLowerStringGUID(), obj)
		allTemplates.Insert(obj.GetID(), obj)
		unusedTemplates.Insert(obj.GetID(), obj)

		_InvalidateCaches()

		return TRUE
	End Method


	Method Remove:int(obj:TNewsEventTemplate)
		allTemplatesGUID.Remove(obj.GetLowerStringGUID())
		allTemplates.Remove(obj.GetID())
		reuseableTemplates.Remove(obj.GetID())
		unusedTemplates.Remove(obj.GetID())

		_InvalidateCaches()

		return TRUE
	End Method


	Method Use:int(obj:TNewsEventTemplate)
		obj.timesUsed :+ 1
		obj.SetLastUsedTime( Long(GetWorldTime().GetTimeGone()) )

		Local setUsed:TNewsEventTemplate[]
		setUsed:+ [obj]

		'set templates with the same thread id as used as well
		If obj.threadId
			For Local unused:TNewsEventTemplate = EachIn unusedTemplates.values()
				If unused And unused<>obj And unused.threadId = obj.threadId Then
					setUsed:+ [unused]
					'print "  setting '"+ unused.GetTitle()+"' used due to thread "+obj.threadId
				EndIf
			Next
		EndIf

		For Local t:TNewsEventTemplate = EachIn setUsed
			unusedTemplates.Remove(t.GetID())
			If t.IsReuseable()
				reuseableTemplates.insert(t.GetID(), t)
			EndIf
		Next

		_InvalidateCaches()
	End Method


	Method GetCount:int()
		if _allCount < 0
			_allCount = 0
			For local k:object = EachIn allTemplates.Keys()
				_allCount :+ 1
			Next
		endif
		return _allCount
	End Method


	Method GetByGUID:TNewsEventTemplate(GUID:object)
		if not TLowerString(GUID) then GUID = TLowerString.Create(string(GUID))
		Return TNewsEventTemplate(allTemplatesGUID.ValueForKey(GUID))
	End Method


	Method GetByID:TNewsEventTemplate(ID:int)
		Return TNewsEventTemplate(allTemplates.ValueForKey(ID))
	End Method


	Global nilNode:TNode = New TNode._parent
	Method SearchByPartialGUID:TNewsEventTemplate(GUID:String)
		'skip searching if there is nothing to search
		if GUID.trim() = "" then return Null

		GUID = GUID.ToLower()

		'find first hit
		Local node:TNode = allTemplatesGUID._FirstNode()
		While node And node <> nilNode
			if TLowerString(node._key).Find(GUID) >= 0
				return TNewsEventTemplate(node._value)
			endif

			'move on to next node
			node = node.NextNode()
		Wend

		return Null
	End Method



	'resets already used news event templates so they can get used again
	Method ResetUsedTemplates(minAgeInDays:int=5, genre:int=-1)
		Local toReuse:TNewsEventTemplate[]

		Local day:Long = GetWorldTime().GetDay()
		Local currentlyUsedIds:TList = new TList
		Local templateThreadLastHappenedTime:Long
		Local threshold:Long = GetWorldTime().GetTimeGone() - minAgeInDays * TWorldTime.DAYLENGTH
		'prevent thread ids recently used or currently active from being reset
		For Local template:TNewsEventTemplate = EachIn allTemplates.Values()
			If genre <> -1 And template.genre <> genre Then Continue
			If Not template.threadId Then Continue
			' ignore templates not even having been used 
			' (eg. optional news chain elements)
			If template.lastUsedTime <= 0 Then Continue
			
			' when did last element in the thread did "happen" ?
			templateThreadLastHappenedTime = Long(String(threadLastHappened.valueForKey(template.threadId)))
			If templateThreadLastHappenedTime > threshold
				currentlyUsedIds.AddLast(template.threadId)
				'print "  mark thread as used recently new " + template.threadId +" "+template.GetTitle() +" "+GetWorldTime().GetFormattedGameDate(templateThreadLastHappenedTime)
			' "lastUsedTime" is when a template was used last time to 
			' initialize a new news event (regardless of the news event
			' being used at the end).
			ElseIf abs(GetWorldTime().GetDay(template.lastUsedTime) - day) < minAgeInDays
				currentlyUsedIds.AddLast(template.threadId)
				'print "  mark thread as used recently old" + template.threadId +" "+template.GetTitle()+" "+GetWorldTime().GetFormattedGameDate(template.lastUsedTime)
			EndIf
		Next

		For Local template:TNewsEventTemplate = EachIn reuseableTemplates.Values()
			'only interested in a specific genre?
			If Not template Or genre <> -1 And template.genre <> genre Then Continue
			'ignore recently used thread ids
			If currentlyUsedIds.Contains(template.threadId)
				'print "  ignoring template "+ template.GetTitle() +" because of thread " +template.threadId
				Continue
			EndIf

			If abs(GetWorldTime().GetDay(template.lastUsedTime) - day) >= minAgeInDays
				toReuse :+ [template]
			EndIf
		Next

		For local t:TNewsEventTemplate = EachIn toReuse
			reuseableTemplates.Remove(t.GetID())

			unusedTemplates.Insert(t.GetID(), t)

			t.SetLastUsedTime(0)
			t.Reset()
		Next

		'reset cache if needed
		If toReuse.length > 0
			_InvalidateUnusedAvailableInitialTemplates()
			_InvalidateUnusedInitialTemplates()
		EndIf
	End Method


	Method GetRandomUnusedAvailableInitial:TNewsEventTemplate(genre:int=-1)
		local arr:TNewsEventTemplate[] = GetUnusedAvailableInitialTemplates(genre)
		'if no news is available, make older ones available again
		'start with 7 days ago and lower until we got a news
		If arr.length = 0
			local days:int = 7
			While arr.length = 0 and days >= 0
				If days<=4 Then TLogger.Log("TNewsEventTemplateCollection.GetRandomUnusedAvailableInitial("+genre+")", "ResetUsedTemplates("+days+", "+genre+").", LOG_DEBUG)
				ResetUsedTemplates(days, genre)
				days :- 1
				arr = GetUnusedAvailableInitialTemplates(genre)
			Wend
		EndIf

		if arr.length = 0
			'This should only happen if no news events were found in the database
			if genre = TVTNewsGenre.CURRENTAFFAIRS
				TLogger.Log("TNewsEventTemplateCollection.GetRandomUnusedAvailableInitial("+genre+")", "no unused news event template found.", LOG_ERROR)
				return null
			else
				TLogger.Log("TNewsEventTemplateCollection.GetRandomUnusedAvailableInitial("+genre+")", "no unused news event template found. Falling back to CURRENT AFFAIR (genre "+ TVTNewsGenre.CURRENTAFFAIRS+").", LOG_ERROR)
				return GetRandomUnusedAvailableInitial(TVTNewsGenre.CURRENTAFFAIRS)
			endif
		endif

		'if there are templates with complex availability conditions (more than one condition must be met)
		'use it with a higher probability; otherwise such a template may never be used at all

		If RandRange(0, 10) > 5
			Local scriptArr:TNewsEventTemplate[] = new TNewsEventTemplate[0]
			For Local t:TNewsEventTemplate = EachIn arr
				If t.availableScript And t.availableScript.contains("${.and")
					scriptArr:+ [t]
				EndIf
			Next
			If scriptArr.length > 0 Then Return scriptArr[ RandRange(0, scriptArr.length-1) ]
		EndIf

		'fetch a random news
		return arr[ RandRange(0, arr.length-1) ]
	End Method


	'returns (and creates if needed) an array containing initial news
	Method GetUnusedInitialTemplates:TNewsEventTemplate[](genre:int=-1)
		if genre >= TVTNewsGenre.count + 1 then return new TNewsEventTemplate[0]
		if genre < -1 then genre = -1

		'index 0 is for "all" while genre 0 would be Politics/Economy
		local genreIndex:int = genre + 1

		'create if missing
		if not _unusedInitialTemplates then _InvalidateUnusedInitialTemplates()

		if not _unusedInitialTemplates[genreIndex]
			'start with the same size as last time (tries to avoid some
			'memory copy when doing an array resize)
			_unusedInitialTemplates[genreIndex] = new TNewsEventTemplate[ _unusedInitialTemplatesCount[genreIndex] ]

			_unusedInitialTemplatesCount[genreIndex] = 0
			For local t:TNewsEventTemplate = EachIn unusedTemplates.Values()
				if t.newsType <> TVTNewsType.InitialNews then continue
				'only interested in a specific genre?
				if genre <> -1 and t.genre <> genre then continue

				'resize if needed
				'number of "+20" is artificial and depends on how likely
				'more than 20 new events get added in average
				if _unusedInitialTemplates[genreIndex].length <= _unusedInitialTemplatesCount[genreIndex]
					_unusedInitialTemplates[genreIndex] = _unusedInitialTemplates[genreIndex][.. _unusedInitialTemplates[genreIndex].length + 20]
				endif

				_unusedInitialTemplates[genreIndex][ _unusedInitialTemplatesCount[genreIndex] ] = t

				_unusedInitialTemplatesCount[genreIndex] :+ 1
			Next

			'resize the array to the now real amount of entries
			if _unusedInitialTemplates[genreIndex].length <> _unusedInitialTemplatesCount[genreIndex]
				local old:int = _unusedInitialTemplates[genreIndex].length
				_unusedInitialTemplates[genreIndex] = _unusedInitialTemplates[genreIndex][.. _unusedInitialTemplatesCount[genreIndex]]
			endif
		endif
		return _unusedInitialTemplates[genreIndex]
	End Method



	'returns (and creates if needed) an array containing only available
	'and initial news
	Method GetUnusedAvailableInitialTemplates:TNewsEventTemplate[](genre:int=-1)
		'create if missing
		if not _unusedAvailableInitialTemplates then _InvalidateUnusedAvailableInitialTemplates()

		'index 0 is for "all" while genre 0 would be Politics/Economy
		local genreIndex:int = genre + 1

		if not _unusedAvailableInitialTemplates[genreIndex]
			'we start with the (maybe) already filtered initial templates
			'array
			'(there can never be more available initial than initial at all)
			local initialEventsArr:TNewsEventTemplate[] = GetUnusedInitialTemplates(genre)
			_unusedAvailableInitialTemplatesCount[genreIndex] = Min(_unusedInitialTemplatesCount[genreIndex], _unusedAvailableInitialTemplatesCount[genreIndex])

			'start with the same size as last time (tries to avoid some
			'memory copy when doing an array resize)
			_unusedAvailableInitialTemplates[genreIndex] = new TNewsEventTemplate[ _unusedAvailableInitialTemplatesCount[genreIndex] ]

			_unusedAvailableInitialTemplatesCount[genreIndex] = 0
			
			For local t:TNewsEventTemplate = EachIn initialEventsArr
				'no further filters required as we already use the
				'prefiltered array
				'exception: availability
				if not t.IsAvailable() then continue

				'planned time for this news in the future
				'(use flag TVTNewsFlag.RESET_HAPPEN_TIME to remove the time 
				' restriction for repetitions of this news(template) )
				if t.happenTime > 0 then continue


				'resize if needed
				'number of "+20" is artificial and depends on how likely
				'more than 20 new events get added in average
				if _unusedAvailableInitialTemplates[genreIndex].length <= _unusedAvailableInitialTemplatesCount[genreIndex]
					_unusedAvailableInitialTemplates[genreIndex] = _unusedAvailableInitialTemplates[genreIndex][.. _unusedAvailableInitialTemplates[genreIndex].length + 20]
				endif

				_unusedAvailableInitialTemplates[genreIndex][ _unusedAvailableInitialTemplatesCount[genreIndex] ] = t

				_unusedAvailableInitialTemplatesCount[genreIndex] :+ 1
			Next

			'resize the array to the now real amount of entries
			if _unusedAvailableInitialTemplates[genreIndex].length <> _unusedAvailableInitialTemplatesCount[genreIndex]
				local old:int = _unusedAvailableInitialTemplates[genreIndex].length
				_unusedAvailableInitialTemplates[genreIndex] = _unusedAvailableInitialTemplates[genreIndex][ .. _unusedAvailableInitialTemplatesCount[genreIndex] ]
			endif
		endif
		return _unusedAvailableInitialTemplates[genreIndex]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetNewsEventTemplateCollection:TNewsEventTemplateCollection()
	Return TNewsEventTemplateCollection.GetInstance()
End Function




Type TNewsEventTemplate extends TBroadcastMaterialSourceBase
	Field LS_guid:TLowerString
	Field threadId:String
	Field genre:Int = 0
	Field quality:Float = -1.0
	Field qualityMin:Float = -1.0
	Field qualityMax:Float = -1.0
	Field qualitySlope:Float = 0.5
	Field keywords:string = ""
	Field templateVariables:TTemplateVariables = null
	'type of the news event according to TVTNewsType
	Field newsType:int = 0 'initialNews
	Field topicality:Float = 1.0
	Field lastUsedTime:Long = 0
	Field timesUsed:int = 0
	'time when a newly created newsevent is SET to happen (fixed time!)
	Field happenTime:Long = -1

	'fine grained attractivity for target groups (splitted gender)
	Field targetGroupAttractivityMod:TAudience = null

	'minimum level to receive a news based on this
	'(eg. filter out soccer news for amateur leagues if only subscribed
	' to level 1 of 3)
	Field minSubscriptionLevel:int = 0
	Field availableYearRangeFrom:int = -1
	Field availableYearRangeTo:int = -1
	'special expression defining whether a contract is available for
	'ad vendor or not (eg. "YEAR > 2000" or "YEARSPLAYED > 2")
	Field availableScript:string = ""


	Method GenerateGUID:string()
		return "broadcastmaterialsource-newseventtemplate-"+id
	End Method
	
	
	Method Init:TNewsEventTemplate(GUID:string, title:TLocalizedString, description:TLocalizedString, Genre:Int, quality:Float=-1, modifiers:TData=null, newsType:int=0)
		self.SetGUID(GUID)
		self.title       = title
		self.description = description
		self.genre       = Genre
		self.topicality  = 1.0
		if quality >= 0 then quality = MathHelper.Clamp(quality, 0, 1.0)
		self.newsType	 = newsType
		'modificators: > 1.0 increases price (1.0 = 100%)
		if modifiers then self.modifiers = modifiers.Copy()

		Return self
	End Method


	Method GetLowerStringGUID:TLowerString()
		if not LS_guid then LS_guid = TLowerString.Create( GetGUID() )
		return LS_guid
	End Method


	Method CreateTemplateVariables:TTemplateVariables()
		'the parent of a template is not known in this moment
		'as the newsEvent gets a potential parent then

		if not templateVariables then templateVariables = new TTemplateVariables

		return templateVariables
	End Method


	'reset things used for random data
	'like placeholders (which are stored there so that children could
	'reuse it)
	Method Reset:int()
		ResetRandomData()
	End Method


	Method ResetRandomData:int()
		if templateVariables then templateVariables.Reset()
	End Method


	Method SetUsed(userObjectGUID:string)
		'TODO: store userObjectGUID somewhere? How to use such kind of
		'      user information - statistics?
		'mark the template (and increase usage count)
		GetNewsEventTemplateCollection().Use(self)
	End Method


	Method SetTitle(title:TLocalizedString)
		self.title = title
	End Method


	Method SetLastUsedTime(time:Long)
		lastUsedTime = time
	End Method


	Method SetDescription(description:TLocalizedString)
		self.description = description
	End Method


	Method SetGenre(genre:int)
		self.genre = genre
	End Method


	Method ToString:String()
		return "newsEventTemplate: title=" + GetTitle() + "  quality=" + GetQuality() + "  priceMod=" + GetModifier("price")
	End Method

	
	Method OnHappen:Int()
		'this allows a previously "fixed" template to happen again later
		if HasFlag(TVTNewsFlag.RESET_HAPPEN_TIME)
			happenTime = -1
		endif
	End Method


	Method IsAvailable:int()
		Return IsAvailableatTime(GetWorldTime().GetTimeGone())
	End Method
	
	
	Method IsAvailableAtHappenTime:int()
		If happenTime >= 0
			Return IsAvailableAtTime(happenTime)
		Else
			Return IsAvailableAtTime(GetWorldTime().GetTimeGone())
		EndIf
	End Method


	Method IsAvailableAtTime:int(t:Long)
		if hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE) then return False

		if availableYearRangeFrom > 0 and GetWorldTime().GetYear(t) < availableYearRangeFrom then return False
		if availableYearRangeTo > 0 and GetWorldTime().GetYear(t) > availableYearRangeTo then return False
		
		'a special script expression defines custom rules for adcontracts
		'to be available or not
		if availableScript and not GetGameScriptExpression().ParseToTrue(availableScript, self)
			return False
		endif

		return True
	End Method


	Function GetGenreString:String(Genre:Int)
		return GetLocale("NEWS_"+ TVTNewsGenre.GetasString(Genre).toUpper())
	End Function


	Method GetQuality:Float()
		If qualityMin >= 0 And qualityMax >= 0
			return 0.001 * BiasedRandRange(int(1000*qualityMin), int(1000*qualityMax), qualitySlope)
		ElseIf Not HasFlag(TVTNewsFlag.UNIQUE_EVENT)
			'for reusable news randomize a bit (+/- 20%) 
			'do not go below 10% / above 90% (or the defined quality in case it is beyond these thresholds)
			Local diff:Float = 0.01 * BiasedRandRange(-20, 20, 0.5)
			Local result:Float = MathHelper.Clamp(quality + diff, Min(0.1, quality), Max(0.9, quality))
			return result
		EndIf

		Return quality
	End Method


	'override
	Method GetMaxTopicality:Float()
		return 1.0
	End Method


	Method AddKeyword:int(keyword:string)
		Local keywordLC:String = keyword.ToLower()
		if HasKeywordLC(keywordLC, True) then return False

		if keywords then keywords :+ ","
		keywords :+ keywordLC
		Return True
	End Method


	Method HasKeyword:int(keyword:string, exactMode:int = False)
		if not keyword or keyword="," then return False

		if exactMode
			return (keywords+",").Find(( keyword+",").ToLower() ) >= 0
		else
			return keywords.Find(keyword.ToLower()) >= 0
		endif
	End Method


	'same method as HasKeyword() but assuming the keyword is LowerCase already
	Method HasKeywordLC:int(keyword:string, exactMode:int = False)
		if not keyword or keyword="," then return False

		if exactMode
			return (keywords+",").Find(keyword+",") >= 0
		else
			return keywords.Find(keyword) >= 0
		endif
	End Method


	Method IsReuseable:int()
		return not HasFlag(TVTNewsFlag.UNIQUE_EVENT)
	End Method
End Type
