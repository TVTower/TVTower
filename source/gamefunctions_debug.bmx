
Global debugAudienceInfos:TDebugAudienceInfos = New TDebugAudienceInfos
Global debugModifierInfos:TDebugModifierInfos = New TDebugModifierInfos
Global debugProgrammePlanInfos :TDebugProgrammePlanInfos = new TDebugProgrammePlanInfos
Global debugProgrammeCollectionInfos :TDebugProgrammeCollectionInfos = new TDebugProgrammeCollectionInfos
Global debugPlayerControls :TDebugPlayerControls = new TDebugPlayerControls
Global debugFinancialInfos :TDebugFinancialInfos = new TDebugFinancialInfos


Type TDebugAudienceInfos
	Field currentStatement:TBroadcastFeedbackStatement
	Field lastCheckedMinute:Int


	Method Update(playerID:int, x:int, y:int)
	End Method


	Method Draw()
		SetColor 0,0,0
		DrawRect(0,0,800,385)
		SetColor 255, 255, 255

		'GetBitmapFontManager().baseFont.Draw("Bevölkerung", 25, startY)

		local playerID:int = TIngameInterface.GetInstance().ShowChannel
		if playerID <= 0 then playerID = GetPlayerBaseCollection().playerID

		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( playerID )

		Local x:Int = 200
		Local y:Int = 25
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		GetBitmapFontManager().baseFont.drawBlock("|b|Taste |color=255,100,0|~qQ~q|/color| drücken|/b| um (Debug-)Quotenbildschirm wieder auszublenden. Spielerwechsel: TV-Kanalbuttons", 0, 360, GetGraphicsManager().GetWidth(), 25, ALIGN_CENTER_CENTER, TColor.clRed)

		font.drawBlock("Gesamt", x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)
		font.drawBlock("Kinder", x + (70*1), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Jugendliche", x + (70*2), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Hausfrau.", x + (70*3), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Arbeitneh.", x + (70*4), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Arbeitslose", x + (70*5), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Manager", x + (70*6), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Rentner", x + (70*7), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)


		font.Draw("Bevölkerung", 25, 50, TColor.clWhite)
		DrawAudience(audienceResult.WholeMarket, 200, 50)

		Local percent:String = MathHelper.NumberToString(audienceResult.GetPotentialMaxAudienceQuotePercentage()*100,2) + "%"
		font.Draw("Potentielle Zuschauer", 25, 70, TColor.clWhite)
		font.Draw(percent, 160, 70, TColor.clWhite)
		DrawAudience(audienceResult.PotentialMaxAudience, 200, 70)

		local colorLight:TColor = TColor.CreateGrey(150)

		'font.drawStyled("      davon Exklusive", 25, 90, TColor.clWhite);
		'DrawAudience(audienceResult.ExclusiveAudienceSum, 200, 90, true);

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 105, colorLight);
		'DrawAudience(audienceResult.AudienceFlowSum, 200, 105, true);

		'font.drawStyled("      davon Zapper", 25, 120, colorLight);
		'DrawAudience(audienceResult.ChannelSurferToShare, 200, 120, true);


		font.Draw("Aktuelle Zuschauerzahl", 25, 90, TColor.clWhite);
		percent = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage()*100,2) + "%"
		font.Draw(percent, 160, 90, TColor.clWhite);
		DrawAudience(audienceResult.Audience, 200, 90);

		'font.drawStyled("      davon Exklusive", 25, 155, colorLight);
		'DrawAudience(audienceResult.ExclusiveAudience, 200, 155, true);

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 170, colorLight);
		'DrawAudience(audienceResult.AudienceFlow, 200, 170, true);

		'font.drawStyled("      davon Zapper", 25, 185, colorLight);
		'DrawAudience(audienceResult.ChannelSurfer, 200, 185, true);







		Local attraction:TAudienceAttraction = audienceResult.AudienceAttraction
		Local genre:String = "kein Genre"
		Select attraction.BroadcastType
			case TVTBroadcastMaterialType.PROGRAMME
				If (attraction.BaseAttraction <> Null and attraction.genreDefinition)
					genre = GetLocale("PROGRAMME_GENRE_"+TVTProgrammeGenre.GetAsString(attraction.genreDefinition.referenceID))
				Endif
			case TVTBroadcastMaterialType.ADVERTISEMENT
				If (attraction.BaseAttraction <> Null)
					genre = GetLocale("INFOMERCIAL")
				Endif
			case TVTBroadcastMaterialType.NEWSSHOW
				If (attraction.BaseAttraction <> Null)
					genre = "News-Genre-Mix"
				Endif
		End Select

		Local offset:Int = 110

		GetBitmapFontManager().baseFontBold.drawStyled("Sendung: " + audienceResult.GetTitle() + "     (" + genre + ") [Spieler: "+playerID+"]", 25, offset, TColor.clRed);
		offset :+ 20

		font.Draw("1. Programmqualität & Aktual.", 25, offset, TColor.clWhite)
		If attraction.Quality
			DrawAudiencePercent(new TAudience.InitValue(attraction.Quality,  attraction.Quality), 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("2. * Zielgruppenattraktivität", 25, offset, TColor.clWhite)
		if attraction.GetTargetGroupAttractivity()
			DrawAudiencePercent(attraction.GetTargetGroupAttractivity(), 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("3. * TrailerMod ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_TRAILER*100)+"%)", 25, offset, TColor.clWhite)
		If attraction.TrailerMod
			font.drawBlock(genre, 60, offset, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.TrailerMod.Copy().MultiplyFloat(TAudienceAttraction.MODINFLUENCE_TRAILER).AddFloat(1), 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("4. + Sonstige Mods ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_MISC*100)+"%)", 25, offset, TColor.clWhite)
		If attraction.MiscMod
			DrawAudiencePercent(attraction.MiscMod, 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("5. + CastMod ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_CAST*100)+"%)", 25, offset, TColor.clWhite)
		DrawAudiencePercent(new TAudience.InitValue(attraction.CastMod,  attraction.CastMod), 200, offset, true, true)
		offset :+ 20

		font.Draw("6. * SenderimageMod", 25, offset, TColor.clWhite)
		If attraction.PublicImageMod
			DrawAudiencePercent(attraction.PublicImageMod.Copy().AddFloat(1.0), 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("7. + Zuschauerentwicklung (inaktiv)", 25, offset, TColor.clWhite)
	'	DrawAudiencePercent(new TAudience.InitValue(-1, attraction.QualityOverTimeEffectMod), 200, offset, true, true)
		offset :+ 20

		font.Draw("9. + Glück / Zufall", 25, offset, TColor.clWhite)
		If attraction.LuckMod
			DrawAudiencePercent(attraction.LuckMod, 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("9. + Audience Flow Bonus", 25, offset, TColor.clWhite)
		if attraction.AudienceFlowBonus
			DrawAudiencePercent(attraction.AudienceFlowBonus, 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("10. * Genreattraktivität (zeitabh.)", 25, offset, TColor.clWhite)
		if attraction.GetGenreAttractivity()
			DrawAudiencePercent(attraction.GetGenreAttractivity(), 200, offset, true, true)
		endif
		offset :+ 20
	
		font.Draw("11. + Sequence", 25, offset, TColor.clWhite)
		If attraction.SequenceEffect
			DrawAudiencePercent(attraction.SequenceEffect, 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("Finale Attraktivität (Effektiv)", 25, offset, TColor.clRed)
		If attraction.FinalAttraction
			DrawAudiencePercent(attraction.FinalAttraction, 200, offset, false, true)
		endif
rem
		font.Draw("Basis-Attraktivität", 25, offset+230, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BaseAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BaseAttraction, 200, offset+230, false, true);
		Endif
		endrem
		rem
		endrem

		rem
		font.Draw("10. Nachrichteneinfluss", 25, offset+330, TColor.clWhite)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.NewsShowBonus Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.NewsShowBonus, 200, offset+330, true, true);
		Endif
		endrem

		rem
		font.Draw("Block-Attraktivität", 25, offset+290, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BlockAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BlockAttraction, 200, offset+290, false, true);
		Endif
		endrem



		rem
		font.Draw("Ausstrahlungs-Attraktivität", 25, offset+270, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BroadcastAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BroadcastAttraction, 200, offset+270, false, true);
		Endif
		endrem

		Local currBroadcast2:TBroadcast = GetBroadcastManager().GetCurrentBroadcast()
		Local feedback:TBroadcastFeedback = currBroadcast2.GetFeedback(playerID)

		Local minute:Int = GetWorldTime().GetDayMinute()

		If ((minute Mod 5) = 0)
			If Not (self.lastCheckedMinute = minute)
				self.lastCheckedMinute = minute
				currentStatement = null
				'DebugStop
			End If
		Endif

		If Not currentStatement Then
			currentStatement:TBroadcastFeedbackStatement = feedback.GetNextAudienceStatement()
		Endif

		SetColor 0,0,0
		DrawRect(520,415,250,40)
		font.Draw("Interest: " + feedback.AudienceInterest.ToStringMinimal(), 530, 420, TColor.clRed)
		font.Draw("Statements: count=" + feedback.FeedbackStatements.Count(), 530, 430, TColor.clRed)
		If currentStatement Then
			font.Draw(currentStatement.ToString(), 530, 440, TColor.clRed);
		Endif

		SetColor 255,255,255


rem
		font.Draw("Genre <> Sendezeit", 25, offset+240, TColor.clWhite)
		Local genreTimeMod:string = MathHelper.NumberToString(attraction.GenreTimeMod  * 100,2) + "%"
		Local genreTimeQuality:string = MathHelper.NumberToString(attraction.GenreTimeQuality * 100,2) + "%"
		font.Draw(genreTimeMod, 160, offset+240, TColor.clWhite)
		font.drawBlock(genreTimeQuality, 200, offset+240, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)

		'Nur vorübergehend
		font.Draw("Trailer-Mod", 25, offset+250, TColor.clWhite)
		Local trailerMod:String = MathHelper.NumberToString(attraction.TrailerMod  * 100,2) + "%"
		Local trailerQuality:String = MathHelper.NumberToString(attraction.TrailerQuality * 100,2) + "%"
		font.Draw(trailerMod, 160, offset+250, TColor.clWhite)
		font.drawBlock(trailerQuality, 200, offset+250, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)



		font.Draw("Image", 25, offset+295, TColor.clWhite);
		font.Draw("100%", 160, offset+295, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+295);

		font.Draw("Effektive Attraktivität", 25, offset+325, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+325)
endrem
	End Method


	Function DrawAudience(audience:TAudience, x:Int, y:Int, gray:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		local color:TColor = TColor.clWhite
		If gray Then color = TColor.CreateGrey(150)

		val = TFunctions.convertValue(audience.GetTotalSum(), 2)
		If gray Then
			font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.Create(150, 80, 80))
		Else
			font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)
		End If

		for local i:int = 1 to TVTTargetGroup.baseGroupCount
			val = TFunctions.convertValue(audience.GetTotalValue(TVTTargetGroup.GetAtIndex(i)), 2)
			font.drawBlock(val, x2 + 70*(i-1), y, 65, 25, ALIGN_RIGHT_TOP, color)
		next
	End Function


	Function DrawAudiencePercent(audience:TAudience, x:Int, y:Int, gray:Int = false, hideAverage:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		local color:TColor = TColor.clWhite
		If gray Then color = TColor.CreateGrey(150)

		If Not hideAverage Then
			val = MathHelper.NumberToString(audience.GetWeightedAverage(),2)
			If gray Then
				font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.Create(150, 80, 80))
			Else
				font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)
			End If
		End if

		for local i:int = 1 to TVTTargetGroup.baseGroupCount
			val = MathHelper.NumberToString(0.5 * audience.GetTotalValue(TVTTargetGroup.GetAtIndex(i)),2)
			font.drawBlock(val, x2 + 70*(i-1), y, 65, 25, ALIGN_RIGHT_TOP, color)
		Next
	End Function
End Type




Type TDebugProgrammeCollectionInfos
	Field initialized:Int = False
	Global addedProgrammeLicences:TMap = CreateMap()
	Global removedProgrammeLicences:TMap = CreateMap()
	Global availableProgrammeLicences:TMap = CreateMap()
	Global addedAdContracts:TMap = CreateMap()
	Global removedAdContracts:TMap = CreateMap()
	Global availableAdContracts:TMap = CreateMap()
	Global oldestEntryTime:Long
	Global _eventListeners:TLink[]

	
	Method New()
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]
		
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.removeAdContract", onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.addAdContract", onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.addUnsignedAdContractToSuitcase", onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.removeUnsignedAdContractFromSuitcase", onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.addProgrammeLicenceToSuitcase", onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.removeProgrammeLicenceFromSuitcase", onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.removeProgrammeLicence", onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.addProgrammeLicence", onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnStart", onGameStart) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.PreparePlayer", onPreparePlayer) ]
	End Method


	Function onGameStart:Int(triggerEvent:TEventBase)
		debugProgrammeCollectionInfos.Initialize()
	End Function

	'called if a player restarts
	Function onPreparePlayer:Int(triggerEvent:TEventBase)
		debugProgrammeCollectionInfos.Initialize()
	End Function
		

	Function onChangeProgrammeCollection:Int(triggerEvent:TEventBase)
		local prog:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().Get("programmelicence"))
		local contract:TAdContract = TAdContract(triggerEvent.GetData().Get("adcontract"))
		local broadcastSource:TBroadcastMaterialSource = prog
		if not broadcastSource then broadcastSource = contract

		if not broadcastSource then print "TDebugProgrammeCollectionInfos.onChangeProgrammeCollection: invalid broadcastSourceMaterial."


		local map:TMap = null
		if triggerEvent.IsTrigger("programmecollection.removeAdContract")
			map = removedAdContracts
			'remove on outdated
			'availableAdContracts.Remove(broadcastSource.GetGUID())
		elseif triggerEvent.IsTrigger("programmecollection.addAdContract")
			map = addedAdContracts
			availableAdContracts.Insert(broadcastSource.GetGUID(), broadcastSource)
'		elseif triggerEvent.IsTrigger("programmecollection.addUnsignedAdContractToSuitcase")
'			map = addedAdContracts
'		elseif triggerEvent.IsTrigger("programmecollection.removeUnsignedAdContractFromSuitcase")
'			map = addedAdContracts
'		elseif triggerEvent.IsTrigger("programmecollection.addProgrammeLicenceToSuitcase")
'			map = addedAdContracts
'		elseif triggerEvent.IsTrigger("programmecollection.removeProgrammeLicenceFromSuitcase")
'			map = addedAdContracts
		elseif triggerEvent.IsTrigger("programmecollection.removeProgrammeLicence")
			map = removedProgrammeLicences
			'remove on outdated
			'availableProgrammeLicences.Remove(broadcastSource.GetGUID())
		elseif triggerEvent.IsTrigger("programmecollection.addProgrammeLicence")
			map = addedProgrammeLicences
			availableProgrammeLicences.Insert(broadcastSource.GetGUID(), broadcastSource)
		endif
		if not map then return False

		map.Insert(broadcastSource.GetGUID(), string(Time.GetTimeGone()) )

		RemoveOutdated()
	End Function


	Function RemoveOutdated()
		local maps:TMap[] = [removedProgrammeLicences, removedAdContracts, addedProgrammeLicences, addedAdContracts]

		oldestEntryTime = -1

		'remove outdated ones (older than 30 seconds))
		For local map:TMap = EachIn maps
			local remove:string[]
			For local guid:String = EachIn map.Keys()
				local changeTime:Long = Long( string(map.ValueForKey(guid)) )

				if changeTime + 3000 < Time.GetTimeGone()
					remove :+ [guid]

					if map = removedProgrammeLicences then availableProgrammeLicences.Remove(guid)
					if map = removedAdContracts then availableAdContracts.Remove(guid)
					continue
				endif

				if oldestEntryTime = -1 then oldestEntryTime = changeTime
				oldestEntryTime = Min(oldestEntryTime, changeTime)
			Next

			for local guid:string = EachIn remove
				map.Remove(guid)
			next
		Next
	End Function
	


	Function GetAddedTime:Long(guid:string, materialType:int=0)
		if materialType = TVTBroadcastMaterialType.PROGRAMME
			return int( string(addedProgrammeLicences.ValueForKey(guid)) )
		else
			return int( string(addedAdContracts.ValueForKey(guid)) )
		endif
	End Function


	Function GetRemovedTime:Long(guid:string, materialType:int=0)
		if materialType = TVTBroadcastMaterialType.PROGRAMME
			return int( string(removedProgrammeLicences.ValueForKey(guid)) )
		else
			return int( string(removedAdContracts.ValueForKey(guid)) )
		endif
	End Function


	Function GetChangedTime:Long(guid:string, materialType:int=0)
		local addedTime:Long = GetAddedTime(guid, materialType)
		local removedTime:Long = GetRemovedTime(guid, materialType)
		if addedTime <> 0 then return addedTime
		return removedTime
	End Function


	Method Initialize:int()
		availableProgrammeLicences.Clear()
		availableAdContracts.Clear()
		'on savegame loads, the maps would be empty without 
		for local i:int = 1 to 4
			local coll:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(i)
			for local l:TProgrammeLicence = EachIn coll.GetProgrammeLicences()
				availableProgrammeLicences.insert(l.GetGUID(), l)
			next
			for local a:TAdContract = EachIn coll.GetAdContracts()
				availableAdContracts.insert(a.GetGUID(), a)
			next
		next

		initialized = True
	End Method


	Method Update(playerID:int, x:int, y:int)
	End Method

	
	Method Draw(playerID:int, x:int, y:int)
		if not initialized then Initialize()
	
		if playerID <= 0 then playerID = GetPlayerBase().playerID
		Local lineHeight:int = 12

		'clean up if needed
		if oldestEntryTime >= 0 and oldestEntryTime + 3000 < Time.GetTimeGone() then RemoveOutdated()

		local collection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		local secondLineCol:TColor = TColor.CreateGrey(220)

		local entryPos:int = 0
		local oldAlpha:Float = GetAlpha()
		for local l:TProgrammeLicence = EachIn availableProgrammeLicences.Values() 'collection.GetProgrammeLicences()
			if l.owner <> playerID then continue
			'skip starting programme
			if not l.isControllable() then continue
			
			local oldAlpha:Float = GetAlpha()
			if entryPos mod 2 = 0
				SetColor 0,0,0
			else
				SetColor 60,60,60
			endif
			SetAlpha 0.75 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight, 180, lineHeight-1)

			local changedTime:int = GetChangedTime(l.GetGUID(), TVTBroadcastMaterialType.PROGRAMME) 
			if changedTime <> 0
				SetColor 255,235,20
				local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - changedTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(x, y + entryPos * lineHeight, 180, lineHeight-1)
				SetBlend ALPHABLEND
			endif

			'draw in topicality
			SetColor 220,110,110
			SetAlpha 0.50 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight + lineHeight-3, 180 * l.GetTopicality(), 2)
			SetAlpha 0.75 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight + lineHeight-3, 180 * l.GetMaxTopicality(), 2)

			SetAlpha oldalpha
			SetColor 255,255,255

			local progString:string = l.GetTitle()
			GetBitmapFont("default", 10).DrawBlock( progString, x+2, y+1 + entryPos*lineHeight, 175, lineHeight, ALIGN_LEFT_CENTER,,,,,False)

			entryPos :+ 1
		next

		lineHeight = 11
		entryPos = 0
		for local a:TAdContract = EachIn availableAdContracts.Values() 'collection.GetAdContracts()
			if a.owner <> playerID then continue

			if entryPos mod 2 = 0
				SetColor 0,0,0
			else
				SetColor 50,50,50
			endif
			SetAlpha 0.85 * oldAlpha
			DrawRect(x+190, y + entryPos * lineHeight*2, 175, lineHeight*2-1)

			local changedTime:int = GetChangedTime(a.GetGUID(), TVTBroadcastMaterialType.ADVERTISEMENT) 
			if changedTime <> 0
				local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - changedTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND

				SetColor 255,235,20
				if GetRemovedTime(a.GetGUID(), TVTBroadcastMaterialType.ADVERTISEMENT) <> 0
					if a.state = a.STATE_FAILED
						SetColor 255,0,0
					elseif a.state = a.STATE_OK
						SetColor 0,255,0
					endif
				endif

				DrawRect(x+190, y + entryPos * lineHeight*2, 175, lineHeight*2-1)
				SetBlend ALPHABLEND
			endif
			SetAlpha oldalpha
			SetColor 255,255,255

			local adString1a:string = a.GetTitle()
			local adString1b:string = "R: "+(a.GetDaysLeft())+"D"
			if a.GetDaysLeft() = 1
				adString1b = "|color=220,180,50|"+adString1b+"|/color|"
			elseif a.GetDaysLeft() = 0
				adString1b = "|color=220,80,80|"+adString1b+"|/color|"
			endif
			local adString2a:string = "Min: " +TFunctions.DottedValue(a.GetMinAudience())
			if a.GetLimitedToTargetGroup() > 0 or a.GetLimitedToGenre() > 0  or a.GetLimitedToProgrammeFlag() > 0
				adString2a = "**" + adString2a
				'adString1a :+ a.GetLimitedToTargetGroup()+","+a.GetLimitedToGenre()+","+a.GetLimitedToProgrammeFlag()
			endif
			adString1b :+ " Bl/D: "+a.SendMinimalBlocksToday()

			local adString2b:string = "Acu: " +MathHelper.NumberToString(a.GetAcuteness()*100.0)
			local adString2c:string = a.GetSpotsSent() + "/" + a.GetSpotCount()
			GetBitmapFont("default", 10).DrawBlock( adString1a, x+192, y+1 + entryPos*lineHeight*2 + lineHeight*0, 130, lineHeight, ALIGN_LEFT_CENTER,,,,,False)
			GetBitmapFont("default", 10).DrawBlock( adString1b, x+192 + 103, y+1 + entryPos*lineHeight*2 + lineHeight*0, 35+30, lineHeight, ALIGN_RIGHT_CENTER, secondLineCol)

			GetBitmapFont("default", 10).DrawBlock( adString2a, x+192, y+1 + entryPos*lineHeight*2 + lineHeight*1 -1, 60, lineHeight, ALIGN_LEFT_CENTER, secondLineCol,,,,False)
			GetBitmapFont("default", 10).DrawBlock( adString2b, x+192 + 65, y+1 + entryPos*lineHeight*2 + lineHeight*1 -1, 55, lineHeight, ALIGN_CENTER_CENTER, secondLineCol)
			GetBitmapFont("default", 10).DrawBlock( adString2c, x+192 + 110, y+1 + entryPos*lineHeight*2 + lineHeight*1 -1, 55, lineHeight, ALIGN_RIGHT_CENTER, secondLineCol)

			entryPos :+ 1
		next
		SetAlpha oldAlpha
		SetColor 255,255,255
	End Method
End Type



Type TDebugProgrammePlanInfos
	Global programmeBroadcasts:TMap = CreateMap()
	Global adBroadcasts:TMap = CreateMap()
	Global newsInShow:TMap = CreateMap()
	Global oldestEntryTime:Long
	Global _eventListeners:TLink[]
	global predictor:TBroadcastAudiencePrediction = new TBroadcastAudiencePrediction
	global predictionCacheProgAudience:TAudience[24]
	global predictionCacheProg:TAudienceAttraction[24]
	global predictionCacheNews:TAudienceAttraction[24]
	global currentPlayer:int = 0
	
	Method New()
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]
		
		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.addObject", onChangeProgrammePlan) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.SetNews", onChangeNewsShow) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.RemoveNews", onChangeNewsShow) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.removeObject", onChangeProgrammePlan) ]

	End Method


	Function onChangeNewsShow:Int(triggerEvent:TEventBase)
		local broadcast:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("news"))
		local slot:int = triggerEvent.GetData().GetInt("slot", -1)
		if not broadcast or slot < 0 then return False

		newsInShow.Insert(broadcast.GetGUID(), string(Time.GetTimeGone()) )

		RemoveOutdated()
	End Function
	

	Function onChangeProgrammePlan:Int(triggerEvent:TEventBase)
		local broadcast:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("object"))
		local slotType:int = triggerEvent.GetData().GetInt("slotType", -1)
		if not broadcast or slotType <= 0 then return False

		if slotType = TVTBroadcastMaterialType.ADVERTISEMENT
			adBroadcasts.Insert(broadcast.GetGUID(), string(Time.GetTimeGone()) )
		else
			programmeBroadcasts.Insert(broadcast.GetGUID(), string(Time.GetTimeGone()) )
		endif

		RemoveOutdated()
	End Function


	Function RemoveOutdated()
		local maps:TMap[] = [programmeBroadcasts, adBroadcasts, newsInShow]

		oldestEntryTime = -1

		'remove outdated ones (older than 30 seconds))
		For local map:TMap = EachIn maps
			local remove:string[]
			For local guid:String = EachIn map.Keys()
				local broadcastTime:Long = Long( string(map.ValueForKey(guid)) )
				'old or not happened yet ?
				if broadcastTime + 8000 < Time.GetTimeGone() ' or broadcastTime > Time.GetTimeGone()
					remove :+ [guid]
					continue
				endif

				if oldestEntryTime = -1 then oldestEntryTime = broadcastTime
				oldestEntryTime = Min(oldestEntryTime, broadcastTime)
			Next

			for local guid:string = EachIn remove
				map.Remove(guid)
			next
		Next

		'reset cache
		ResetPredictionCache( GetWorldTime().GetDayHour()+1 )
	End Function


	Function ResetPredictionCache(minHour:int = 0)
		if minHour = 0
			predictionCacheProgAudience = new TAudience[24]
			predictionCacheProg = new TAudienceAttraction[24]
			predictionCacheNews = new TAudienceAttraction[24]
		else
			for local hour:int = minHour to 23
				predictionCacheProgAudience[hour] = null
				predictionCacheProg[hour] = null
				predictionCacheNews[hour] = null
			Next
		endif
	End Function
	

	Function GetAddedTime:Long(guid:string, slotType:int=0)
		Select slotType
			case TVTBroadcastMaterialType.PROGRAMME
				return int( string(programmeBroadcasts.ValueForKey(guid)) )
			case TVTBroadcastMaterialType.ADVERTISEMENT
				return int( string(adBroadcasts.ValueForKey(guid)) )
			case TVTBroadcastMaterialType.NEWS
				return int( string(newsInShow.ValueForKey(guid)) )
		End Select
		return 0
	End Function


	Method Update(playerID:int, x:int, y:int)
	End Method

	
	Function Draw(playerID:int, x:int, y:int)
		if playerID <= 0 then playerID = GetPlayerBase().playerID
		local currDay:int = GetWorldTime().GetDay()
		local currHour:int = GetWorldTime().GetDayHour()
		Local daysProgramme:TBroadcastMaterial[] = GetPlayerProgrammePlan( playerID ).GetProgrammeSlotsInTimeSpan(currDay, 0, currDay, 23)
		Local daysAdvertisements:TBroadcastMaterial[] = GetPlayerProgrammePlan( playerID ).GetAdvertisementSlotsInTimeSpan(currDay, 0, currDay, 23)
		Local lineHeight:int = 12
		
		'statistic for today
		local dailyBroadcastStatistic:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(currDay, true)

		'clean up if needed
		if oldestEntryTime >= 0 and oldestEntryTime + 10000 < Time.GetTimeGone() then RemoveOutdated()


		if currentPlayer <> playerID
			currentPlayer = playerID
			ResetPredictionCache(0) 'predict all again
		endif

		if GetWorldTime().GetTimeGone() mod 5 = 0
			predictor.RefreshMarkets()
		endif


		For local hour:int = 0 until daysProgramme.length
			local audienceResult:TAudienceResultBase
			if hour <= currHour
				audienceResult = dailyBroadcastStatistic.GetAudienceResult(playerID, hour)
			endif

			Local adString:String = ""
			Local progString:String = ""
			Local adString2:String = ""
			Local progString2:String = ""

			'use "0" as day param because currentHour includes days already
			Local advertisement:TBroadcastMaterial = daysAdvertisements[hour]
			If advertisement
				local spotNumber:string
				local specialMarker:string = ""
				local ad:TAdvertisement = TAdvertisement(advertisement)
				if ad
					if ad.IsState(TAdvertisement.STATE_FAILED)
						spotNumber = "-/" + ad.contract.GetSpotCount()
					else
						spotNumber = GetPlayerProgrammePlan(advertisement.owner).GetAdvertisementSpotNumber(ad) + "/" + ad.contract.GetSpotCount()
					endif

					if ad.contract.GetLimitedToTargetGroup()>0 or ad.contract.GetLimitedToGenre()>0 or ad.contract.GetLimitedToProgrammeFlag()>0
						specialMarker = "**"
					endif
				else
					spotNumber = (hour - advertisement.programmedHour + 1) + "/" + advertisement.GetBlocks(TVTBroadcastMaterialType.ADVERTISEMENT)
				endif
				adString = advertisement.GetTitle()
				if ad then adString = int(ad.contract.GetMinAudience()/1000) +"k " + adString
				adString2 = specialMarker + "[" + spotNumber + "]"

				if TProgramme(advertisement) then adString = "T: "+adString
			EndIf

			Local programme:TBroadcastMaterial = daysProgramme[hour]
			If programme
				progString = programme.GetTitle()
				if TAdvertisement(programme) then progString = "I: "+progString

				progString2 = (hour - programme.programmedHour + 1) + "/" + programme.GetBlocks(TVTBroadcastMaterialType.PROGRAMME)
'				if currHour < hour
					'uncached
					if not predictionCacheProgAudience[hour]
						for local i:int = 1 to 4
							local prog:TBroadcastMaterial = GetPlayerProgrammePlan(i).GetProgramme(currDay, hour)
							if prog
								local progBlock:int = GetPlayerProgrammePlan(i).GetProgrammeBlock(currDay, hour)
								local prevProg:TBroadcastMaterial = GetPlayerProgrammePlan(i).GetProgramme(currDay, hour-1)
								local newsAttr:TAudienceAttraction = null
								local prevAttr:TAudienceAttraction = null
								if prevProg and currDay
									local prevProgBlock:int = GetPlayerProgrammePlan(i).GetProgrammeBlock(currDay, (hour-1 + 24) mod 24)
									if prevProgBlock > 0
										prevAttr = prevProg.GetAudienceAttraction((hour-1 + 24) mod 24, prevProgBlock, null, null, true, true)
									endif
								endif
								local newsAge:int = 0
								local newsshow:TBroadcastMaterial
								for local hoursAgo:int = 0 to 6
									newsshow = GetPlayerProgrammePlan(i).GetNewsShow(currDay, hour - hoursAgo)
									if newsshow then exit
									newsAge = hoursAgo
								Next
								if newsshow
									newsAttr = newsshow.GetAudienceAttraction(hour, 1, prevAttr, null, true, true)
'									newsAttr.MultiplyFloat()
								endif
								local attr:TAudienceAttraction = prog.GetAudienceAttraction(hour, progBlock, prevAttr, newsAttr, true, true)
								predictor.SetAttraction(i, attr)
							else
								predictor.SetAverageValueAttraction(i, 0)
							endif
						Next
						predictor.RunPrediction(currDay, hour)
						predictionCacheProgAudience[hour] = predictor.GetAudience(playerID)
					endif
					
					progString2 :+ " |color=200,255,200|"+int(predictionCacheProgAudience[hour].GetTotalSum()/1000)+"k|/color|"
'				endif
				if audienceResult
					progString2 :+ " / |color=255,220,210|"+int(audienceResult.audience.GetTotalSum()/1000) +"k|/color|"
				else
					progString2 :+ " / |color=255,220,210|??|/color|"
				endif

				local player:TPlayer = GetPlayer(playerID)
				local guessedAudience:TAudience
				if player then guessedAudience = TAudience(player.aiData.Get("guessedaudience_"+currDay+"_"+hour, null))
				if guessedAudience
					progString2 :+ " / |color=200,200,255|"+int(guessedAudience.GetTotalSum()/1000)+"k|/color|"
				else
					progString2 :+ " / |color=200,200,255|??|/color|"
				endif
			EndIf

			If progString = "" and GetWorldTime().GetDayHour() > hour Then progString = "PROGRAMME OUTAGE"
			If adString = "" and GetWorldTime().GetDayHour() > hour Then adString = "AD OUTAGE"

			local oldAlpha:Float = GetAlpha()
			if hour mod 2 = 0
				SetColor 0,0,0
			else
				SetColor 50,50,50
			endif
			SetAlpha 0.85 * oldAlpha
			DrawRect(x, y + hour * lineHeight, 15, lineHeight-1)
			DrawRect(x+20, y + hour * lineHeight, 195, lineHeight-1)
			DrawRect(x+220, y + hour * lineHeight, 150, lineHeight-1)


			local progTime:Long = 0, adTime:Long = 0
			if advertisement then adTime = GetAddedTime(advertisement.GetGUID(), TVTBroadcastMaterialType.ADVERTISEMENT)
			if programme then progTime = GetAddedTime(programme.GetGUID(), TVTBroadcastMaterialType.PROGRAMME)

			SetColor 255,235,20
			if progTime <> 0
				local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - progTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(x+20, y + hour * lineHeight, 195, lineHeight-1)
				SetBlend ALPHABLEND
			endif
			if adTime <> 0
				local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - adTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(x+220, y + hour * lineHeight, 150, lineHeight-1)
				SetBlend ALPHABLEND
			endif
			
			if hour < currHour and TAdvertisement(advertisement) and audienceResult
				local reachedAudience:int = audienceResult.audience.GetTotalSum()
				local adMinAudience:int = TAdvertisement(advertisement).contract.GetMinAudience()
				SetColor 160,160,255
				Setalpha 0.85 * oldAlpha
				DrawRect(x+225, y + hour * lineHeight + lineHeight - 4, 150 * Min(1.0,  reachedAudience / float(adMinAudience)), 2)
			endif

			SetColor 255,255,255
			SetAlpha oldAlpha

			GetBitmapFont("default", 10).Draw( Rset(hour,2).Replace(" ", "0"), x+2, y + hour*lineHeight)
			if programme then SetStateColor(programme)
			GetBitmapFont("default", 10).DrawBlock( progString, x+22, y + hour*lineHeight, 120, lineHeight, ALIGN_LEFT_TOP,,,,,False)
			GetBitmapFont("default", 10).DrawBlock( progString2, x+125, y + hour*lineHeight, 88, lineHeight, ALIGN_RIGHT_TOP)
			if advertisement then SetStateColor(advertisement)
			GetBitmapFont("default", 10).DrawBlock( adString, x+222, y + hour*lineHeight, 110, lineHeight, ALIGN_LEFT_TOP,,,,,False)
			GetBitmapFont("default", 10).DrawBlock( adString2, x+335, y + hour*lineHeight, 33, lineHeight, ALIGN_RIGHT_TOP)
			SetColor 255,255,255
		Next

		'a bit space between programme plan and news show plan
		local newsY:int = y + daysProgramme.length * lineHeight + lineHeight
		For local newsSlot:int = 0 to 2
			local news:TBroadcastMaterial = GetPlayerProgrammePlan( playerID ).GetNewsAtIndex(newsSlot)
			local oldAlpha:Float = GetAlpha()
			if newsSlot mod 2 = 0
				SetColor 0,0,40
			else
				SetColor 50,50,90
			endif
			SetAlpha 0.85 * oldAlpha
			DrawRect(x, newsY + newsSlot * lineHeight, 15, lineHeight-1)
			DrawRect(x+20, newsY + newsSlot * lineHeight, 195, lineHeight-1)


			if TNews(news)
				local newsTime:Long = GetAddedTime(news.GetGUID(), TVTBroadcastMaterialType.NEWS)
				if newsTime <> 0
					local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - newsTime) / 5000.0))
					SetColor 255,255,255
					SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
					SetBlend LIGHTBLEND
					DrawRect(x+20, newsY + newsSlot * lineHeight, 195, lineHeight-1)
					SetBlend ALPHABLEND
				endif

				SetColor 220,110,110
				SetAlpha 0.50 * oldAlpha
				DrawRect(x+22, newsY + newsSlot * lineHeight + lineHeight-3, 192 * TNews(news).newsEvent.GetTopicality(), 2)
			endif

			SetColor 255,255,255
			SetAlpha oldAlpha

			GetBitmapFont("default", 10).DrawBlock( newsSlot+1 , x+2, newsY + newsSlot*lineHeight, 11, lineHeight, ALIGN_CENTER_TOP)
			if news
				GetBitmapFont("default", 10).DrawBlock(news.GetTitle(), x+22, newsY + newsSlot*lineHeight, 192, lineHeight, ALIGN_LEFT_TOP,,,,False)
			else
				GetBitmapFont("default", 10).DrawBlock("NEWS OUTAGE", x+22, newsY + newsSlot*lineHeight, 192, lineHeight, ALIGN_LEFT_TOP, TColor.clRed)
			endif
		Next
	End Function
	

	Function SetStateColor(material:TBroadcastMaterial)
		if not material
			SetColor 255,255,255
			return
		endif
			
		Select material.state
			Case TBroadcastMaterial.STATE_RUNNING
				SetColor 255,230,120
			Case TBroadcastMaterial.STATE_OK
				SetColor 200,255,200
			Case TBroadcastMaterial.STATE_FAILED
				SetColor 250,150,120
			default
				SetColor 255,255,255
		End select
	End Function
End Type



Type TDebugPlayerControls
	Method Update:int(playerID:int, x:int, y:int)
		local player:TPlayer = GetPlayer(playerID)
		if not player then return False

		local buttonX:int = 0
		if UpdateButton(buttonX, y, 120, 20)
			player.GetFigure().FinishCurrentTarget()
		endif

		buttonX :+ 120+5
		if UpdateButton(x+buttonX,y, 140, 20)
			'forecfully! leave the room
			player.GetFigure().LeaveRoom(True)
		endif
	End Method

	
	Method Draw:int(playerID:int, x:int, y:int)
		local player:TPlayer = GetPlayer(playerID)
		if not player then return False

		local buttonX:int = x
		if not player.GetFigure().GetTarget()
			DrawButton("ohne Ziel", buttonX, y, 140, 20)
		else
			if not player.GetFigure().IsControllable()
				DrawButton("erzw. Ziel entfernen", buttonX, y, 140, 20)
			else
				DrawButton("Ziel entfernen", buttonX, y, 140, 20)
			endif
		endif

		buttonX :+ 140+5
		if TRoomBase(player.GetFigure().GetInRoom())
			DrawButton("in Raum: "+ TRoomBase(player.GetFigure().GetInRoom()).name, buttonX, y, 120, 20)
		else
			DrawButton("im Hochhaus", buttonX, y, 120, 20)
		endif
	End Method


	Method DrawButton(text:string, x:int, y:int, w:int, h:int)
		SetColor 150,150,150
		DrawRect(x,y,w,h)
		if THelper.MouseIn(x,y,w,h)
			SetColor 50,50,50
		else
			SetColor 0,0,0
		endif
		DrawRect(x+1,y+1,w-2,h-2)
		SetColor 255,255,255
		GetBitmapFont("default", 11).DrawBlock(text, x,y,w,h, ALIGN_CENTER_CENTER)
	End Method


	Method UpdateButton:int(x:int, y:int, w:int, h:int)
		if THelper.MouseIn(x,y,w,h)
			if MouseManager.IsHit(1)
				MouseManager.ResetKey(1)
				return True
			endif
		endif
		return False
	End Method
End Type



Type TDebugFinancialInfos
	Method Update(playerID:int, x:int, y:int)
	End Method

	Method Draw(playerID:int, x:int, y:int)
		if playerID = -1
			Draw(1, x, y + 30*0)
			Draw(2, x, y + 30*1)
			Draw(3, x + 125, y + 30*0)
			Draw(4, x + 125, y + 30*1)
			return
		endif
		
		SetColor 0,0,0
		DrawRect(x, y, 123, 30)

		SetColor 255,255,255

		local textX:int = x+1
		local textY:int = y+1

		local finance:TPlayerFinance = GetPlayerFinance(playerID, GetWorldTime().GetDay(), True)
		local financeTotal:TPlayerFinance = GetPlayerFinanceCollection().GetTotal(playerID)

		local font:TBitmapfont = GetBitmapFont("default", 10)
		font.Draw("Money #"+playerID+": "+TFunctions.dottedValue(finance.money), textX, textY)
		textY :+ 9+1
		font.Draw("~tLic:~t~t|color=120,255,120|"+TFunctions.dottedValue(finance.income_programmeLicences)+"|/color| / |color=255,120,120|"+TFunctions.dottedValue(finance.expense_programmeLicences), textX, textY)
		textY :+ 9
		font.Draw("~tAd:~t~t|color=120,255,120|"+TFunctions.dottedValue(finance.income_ads)+"|/color| / |color=255,120,120|"+TFunctions.dottedValue(finance.expense_penalty), textX, textY)
	End Method
End Type



Type TDebugModifierInfos
	Method Update(x:int, y:int)
	End Method

	Method Draw(x:int=0, y:int=0)
		SetColor 0,0,0
		DrawRect(x, y, 200, 350)

		SetColor 255,255,255

		local textX:int = x+1
		local textY:int = y+1

		local font:TBitmapfont = GetBitmapFont("default", 10)
		font.Draw("Modifiers", textX, textY)
		textY :+ 12

		local data:TData = GameConfig._modifiers
		if data
			for local k:TLowerString = eachIn data.data.Keys()
				font.Draw(k.ToString(), textX, textY)
				textY :+ 10
				font.Draw("    =    "+ data.GetString(k.ToString()), textX, textY)
				textY :+ 10
			next
		endif
	End Method
End Type