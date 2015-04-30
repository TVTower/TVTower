Rem
	====================================================================
	ProgrammeLicence data - basics of broadcastable programme
	====================================================================
EndRem
SuperStrict
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.gameobject.bmx"
Import "game.broadcastmaterial.base.bmx"
Import "game.programme.programmedata.bmx"
Import "game.player.base.bmx"
Import "game.player.finance.bmx"
Import "game.broadcast.audience.bmx"
Import "game.broadcast.broadcaststatistic.bmx"
Import "basefunctions.bmx" 'CreateEmptyImage()


Type TProgrammeLicenceCollection
	'holding all programme licences
	Field licences:TList = CreateList()
	'holding only licences of special packages containing multiple
	'movies/series
	Field collections:TList	= CreateList()
	'holding only single licences (movies, one-time-events)
	Field singles:TList = CreateList()
	'holding only series licences
	Field series:TList = CreateList()

	Global _instance:TProgrammeLicenceCollection


	Function GetInstance:TProgrammeLicenceCollection()
		if not _instance then _instance = new TProgrammeLicenceCollection
		return _instance
	End Function


	Method Initialize:TProgrammeLicenceCollection()
		licences.Clear()
		collections.Clear()
		singles.Clear()
		series.Clear()
		
		return self
	End Method


	Method PrintLicences:int()
		print "--------- singles: "+singles.Count()
		For local single:TProgrammeLicence = Eachin singles
			print single.GetTitle() + "   [owner: "+single.owner+"]"
		Next
		print "---------"
		print "--------- series: "+series.Count()
		For local serie:TProgrammeLicence = Eachin series
			print serie.GetTitle() + "   [owner: "+serie.owner+"]"
			For local episode:TProgrammeLicence = Eachin serie.subLicences
				print "'-- "+episode.GetTitle() + "   [owner: "+episode.owner+"]"
			Next
		Next
		print "---------"
		print "--------- collections: "+collections.Count()
		For local collection:TProgrammeLicence = Eachin collections
			print collection.GetTitle() + "   [owner: "+collection.owner+"]"
			For local episode:TProgrammeLicence = Eachin collection.subLicences
				print "'-- "+episode.GetTitle() + "   [owner: "+episode.owner+"]"
			Next
		Next
		print "---------"
	End Method


	'add a licence
	Method Add:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and licences.contains(licence) then return False

		licences.AddLast(licence)
		return True
	End Method


	'checks if the licences list contains the given licence
	Method Contains:Int(licence:TProgrammeLicence)
		return licences.contains(licence)
	End Method


	'add a licence as single (movie, one-time-event)
	Method AddSingle:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and singles.contains(licence) then return False

		singles.AddLast(licence)
		return True
	End Method


	'checks if the singles list contains the given licence
	Method ContainsSingle:Int(licence:TProgrammeLicence)
		return singles.contains(licence)
	End Method	


	'add a licence as series
	Method AddSeries:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and series.contains(licence) then return False
		
		series.AddLast(licence)
		return True
	End Method


	'add a licence as series
	Method RemoveSeries:Int(licence:TProgrammeLicence)
		series.Remove(licence)
	End Method


	'checks if the series list contains the given licence
	Method ContainsSeries:Int(licence:TProgrammeLicence)
		return series.contains(licence)
	End Method	


	'add a licence as collection
	Method AddCollection:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and collections.contains(licence) then return False
		
		collections.AddLast(licence)
		return True
	End Method


	'checks if the collection list contains the given licence
	Method ContainsCollection:Int(licence:TProgrammeLicence)
		return collections.contains(licence)
	End Method


	'add a licence to all needed lists
	Method AddAutomatic:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'do not add franchise-licences
		if licence.licenceType = TVTProgrammeLicenceType.FRANCHISE then return False

		'=== ALL ===
		'all licences should be listed in the "all-licences-list"
		'this also includes episodes!
		Add(licence, skipDuplicates)

		'=== SINGLES ===
		if licence.isSingle() then AddSingle(licence, skipDuplicates)

		'=== EPISODES ===
		'episodes do not need special handling ...

		'=== SERIES ===
		if licence.isSeries() then AddSeries(licence, skipDuplicates)

		'=== COLLECTIONS ===
		if licence.isCollection() then AddCollection(licence, skipDuplicates)

		return True
	End Method
	

	'returns the list to use for the given type
	'this is just important for "random" access as we could
	'also just access "progList" in all cases...
	Method _GetList:TList(programmeLicenceType:int=0)
		Select programmeLicenceType
			case TVTProgrammeLicenceType.SINGLE
				return singles
			case TVTProgrammeLicenceType.SERIES
				return series
			case TVTProgrammeLicenceType.COLLECTION
				return collections
			default
				return licences
		End Select
	End Method


	Global warnedEmptyRandomFromList:int = False
	Method GetRandomFromList:TProgrammeLicence(_list:TList)

		If _list = Null Then Return Null
		If _list.count() > 0
			Local Licence:TProgrammeLicence = TProgrammeLicence(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If Licence then return Licence
		EndIf
		if not warnedEmptyRandomFromList
			TLogger.log("TProgrammeLicence.GetRandomFromList()", "list is empty (incorrect filter or not enough available licences?)", LOG_DEBUG | LOG_WARNING | LOG_DEV, TRUE)
			warnedEmptyRandomFromList = true
		endif
		Return Null
	End Method


	Method Get:TProgrammeLicence(id:Int, programmeLicenceType:int=0)
		local list:TList = _GetList(programmeLicenceType)
		local licence:TProgrammeLicence = null

		For Local i:Int = 0 To list.Count() - 1
			Licence = TProgrammeLicence(list.ValueAtIndex(i))
			if Licence and Licence.id = id Then Return Licence
		Next
		Return Null
	End Method


	Method GetByGUID:TProgrammeLicence(GUID:String)
		'TODO: change to tmap if to slow
		For local licence:TProgrammeLicence = EachIn licences
			if licence.GetGUID() = GUID then return licence
		Next
		Return Null
	End Method



	Method GetRandom:TProgrammeLicence(programmeLicenceType:int=0, includeEpisodes:int=FALSE)
		'filter to entries we need
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeLicenceType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.IsOwned() or not Licence.isReleased() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'if available (unbought, released..), add it to candidates list
			resultList.addLast(Licence)
		Next

		Return GetRandomFromList(resultList)
	End Method


	Method GetRandomWithPrice:TProgrammeLicence(MinPrice:int=0, MaxPrice:Int=-1, programmeLicenceType:int=0, includeEpisodes:int=FALSE)
		'filter to entries we need
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeLicenceType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.IsOwned() or not Licence.isReleased() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'skip if to expensive
			if MaxPrice > 0 and Licence.getPrice() > MaxPrice then continue

			'if available (unbought, released..), add it to candidates list
			If Licence.getPrice() >= MinPrice Then resultList.addLast(Licence)
		Next
		Return GetRandomFromList(resultList)
	End Method


	Method GetRandomWithGenre:TProgrammeLicence(genre:Int=0, programmeLicenceType:int=0, includeEpisodes:int=FALSE)
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeLicenceType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.IsOwned() or not Licence.isReleased() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'if available (unbought, released..), add it to candidates list
			If Licence.isSingle() or Licence.isEpisode()
				if Licence.GetData().getGenre() = genre Then resultList.addLast(Licence)
			else
				local foundGenreInSubLicence:int = FALSE
				for local subLicence:TProgrammeLicence = eachin Licence.subLicences
					if foundGenreInSubLicence then continue
					if subLicence.GetData() and subLicence.GetData().getGenre() = genre
						resultList.addLast(Licence)
						foundGenreInSubLicence = TRUE
					endif
				Next
			endif
		Next
		Return GetRandomFromList(resultList)
	End Method


	Method GetRandomByFilter:TProgrammeLicence(filter:TProgrammeLicenceFilter)
		Local Licence:TProgrammeLicence
		Local resultList:TList = CreateList()

		For Licence = EachIn licences
			'ignore already used or unreleased
			If Licence.IsOwned() or not Licence.isReleased() Then continue
			'ignore episodes
			If Licence.isEpisode() Then continue

			if not filter.DoesFilter(licence) then continue

			'add it to candidates list
			resultList.addLast(Licence)
		Next
		Return GetRandomFromList(resultList)
	End Method	
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeLicenceCollection:TProgrammeLicenceCollection()
	Return TProgrammeLicenceCollection.GetInstance()
End Function




'licence of for movies, series and so on
Type TProgrammeLicence Extends TNamedGameObject {_exposeToLua="selected"}
	'wird nur in der Lua-KI verwendet um die Lizenzen zu bewerten
	Field attractiveness:Float = -1
	Field data:TProgrammeData				{_exposeToLua}
	'the latest hour-(from-start) one of the planned programmes ends
	Field latestPlannedEndHour:int = -1
	'is this licence a: collection, series, episode or single element?
	'you cannot distinguish between "series" and "collections" without
	'as both could contain "shows" or "episodes"
	Field licenceType:int = 0
	'series are parent of episodes
	Field parentLicenceGUID:string = ""
	'other licences this licence covers
	Field subLicences:TProgrammeLicence[]
	'store stats for each owner
	Field broadcastStatistics:TBroadcastStatistic[]

'	Field cacheTextOverlay:TImage 			{nosave}
'	Field cacheTextOverlayMode:string = ""	{nosave}	'for which mode the text was cached

	'hide movies of 2012 when in 1985?
	Global ignoreUnreleasedProgrammes:int = TRUE
	Global _filterReleaseDateStart:int = 1900
	Global _filterReleaseDateEnd:int = 2100


	Method GetReferenceID:int() {_exposeToLua}
		'return own licence id as referenceID - programme.id is not
		'possible for collections/series
		return self.ID
	End Method


	'connect programmedata to a licence
	Method SetData:int(data:TProgrammeData)
		self.data = data
	End Method


	Method GetData:TProgrammeData() {_exposeToLua}
		'if not self.data then print "[ERROR] data for TProgrammeLicence with title: ~q"+title+"~q is missing."
		return self.data
	End Method


	Method GetSubLicenceCount:int() {_exposeToLua}
		return subLicences.length
	End Method


	Method GetSubLicenceAtIndex:TProgrammeLicence(arrayIndex:int=1) {_exposeToLua}
		if arrayIndex > subLicences.length or arrayIndex < 0 then return null
		return subLicences[arrayIndex]
	End Method


	Method AddSubLicence:int(licence:TProgrammeLicence)
		'=== ADJUST LICENCE TYPES ===

		'as each licence is individual we easily can set the main licence
		'as parent (so sublicences can ask for sibling licences).
		licence.parentLicenceGUID = self.GetGUID()

		'add to array of sublicences
		subLicences :+ [licence]
		Return TRUE
	End Method


	Method GetBroadcastStatistic:TBroadcastStatistic()
		local useOwner:int = owner
		if owner < 0 then useOwner = 0

		if broadcastStatistics.length <= useOwner then broadcastStatistics = broadcastStatistics[.. useOwner + 1]
		if not broadcastStatistics[useOwner] then broadcastStatistics[useOwner] = new TBroadcastStatistic

		return broadcastStatistics[useOwner]
	End Method


	Method SetBroadcastStatistic:Int(broadcastStatistic:TBroadcastStatistic)
		local useOwner:int = owner
		if owner < 0 then useOwner = 0

		if broadcastStatistics.length <= useOwner then broadcastStatistics = broadcastStatistics[.. useOwner + 1]
		broadcastStatistics[useOwner] = broadcastStatistic
		return True
	End Method


	Method isProgrammeType:int(programmeDataType:int) {_exposeToLua}
		return GetData() and GetData().isType(programmeDataType)
	End Method


	Method isSeries:int() {_exposeToLua}
		return licenceType = TVTProgrammeLicenceType.SERIES
	End Method


	Method isEpisode:int() {_exposeToLua}
		return licenceType = TVTProgrammeLicenceType.EPISODE
	End Method


	Method isSingle:int() {_exposeToLua}
		return licenceType = TVTProgrammeLicenceType.SINGLE
	End Method
	

	Method isCollection:int() {_exposeToLua}
		return licenceType = TVTProgrammeLicenceType.COLLECTION
	End Method
	

	Function setIgnoreUnreleasedProgrammes(ignore:int=TRUE, releaseStart:int=1900, releaseEnd:int=2100)
		ignoreUnreleasedProgrammes = ignore
		_filterReleaseDateStart = releaseStart
		_filterReleaseDateEnd = releaseEnd
	End Function


	'override default method to add sublicences
	Method SetOwner:int(owner:int=0)
		self.owner = owner
		'do the same for all children
		For local licence:TProgrammeLicence = eachin subLicences
			licence.SetOwner(owner)
		Next
		return TRUE
	End Method


	Method Sell:int()
		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(owner,-1)
		if not finance then return False

		finance.SellProgrammeLicence(getPrice(), self)

		'set unused again
		SetOwner( TOwnedGameObject.OWNER_NOBODY )

		return TRUE
	End Method


	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int=-1)
		local finance:TPlayerFinance = GetPlayerFinance(playerID, -1)
		if not finance then return False

		If finance.PayProgrammeLicence(getPrice(), self)
			SetOwner(playerID)
			Return TRUE
		EndIf
		Return FALSE
	End Method


	Method GetParentLicence:TProgrammeLicence() {_exposeToLua}
		if not self.parentLicenceGUID then return self
		return GetProgrammeLicenceCollection().GetByGUID(self.parentLicenceGUID)
	End Method


	Method GetSubLicencePosition:int(licence:TProgrammeLicence) {_exposeToLua}
		'find my position and add 1
		For local i:int = 0 to GetSubLicenceCount() - 1
			if GetSubLicenceAtIndex(i) = licence then return i
		Next
		return 0
	End Method


	'returns the next licence of a licences parent sublicences
	Method GetNextSubLicence:TProgrammeLicence() {_exposeToLua}
		if not parentLicenceGUID then return Null

		'find my position and add 1
		local nextArrayIndex:int = GetParentLicence().GetSubLicencePosition(self) + 1
		'if we are at the last position, return the first one
		if nextArrayIndex >= GetParentLicence().GetSubLicenceCount() then nextArrayIndex = 0

		return GetParentLicence().GetSubLicenceAtIndex(nextArrayIndex)
	End Method


	Method isReleased:int() {_exposeToLua}
		if not self.ignoreUnreleasedProgrammes then return TRUE

		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().isReleased()

		'if licence is a collection: ask subs
		For local licence:TProgrammeLicence = eachin subLicences
			if not licence.isReleased() then return FALSE
		Next

		return TRUE
	End Method


	Method setPlanned:int(latestHour:int=-1)
		if latestHour >= 0
			'set to maximum
			self.latestPlannedEndHour = Max(latestHour, self.latestPlannedEndHour)
		else
			'reset
			self.latestPlannedEndHour = -1
		endif
	End Method


	'instead of asking the programmeplan about each licence
	'we cache that information directly within the programmeplan
	Method isPlanned:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData()
			if (latestPlannedEndHour>=0) then return TRUE
			'if self is not planned - ask if parent is set to planned
			'do not use this for series if used in the programmePlanner-view
			'to "emphasize" planned programmes
			'if self.parentLicence then return self.parentLicence.isPlanned()

			return False
		endif

		For local licence:TProgrammeLicence = eachin subLicences
			if licence.isPlanned() then return TRUE
		Next
		return FALSE
	End Method


	'returns the genre of a licence - if a group, the one used the most
	'often is returned
	Method GetGenre:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetGenre()

		local genres:int[]
		local bestGenre:int=0
		For local licence:TProgrammeLicence = eachin subLicences
			local genre:int = licence.GetGenre()
			if genre > genres.length-1 then genres = genres[..genre+1]
			genres[genre]:+1
		Next
		For local i:int = 0 to genres.length-1
			if genres[i] > bestGenre then bestGenre = i
		Next

		return bestGenre
	End Method


	'returns the flags as a mix of all licences
	'ATTENTION: if ONE has xrated, all are xrated, if one has trash, all ..
	'so this kind of "taints"
	Method GetFlags:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().flags

		local flags:int
		For local licence:TProgrammeLicence = eachin subLicences
			flags :| licence.GetFlags()
		Next
		return flags
	End Method


	Method GetQuality:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetQuality()

		'if licence is a collection: ask subs
		local quality:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			quality :+ licence.GetQuality()
		Next

		if subLicences.length > 0 then return quality / subLicences.length
		return 0.0
	End Method


	Method GetTitle:string() {_exposeToLua}
		if GetData() then return GetData().GetTitle()
		return ""
	End Method


	Method GetDescription:string() {_exposeToLua}
		if GetData() then return GetData().GetDescription()
		return ""
	End Method


	'returns the avg topicality of a licence (package)
	Method GetTopicality:Int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetTopicality()

		'licence for a package or series
		Local value:int
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetTopicality()
		Next

		if subLicences.length > 0 then return floor(value / subLicences.length)
		return 0
	End Method


	Method GetPrice:Int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetPrice()

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetPrice()
		Next
		value :* 0.75

		'round to next "1000" block
		value = Int(Floor(value / 1000) * 1000)


		Return value
	End Method


	Method CutTrailerEfficiency:float()
		'maximum is 100% efficiency (never shown before)
		local efficiency:float = 1.0
		'each air during the last 24 hrs decreases by 5%

	End Method


	Method ShowSheet:Int(x:Int,y:Int, align:int=0, showMode:int=0)
		'set default mode
		if showMode = 0 then showMode = TBroadcastMaterial.TYPE_PROGRAMME

		if KeyManager.IsDown(KEY_LALT) or KeyManager.IsDown(KEY_RALT)
			if showMode = TBroadcastMaterial.TYPE_PROGRAMME
				showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			else
				showMode = TBroadcastMaterial.TYPE_PROGRAMME
			endif
		Endif


		if showMode = TBroadcastMaterial.TYPE_PROGRAMME
			ShowProgrammeSheet(x, y, align)
		'trailermode
		elseif showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			ShowTrailerSheet(x, y, align)
		endif
	End Method


	Method ShowProgrammeSheet:Int(x:Int,y:Int, align:int=0)
		local data:TProgrammeData        = GetData()
		Local fontNormal:TBitmapFont     = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont       = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont   = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

		Local showPlannedWarning:Int = False
		Local showEarnInfo:Int = False
		
		if owner > 0 'and GetPlayer().figure.inRoom
			'only if planned and in archive
			if self.IsPlanned() ' and GetPlayer().figure.inRoom.name = "archive"
				showPlannedWarning = True
			endif
		endif

		If data.HasFlag(TVTProgrammeFlag.PAID) then showEarnInfo = True

'debug
'showPlannedWarning = True
'showEarnInfo = True

		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y
		local currTextWidth:int

		'move sheet to left when right-aligned
		if align = 1 then currX = x - GetSpriteFromRegistry("gfx_datasheet_title").area.GetW()


		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		if isEpisode() or isSeries()
			sprite = GetSpriteFromRegistry("gfx_datasheet_series"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		endif
		sprite = GetSpriteFromRegistry("gfx_datasheet_country"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_splitter"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content2"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subMovieRatings"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()


		If showEarnInfo
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageEarn"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		EndIf

		If showPlannedWarning
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageWarning"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		endif


		sprite = GetSpriteFromRegistry("gfx_datasheet_subMovieAttributes"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textLightColor:TColor = TColor.CreateGrey(75)
		local textEarnColor:TColor = TColor.Create(45,80,10)
		local textWarningColor:TColor = TColor.Create(80,45,10)
		
		if isSeries()
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
			fontNormal.drawBlock(GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetSubLicenceCount()), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 16
		elseif isEpisode()
			'title of "series"
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetParentLicence().GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
			'episode num/max + episode title
			fontNormal.drawBlock((GetParentLicence().GetSubLicencePosition(self)+1) + "/" + GetParentLicence().GetSubLicenceCount() + ": " + data.GetTitle(), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 16
		else ' = if isMovie()
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
		endif

		'country + genre
		'country/year + genre   - for non-callin-shows
		local countryYear:String = data.country
		If not data.HasFlag(TVTProgrammeFlag.PAID)
			countryYear :+ " " + data.year
		endif
		fontNormal.drawBlock(countryYear, currX + 6, currY, 65, 16, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		fontNormal.drawBlock(data.GetGenreString(), currX + 6 + 67, currY, 215, 16, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 16

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(data.GetDescription(), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		'splitter
		currY :+ 6

		local addCastTitle:string  = ""
		local addCast:string = ""
		if data.GetActorsString() <> ""
			addCastTitle = GetLocale("MOVIE_ACTORS")
			addCast = data.GetActorsString()

		elseif data.GetCastGroupString(TVTProgrammePersonJob.SUPPORTINGACTOR) <> ""
			addCastTitle = GetLocale("MOVIE_SUPPORTINGACTORS")
			addCast = data.GetCastGroupString(TVTProgrammePersonJob.SUPPORTINGACTOR)

		elseif data.GetCastGroupString(TVTProgrammePersonJob.REPORTER) <> ""
			addCastTitle = GetLocale("MOVIE_REPORTERS")
			addCast = data.GetCastGroupString(TVTProgrammePersonJob.REPORTER)

		elseif data.GetCastGroupString(TVTProgrammePersonJob.GUEST) <> ""
			addCastTitle = GetLocale("MOVIE_GUESTS")
			addCast = data.GetCastGroupString(TVTProgrammePersonJob.GUEST)

		elseif data.GetCastGroupString(TVTProgrammePersonJob.HOST) <> ""
			addCastTitle = GetLocale("MOVIE_HOST")
			addCast = data.GetCastGroupString(TVTProgrammePersonJob.HOST)

		elseif data.GetCastGroupString(TVTProgrammePersonJob.SCRIPTWRITER) <> ""
			addCastTitle = GetLocale("MOVIE_SCRIPT")
			addCast = data.GetCastGroupString(TVTProgrammePersonJob.SCRIPTWRITER)

		elseif data.GetCastGroupString(TVTProgrammePersonJob.MUSICIAN) <> ""
			addCastTitle = GetLocale("MOVIE_MUSIC")
			addCast = data.GetCastGroupString(TVTProgrammePersonJob.MUSICIAN)
		endif


		'max width of director/actors - to align their content properly
		currTextWidth = Int(fontSemiBold.getWidth(GetLocale("MOVIE_DIRECTOR")+":"))
		if addCastTitle
			currTextWidth = Max(currTextWidth, Int(fontSemiBold.getWidth(addCastTitle+":")))
		endif


		currY :+ 3	'subcontent (actors/director) start with offset
		'director
		if data.GetDirectorsString() <> ""
			fontSemiBold.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", currX + 6, currY, 280, 13, null, textColor)
			fontNormal.drawBlock(data.GetDirectorsString(), currX + 6 + 5 + currTextWidth, currY , 280 - 15 - currTextWidth, 15, null, textColor)
			currY :+ 13
		endif

		'actors or other additional cast members
		if addCast <> ""
			fontSemiBold.drawBlock(addCastTitle+":", currX + 6 , currY, 280, 26, null, textColor)
			fontNormal.drawBlock(addCast, currX + 6 + 5 + currTextWidth, currY, 280 - 15 - currTextWidth, 30, null, textColor)
		endif
		if data.GetDirectorsString() = ""
			currY :+ 13
		endif
		currY :+ 26
		currY :+ 3 'subcontent end with offset
		currY :+ 1 'end of subcontent area

		'===== DRAW RATINGS / BARS =====
		'captions
		currY :+ 4 'offset of ratings
		fontSemiBold.drawBlock(GetLocale("MOVIE_SPEED"),      currX + 215, currY,      75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_CRITIC"),     currX + 215, currY + 16, 75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_BOXOFFICE"),  currX + 215, currY + 32, 75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), currX + 215, currY + 48, 75, 15, null, textLightColor)

		'===== DRAW BARS =====

		If data.GetSpeed() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1, data.GetSpeed()*200  , 10))
		If data.GetReview() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 16, data.GetReview()*200 , 10))
		If data.GetOutcome() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 32, data.GetOutcome()*200, 10))
		If data.GetMaxTopicality() > 0.01
			SetAlpha GetAlpha()*0.25
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1 + 48, data.GetMaxTopicality()*200, 10))
			SetAlpha GetAlpha()*4.0
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1 + 48, data.GetTopicality()*200, 10))
		EndIf
		currY :+ 65

		
		'=== DRAW SPECIAL MESSAGES ===
		If showEarnInfo
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			local revenue:string = TFunctions.DottedValue(int(1000 * data.GetPerViewerRevenue()))+CURRENCYSIGN
			currY :+ 4 'top content padding of that line
			fontSemiBold.drawBlock(getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), currX + 35,  currY, 245, 15, ALIGN_CENTER_CENTER, textEarnColor, 0,1,1.0,True, True)
			currY :+ 15 + 8 'lineheight + bottom content padding
		EndIf

		if showPlannedWarning
			currY :+ 4 'top content padding of that line
			fontSemiBold.drawBlock("Programm im Sendeplan!", currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			currY :+ 15 + 8 'lineheight + bottom content padding
		endif

		currY :+ 4 'align to content portion of that line
		'blocks
		fontBold.drawBlock(data.GetBlocks(), currX + 33, currY, 17, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)

		'repetitions
		fontBold.drawBlock(data.GetTimesAired(owner), currX + 84, currY, 22, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)

		'record
		fontBold.drawBlock(TFunctions.convertValue(GetBroadcastStatistic().GetBestAudienceResult(owner, -1).audience.GetSum(),2), currX + 140, currY, 52, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)

		
		'price
		local finance:TPlayerFinance
		'only check finances if it is no other player (avoids exposing
		'that information to us)
		if owner <= 0 or GetPlayerBaseCollection().playerID = owner
			finance = GetPlayerFinanceCollection().Get(GetPlayerBaseCollection().playerID, -1)
		endif
		local canAfford:int = False
		'possessing player always can
		if GetPlayerBaseCollection().playerID = owner
			canAfford = True
		'if it is another player... just display "can afford"
		elseif owner > 0
			canAfford = True
		'not our licence but enough money to buy
		elseif finance and finance.canAfford(GetPrice())
			canAfford = True
		endif
		
		if canAfford
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 227, currY, 55, 15, ALIGN_RIGHT_CENTER, textColor, 0,1,1.0,True, True)
		else
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 227, currY, 55, 15, ALIGN_RIGHT_CENTER, TColor.Create(200,0,0), 0,1,1.0,True, True)
		endif
		currY :+ 15 + 8 'lineheight + bottom content padding

		'=== X-Rated Overlay ===
		If data.IsXRated()
			GetSpriteFromRegistry("gfx_datasheet_xrated").Draw(currX + GetSpriteFromRegistry("gfx_datasheet_title").GetWidth(), y, -1, ALIGN_RIGHT_TOP)
		Endif


		If TVTDebugInfos
			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0

			local w:int = GetSpriteFromRegistry("gfx_datasheet_title").area.GetW() - 20
			local h:int = Max(120, currY-y)
			DrawRect(currX, y, w,h)
		
			SetColor 255,255,255
			SetAlpha oldAlpha

			local textY:int = y + 5
			fontBold.draw("Programm: "+GetTitle(), currX + 5, textY)
			textY :+ 14	
			fontNormal.draw("Letzte Stunde im Plan: "+latestPlannedEndHour, currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Tempo: "+data.GetSpeed(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Kritik: "+data.GetReview(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Kinokasse: "+data.GetOutcome(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Preismodifikator: "+data.GetModifier("price"), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Qualitaet roh: "+data.GetQualityRaw()+"  (ohne Alter, Wdh.)", currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Qualitaet: "+data.GetQuality(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Aktualitaet: "+data.GetTopicality()+" von " + data.GetMaxTopicality(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Bloecke: "+data.GetBlocks(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Ausgestrahlt: "+data.GetTimesAired(owner)+"x Spieler, "+data.GetTimesAired()+"x alle", currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Quotenrekord: "+Long(GetBroadcastStatistic().GetBestAudienceResult(owner, -1).audience.GetSum())+" (Spieler), "+Long(GetBroadcastStatistic().GetBestAudienceResult(-1, -1).audience.GetSum())+" (alle)", currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Preis: "+GetPrice(), currX + 5, textY)
		Endif
	End Method


	Method ShowTrailerSheet:Int(x:Int,y:Int, align:int=0)
		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y

		'move sheet to left when right-aligned
		if align = 1 then currX = x - GetSpriteFromRegistry("gfx_datasheet_title").area.GetW()
		
		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_series"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTopicalityRating"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textLightColor:TColor = TColor.CreateGrey(75)
		Local fontNormal:TBitmapFont = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, y + 8, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 18
		fontNormal.drawBlock(GetLocale("TRAILER"), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 16

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(getLocale("MOVIE_TRAILER"), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		currY :+ 4 'offset of subContent

		'topicality
		fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), currX + 215, currY, 75, 15, null, textLightColor)

		if data.trailerTopicality > 0.1
			SetAlpha GetAlpha()*0.25
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1, 200, 10))
			SetAlpha GetAlpha()*4.0
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1, data.trailerTopicality*200, 10))
		endif


		If TVTDebugInfos
			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0

			local w:int = GetSpriteFromRegistry("gfx_datasheet_title").area.GetW() - 20
			local h:int = currY-y
			DrawRect(currX, y, w,h)
		
			SetColor 255,255,255
			SetAlpha oldAlpha

			local textY:int = y + 5
			fontBold.draw("Trailer: "+GetTitle(), currX + 5, textY)
			textY :+ 14	
			fontNormal.draw("Traileraktualitaet: "+data.trailerTopicality+" von " + data.trailerMaxTopicality, currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Ausstrahlungen: "+data.trailerAired, currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Ausstrahlungen seit letzter Sendung: "+data.trailerAiredSinceShown, currX + 5, textY)

		Endif
	End Method


	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method SetAttractiveness(value:Float) {_exposeToLua}
		Self.attractiveness = value
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method GetPricePerBlock:Int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetBlocks()

		'if licence is a collection: ask subs
		local ppB:int = 0
		local ppBcount:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			ppB:+ licence.GetPricePerBlock()
			ppBcount:+1
		Next
		if ppBcount > 0 then Return ppB/ppBcount
		Return 0
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method GetQualityLevel:Int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData()
			Local quality:Int = Self.GetData().GetQuality() * 100
			If quality > 20
				Return 5
			ElseIf quality > 15
				Return 4
			ElseIf quality > 10
				Return 3
			ElseIf quality > 5
				Return 2
			Else
				Return 1
			EndIf
		endif

		'if licence is a collection: ask subs
		local quality:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			quality :+ licence.GetQualityLevel()
		Next

		if subLicences.length > 0 then return quality / subLicences.length
		return 1
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type





'create all filters
TProgrammeLicenceFilter.Init()

Type TProgrammeLicenceFilter
	Field caption:string = ""
	Field genres:Int[]
	Field flags:int
	Field notFlags:int
	Field displayInMenu:int = False
	Field id:int = 0

	Global filters:TList = CreateList()
	Global visibleCount:int = -1
	Global lastID:Int=0


	Method New()
		lastID:+1
		id = lastID
	End Method


	function Init()
		'reset old filters
		filters = CreateList()

		'flags having custom categories
		local categoryFlags:int = TVTProgrammeFlag.PAID | TVTProgrammeFlag.LIVE | TVTProgrammeFlag.TRASH

		CreateVisible().AddNotFlag(categoryFlags).AddGenres([1])			'adventure
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([2])			'action
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([4, 17])		'crime & thriller
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([5])			'comedy
		'documentation & reportage
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([6, 300]).SetCaption("PROGRAMME_GENRE_DOCUMENTARIES_AND_FEATURES")
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([7])			'drama
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([8])			'erotic
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([9, 3])			'family & cartoons
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([10, 14])		'fantasy & mystery
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([11])			'history
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([12])			'horror
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([13])			'monumental
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([15])			'lovestory
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([16])			'scifi
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([18])			'western
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([0])			'undefined
		'show/event -> all categories
		CreateVisible().AddNotFlag(categoryFlags).AddGenres([100, 101, 102, 200, 201, 202, 203, 204]).SetCaption("PROGRAMME_GENRE_SHOW_AND_EVENTS")
		CreateVisible().AddFlag(TVTProgrammeFlag.LIVE)						'live
		CreateVisible().AddFlag(TVTProgrammeFlag.TRASH).AddGenres([301])	'Trash + Yellow Press
		CreateVisible().AddFlag(TVTProgrammeFlag.PAID)						'Call-In
	End Function


	'creates a new filter and sets it up to get displayed in the licence
	'selection menu
	Function CreateVisible:TProgrammeLicenceFilter()
		local obj:TProgrammeLicenceFilter = new TProgrammeLicenceFilter
		obj.displayInMenu = True

		'add to list
		Add(obj)

		return obj
	End Function


	Function Add:TProgrammeLicenceFilter(filter:TProgrammeLicenceFilter)
		filters.AddLast(filter)

		'invalidate cached vars
		visibleCount :-1

		return filter
	End Function


	Method SetCaption(caption:String)
		self.caption = caption
	End Method


	Method GetCaption:string()
		if caption then return GetLocale(caption)

		local result:string
'		if result = ""
			local flag:int = 0
			For local flagNumber:int = 0 to 7 'manual limitation to "7" to exclude series/paid?
				flag = 2^flagNumber
				'contains that flag?
				if flags & flag > 0
					if result <> "" then result :+ " & "
					result :+ GetLocale("PROGRAMME_FLAG_" + TVTProgrammeFlag.GetAsString(flag))
				endif
			Next
'		endif

		For local entry:int = EachIn GetGenres()
			if result <> "" then result :+ " & "
			result :+ GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(entry))
		Next
		return result
	End Method


	Function GetCount:Int()
		return filters.Count()
	End Function


	Function GetVisibleCount:Int()
		if visibleCount >= 0 then return visibleCount

		visibleCount = 0
		For local f:TProgrammeLicenceFilter = EachIn filters
			if f.displayInMenu then visibleCount :+ 1
		Next
		return visibleCount
	End Function


	Function GetVisible:TProgrammeLicenceFilter[]()
		local result:TProgrammeLicenceFilter[]
		For local f:TProgrammeLicenceFilter = EachIn filters
			if f.displayInMenu then result :+ [f]
		Next
		return result
	End Function


	'returns a filter which contains ALL given genres and flags
	'so it is like "genre1 AND genre2 AND flag1 AND flag2"
	Function Get:TProgrammeLicenceFilter(genres:int[], flags:int=0)
		local result:TProgrammeLicenceFilter
		For local filter:TProgrammeLicenceFilter = EachIn filters
			if genres.length > 0
				for local genre:int = eachin genres
					local foundGenre:int = False
					for local filterGenre:int = eachin filter.genres
						if filterGenre = genre then foundGenre = True;exit 
					Next
					'if the genre was not found, the filter is not the right
					'one -> exit the genre loop
					if not foundGenre
						result = Null
						exit
					else
						result = filter
					endif
				Next
				if not result then continue
			endif

			'check flags
			'skip if not all were set
			if (filter.flags & flags) <> flags then continue

			'found the filter
			return filter
		Next
		return result
	End Function


	Function GetAtIndex:TProgrammeLicenceFilter(index:int)
		return TProgrammeLicenceFilter(filters.ValueAtIndex(index))
	End Function


	Method ToString:String()
		local g:string = ""
		for local i:int = eachin genres
			if g<>"" then g:+ ", "
			g:+ i
		Next

		return "filter["+id+"]  genres=~q"+g+"~q  flags="+flags
	End Method
	

	Method AddGenres:TProgrammeLicenceFilter(newGenres:int[])
		For local newGenre:int = eachIn newGenres
			For local genre:int = EachIn genres
				'skip if genre exists already
				if genre = newGenre then continue
			Next
			genres :+ [newGenre]
		Next
		return self
	End Method


	Method AddFlag:TProgrammeLicenceFilter(flag:int)
		self.flags :| flag

		return self
	End Method


	Method AddNotFlag:TProgrammeLicenceFilter(flag:int)
		self.notFlags :| flag

		return self
	End Method


	Method GetGenres:int[]()
		return genres
	End Method


	'checks if the given programmelicence contains at least ONE of the given
	'filter criterias ("OR"-chain of criterias)
	'Ex.: filter cares for genres 1,2 and flags "trash" and "bmovie"
	'     True is returned genre 1 or 2 or flag "trash" or flag "bmovie"
	Method DoesFilter:Int(licence:TProgrammeLicence)
		if not licence then return False
		'check flags filter does NOT care for
		if notFlags > 0 and (licence.GetFlags() & notFlags) > 0 then return False

		if genres.length > 0
			local licenceGenre:int = licence.GetGenre()
			local hasGenre:int = False
			for local genre:int = eachin genres
				if licenceGenre = genre then hasGenre = True;exit
			Next
			if hasGenre then return True
		endif

		'check flags share something
		if flags > 0 and (licence.GetFlags() & flags) > 0 then return True

		return False
	End Method
End Type


