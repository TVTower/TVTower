REM
	===========================================================
	code for news-objects in programme planning
	===========================================================
ENDREM

REM
	as globals are not recognized by reflection, we need to
	take care of globals/consts using an singleton manager instead
	of a "global list" containing the children
ENDREM
Type TNewsEventCollection
	Field usedList:TList		= CreateList()		'holding already announced news
	Field List:TList			= CreateList()		'holding single news and first/parent of news-chains (start)


	Method Add:int(obj:TNewsEvent)
		List.AddLast(obj)
		return TRUE
	End Method


	Method Remove:int(obj:TNewsEvent)
		List.Remove(obj)
		return TRUE
	End Method


	Method Get:TNewsEvent(id:Int)
		Local news:TNewsEvent = Null
		For Local i:Int = 0 To List.Count()-1
			news = TNewsEvent(List.ValueAtIndex(i))
			If news and news.id = id
				news.doHappen()
				Return news
			endif
		Next
		Return Null
	End Method


	Method SetOldNewsUnused(daysAgo:int=1)
		For local news:TNewsEvent = eachin usedList
			if abs(Game.GetDay(news.happenedTime) - Game.GetDay()) >= daysAgo
				usedList.Remove(news)
				list.addLast(news)
				news.happenedTime = -1
			endif
		Next
	End Method


	Method GetRandom:TNewsEvent()
		'if no news is available, make older ones available again
		if List.Count() = 0 then SetOldNewsUnused(7)
		'if there is still nothing - also accept younger ones
		if List.Count() = 0 then SetOldNewsUnused(2)

		if List.Count() = 0 then print "NO ELEMENTS IN NEWSEVENT LIST!!"

		'fetch a random news
		Local news:TNewsEvent = TNewsEvent(List.ValueAtIndex((randRange(0, List.Count() - 1))))

		news.doHappen()

		'Print "get random news: "+news.title + " ("+news.episode+"/"+news.getEpisodesCount()+")"
		Return news
	End Method


	Method setNewsHappened(news:TNewsEvent, time:int = 0)
		'nothing set - use "now"
		if time = 0 then time = Game.timegone
		news.happenedtime = time

		if not news.parent
			self.usedList.addLast(news)
			self.list.remove(news)
		endif
	End Method
End Type
Global NewsEventCollection:TNewsEventCollection = new TNewsEventCollection



Type TNewsEvent extends TGameObject {_exposeToLua="selected"}
	Field title:string			= ""
	Field description:string	= ""
	Field genre:Int				= 0
	Field quality:Int			= 0					'TODO: Quality wird nirgends definiert... keine Werte in der DB.
	Field price:Int				= 0					'TODO: Es muss definiert werden welchen Rahmen price hat. In der DB sind fast alle Werte 0. Der Höchstwert ist 99.
	Field episode:Int			= 0
	Field episodes:TList		= CreateList()
	Field happenedTime:Double	= -1
	Field happenDelayData:int[]	= [5,0,0,0]			'different params for delay generation
	Field happenDelayType:int	= 2					'what kind of delay do we have? 2 = hours
	Field parent:TNewsEvent		= Null				'is this news a child of a chain?

	Const GENRE_POLITICS:Int	= 0	{_exposeToLua}
	Const GENRE_SHOWBIZ:Int		= 1	{_exposeToLua}
	Const GENRE_SPORT:Int		= 2	{_exposeToLua}
	Const GENRE_TECHNICS:Int	= 3	{_exposeToLua}
	Const GENRE_CURRENTS:Int	= 4	{_exposeToLua}


	Function Create:TNewsEvent(title:String, description:String, Genre:Int, quality:Int=0, price:Int=0)
		Local obj:TNewsEvent =New TNewsEvent
		obj.title       = title
		obj.description = description
		obj.genre       = Genre
		obj.episode     = 0
		obj.quality     = quality
		obj.price       = price

		NewsEventCollection.Add(obj)
		Return obj
	End Function


	Method AddEpisode:TNewsEvent(title:String, description:String, Genre:Int, episode:Int=0,quality:Int=0, price:Int=0, id:Int=0)
		Local obj:TNewsEvent =New TNewsEvent
		obj.title       = title
		obj.description = description
		obj.Genre       = Genre
		obj.quality     = quality
		obj.price       = price

	    obj.episode     = episode
		obj.parent		= Self

		obj.happenDelayType		= 2 'data is hours
		obj.happenDelayData[0]	= 5 '5hrs default
		'add to parent
		Self.episodes.AddLast(obj)
		SortList(Self.episodes)

		Return obj
	End Method


	'returns the next news out of a chain
	Method GetNextNewsEventFromChain:TNewsEvent()
		Local news:TNewsEvent=Null
		'if element is an episode of a chain
		If self.parent
			news = TNewsEvent(self.parent.episodes.ValueAtIndex(Max(0,self.episode -1)))
		'if it is the parent of a chain
		elseif self.episodes.count() > 0
			news = TNewsEvent(self.episodes.ValueAtIndex(0))
		endif
		if news
			news.doHappen()
			Return news
		endif
		'if something strange happens - better return self than nothing
		return self
	End Method


	Function GetGenreString:String(Genre:Int)
		If Genre = 0 Then Return GetLocale("NEWS_POLITICS_ECONOMY")
		If Genre = 1 Then Return GetLocale("NEWS_SHOWBIZ")
		If Genre = 2 Then Return GetLocale("NEWS_SPORT")
		If Genre = 3 Then Return GetLocale("NEWS_TECHNICS_MEDIA")
		If Genre = 4 Then Return GetLocale("NEWS_CURRENTAFFAIRS")
		Return Genre+ " unbekannt"
	End Function


	Method getHappenDelay:int()
		'data is days from now
		if self.happenDelayType = 1 then return self.happenDelayData[0]*60*24
		'data is hours from now
		if self.happenDelayType = 2 then return self.happenDelayData[0]*60
		'data is days from now at X:00
		if self.happenDelayType = 3
			local time:int = Game.MakeTime(Game.GetYear(), Game.GetDayOfYear() + self.happenDelayData[0], self.happenDelayData[1],0)
			return time - Game.getTimeGone()
		endif

		return 0
	End Method


	Method doHappen(time:int = 0)
		NewsEventCollection.setNewsHappened(self, time)
	End Method


	Method getEpisodesCount:int()
		if self.parent then return self.parent.episodes.Count()
		return self.episodes.Count()
	End Method


	Method isLastEpisode:int()
		return self.parent<>null and self.episode = self.parent.episodes.count()
	End Method


	Method ComputeTopicality:Float()
		'the older the less ppl want to watch - 1hr = 0.95%, 2hr = 0.90%...
		'means: after 20 hrs, the topicality is 0
		local ageHours:int = floor( float(Game.GetTimeGone() - self.happenedTime)/60.0 )
		Local age:float = Max(0,100-5*Max(0, ageHours) )
		return age*2.55 ',max is 255
	End Method


	Method GetAttractiveness:Float() {_exposeToLua}
		Return 0.30*((quality+5)/255) + 0.4*ComputeTopicality()/255 + 0.2*price/255 + 0.1
	End Method


	Method GetQuality:Float(luckFactor:Int = 1) {_exposeToLua}
		Local qualityTemp:Float = 0.0

		qualityTemp = Float(ComputeTopicality()) / 255.0 * 0.45 ..
			+ Float(quality) / 255.0 * 0.35 ..
			+ Float(price) / 255.0 * 0.2

		If luckFactor = 1 Then
			qualityTemp = qualityTemp * 0.97 + (Float(RandRange(10, 30)) / 1000.0) '1%-Punkte bis 3%-Punkte Basis-Qualität
		Else
			qualityTemp = qualityTemp * 0.99 + 0.01 'Mindestens 1% Qualität
		EndIf

		'no minus quote
		Return Max(0, qualityTemp)
	End Method


	Method ComputeBasePrice:Int() {_exposeToLua}
		'price ranges from 0-10.000
		Return 100 * ceil( 100 * float(0.6*quality + 0.3*price + 0.1*self.ComputeTopicality())/255.0 )
		'Return Floor(Float(quality * price / 100 * 2 / 5)) * 100 + 1000  'Teuerstes in etwa 10000+1000
	End Method
End Type




Type TNewsShow extends TBroadcastMaterial {_exposeToLua="selected"}
	Field news:TBroadcastMaterial[3]
	Field title:string = ""

	Function Create:TNewsShow(title:String="", owner:int=0, newsA:TBroadcastMaterial, newsB:TBroadcastMaterial, newsC:TBroadcastMaterial)
		Local obj:TNewsShow = New TNewsShow
		obj.news[0] = newsA
		obj.news[1] = newsB
		obj.news[2] = newsC
		obj.owner = owner 'cannot use newsA.owner as newsA may be empty...
		obj.title = title

		Return obj
	End Function


	'returns the audienceAttraction for a newsShow (3 news)
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction )
		Local resultAudienceAttr:TAudienceAttraction = New TAudienceAttraction
		resultAudienceAttr.BroadcastType = 2
		resultAudienceAttr.Genre = -1
		resultAudienceAttr.GenrePopularityMod = 0
		resultAudienceAttr.GenreTargetGroupMod = New TAudience
		resultAudienceAttr.PublicImageMod = New TAudience
		resultAudienceAttr.TrailerMod = New TAudience
		resultAudienceAttr.FlagsMod = New TAudience
		resultAudienceAttr.AudienceFlowBonus = New TAudience
		resultAudienceAttr.SequenceEffect = New TAudience
		resultAudienceAttr.BaseAttraction = New TAudience
		resultAudienceAttr.BlockAttraction = New TAudience
		resultAudienceAttr.FinalAttraction = New TAudience
		resultAudienceAttr.PublicImageAttraction = New TAudience

		Local tempAudienceAttr:TAudienceAttraction = null
		for local i:int = 0 to 2
			'RONNY @Manuel: Todo - "Filme" usw. vorbereiten/einplanen
			'               es koennte ja jemand "Trailer" in die News
			'               verpacken - siehe RTL2 und Co.
			tempAudienceAttr = CalculateNewsBlockAudienceAttraction(TNews(news[i]), lastMovieBlockAttraction )

			'different weight for news slots
			If i = 0 Then resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(0.5))
			If i = 1 Then resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(0.3))
			If i = 2 Then resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(0.2))
		Next
		Return resultAudienceAttr
	End Method

	Method CalculateNewsBlockAudienceAttraction:TAudienceAttraction(news:TNews, lastMovieBlockAttraction:TAudienceAttraction)
		Local result:TAudienceAttraction = New TAudienceAttraction
		Local genreDefintion:TNewsGenreDefinition = null

		'Local result:TAudienceAttraction = Null

		'Local rawQuality:Float = news.GetQuality()
		'Local quality:Float = Max(0, Min(99, rawQuality))

		'result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		'result.Quality = rawQuality

		'Return result

		'1 - Qualität des Programms
		If news Then
			genreDefintion = Game.BroadcastManager.GetNewsGenreDefinition(news.GetGenre())
			result.Quality = news.GetQuality()
		Endif
		result.Quality = Max(0.01, Min(0.99, result.Quality))

		If genreDefintion Then
			'2 - Mod: Trend
			result.GenrePopularityMod = (genreDefintion.Popularity.Popularity / 100) 'Popularity => Wert zwischen -50 und +50

			'3 - Genre <> Zielgruppe
			result.GenreTargetGroupMod = genreDefintion.AudienceAttraction.Copy()
			result.GenreTargetGroupMod.SubtractFloat(0.5)
		Else
			result.GenrePopularityMod = 0
			result.GenreTargetGroupMod = TAudience.CreateAndInitValue(0)
		Endif

		'4 - Image
		result.PublicImageMod = Game.getPlayer(owner).PublicImage.GetAttractionMods()
		result.PublicImageMod.SubtractFloat(1)

		'5 - Trailer
		result.TrailerMod = null

		'6 - Flags
		result.FlagsMod = null

		result.CalculateBaseAttraction()

		'7 - Audience Flow
		rem
		If lastMovieBlockAttraction <> Null Then
			result.AudienceFlowBonus = lastMovieBlockAttraction.Copy()
			Local audienceFlowFactor:Float = 0.1 + (result.Quality / 3)
			result.AudienceFlowBonus.MultiplyFloat(audienceFlowFactor)
		End If
		endrem

		'result.CalculateBroadcastAttraction()

		'8 - Stetige Auswirkungen der Film-Quali. Gute Filme bekommen mehr Attraktivität, schlechte Filme animieren eher zum Umschalten
		result.QualityOverTimeEffectMod = 0

		'9 - Genres <> Sendezeit
		result.GenreTimeMod = 0 'TODO

		'10 - News-Mod
		'result.NewsShowMod = lastNewsBlockAttraction

		result.CalculateBlockAttraction()

		'If (Game.playerID = 1) Then DebugStop

		'Sequence
		'If genreDefintion Then
			'result.SequenceEffect = TGenreDefinitionBase.GetSequence(lastMovieBlockAttraction, result, 0.25, 0.35)
		'Else

		'Endif
		if result.SequenceEffect
			Print "Seq: " + result.SequenceEffect.ToString()
		else
			Print "Seq: -- none --"
		endif

		result.CalculateFinalAttraction()

		result.CalculatePublicImageAttraction()

		Return result
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
		local count:int = 0
		for local i:int = 0 to 2
			if TNews(news[i]) then quality:+TNews(news[i]).GetQuality();count:+1
		Next
		if count > 0 then quality :/ count

		'no minus quote
		Return Max(0, quality)
	End Method
End Type




'This object stores a players news.
Type TNews extends TBroadcastMaterial {_exposeToLua="selected"}
    Field newsEvent:TNewsEvent	= Null	{_exposeToLua}
    'delay the news for a certain time (depending on the abonnement-level)
    Field publishDelay:Int 		= 0
    'modificators to this news (stored here: is individual for each player)
    'absolute: value just gets added
    'relative: fraction of base price (eg. 0.3 -> 30%)
	Field priceModRelativeNewsAgency:float = 0.0
	Field priceModAbsoluteNewsAgency:int = 0

    Field paidPrice:int			= 0					'the price which was paid for the news
    Field paid:int	 			= 0
	Field timesAired:int		= 0					'how many times that programme was run




	Function Create:TNews(text:String="unknown", publishdelay:Int=0, useNewsEvent:TNewsEvent=Null)
		If not useNewsEvent
			useNewsEvent = NewsEventCollection.GetRandom()
		endif

		'if no happened time is set, use the Game time
		if useNewsEvent.happenedtime <= 0 then useNewsEvent.happenedtime = Game.GetTimeGone()

		Local obj:TNews = New TNews
		obj.publishDelay = publishdelay
		obj.newsEvent = useNewsEvent

		Return obj
	End Function


	'call this to add it to the players collection (and send it to network etc)
	Method AddToPlayer:int(playerID:int)
		self.owner = playerID
		'add to players collection (sends out event which gets
		'recognized by the network handler)
		Game.GetPlayer(owner).ProgrammeCollection.AddNews(self)
	End Method


	'returns the audienceAttraction for one (single!) news
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction )
		'each potential news audience is calculated
		'as if this news is the only one in the show
		'at the end someone (the engine) has to weight the
		'audience (eg. slot1=50%, slot2=30%, slot3=20%)

		Local genreDefintion:TNewsGenreDefinition = Game.BroadcastManager.GetNewsGenreDefinition(GetGenre())
		Return genreDefintion.CalculateAudienceAttraction(self, Game.GetHour())
	End Method


	Method GetQuality:Float() {_exposeToLua}
		local quality:float = newsEvent.GetQuality()
		'Zusaetzlicher Bonus bei Erstausstrahlung
		If timesAired = 0 Then quality:*1.15
		return quality
	End Method


	'returns the price of this news
	'price differs from the (base) price of the newsEvent
	Method GetPrice:int() {_exposeToLua}
		'the price is fixed in the moment of getting bought
		if paid and paidPrice<>0 then return paidPrice

		'calculate the price including modifications
		local price:int = newsEvent.ComputeBasePrice()
		'add modificators
		price :+ priceModRelativeNewsAgency * price
		price :+ priceModAbsoluteNewsAgency
		return price
	End Method


    Method Pay:int()
		'only pay if not already done
		if not paid then paid = Game.GetPlayer(owner).GetFinance().PayNews(GetPrice(), self)
		'store the paid price as the price "sinks" during aging
		if paid then paidPrice = GetPrice()
		return paid
    End Method


	'override default getter to make event id the reference id
	Method GetReferenceID:int() {_exposeToLua}
		return newsEvent.id
	End Method


	'override default
    Method GetTitle:string() {_exposeToLua}
		return newsEvent.title
    End Method


	'override default
    Method GetDescription:string() {_exposeToLua}
		return newsEvent.description
    End Method


    Method GetPublishTime:int() {_exposeToLua}
		return newsEvent.happenedtime + publishdelay
    End Method


	Method IsReadyToPublish:Int() {_exposeToLua}
		Return (newsEvent.happenedtime + publishDelay <= Game.GetTimeGone())
	End Method


	Method GetGenre:int() {_exposeToLua}
		return newsEvent.genre
	End Method


	Method GetGenreString:string() {_exposeToLua}
		return TNewsEvent.GetGenreString(newsEvent.genre)
	End Method


	Method IsInProgramme:Int() {_exposeToLua}
		Return Game.getPlayer(owner).ProgrammePlan.HasNews(self)
	End Method


	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		return newsEvent.GetAttractiveness()
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type




'a graphical representation of programmes/news/ads...
Type TGUINews extends TGUIGameListItem
	Field news:TNews = Null
	Field imageBaseName:string = "gfx_news_sheet"
	Field cacheTextOverlay:TImage

    Method Create:TGUINews(label:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		Super.Create(label,x,y,width,height)

		return self
	End Method

	Method SetNews:int(news:TNews)
		self.news = news
		if news
			'now we can calculate the item width
			self.Resize( Assets.GetSprite(Self.imageBaseName+news.newsEvent.genre).area.GetW(), Assets.GetSprite(Self.imageBaseName+news.newsEvent.genre).area.GetH() )
		endif
		'self.SetLimitToState("Newsplanner")

		'as the news inflicts the sorting algorithm - resort
		GUIManager.sortLists()
	End Method


	Method Compare:int(Other:Object)
		local otherBlock:TGUINews = TGUINews(Other)
		If otherBlock<>null
			'both items are dragged - check time
			if self._flags & GUI_OBJECT_DRAGGED AND otherBlock._flags & GUI_OBJECT_DRAGGED
				'if a drag was earlier -> move to top
				if self._timeDragged < otherBlock._timeDragged then Return 1
				if self._timeDragged > otherBlock._timeDragged then Return -1
				return 0
			endif

			if self.news and otherBlock.news
				local publishDifference:int = self.news.GetPublishTime() - otherBlock.news.GetPublishTime()

				'self is newer ("later") than other
				if publishDifference>0 then return -1
				'self is older than other
				if publishDifference<0 then return 1
				'self is same age than other
				if publishDifference=0 then return Super.Compare(Other)
			endif
		endif

		return Super.Compare(Other)
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		'set mouse to "hover"
		if news.owner = Game.playerID or news.owner <= 0 and mouseover then Game.cursorstate = 1
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2
	End Method


	Method DrawTextOverlay()
		local screenX:float = int(GetScreenX())
		local screenY:float = int(GetScreenY())

		'===== CREATE CACHE IF MISSING =====
		if not cacheTextOverlay
			cacheTextOverlay = TFunctions.CreateEmptyImage(rect.GetW(), rect.GetH())
'			cacheTextOverlay = CreateImage(rect.GetW(), rect.GetH(), DYNAMICIMAGE | FILTEREDIMAGE)

			'render to image
			TGW_BitmapFont.SetRenderTarget(cacheTextOverlay)

			'default texts (title, text,...)
			Assets.fonts.basefontBold.drawBlock(news.GetTitle(), 15, 4, 290, 15 + 8, null, TColor.CreateGrey(20))
			Assets.fonts.baseFont.drawBlock(news.GetDescription(), 15, 19, 300, 50 + 8, null, TColor.CreateGrey(100))

			local oldAlpha:float = GetAlpha()
			SetAlpha 0.3*oldAlpha
			Assets.GetFont("Default", 9).drawBlock(news.GetGenreString(), 15, 74, 120, 15, null, TColor.clBlack)
			SetAlpha 1.0*oldAlpha

			'set back to screen Rendering
			TGW_BitmapFont.SetRenderTarget(null)
		endif

		'===== DRAW CACHE =====
		DrawImage(cacheTextOverlay, screenX, screenY)
	End Method


	Method Draw()
		State = 0
		SetColor 255,255,255

		if self.RestrictViewPort()
			local screenX:float = int(GetScreenX())
			local screenY:float = int(GetScreenY())

			local oldAlpha:float = GetAlpha()
			local itemAlpha:float = 1.0
			'fade out dragged
			if isDragged() then itemAlpha = 0.25 + 0.5^GuiManager.GetDraggedNumber(self)

			SetAlpha oldAlpha*itemAlpha
			'background - no "_dragged" to add to name
			Assets.GetSprite(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)

			'highlight hovered news (except already dragged)
			if not isDragged() and self = RoomHandler_News.hoveredGuiNews
				local oldAlpha:float = GetAlpha()
				SetBlend LightBlend
				SetAlpha 0.30*oldAlpha
				SetColor 150,150,150
				Assets.GetSprite(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)
				SetAlpha oldAlpha
				SetBlend AlphaBlend
			endif

			'===== DRAW CACHED TEXTS =====
			'creates cache if needed
			DrawTextOverlay()

			'===== DRAW NON-CACHED TEXTS =====
			if not news.paid
				Assets.GetFont("Default", 12, BOLDFONT).drawBlock(news.GetPrice() + ",-", screenX + 219, screenY + 72, 90, -1, TPoint.Create(ALIGN_RIGHT), TColor.clBlack)
			else
				Assets.GetFont("Default", 12).drawBlock(news.GetPrice() + ",-", screenX + 219, screenY + 72, 90, -1, TPoint.Create(ALIGN_RIGHT), TColor.CreateGrey(50))
			endif

			Select Game.getDay() - Game.GetDay(news.newsEvent.happenedTime)
				case 0	Assets.fonts.baseFont.drawBlock(GetLocale("TODAY")+" " + Game.GetFormattedTime(news.newsEvent.happenedtime), screenX + 90, screenY + 74, 140, 15, TPoint.Create(ALIGN_RIGHT), TColor.clBlack )
				case 1	Assets.fonts.baseFont.drawBlock("("+GetLocale("OLD")+") "+GetLocale("YESTERDAY")+" "+ Game.GetFormattedTime(news.newsEvent.happenedtime), screenX + 90, screenY + 74, 140, 15, TPoint.Create(ALIGN_RIGHT), TColor.clBlack)
				case 2	Assets.fonts.baseFont.drawBlock("("+GetLocale("OLD")+") "+GetLocale("TWO_DAYS_AGO")+" " + Game.GetFormattedTime(news.newsEvent.happenedtime), screenX + 90, screenY + 74, 140, 15, TPoint.Create(ALIGN_RIGHT), TColor.clBlack)
			End Select

			SetColor 255, 255, 255
			SetAlpha oldAlpha
			rem
			if Game.GetPlayer(news.owner).ProgrammePlan.hasNews(news)
				Assets.GetFont("Default", 24).Draw("NEWS GEPLANT", screenX + 20, screenY + 20, TColor.Create(0,0,0,1))
			endif
			if Game.GetPlayer(news.owner).ProgrammeCollection.hasNews(news)
				Assets.GetFont("Default", 24).Draw("NEWS VERFUEGBAR", screenX + 20, screenY + 30, TColor.Create(0,0,0,1))
			endif
			if not Game.GetPlayer(news.owner).ProgrammeCollection.hasNews(news) and not Game.GetPlayer(news.owner).ProgrammePlan.hasNews(news)
				Assets.GetFont("Default", 24).Draw("IN KEINER LISTE", screenX + 20, screenY + 25, TColor.Create(0,0,0,1))
			endif
			endrem
			self.resetViewport()
		endif
	End Method
End Type




Type TGUINewsList extends TGUIListBase

    Method Create:TGUINewsList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)
		return self
	End Method

	Method ContainsNews:int(news:TNews)
		for local guiNews:TGUINews = eachin entries
			if guiNews.news = news then return TRUE
		Next
		return FALSE
	End Method
End Type




Type TGUINewsSlotList extends TGUISlotList

    Method Create:TGUINewsSlotList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)
		return self
	End Method

	Method ContainsNews:int(news:TNews)
		for local i:int = 0 to self.GetSlotAmount()-1
			local guiNews:TGUINews = TGUINews( self.GetItemBySlot(i) )
			if guiNews and guiNews.news = news then return TRUE
		Next
		return FALSE
	End Method
End Type
