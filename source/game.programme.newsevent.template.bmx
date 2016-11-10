Rem
	====================================================================
	NewsEvent data - basic of broadcastable news
	====================================================================
EndRem
SuperStrict
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.math.bmx"
Import "Dig/base.util.scriptexpression.bmx"
Import "game.gameconstants.bmx"
Import "game.modifier.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.player.base.bmx"

Import "common.misc.templatevariables.bmx"
Import "game.broadcast.genredefinition.news.bmx"



Type TNewsEventTemplateCollection
	'holding all news event templates ever created (for GetByGUID() )
	Field allTemplates:TMap = new TMap
	Field reuseableTemplates:TMap = new TMap
	Field unusedTemplates:TMap = new TMap

	'CACHES (eg. for random accesses)
	Field _allCount:int = -1 {nosave}
	Field _unusedInitialTemplates:TList[] {nosave}
	Field _unusedAvailableInitialTemplates:TList[] {nosave}
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
		_unusedAvailableInitialTemplates = New TList[TVTNewsGenre.count + 1]
	End Method

	Method _InvalidateUnusedInitialTemplates()
		_unusedInitialTemplates = New TList[TVTNewsGenre.count + 1]
	End Method


	Method Add:int(obj:TNewsEventTemplate)
		'add to common maps
		'special lists get filled when using their Getters
		allTemplates.Insert(obj.GetLowerStringGUID(), obj)
		unusedTemplates.Insert(obj.GetLowerStringGUID(), obj)

		_InvalidateCaches()		

		return TRUE
	End Method


	Method Remove:int(obj:TNewsEventTemplate)
		allTemplates.Remove(obj.GetLowerStringGUID())
		reuseableTemplates.Remove(obj.GetLowerStringGUID())
		unusedTemplates.Remove(obj.GetLowerStringGUID())

		_InvalidateCaches()

		return TRUE
	End Method


	Method Use:int(obj:TNewsEventTemplate)
		obj.timesUsed :+ 1
		obj.SetLastUsedTime( Long(GetWorldTime().GetTimeGone()) )

		'this allows a previously "fixed" template to happen again later
		if obj.HasFlag(TVTNewsFlag.RESET_HAPPEN_TIME)
			obj.happenTime = -1
		endif

		unusedTemplates.Remove(obj.GetLowerStringGUID())
		if obj.IsReuseable()
			reuseableTemplates.insert(obj.GetLowerStringGUID(), obj)
		endif

		_InvalidateCaches()
	End Method


	Method GetCount:int()
		if _allCount < 0
			_allCount = 0
			For local k:string = EachIn allTemplates.Keys()
				_allCount :+ 1
			Next
		endif
		return _allCount
	End Method


	Method GetByGUID:TNewsEventTemplate(GUID:object)
		if not TLowerString(GUID) then GUID = TLowerString.Create(string(GUID))
		Return TNewsEventTemplate(allTemplates.ValueForKey(GUID))
	End Method


	Global nilNode:TNode = New TNode._parent
	Method SearchByPartialGUID:TNewsEventTemplate(GUID:String)
		'skip searching if there is nothing to search
		if GUID.trim() = "" then return Null
		
		GUID = GUID.ToLower()

		'find first hit
		Local node:TNode = allTemplates._FirstNode()
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
		local toReuse:TNewsEventTemplate[]

		For local template:TNewsEventTemplate = eachin reuseableTemplates.Values()
			'only interested in a specific genre?
			if genre <> -1 and template.genre <> genre then continue 

			if abs(GetWorldTime().GetDay(template.lastUsedTime) - GetWorldTime().GetDay()) >= minAgeInDays
				toReuse :+ [template]
			endif
		Next

		For local t:TNewsEventTemplate = Eachin toReuse
			reuseableTemplates.Remove(t.GetLowerStringGUID())

			unusedTemplates.Insert(t.GetLowerStringGUID(), t)

			t.SetLastUsedTime(0)
		Next

		'reset cache if needed
		if toReuse.length > 0
			_InvalidateUnusedAvailableInitialTemplates()
			_InvalidateUnusedInitialTemplates()
		endif
	End Method


	Method GetRandomUnusedAvailableInitial:TNewsEventTemplate(genre:int=-1)
		if not GetUnusedAvailableInitialTemplateList(genre) then return Null
		
		'if no news is available, make older ones available again
		'start with 4 days ago and lower until we got a news
		local days:int = 4
		While GetUnusedAvailableInitialTemplateList(genre).Count() = 0 and days >= 0
			TLogger.Log("TNewsEventTemplateCollection.GetRandomUnusedAvailableInitial("+genre+")", "ResetUsedTemplates("+days+", "+genre+").", LOG_DEBUG)
			ResetUsedTemplates(days, genre)
			days :- 1
		Wend

		local list:TList = GetUnusedAvailableInitialTemplateList(genre)
		if list.Count() = 0
			'This should only happen if no news events were found in the database
			if genre = TVTNewsGenre.CURRENTAFFAIRS
				TLogger.Log("TNewsEventTemplateCollection.GetRandomUnusedAvailableInitial("+genre+")", "no unused news event template found.", LOG_ERROR)
				return null
			else
				TLogger.Log("TNewsEventTemplateCollection.GetRandomUnusedAvailableInitial("+genre+")", "no unused news event template found. Falling back to CURRENT AFFAIR (genre "+ TVTNewsGenre.CURRENTAFFAIRS+").", LOG_ERROR)
				return GetRandomUnusedAvailableInitial(TVTNewsGenre.CURRENTAFFAIRS)
			endif
		endif
		
		'fetch a random news
		return TNewsEventTemplate( list.ValueAtIndex(randRange(0, list.Count() - 1)))
	End Method


	'returns (and creates if needed) a list containing only available
	'and initial news
	Method GetUnusedInitialTemplateList:TList(genre:int=-1)
		if genre >= TVTNewsGenre.count + 1 then return null
		if genre < -1 then genre = -1

		'create if missing
		if not _unusedInitialTemplates then _InvalidateUnusedInitialTemplates()

		if not _unusedInitialTemplates[genre+1]
			_unusedInitialTemplates[genre+1] = CreateList()
			For local t:TNewsEventTemplate = EachIn unusedTemplates.Values()
				if t.newsType <> TVTNewsType.InitialNews then continue
				'only interested in a specific genre?
				if genre <> -1 and t.genre <> genre then continue

				_unusedInitialTemplates[genre+1].AddLast(t)
			Next
		endif
		return _unusedInitialTemplates[genre+1]
	End Method


	'returns (and creates if needed) a list containing only available
	'and initial news
	Method GetUnusedAvailableInitialTemplateList:TList(genre:int=-1)
		if genre >= TVTNewsGenre.count + 1 then return null
		if genre < -1 then genre = -1

		'create if missing
		if not _unusedAvailableInitialTemplates then _InvalidateUnusedAvailableInitialTemplates()

		if not _unusedAvailableInitialTemplates[genre+1] 'with -1 this leads to [0]
			_unusedAvailableInitialTemplates[genre+1] = CreateList()
			For local t:TNewsEventTemplate = EachIn unusedTemplates.Values()
				if t.newsType <> TVTNewsType.InitialNews then continue
				'only interested in a specific genre?
				if genre <> -1 and t.genre <> genre then continue

				if not t.IsAvailable() then continue

				'ignore also if template has a "dated happen time"
				if t.happenTime <> - 1 then continue

				_unusedAvailableInitialTemplates[genre+1].AddLast(t)
			Next
		endif
		return _unusedAvailableInitialTemplates[genre+1]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetNewsEventTemplateCollection:TNewsEventTemplateCollection()
	Return TNewsEventTemplateCollection.GetInstance()
End Function



Type TNewsEventTemplate extends TBroadcastMaterialSourceBase
	Field LS_guid:TLowerString
	Field genre:Int = 0
	Field quality:Float = 1.0
	Field keywords:string = ""
	Field available:int = True
	Field templateVariables:TTemplateVariables = null
	'type of the news event according to TVTNewsType
	Field newsType:int = 0 'initialNews
	Field topicality:Float = 1.0
	Field lastUsedTime:Long = 0
	Field timesUsed:int = 0
	'time when a newly created newsevent is SET to happen (fixed time!)
	Field happenTime:Long = -1

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
		if quality >= 0 then SetQuality(quality)
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


	Method SetQuality(quality:Float)
		self.quality = MathHelper.Clamp(quality, 0, 1.0)
	End Method


	Method ToString:String()
		return "newsEventTemplate: title=" + GetTitle() + "  quality=" + GetQuality() + "  priceMod=" + GetModifier("price")
	End Method
	

	Method IsAvailable:int()
		'field "available" = false ?
		if not available then return False
		
		if availableYearRangeFrom >= 0 and GetWorldTime().GetYear() < availableYearRangeFrom then return False
		if availableYearRangeTo >= 0 and GetWorldTime().GetYear() > availableYearRangeTo then return False

		'a special script expression defines custom rules for adcontracts
		'to be available or not
		if availableScript and not GetScriptExpression().Eval(availableScript)
			return False
		endif

		return True
	End Method


	Function GetGenreString:String(Genre:Int)
		return GetLocale("NEWS_"+ TVTNewsGenre.GetasString(Genre).toUpper())
	End Function


	'override
	Method GetMaxTopicality:Float()
		return 1.0
	End Method


	Method AddKeyword:int(keyword:string)
		if HasKeyword(keyword, True) then return False

		if keywords then keywords :+ ","
		keywords :+ keyword.ToLower()
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


	Method IsReuseable:int()
		return not HasFlag(TVTNewsFlag.UNIQUE_EVENT)
	End Method


	'contains age/topicality decrease
	Method GetQuality:Float() {_exposeToLua}
		return quality
	End Method
End Type