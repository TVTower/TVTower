SuperStrict
'for TBroadcastSequence
Import "game.broadcast.base.bmx"
Import "game.broadcast.genredefinition.news.bmx"
Import "game.broadcastmaterial.base.bmx"
'for TNewsEvent
Import "game.programme.newsevent.bmx"
Import "game.publicimage.bmx"
Import "game.stationmap.bmx" 'to access current broadcast area



Type TNewsShow extends TBroadcastMaterial {_exposeToLua="selected"}
	Field news:TBroadcastMaterial[3]
	Field title:string = ""


	Method GenerateGUID:string()
		return "broadcastmaterial-newsshow-"+id
	End Method


	Function Create:TNewsShow(title:String="", owner:int=0, newsA:TBroadcastMaterial, newsB:TBroadcastMaterial, newsC:TBroadcastMaterial)
		Local obj:TNewsShow = New TNewsShow
		obj.news[0] = newsA
		obj.news[1] = newsB
		obj.news[2] = newsC
		obj.owner = owner 'cannot use newsA.owner as newsA may be empty...
		obj.title = title

		obj.setMaterialType(TVTBroadcastMaterialType.NEWSSHOW)
		'by default a freshly created programme is of its own type
		obj.setUsedAsType(TVTBroadcastMaterialType.ADVERTISEMENT)

		Return obj
	End Function


	'override
	Method SourceHasBroadcastFlag:int(flag:Int) {_exposeToLua}
		for local n:TNews = EachIn news
			if n.SourceHasBroadcastFlag(flag) then return True
		Next
		return False
	End Method


	Method IsControllable:int() {_exposeToLua}
		For local n:TNews = EachIn news
			if not n.IsControllable() then return False
		Next
		return True
	End Method


	'override to inform contained news too
	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		'inform others
		TriggerBaseEvent(GameEventKeys.Broadcast_Newsshow_BeforeBeginBroadcasting, New TData.addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute).add("audienceData", audienceData), Self)

		Super.BeginBroadcasting(day, hour, minute, audienceData)

		For local newsEntry:TBroadcastMaterial = EachIn news
			newsEntry.BeginBroadcasting(day, hour, minute, audienceData)
		Next

		'inform others
		TriggerBaseEvent(GameEventKeys.Broadcast_Newsshow_BeginBroadcasting, New TData.addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute).add("audienceData", audienceData), Self)
	End Method


	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		'inform others _before_ newsentries get adjusted!
		TriggerBaseEvent(GameEventKeys.Broadcast_Newsshow_BeforeFinishBroadcasting, New TData.addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute).add("audienceData", audienceData), Self)

		Super.FinishBroadcasting(day, hour, minute, audienceData)

		'adjust topicality relative to possible audience
		local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		local newsSlot:int
		local topAudience:int = GetBroadcastManager().GetCurrentBroadcast().GetTopAudience()
		local audienceSum:int = audienceResult.Audience.GetTotalSum()

		for local i:int = 0 to 2
			local newsEntry:TBroadcastMaterial = news[i]
			if not newsEntry then continue

			newsEntry.FinishBroadcasting(day, hour, minute, audienceData)

			local news:TNews = TNews(newsEntry)
			if news
				'adjust trend/popularity
				local popData:TData = new TData
				popData.AddNumber("attractionQuality", audienceResult.AudienceAttraction.Quality)
				popData.AddNumber("audienceSum", audienceSum)
				popData.AddNumber("broadcastTopAudience", topAudience)

				Local popularity:TGenrePopularity = news.GetNewsEvent().GetGenreDefinition().GetPopularity()
if popularity
				popularity.FinishBroadcastingNews(popData, i+1)
else
	TLogger.Log("FinishBroadcastingNews", "Popularity inexistent.", LOG_ERROR)
	debugstop
endif
			endif

		Next

		'inform others
		TriggerBaseEvent(GameEventKeys.Broadcast_Newsshow_FinishBroadcasting, New TData.addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute).add("audienceData", audienceData), Self)
	End Method


	'add mod for all news slots
	Method GetGenreTargetGroupMod:SAudience(definition:TGenreDefinitionBase)
		local result:SAudience = New SAudience(1,1)

		local newsSlotsUsed:int = 0
		for local i:int = 0 until news.length
			Local currentNews:TNews = TNews(news[i])
			'skip empty slots
			If not currentNews Then continue

			newsSlotsUsed :+ 1

			local newsGenreTargetGroupMod:SAudience = currentNews.GetGenreTargetGroupMod( currentNews.GetGenreDefinition() )
			newsGenreTargetGroupMod.Multiply(GetNewsSlotWeight(i))
			result.Add( newsGenreTargetGroupMod )
		Next
		if newsSlotsUsed > 1
			result.Divide(newsSlotsUsed)
		endif
		return result
	End Method


	'returns the audienceAttraction for a newsShow (3 news)
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		Local resultAudienceAttr:TAudienceAttraction = New TAudienceAttraction
		resultAudienceAttr.BroadcastType = TVTBroadcastMaterialType.NEWSSHOW
		resultAudienceAttr.FlagsTargetGroupMod = New TAudience
		resultAudienceAttr.PublicImageMod = New TAudience
		resultAudienceAttr.TrailerMod = New TAudience
		resultAudienceAttr.MiscMod = New TAudience
		resultAudienceAttr.AudienceFlowBonus = New TAudience
		resultAudienceAttr.SequenceEffect = New TAudience
		resultAudienceAttr.BaseAttraction = New TAudience
		resultAudienceAttr.FinalAttraction = New TAudience
		resultAudienceAttr.targetGroupAttractivity = New TAudience
		resultAudienceAttr.LuckMod = New TAudience
		'attention: set mods to 0 (news mods get _added_)
		resultAudienceAttr.CastMod = 0
		resultAudienceAttr.GenrePopularityMod = 0
		resultAudienceAttr.FlagsPopularityMod = 0
		'do not to the following as this mod is added already in "GetAudienceAttraction"
		'of the individual news
		'resultAudienceAttr.GenreTargetGroupMod = New TAudience( GetGenreTargetGroupMod() )
		'just create an empty audience instead, the function still returns
		'valid values (for debugging output)
		resultAudienceAttr.GenreTargetGroupMod = New TAudience

		local genreCount:int[ TVTNewsGenre.count ]
		local slotsUsed:int = 0

		for local i:int = 0 until news.length
			'RONNY @Manuel: Todo - "Filme" usw. vorbereiten/einplanen
			'               es koennte ja jemand "Trailer" in die News
			'               verpacken - siehe RTL2 und Co.
			Local currentNews:TNews = TNews(news[i])
			'skip empty slots
			If not currentNews Then continue

			genreCount[currentNews.GetGenre()] :+ 1
			slotsUsed :+ 1

			'fix broken (old) savegame-information
			if currentNews.usedAsType = 0
				currentNews.setUsedAsType(TVTBroadcastMaterialType.NEWS)
			endif

			Local tempAudienceAttr:TAudienceAttraction = currentNews.GetAudienceAttraction(hour, block, lastMovieBlockAttraction, lastNewsBlockAttraction, withSequenceEffect, withLuckEffect)
			'limit attraction values to 0-1.0
			tempAudienceAttr.FinalAttraction.CutBorders(0, 1.0)

			'if owner=1 then print "owner #"+owner+"   news #"+i+": " + tempAudienceAttr.targetGroupAttractivity.ToString() +"  * " + GetNewsSlotWeight(i)

			'different weight for news slots
			resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(GetNewsSlotWeight(i)))
			local title:string = "--"
			if currentNews then title = currentNews.GetTitle()
		Next
		'if owner=1 then print "owner #"+owner+"  newsshow: " + resultaudienceAttr.targetGroupAttractivity.ToString()

		local genresUsed:int = 0
		For local g:int = EachIn genreCount
			if g > 0 then genresUsed :+ 1
		Next

		'bonus if sending varying genres (a good "mix")
		'5% bonus if 2+ genres used
		if genresUsed = 2
'			resultAudienceAttr.Multiply(1.05)
		'10% bonus if 3+ genres used
		elseif genresUsed >= 3
'			resultAudienceAttr.Multiply(1.10)
		endif

		'malus for not sending something in each slot
		if slotsUsed = 1
'			resultAudienceAttr.Multiply(0.90)
		elseif slotsUsed = 2
'			resultAudienceAttr.Multiply(0.96)
		endif

		'Ronny 2016/06/29: should we mark it as a malfunction?
		'mark malfunction if nothing is send
		if slotsUsed = 0 then resultAudienceAttr.malfunction = True

		'already done with "addAttraction"
		'resultAudienceAttr.Quality = GetQuality()

		Return resultAudienceAttr
	End Method


	'override default getter to make event id the reference id
	Method GetReferenceID:int() {_exposeToLua}
		return self.id
	End Method


	'override default
    Method GetTitle:string() {_exposeToLua}
		return title
    End Method


	'override default
    Method GetDescription:string() {_exposeToLua}
		local text:string = "Inhalt:~n"
		for local i:int = 0 to 2
			if news[i] then text = text + news[i].getTitle()+"~n"
		Next
		return text
    End Method



	Method GetQuality:Float() {_exposeToLua}
		Local quality:Float = 0.0

		For local i:int = 0 until news.length
			If TNews(news[i]) Then quality :+ TNews(news[i]).GetQuality() * GetNewsSlotWeight(i)
		Next

		'no minus quote
		Return Max(0, quality)
	End Method


	Function GetNewsSlotWeight:Float(slotIndex:int) {_exposeToLua}
		Select slotIndex
			case 0	return 0.45
			case 1	return 0.35
			case 2	return 0.2
			Default	return 0.1
		End Select
	End Function
End Type




'This object stores a players news.
Type TNews extends TBroadcastMaterialDefaultImpl {_exposeToLua="selected"}
	'deprecated - use GetNewsEvent() from now on
    Field newsEvent:TNewsEvent {_exposeToLua}
    Field newsEventID:Int {_exposeToLua}
    'Field newsEvent:TNewsEvent	= Null	{_exposeToLua}
    'delay the news for a certain time (depending on the abonnement-level)
    Field publishDelay:Int = 0
    'store the event happenedTime here, so the event could get used
    'multiple times without changing the news
    Field happenedTime:Long = -1
    'modificators to this news (stored here: is individual for each player)
    'absolute: value just gets added
    'relative: fraction of base price (eg. 0.3 -> 30%)
	Field priceModRelativeNewsAgency:float = 0.0
	Field priceModAbsoluteNewsAgency:int = 0

    'the price which was paid for the news
    Field paidPrice:int = 0
    Field paid:int = 0


	Method GenerateGUID:string()
		return "broadcastmaterial-news-"+id
	End Method


	Function Create:TNews(newsEvent:TNewsEvent, publishdelay:Int = 0)
		If Not newsEvent then Throw "TNews.Create() - newsEvent is null" 
		If Not newsEvent.HasHappened() then Throw "TNews.Create() - newsEvent has not happened yet" 
		
		Local obj:TNews = New TNews
		obj.publishDelay = publishdelay
		obj.newsEventID = newsEvent.GetID()

		obj.setMaterialType(TVTBroadcastMaterialType.NEWS)
		'by default a freshly created programme is of its own type
		obj.setUsedAsType(TVTBroadcastMaterialType.NEWS)

		Return obj
	End Function


	Method GetSource:TBroadcastMaterialSource() {_exposeToLua}
		return GetNewsEvent()
	End Method


	'override
	Method SourceHasBroadcastFlag:int(flag:Int) {_exposeToLua}
		return GetNewsEvent().HasBroadcastFlag(flag)
	End Method


	Method GetHappenedTime:Long()
		If happenedTime = - 1 Then happenedTime = GetNewsEvent().happenedTime
		return happenedTime
	End Method


	'override default to inform contained "newsEvent" too
	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.BeginBroadcasting(day, hour, minute, audienceData)

		'inform newsEvent that it gets broadcasted by a player
		GetNewsEvent().doBeginBroadcast(owner)
	End Method


	'override
	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.FinishBroadcasting(day, hour, minute, audienceData)

		local ne:TNewsEvent = GetNewsEvent()

		'inform newsEvent that it gets broadcasted by a player
		ne.doFinishBroadcast(owner)

		'adjust topicality relative to possible audience
		Local audienceResult:TAudienceResult = TAudienceResult(audienceData)
		ne.CutTopicality( GetTopicalityCutModifier(audienceResult.GetWholeMarketAudienceQuotePercentage() ) )

		ne.SetTimesBroadcasted( ne.GetTimesBroadcasted(owner) + 1, owner )
	End Method


	Method SetSequenceCalculationPredecessorShare(seqCal:SSequenceCalculation var, audienceFlow:Int)
		seqCal.PredecessorShareOnShrink = New SAudience(0.4, 0.4) '0.5
		seqCal.PredecessorShareOnRise = New SAudience(0.4, 0.4) '0.5
	End Method

rem
	'returns the audienceAttraction for one (single!) news
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		'each potential news audience is calculated
		'as if this news is the only one in the show
		'at the end someone (the engine) has to weight the
		'audience (eg. slot1=50%, slot2=30%, slot3=20%)

		Local genreDefintion:TNewsGenreDefinition = GetNewsGenreDefinitionCollection().Get(GetGenre())
		Return genreDefintion.CalculateAudienceAttraction(self, GetWorldTime().GetHour())
	End Method
endrem


	Method GetQuality:Float() {_exposeToLua}
		local ne:TNewsEvent = GetNewsEvent()
		Local quality:Float = ne.GetQuality()
		'extra bonus for first broadcast
		If ne.GetTimesBroadcasted() = 0 Then quality :* 1.10
		Return MathHelper.Clamp(quality, 0.01, 0.99)
	End Method


	'returns the price of this news
	'price differs from the (base) price of the newsEvent
	Method GetPrice:int(owner:int) {_exposeToLua}
		'Ronny 15.08.2016: deactivated, news are now displaying the
		'                  current price (for easier comparison)
		'the price is fixed in the moment of getting bought
		'if paid and paidPrice<>0 then return paidPrice

		'calculate the price including modifications
		local price:int = GetNewsEvent().GetPrice()
		'add modificators
		price :+ priceModRelativeNewsAgency * price
		price :+ priceModAbsoluteNewsAgency

		price :* GetPlayerDifficulty(owner).newsItemPriceMod

		'adjust by broadcast area
		'multiply by amount of "5 million" people blocks
		local map:TStationMap = GetStationMap(owner)
		if map then price :* int(ceil(map.GetReceivers() / 5000000.0))

		price = TFunctions.RoundToBeautifulValue(price)

		return price
	End Method


	Method IsPaid:int() {_exposeToLua}
		return paid
	End Method


    Method Pay:int()
		'only pay if not already done
		if not paid then paid = GetPlayerFinance(owner).PayNews(GetPrice(owner), self)
		'store the paid price as the price "sinks" during aging
		if paid and paidPrice = 0 then paidPrice = GetPrice(owner)
		return paid
    End Method


	'override default getter to make event id the reference id
	Method GetReferenceID:int() {_exposeToLua}
		return newsEventID
	End Method


	'override default
	Method GetTitle:string() {_exposeToLua}
		Local event:TNewsEvent=GetNullableNewsEvent()
		If event
			return event.GetTitle()
		Else
			return "unknown news"
		EndIf
	End Method


	'override default
    Method GetDescription:string() {_exposeToLua}
		return GetNewsEvent().GetDescription()
    End Method


    Method GetPublishTime:Long() {_exposeToLua}
		return GetHappenedTime() + publishdelay
    End Method


	Method IsReadyToPublish:Int(subscriptionDelay:Long = 0)
		Return (GetPublishTime() + subscriptionDelay <= GetWorldTime().GetTimeGone())
	End Method


	Method GetGenre:int() {_exposeToLua}
		return GetNewsEvent().GetGenre()
	End Method


	Method GetGenreString:string() {_exposeToLua}
		return TNewsEvent.GetGenreString(GetNewsEvent().GetGenre())
	End Method

	Method GetNullableNewsEvent:TNewsEvent() {_exposeToLua}
		if newsEventID = 0 and newsEvent then return newsEvent
		return  GetNewsEventCollection().GetByID(newsEventID)
	End Method

	Method GetNewsEvent:TNewsEvent() {_exposeToLua}
		if newsEventID = 0 and newsEvent then return newsEvent
		Local result:TNewsEvent = GetNullableNewsEvent()
		if not result
			for local ik:TIntKey = EachIn GetNewsEventCollection().allNewsEvents.Keys()
				print "known: " + ik.value + "   " + GetNewsEventCollection().GetByID(ik.value).GetTitle()
			Next
			Throw "Unknown Event id "+ newsEventID
		endif
		return result
	End Method


	'override
	Method GetGenreDefinition:TGenreDefinitionBase()
		Return GetNewsEvent().GetGenreDefinition()
	End Method


	'add individual targetgroup attractivity
	Method GetTargetGroupAttractivityMod:SAudience() override
		Local result:SAudience = Super.GetTargetGroupAttractivityMod()

		'modify with a complete fine grained target group setup
		result.Multiply( GetNewsEvent().GetTargetGroupAttractivityMod() )

		Return result
	End Method


	'override
	'add game modifier support
	Method GetGenreMod:Float()
		local valueMod:Float = Super.GetGenreMod()

		valueMod :* GameConfig.GetModifier("Attractivity.NewsGenre."+GetGenre())
		valueMod :* GameConfig.GetModifier("Attractivity.NewsGenre.player"+GetOwner()+"."+GetGenre())

		return valueMod
	End Method



	'=== SORT FUNCTIONS ===
	Method CompareByName:int(other:object)
		Local n2:TNews = TNews(other)
		If Not n2 Then Return 1
		
		'case insensitive comparison
		Local t1:String = GetTitle().ToLower()
		Local t2:String = n2.GetTitle().ToLower()

		If t1 > t2
			Return 1
		Elseif t1 < t2
			Return -1
		Else
			Local pt1:Long = GetPublishTime()
			Local pt2:Long = n2.GetPublishTime()
			If pt1 > pt2
				Return 1
			ElseIf pt1 < pt2
				Return -1
			Else
				Return 0
			EndIf
		EndIf
	End Method


	Method CompareByPrice:int(other:object)
		Local n2:TNews = TNews(other)
		If Not n2 Then Return 1
		
		Local p1:Int = GetPrice(owner)
		Local p2:Int = n2.GetPrice(owner)
		
		If p1 > p2
			Return 1
		ElseIf p1 < p2
			Return -1
		Else
			Return CompareByPublishedDate(other)
		EndIf
	End Method


	Method CompareByPublishedDate:int(other:object)
		Local n2:TNews = TNews(other)
		If Not n2 Then Return 1

		'avoid simply returning "long - long" as the result can be
		'bigger than an "int" and so roll-overs will happen
        'Return GetPublishTime() - n2.GetPublishTime()
	
		Local pt1:Long = GetPublishTime()
		Local pt2:Long = n2.GetPublishTime()

		If pt1 > pt2
			Return 1
		ElseIf pt1 < pt2
			Return -1
		Else
			If GetTitle().ToLower() > n2.GetTitle().ToLower()
				Return 1
			ElseIf GetTitle().ToLower() < n2.GetTitle().ToLower()
				Return -1
			Else
				Return 0
			EndIf
		EndIf
	End Method


	Method CompareByIsPaid:int(other:object)
		Local n2:TNews = TNews(other)
		If Not n2 Then Return 1

		Local p1:Int = IsPaid()
		Local p2:Int = n2.IsPaid()
		
		If p1 > p2
			Return 1
		ElseIf p1 < p2
			Return -1
		Else
			Return CompareByPublishedDate(other)
		EndIf
	End Method


	Method CompareByTopicality:int(other:object)
		Local n2:TNews = TNews(other)
		If Not n2 Then Return 1

		Local t1:Float = GetNewsEvent().GetTopicality()
		Local t2:Float = n2.GetNewsEvent().GetTopicality()
		
		If t1 > t2
			Return 1
		ElseIf t1 < t2
			Return -1
		Else
			Return CompareByPublishedDate(other)
		EndIf
	End Method


	Function SortByName:Int(o1:Object, o2:Object)
		if not TNews(o1) Then Return -1
		return TNews(o1).CompareByName(o2)
	End Function


	Function SortByPrice:Int(o1:Object, o2:Object)
		if not TNews(o1) Then Return -1
		Return TNews(o1).CompareByPrice(o2)
	End Function


	Function SortByPublishedDate:Int(o1:Object, o2:Object)
		if not TNews(o1) Then Return -1
		Return TNews(o1).CompareByPublishedDate(o2)
	End Function


	Function SortByIsPaid:Int(o1:Object, o2:Object)
		if not TNews(o1) Then Return -1
		Return TNews(o1).CompareByIsPaid(o2)
	End Function


	Function SortByTopicality:Int(o1:Object, o2:Object)
		if not TNews(o1) Then Return -1
		Return TNews(o1).CompareByTopicality(o2)
	End Function


	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		return GetNewsEvent().GetAttractiveness()
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type
