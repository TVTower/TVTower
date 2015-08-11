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
'to access datasheet-functions
Import "common.misc.datasheet.bmx"




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


	Method Remove:Int(licence:TProgrammeLicence)
		return licences.Remove(licence)
	End Method


	'checks if the licences list contains the given licence
	Method Contains:Int(licence:TProgrammeLicence)
		return licences.contains(licence)
	End Method


	'add a licence as single (movie, one-time-event)
	Method AddSingle:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False

		singles.AddLast(licence)
		return True
	End Method


	Method RemoveSingle:Int(licence:TProgrammeLicence)
		Remove(licence)
		singles.Remove(licence)
	End Method


	'checks if the singles list contains the given licence
	Method ContainsSingle:Int(licence:TProgrammeLicence)
		return singles.contains(licence)
	End Method	


	'add a licence as series
	Method AddSeries:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False
		
		series.AddLast(licence)
		return True
	End Method


	Method RemoveSeries:Int(licence:TProgrammeLicence)
		Remove(licence)
		series.Remove(licence)
	End Method


	'checks if the series list contains the given licence
	Method ContainsSeries:Int(licence:TProgrammeLicence)
		return series.contains(licence)
	End Method	


	Method AddEpisode:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False

		'nothing more to do
		
		return True
	End Method


	Method RemoveEpisode:Int(licence:TProgrammeLicence)
		'TODO: remove from parents sublicence list?
		
		Remove(licence)
	End Method


	'checks if the licences list contains the given licence
	Method ContainsEpisode:Int(licence:TProgrammeLicence)
		return Contains(licence)
	End Method	


	'add a licence as collection
	Method AddCollection:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False
		
		collections.AddLast(licence)
		return True
	End Method


	'checks if the collection list contains the given licence
	Method ContainsCollection:Int(licence:TProgrammeLicence)
		return collections.contains(licence)
	End Method


	Method RemoveCollection:Int(licence:TProgrammeLicence)
		Remove(licence)
		collections.Remove(licence)
	End Method


	'add a licence to all needed lists
	Method AddAutomatic:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'do not add franchise-licences
		if licence.licenceType = TVTProgrammeLicenceType.FRANCHISE then return False

		'=== SINGLES ===
		if licence.isSingle() then AddSingle(licence, skipDuplicates)


		'=== SERIES ===
		if licence.isSeries() then AddSeries(licence, skipDuplicates)
		if licence.isEpisode() then AddEpisode(licence, skipDuplicates)

		'=== COLLECTIONS ===
		if licence.isCollection() then AddCollection(licence, skipDuplicates)

		return True
	End Method
		

	'remove a licence from all needed lists
	Method RemoveAutomatic:Int(licence:TProgrammeLicence)
		'skip franchise-licences
		if licence.licenceType = TVTProgrammeLicenceType.FRANCHISE then return False

		'=== SINGLES ===
		if licence.isSingle() then RemoveSingle(licence)

		'=== SERIES ===
		if licence.isSeries() then RemoveSeries(licence)
		if licence.isEpisode() then RemoveEpisode(licence)

		'=== COLLECTIONS ===
		if licence.isCollection() then RemoveCollection(licence)

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
				if Licence.GetGenre() = genre Then resultList.addLast(Licence)
			else
				local foundGenreInSubLicence:int = FALSE
				for local subLicence:TProgrammeLicence = eachin Licence.subLicences
					if foundGenreInSubLicence then continue
					if subLicence.GetGenre() = genre
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


	Method GetLicenceType:int()
		return licenceType
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


	Method GetEpisodeNumber:int()
		if not self.parentLicenceGUID then return 1
		return GetParentLicence().GetSubLicencePosition(self)+1
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


	Method GetGenreString:String(_genre:Int=-1)
		'return the string of the best genre of the licence (packet)
		if GetData() then return GetData().GetGenreString( GetGenre() )
		return ""
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
		local quality:Float = 0
		For local licence:TProgrammeLicence = eachin subLicences
			quality :+ licence.GetQuality()
		Next

		if subLicences.length > 0 then return quality / subLicences.length
		return 0.0
	End Method


	Method GetQualityRaw:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetQualityRaw()

		'if licence is a collection: ask subs
		local qualityRaw:Float = 0
		For local licence:TProgrammeLicence = eachin subLicences
			qualityRaw :+ licence.GetQualityRaw()
		Next

		if subLicences.length > 0 then return qualityRaw / subLicences.length
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
	Method GetTopicality:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetTopicality()

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetTopicality()
		Next

		if subLicences.length > 0 then return value / subLicences.length
		return 0.0
	End Method


	'returns the avg maxTopicality of a licence (package)
	Method GetMaxTopicality:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetMaxTopicality()

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetMaxTopicality()
		Next

		if subLicences.length > 0 then return value / subLicences.length
		return 0.0
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
		if showMode = 0 then showMode = TVTBroadcastMaterialType.PROGRAMME

		if KeyManager.IsDown(KEY_LALT) or KeyManager.IsDown(KEY_RALT)
			if showMode = TVTBroadcastMaterialType.PROGRAMME
				showMode = TVTBroadcastMaterialType.ADVERTISEMENT
			else
				showMode = TVTBroadcastMaterialType.PROGRAMME
			endif
		Endif


		if showMode = TVTBroadcastMaterialType.PROGRAMME
			ShowProgrammeSheet(x, y, align)
		'trailermode
		elseif showMode = TVTBroadcastMaterialType.ADVERTISEMENT
			ShowTrailerSheet(x, y, align)
		endif
	End Method


	Method ShowProgrammeSheet:Int(x:Int,y:Int, align:int=0)
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 310
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("programme")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()

		'save checks on data availability...
		local data:TProgrammeData = GetData()
		'save on requests to the player finance
		local finance:TPlayerFinance
		'only check finances if it is no other player (avoids exposing
		'that information to us)
		if owner <= 0 or GetPlayerBaseCollection().playerID = owner
			finance = GetPlayerFinanceCollection().Get(GetPlayerBaseCollection().playerID, -1)
		endif

		local title:string
		if not isEpisode()
			title = GetTitle()
		else
			title = GetParentLicence().GetTitle()
		endif

		'can player afford this licence?
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
		
		Local showMsgPlannedWarning:Int = False
		Local showMsgEarnInfo:Int = False
		
		'only if planned and in archive
		'if owner > 0 and GetPlayer().figure.inRoom
		'	if self.IsPlanned() and GetPlayer().figure.inRoom.name = "archive"
		if owner > 0 and self.IsPlanned() then showMsgPlannedWarning = True
		'if licence is for a specific programme it might contain a flag...
		'TODO: do this for "all" via licence.HasFlag() doing recursive checks?
		If data.HasFlag(TVTProgrammeFlag.PAID) then showMsgEarnInfo = True


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, subtitleH:int = 16, genreH:int = 16, descriptionH:int = 70, castH:int=50
		local splitterHorizontalH:int = 6
		local boxH:int = 0, msgH:int = 0, barH:int = 0
		local msgAreaH:int = 0, boxAreaH:int = 0, barAreaH:int = 0
		local boxAreaPaddingY:int = 4, msgAreaPaddingY:int = 4, barAreaPaddingY:int = 4
		 
		msgH = skin.GetMessageSize(contentW - 10, -1, "", "money", "good", null, ALIGN_CENTER_CENTER).GetY()
		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").GetY()
		barH = skin.GetBarSize(100, -1).GetY()
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(title, contentW - 10, 100))
		'increase for multiline
'		if titleH > 18 then titleH :+ 3

		'message area
		If showMsgEarnInfo then msgAreaH :+ msgH
		If showMsgPlannedWarning then msgAreaH :+ msgH
		'if there are messages, add padding of messages
		if msgAreaH > 0 then msgAreaH :+ 2* msgAreaPaddingY


		'box area
		'contains 1 line of boxes
		'box area might start with padding and end with padding
		boxAreaH = 1 * boxH
		if msgAreaH = 0 then boxAreaH :+ boxAreaPaddingY
		'no ending if nothing comes after "boxes"

		'bar area starts with padding, ends with padding and contains
		'also contains 4 bars
		barAreaH = 2 * barAreaPaddingY + 4 * (barH + 2)

		'total height
		sheetHeight = titleH + genreH + descriptionH + castH + barAreaH + msgAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		if isSeries() or isEpisode() then sheetHeight :+ subtitleH
		'there is a splitter between description and cast...
		sheetHeight :+ splitterHorizontalH

		
		'=== RENDER ===
	
		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
			if titleH <= 18
				GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY -1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY +1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
		contentY :+ titleH

		
		'=== SUBTITLE AREA ===
		if isSeries()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			skin.fontNormal.drawBlock(GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetSubLicenceCount()), contentX + 5, contentY, contentW - 10, genreH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ subtitleH
		elseif isEpisode()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			'episode num/max + episode title
			skin.fontNormal.drawBlock(GetEpisodeNumber() + "/" + GetParentLicence().GetSubLicenceCount() + ": " + data.GetTitle(), contentX + 5, contentY, contentW - 10, genreH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ subtitleH
		endif
		

		'=== COUNTRY / YEAR / GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		'splitter
		GetSpriteFromRegistry("gfx_datasheet_content_splitterV").DrawArea(contentX + 5 + 65, contentY, 2, 16)
		'country [+year] + genre, year for non-callin-shows
		If data.HasFlag(TVTProgrammeFlag.PAID)
			skin.fontNormal.drawBlock(data.country, contentX + 5, contentY, 65, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		else
			skin.fontNormal.drawBlock(data.country + " " + data.year, contentX + 5, contentY, 65, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		endif
		skin.fontNormal.drawBlock(GetGenreString(), contentX + 5 + 65 + 2, contentY, contentW - 10 - 65 - 2, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ genreH

	
		'=== DESCRIPTION AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.drawBlock(GetDescription(), contentX + 5, contentY + 3, contentW - 10, descriptionH - 3, null, skin.textColorNeutral)
		contentY :+ descriptionH


		'splitter
		skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
		contentY :+ splitterHorizontalH
		

		'=== CAST AREA ===
		skin.RenderContent(contentX, contentY, contentW, castH, "2")

		local addCastTitle:string  = "", addCast:string = ""
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
		local currTextWidth:int = Int(skin.fontSemiBold.getWidth(GetLocale("MOVIE_DIRECTOR")+":"))
		if addCastTitle
			currTextWidth = Max(currTextWidth, Int(skin.fontSemiBold.getWidth(addCastTitle+":")))
		endif

		'render director + cast (offset by 3 px)
		contentY :+ 3
		'director
		local directorH:int = 0
		if data.GetDirectorsString() <> ""
			directorH = 15
			skin.fontSemiBold.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", contentX + 5, contentY, contentW - 10, directorH, null, skin.textColorNeutral)
			skin.fontNormal.drawBlock(data.GetDirectorsString(), contentX + 5 + currTextWidth + 5, contentY , contentW  - 10 - currTextWidth - 5, directorH, null, skin.textColorNeutral)
			contentY :+ directorH
		endif

		'actors or other additional cast members
		if addCast <> ""
			skin.fontSemiBold.drawBlock(addCastTitle+":", contentX + 5, contentY, contentW - 10, (castH- directorH), null, skin.textColorNeutral)
			'add 2 px to height to allow a slight oversized cast block
			skin.fontNormal.drawBlock(addCast, contentX + 5 + currTextWidth + 5, contentY, contentW - 10 - currTextWidth - 5, (castH - directorH), null, skin.textColorNeutral)
		endif
		'move to next content (pay attention to 3px offset)
		contentY :+ (castH - directorH - 3)


		'=== BARS / MESSAGES / BOXES AREA ===
		'background for bars + messages + boxes
		skin.RenderContent(contentX, contentY, contentW, barAreaH + msgAreaH + boxAreaH, "1_bottom")


		'===== DRAW RATINGS / BARS =====

		'bars have a top-padding
		contentY :+ barAreaPaddingY
		'speed
		skin.RenderBar(contentX + 5, contentY, 200, 12, data.GetSpeed())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_SPEED"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'critic/review
		skin.RenderBar(contentX + 5, contentY, 200, 12, data.GetReview())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_CRITIC"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'boxoffice/outcome
		skin.RenderBar(contentX + 5, contentY, 200, 12, data.GetOutcome())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_BOXOFFICE"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'topicality/maxtopicality
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetTopicality(), GetMaxTopicality())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
	

		'=== MESSAGES ===
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY

		If showMsgEarnInfo
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			local revenue:string = TFunctions.DottedValue(int(1000 * data.GetPerViewerRevenue()))+CURRENCYSIGN

			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), "money", "good", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		if showMsgPlannedWarning
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PROGRAMME_IN_PROGRAMME_PLAN"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif

		'if there is a message then add padding to the bottom
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		'=== BOXES ===
		'boxes have a top-padding (except with messages)
		if msgAreaH = 0 then contentY :+ boxAreaPaddingY


		'=== BOX LINE 1 ===
		'blocks
		skin.RenderBox(contentX + 5, contentY, 47, -1, data.GetBlocks(), "duration", "neutral", skin.fontBold)
		'repetitions
		skin.RenderBox(contentX + 5 + 51, contentY, 52, -1, data.GetTimesAired(owner), "repetitions", "neutral", skin.fontBold)
		'record
		skin.RenderBox(contentX + 5 + 107, contentY, 83, -1, TFunctions.convertValue(GetBroadcastStatistic().GetBestAudienceResult(owner, -1).audience.GetSum(),2), "maxAudience", "neutral", skin.fontBold)
		'price
		if canAfford
			skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(GetPrice()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		else
			skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(GetPrice()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER, "bad")
		endif
		'=== BOX LINE 2 ===
		contentY :+ boxH



		'=== DEBUG ===
		If TVTDebugInfos
			'begin at the top ...again
			contentY = y + skin.GetContentY()
			local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.drawBlock("Programm: "+GetTitle(), contentX + 5, contentY, contentW - 10, 28)
			contentY :+ 28
			skin.fontNormal.draw("Letzte Stunde im Plan: "+latestPlannedEndHour, contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Tempo: "+MathHelper.NumberToString(data.GetSpeed(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Kritik: "+MathHelper.NumberToString(data.GetReview(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Kinokasse: "+MathHelper.NumberToString(data.GetOutcome(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Preismodifikator: "+MathHelper.NumberToString(data.GetModifier("price"), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Qualitaet roh: "+MathHelper.NumberToString(GetQualityRaw(), 4)+"  (ohne Alter, Wdh.)", contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Qualitaet: "+MathHelper.NumberToString(GetQuality(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Aktualitaet: "+MathHelper.NumberToString(GetTopicality(), 4)+" von " + MathHelper.NumberToString(data.GetMaxTopicality(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Bloecke: "+data.GetBlocks(), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Ausgestrahlt: "+data.GetTimesAired(owner)+"x Spieler, "+data.GetTimesAired()+"x alle", contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Quotenrekord: "+Long(GetBroadcastStatistic().GetBestAudienceResult(owner, -1).audience.GetSum())+" (Spieler), "+Long(GetBroadcastStatistic().GetBestAudienceResult(-1, -1).audience.GetSum())+" (alle)", contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Preis: "+GetPrice(), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Trailerakt.-modifikator: "+MathHelper.NumberToString(data.GetTrailerMod().GetAverage(), 4), contentX + 5, contentY)
		endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)

		'=== X-Rated Overlay ===
		If data.IsXRated()
			GetSpriteFromRegistry("gfx_datasheet_overlay_xrated").Draw(contentX + sheetWidth, y, -1, ALIGN_RIGHT_TOP)
		Endif
	End Method


	Method ShowTrailerSheet:Int(x:Int,y:Int, align:int=0)
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 310
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("trailer")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, genreH:int = 16, descriptionH:int = 70
		local barH:int = 0, msgH:int = 0
		local msgAreaH:int = 0, barAreaH:int = 0
		local barAreaPaddingY:int = 4, msgAreaPaddingY:int = 4

		'reactivate when adding messages
		'msgH = skin.GetMessageSize(contentW - 10, -1, "", "targetGroupLimited", "warning", null, ALIGN_CENTER_CENTER).GetY()
		barH = skin.GetBarSize(100, -1).GetY()

		'bar area
		'bar area starts with padding, ends with padding and contains
		barAreaH = 2 * barAreaPaddingY + barH

		'message area
		'show earn message
		rem
		'TODO: add messages? ("shown max already - no efficiency increase")
		'if blaCondition > 0 then msgAreaH :+ msgH
		'if there are messages, add padding of messages
		if msgAreaH > 0 then msgAreaH :+ msgAreaPaddingY
		'if nothing comes after the messages, add bottom padding
		if msgAreaH > 0 and barAreaH=0 then msgAreaH :+ msgAreaPaddingY
		endrem
		
		'total height
		sheetHeight = titleH + genreH + descriptionH + msgAreaH + barAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()


		
		'=== RENDER ===
	
		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH


		'=== GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		skin.fontNormal.drawBlock(GetLocale("TRAILER"), contentX + 5, contentY -1, contentW - 10, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ genreH


		'=== CONTENT AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.drawBlock(getLocale("MOVIE_TRAILER"), contentX + 5, contentY + 3, contentW - 10, descriptionH, null, skin.textColorNeutral)
		contentY :+ descriptionH
		

		'=== MESSAGES ===
		'background for messages + boxes
		skin.RenderContent(contentX, contentY, contentW, msgAreaH + barAreaH , "1_bottom")
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		'=== BARS ===
		'bars have a top-padding
		contentY :+ barAreaPaddingY

		'topicality
		skin.RenderBar(contentX + 5, contentY, 200, 12, data.GetTrailerTopicality())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)


		If TVTDebugInfos
			'begin at the top ...again
			contentY = y + skin.GetContentY()

			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.draw("Trailer: "+GetTitle(), contentX + 5, contentY)
			contentY :+ 14	
			skin.fontNormal.draw("Traileraktualitaet: "+MathHelper.NumberToString(data.GetTrailerTopicality(), 4)+" von " + MathHelper.NumberToString(data.GetMaxTrailerTopicality(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Ausstrahlungen: "+data.trailerAired, contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Ausstrahlungen seit letzter Sendung: "+data.trailerAiredSinceShown, contentX + 5, contentY)
		Endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
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
	Field qualityMin:Float = -1.0
	Field qualityMax:Float = -1.0
	Field licenceTypes:int[]
	Field priceMin:int = -1
	Field priceMax:int = -1
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

		'check if it fits to the desired genres
		if genres.length > 0
			local licenceGenre:int = licence.GetGenre()
			local hasGenre:int = False
			for local genre:int = eachin genres
				if licenceGenre = genre then hasGenre = True;exit
			Next
			if not hasGenre then return False
		endif

		'check quality (not qualityRaw which ignores age, airedtimes,...)
		if qualityMin >= 0 and licence.GetQuality() < qualityMin then return False
		if qualityMax >= 0 and licence.GetQuality() > qualityMax then return False

		'check price
		if priceMin >= 0 and licence.GetPrice() < priceMin then return False
		if priceMax >= 0 and licence.GetPrice() > priceMax then return False

		'check licenceType
		if licenceTypes.length > 0
			local hasType:int = False
			for local licenceType:int = eachin licenceTypes
				if licenceType = licence.licenceType then hasType = True;exit
			Next
			if not hasType then return False
		endif

		'check flags share something
		if flags > 0 and (licence.GetFlags() & flags) <= 0 then return False

		return True
	End Method
End Type



'filters checked via "OR" (a or b) or "AND" (a and b)
Type TProgrammeLicenceFilterGroup extends TProgrammeLicenceFilter
	Field filters:TProgrammeLicenceFilter[]
	Field connectionType:int = 0
	Const CONNECTION_TYPE_OR:int = 0
	Const CONNECTION_TYPE_AND:int = 1

	Method AddFilter(filter:TProgrammeLicenceFilter)
		filters :+ [filter]
	End Method

	
	Method DoesFilter:Int(licence:TProgrammeLicence)
		if connectionType = CONNECTION_TYPE_OR
			For local filter:TProgrammeLicenceFilter = Eachin filters
				if filter.DoesFilter(licence) then return True
			Next
			return False
		else
			For local filter:TProgrammeLicenceFilter = Eachin filters
				if filter <> filters[filters.length - 1]
					if not filter.DoesFilter(licence) then return False
				else
					'last filter - if this is reached, all others filtered
					'ok and this one might return desired result
					if filter.DoesFilter(licence) then return True
				endif
			Next
			return False
		endif
	End Method
End Type